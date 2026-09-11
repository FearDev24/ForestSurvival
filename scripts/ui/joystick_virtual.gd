class_name JoystickVirtual
extends Control
## Joystick virtual flutuante (`docs/ROADMAP.md`, FASE 12).
##
## Aparece onde o polegar encosta na metade esquerda da tela e aperta as mesmas
## ações do teclado — `move_left`, `move_right`, `move_up`, `move_down` —, com
## a força de quanto o polegar se afastou do centro. É o que o `docs/ANDROID.md`
## pede em "Input abstraction": o druida lê `Input.get_vector()` e não sabe que
## existe joystick.
##
## **Flutuante, e não fixo**: o canto inferior esquerdo, onde um joystick fixo
## iria, é da barra de vida. Nascendo sob o polegar, ele também não obriga o
## jogador a achar um ponto exato da tela sem olhar.
##
## Um dedo só: o primeiro toque na metade esquerda é o joystick, e os outros
## dedos ficam livres para os botões.
##
## Visual: PLACEHOLDER desenhado em código (DEC-013).

## Distância, em unidades de viewport, em que a força chega ao máximo.
@export var raio := 90.0

## Fração da largura da tela, a partir da esquerda, onde um toque começa o
## joystick.
@export var fracao_da_tela := 0.5

const _COR_BASE := Color(0.85, 1.0, 0.85, 0.14)
const _COR_BORDA := Color(0.85, 1.0, 0.85, 0.35)
const _COR_PONTA := Color(0.75, 1.0, 0.75, 0.5)

## Liga e desliga o joystick. Nasce ligado só em tela de toque; os testes e o
## modo de emular toque com o mouse ligam à mão.
var ativo := false:
	set = set_ativo

var _dedo := -1
var _centro := Vector2.ZERO
var _ponta := Vector2.ZERO
## As ações que **este** joystick apertou. Ele solta só estas.
var _apertadas := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_ativo(DisplayServer.is_touchscreen_available())


func set_ativo(valor: bool) -> void:
	ativo = valor
	visible = valor
	if not valor:
		soltar()


## Direção atual, com comprimento de 0 a 1. Zero sem dedo encostado.
func get_direcao() -> Vector2:
	if _dedo < 0:
		return Vector2.ZERO
	return ((_ponta - _centro) / maxf(1.0, raio)).limit_length(1.0)


func _input(event: InputEvent) -> void:
	if not ativo:
		return
	var toque := event as InputEventScreenTouch
	if toque != null:
		if toque.pressed and _dedo < 0 and _na_regiao(toque.position):
			_dedo = toque.index
			_centro = toque.position
			_ponta = toque.position
			_aplicar()
			get_viewport().set_input_as_handled()
		elif not toque.pressed and toque.index == _dedo:
			soltar()
			get_viewport().set_input_as_handled()
		return
	var arrasto := event as InputEventScreenDrag
	if arrasto != null and arrasto.index == _dedo:
		_ponta = arrasto.position
		_aplicar()
		get_viewport().set_input_as_handled()


func _na_regiao(posicao: Vector2) -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	return posicao.x < viewport.get_visible_rect().size.x * fracao_da_tela


## Solta as ações que o joystick apertou e esquece o dedo.
##
## **Só as que ele apertou.** A primeira versão soltava as quatro, e desligar o
## joystick com uma tecla segurada parava o druida de quem joga no teclado — a
## suíte da FASE 1 pegou, porque ela empurra o druida segurando a direita.
##
## Chamado também quando a partida pausa ou o app perde o foco: pausado, este
## nó não recebe mais o toque de soltar, e sem isto o druida voltaria da pausa
## andando sozinho.
func soltar() -> void:
	_dedo = -1
	for acao in _apertadas.keys():
		Input.action_release(acao)
	_apertadas.clear()
	queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE:
			if _dedo >= 0:
				soltar()


func _aplicar() -> void:
	var direcao := get_direcao()
	_eixo(&"move_right", &"move_left", direcao.x)
	_eixo(&"move_down", &"move_up", direcao.y)
	queue_redraw()


## Aperta o lado do eixo para onde o polegar aponta e solta o oposto. A zona
## morta é a das próprias ações (0,2 no `project.godot`), a mesma do teclado.
func _eixo(positivo: StringName, negativo: StringName, valor: float) -> void:
	if valor > 0.0:
		_largar(negativo)
		Input.action_press(positivo, valor)
		_apertadas[positivo] = true
	elif valor < 0.0:
		_largar(positivo)
		Input.action_press(negativo, -valor)
		_apertadas[negativo] = true
	else:
		_largar(positivo)
		_largar(negativo)


func _largar(acao: StringName) -> void:
	if _apertadas.has(acao):
		Input.action_release(acao)
		_apertadas.erase(acao)


func _draw() -> void:
	if _dedo < 0:
		return
	var centro := _centro - global_position
	var ponta := centro + (_ponta - _centro).limit_length(raio)
	draw_circle(centro, raio, _COR_BASE)
	draw_arc(centro, raio, 0.0, TAU, 48, _COR_BORDA, 3.0)
	draw_circle(ponta, raio * 0.42, _COR_PONTA)
