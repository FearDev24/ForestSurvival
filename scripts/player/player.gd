class_name Player
extends CharacterBody2D
## Druida Guardião — jogador.
##
## FASE 1: apenas movimento e câmera.
## Sem HP, dano, hurtbox, armas ou coleta — esses sistemas entram nas fases
## seguintes do `docs/ROADMAP.md`.
##
## Desacoplamento de arte (DEC-013 / `docs/ASSET_WORKFLOW.md`):
## este script nunca lê textura, sprite, tamanho de imagem ou animação.
## Ele apenas informa a direção encarada pelo sinal `facing_changed`; o nó
## `Visual` decide como representá-la. Trocar o placeholder pela sprite
## definitiva do druida não deve exigir nenhuma alteração aqui.
##
## Input (DEC-005 / `docs/ANDROID.md`): o movimento usa exclusivamente Input
## Actions. Nenhuma tecla é lida diretamente, de modo que um joystick virtual
## no Android possa alimentar o mesmo código sem reescrita.

## Direção encarada. Existe para permitir integrar as sprites direcionais
## (south/north/west/east) mais tarde sem mexer na lógica de movimento.
enum Facing { SOUTH, NORTH, WEST, EAST }

## Emitido somente quando a direção muda, não a cada frame.
signal facing_changed(facing: Facing)

## Emitido somente quando o jogador começa ou para de se mover.
## A camada visual usa isto para alternar entre parado e caminhando; a lógica
## não sabe que animações existem.
signal movement_state_changed(is_moving: bool)

## Velocidade em pixels por segundo.
## Faixa planejada no GDD (`docs/01_GAME_DESIGN.md`): 180–220 px/s.
## Valor provisório: o sistema de Stats só entra na FASE 6.
@export var move_speed: float = 200.0

## Zoom da câmera. Provisório, para avaliar a leitura do personagem.
##
## Usar valores inteiros: a arte é pixel art e zoom fracionário produz pixels
## de tamanhos diferentes. Deve ser revisto na FASE 3, quando existirem hordas
## e o campo de visão passar a competir com a legibilidade.
@export var camera_zoom: float = 2.0

var facing: Facing = Facing.SOUTH

var _is_moving := false

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	# Garante que a camada visual comece coerente com o estado inicial.
	facing_changed.emit(facing)
	movement_state_changed.emit(_is_moving)


func _physics_process(_delta: float) -> void:
	# `Input.get_vector` já limita o comprimento a 1, então a diagonal não é
	# mais rápida que os eixos. Não multiplicar por delta: em CharacterBody2D
	# `velocity` é px/s e `move_and_slide()` aplica o passo de física.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * move_speed
	_update_facing(direction)
	_update_movement_state(direction)
	move_and_slide()


## Aplica os limites do mundo à câmera.
##
## Quem chama é a cena que compõe a partida: o Player não conhece o mapa, e o
## mapa não alcança dentro do Player. Ver `scripts/systems/game.gd`.
func apply_camera_limits(bounds: Rect2) -> void:
	_camera.limit_left = roundi(bounds.position.x)
	_camera.limit_top = roundi(bounds.position.y)
	_camera.limit_right = roundi(bounds.end.x)
	_camera.limit_bottom = roundi(bounds.end.y)


func _update_movement_state(direction: Vector2) -> void:
	var moving := not direction.is_zero_approx()
	if moving == _is_moving:
		return
	_is_moving = moving
	movement_state_changed.emit(_is_moving)


func _update_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return # Parado mantém a última direção válida.

	var new_facing: Facing
	if absf(direction.x) > absf(direction.y):
		new_facing = Facing.EAST if direction.x > 0.0 else Facing.WEST
	else:
		# Empate (diagonal exata) resolve para o eixo vertical. Regra fixa,
		# para que a direção não oscile enquanto o jogador anda na diagonal.
		new_facing = Facing.SOUTH if direction.y > 0.0 else Facing.NORTH

	if new_facing == facing:
		return

	facing = new_facing
	facing_changed.emit(facing)
