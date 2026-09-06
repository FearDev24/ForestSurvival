extends CanvasLayer
## Tela de escolha ao subir de nível (`docs/03_SYSTEMS.md` §13).
##
## Pausa, oferece opções **válidas**, aplica uma só e volta ao jogo.
##
## Não decide o que pode ser oferecido nem o que uma escolha faz: isso é do
## `UpgradePool`, que trabalha sobre `UpgradeData` em `.tres`. Esta tela recebe
## uma lista pronta e devolve o id escolhido.
##
## A separação existe porque as duas coisas mudam por motivos diferentes: a
## regra do que é oferecível muda quando entra conteúdo, o desenho da tela muda
## quando entra arte.
##
## Níveis acumulam: subir três de uma vez abre a tela três vezes, uma escolha
## por vez. Sem isso, dois níveis no mesmo instante dariam uma escolha só e o
## jogador perderia o que ganhou.

## Emitido quando uma escolha é aplicada.
signal choice_made(id: StringName)

## Emitido quando a fila esvazia e o jogo volta a andar.
signal closed

## Quantas opções mostrar, no máximo.
const MAX_OPCOES := 3

var _pool: UpgradePool = null
var _pendentes := 0
## As opções da tela aberta, para o botão saber o que aplicar.
var _oferta: Array[UpgradeData] = []

@onready var _opcoes: VBoxContainer = $Caixa/Opcoes
@onready var _titulo: Label = $Caixa/Titulo


## Ligada pela raiz da partida.
func configure(pool: UpgradePool, level: LevelComponent) -> void:
	_pool = pool
	if level != null and not level.leveled_up.is_connected(_on_leveled_up):
		level.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(_level: int) -> void:
	_pendentes += 1
	if visible:
		return

	# Adiado de propósito. O nível costuma subir **dentro** da detecção de área
	# que coletou o fragmento, e pausar a árvore ali faz a Godot recusar: pausar
	# desliga o monitoramento das áreas, e mexer nisso durante a consulta de
	# física é proibido ("Can't change this state while flushing queries").
	_abrir.call_deferred()


func _abrir() -> void:
	_oferta = _pool.sortear(MAX_OPCOES) if _pool != null else [] as Array[UpgradeData]
	if _oferta.is_empty():
		# Nada aplicável: não faz sentido pausar o jogo para não oferecer nada.
		# Acontece quando todas as armas estão no nível máximo — até a FASE 6
		# trazer passivas, é um beco sem saída legítimo.
		_pendentes = 0
		return

	for antigo in _opcoes.get_children():
		antigo.queue_free()

	for upgrade in _oferta:
		var botao := Button.new()
		botao.text = _rotulo(upgrade)
		botao.custom_minimum_size = Vector2(0.0, 52.0)
		botao.add_theme_font_size_override("font_size", 22)
		# Ícone e moldura entram quando a arte chegar. Enquanto não chega, o
		# texto sozinho já deixa a escolha jogável (DEC-013).
		if upgrade.icon != null:
			botao.icon = upgrade.icon
			botao.expand_icon = true
		botao.pressed.connect(_on_escolha.bind(upgrade.id))
		_opcoes.add_child(botao)

	_titulo.text = "SUBIU DE NIVEL" if _pendentes <= 1 else "SUBIU DE NIVEL  (x%d)" % _pendentes
	visible = true
	get_tree().paused = true

	# Foco no primeiro botão: dá para escolher no teclado, sem mouse.
	if _opcoes.get_child_count() > 0:
		(_opcoes.get_child(0) as Button).grab_focus()


## Nome, efeito e quantas vezes a opção já foi levada.
##
## O contador só aparece a partir da segunda vez: "Casca de Carvalho II" diz ao
## jogador que ele está empilhando, e some quando não há o que dizer.
func _rotulo(upgrade: UpgradeData) -> String:
	var nome := upgrade.display_name
	var repetida := _pool.stacks(upgrade.id) if _pool != null else 0
	if repetida > 0:
		nome += "  %s" % "I".repeat(mini(repetida + 1, 5))

	var efeito := upgrade.description
	if efeito.is_empty():
		efeito = upgrade.resumo()
	return nome if efeito.is_empty() else "%s
%s" % [nome, efeito]


func _on_escolha(id: StringName) -> void:
	if _pool != null:
		_pool.apply(id)
	choice_made.emit(id)

	_pendentes = maxi(0, _pendentes - 1)
	if _pendentes > 0:
		# Ainda há nível na fila: uma escolha por vez, sem fechar no meio.
		_abrir()
		return

	visible = false
	get_tree().paused = false
	closed.emit()
