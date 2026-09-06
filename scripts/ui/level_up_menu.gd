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

## Tamanho de cada linha de opção, em pixels de viewport.
##
## A proporção é a da placa desenhada — 1970x330, ou 5,97:1. Deixar o container
## esticar a linha até a largura toda deformaria as pedras das pontas, então o
## tamanho é fixo e o container encolhe em volta.
##
## A altura sai da conta do painel: 448 px de área útil medidos na arte, menos o
## título e as folgas, dividido por três.
const TAMANHO_OPCAO := Vector2(704.0, 118.0)

## Lado do ícone dentro da linha.
##
## A madeira escura da placa ocupa 72% da altura dela — o resto são os trilhos
## de pedra de cima e de baixo. Numa linha de 118 px isso dá 85 px de banda
## útil, e um ícone maior que isso sai por cima dos trilhos.
const LADO_ICONE := 82.0

## Placa de fundo de cada opção, nos dois estados. Vêm da cena porque são arte,
## e arte não se escolhe em código (DEC-013).
@export var textura_opcao: Texture2D
@export var textura_opcao_destaque: Texture2D

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
		_opcoes.add_child(_montar_linha(upgrade))

	_titulo.text = "SUBIU DE NIVEL" if _pendentes <= 1 else "SUBIU DE NIVEL  (x%d)" % _pendentes
	visible = true
	get_tree().paused = true

	# Foco no primeiro botão: dá para escolher no teclado, sem mouse.
	if _opcoes.get_child_count() > 0:
		(_opcoes.get_child(0) as Button).grab_focus()


## Uma linha da tela: placa de fundo, ícone e texto.
##
## O botão continua sendo um `Button` de verdade — foco pelo teclado, `pressed`,
## estados — e o conteúdo entra como filho dele. Os filhos ignoram o mouse, para
## o clique chegar ao botão em vez de parar no rótulo.
func _montar_linha(upgrade: UpgradeData) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = TAMANHO_OPCAO
	botao.focus_mode = Control.FOCUS_ALL
	botao.pressed.connect(_on_escolha.bind(upgrade.id))
	_vestir(botao)

	var linha := HBoxContainer.new()
	linha.set_anchors_preset(Control.PRESET_FULL_RECT)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 18)
	# 90 px de recuo: a peça de pedra da ponta esquerda vai até 87 px numa linha
	# de 704, medido na própria placa. Menos que isso e o ícone monta em cima
	# dela; a ponta direita é simétrica.
	linha.offset_left = 90.0
	linha.offset_right = -90.0
	botao.add_child(linha)

	# A coluna do ícone existe mesmo sem ícone: sem ela, uma opção ainda sem arte
	# empurraria o texto para a esquerda e a fileira perderia o alinhamento.
	if upgrade.icon != null:
		var icone := TextureRect.new()
		icone.texture = upgrade.icon
		icone.custom_minimum_size = Vector2(LADO_ICONE, LADO_ICONE)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(icone)
	else:
		var vazio := Control.new()
		vazio.custom_minimum_size = Vector2(LADO_ICONE, LADO_ICONE)
		vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(vazio)

	var texto := VBoxContainer.new()
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.alignment = BoxContainer.ALIGNMENT_CENTER
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.add_theme_constant_override("separation", 2)
	linha.add_child(texto)

	texto.add_child(_rotulo_nome(upgrade))
	var efeito := upgrade.description if not upgrade.description.is_empty() else upgrade.resumo()
	if not efeito.is_empty():
		texto.add_child(_rotulo_efeito(efeito))

	return botao


## Troca o visual padrão do botão pela placa desenhada.
##
## Só `hover` e `pressed` acendem a placa. O foco **não** — a Godot desenha o
## estilo de foco **por cima** do estado, então uma placa acesa ali deixaria a
## primeira opção permanentemente ligada, já que ela recebe o foco ao abrir.
##
## O foco vira um contorno: quem navega no teclado continua vendo onde está, sem
## que a linha finja estar sob o mouse.
func _vestir(botao: Button) -> void:
	if textura_opcao == null:
		return

	var acesos: Array[String] = ["hover", "pressed"]
	var estados: Array[String] = ["normal", "hover", "pressed", "disabled"]
	for estado in estados:
		var caixa := StyleBoxTexture.new()
		var aceso: bool = estado in acesos and textura_opcao_destaque != null
		caixa.texture = textura_opcao_destaque if aceso else textura_opcao
		botao.add_theme_stylebox_override(estado, caixa)

	var contorno := StyleBoxFlat.new()
	contorno.draw_center = false
	contorno.border_color = Color(0.35, 0.95, 0.65, 0.85)
	contorno.set_border_width_all(2)
	contorno.set_corner_radius_all(3)
	# A placa tem musgo saindo das bordas; o contorno recua para não cortá-lo.
	contorno.set_expand_margin_all(-6.0)
	botao.add_theme_stylebox_override("focus", contorno)


func _rotulo_nome(upgrade: UpgradeData) -> Label:
	var nome := Label.new()
	nome.text = _titulo_da_opcao(upgrade)
	nome.add_theme_font_size_override("font_size", 25)
	nome.add_theme_color_override("font_color", Color(0.93, 0.98, 0.88))
	nome.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	nome.add_theme_constant_override("outline_size", 6)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return nome


func _rotulo_efeito(texto: String) -> Label:
	var linha := Label.new()
	linha.text = texto
	linha.add_theme_font_size_override("font_size", 17)
	linha.add_theme_color_override("font_color", Color(0.72, 0.82, 0.66))
	linha.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	linha.add_theme_constant_override("outline_size", 5)
	linha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return linha


## Nome, e quantas vezes a opção já foi levada.
##
## O contador só aparece a partir da segunda vez: "Casca de Carvalho II" diz ao
## jogador que ele está empilhando, e some quando não há o que dizer.
func _titulo_da_opcao(upgrade: UpgradeData) -> String:
	var repetida := _pool.stacks(upgrade.id) if _pool != null else 0
	if repetida <= 0:
		return upgrade.display_name
	# O contador só aparece a partir da segunda vez: "Casca de Carvalho II" diz
	# ao jogador que ele está empilhando, e some quando não há o que dizer.
	return "%s  %s" % [upgrade.display_name, "I".repeat(mini(repetida + 1, 5))]


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
