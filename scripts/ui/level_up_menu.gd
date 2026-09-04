extends CanvasLayer
## Tela de escolha ao subir de nível (`docs/03_SYSTEMS.md` §13).
##
## Faz o mínimo que a §13 exige: pausa, oferece opções **válidas**, aplica uma
## só e volta ao jogo.
##
## O que ela **não** faz ainda: passivas e novas armas. Hoje só existe melhorar
## arma equipada, porque só existem armas. O sistema de upgrades completo é a
## FASE 6 — e é lá que `UpgradeData` entra, no lugar do que aqui é montado à mão.
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

var _weapons: WeaponManager = null
var _pendentes := 0

@onready var _opcoes: VBoxContainer = $Caixa/Opcoes
@onready var _titulo: Label = $Caixa/Titulo


## Ligada pela raiz da partida.
func configure(weapons: WeaponManager, level: LevelComponent) -> void:
	_weapons = weapons
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
	var opcoes := _montar_opcoes()
	if opcoes.is_empty():
		# Nada aplicável: não faz sentido pausar o jogo para não oferecer nada.
		# Acontece quando todas as armas estão no nível máximo — até a FASE 6
		# trazer passivas, é um beco sem saída legítimo.
		_pendentes = 0
		return

	for antigo in _opcoes.get_children():
		antigo.queue_free()

	for opcao in opcoes:
		var botao := Button.new()
		botao.text = opcao["texto"]
		botao.custom_minimum_size = Vector2(0.0, 52.0)
		botao.add_theme_font_size_override("font_size", 22)
		botao.pressed.connect(_on_escolha.bind(opcao["id"]))
		_opcoes.add_child(botao)

	_titulo.text = "SUBIU DE NIVEL" if _pendentes <= 1 else "SUBIU DE NIVEL  (x%d)" % _pendentes
	visible = true
	get_tree().paused = true

	# Foco no primeiro botão: dá para escolher no teclado, sem mouse.
	if _opcoes.get_child_count() > 0:
		(_opcoes.get_child(0) as Button).grab_focus()


## Só entra na lista o que pode ser aplicado de verdade.
##
## A §13 pede "evitar opções impossíveis": oferecer uma arma que já está no
## nível máximo seria uma escolha que não faz nada.
func _montar_opcoes() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	if _weapons == null:
		return lista

	for filho in _weapons.get_children():
		var arma := filho as Weapon
		if arma == null or arma.level >= arma.data.max_level:
			continue
		lista.append({
			"id": arma.data.id,
			"texto": "%s  —  nivel %d" % [arma.data.display_name, arma.level + 1],
		})
		if lista.size() >= MAX_OPCOES:
			break

	return lista


func _on_escolha(id: StringName) -> void:
	if _weapons != null:
		_weapons.upgrade_weapon(id)
	choice_made.emit(id)

	_pendentes = maxi(0, _pendentes - 1)
	if _pendentes > 0:
		# Ainda há nível na fila: uma escolha por vez, sem fechar no meio.
		_abrir()
		return

	visible = false
	get_tree().paused = false
	closed.emit()
