class_name Player
extends CharacterBody2D
## Druida Guardião — jogador.
##
## Movimento, câmera e morte. A vida está no componente irmão `Health` e o dano
## chega pela `Hurtbox`; este script só reage à morte.
##
## Armas e coleta ainda não existem — entram nas FASES 4 e 5 do
## `docs/ROADMAP.md`.
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

## Emitido uma única vez, quando o jogador morre. O nó **não** é removido da
## árvore: game over, tela de resultado e restart são da FASE 9. Aqui o Player
## apenas para de responder e deixa de ser alvo.
signal died

## Emitido somente quando o jogador começa ou para de se mover.
## A camada visual usa isto para alternar entre parado e caminhando; a lógica
## não sabe que animações existem.
signal movement_state_changed(is_moving: bool)

## Velocidade em pixels por segundo.
## Faixa planejada no GDD (`docs/01_GAME_DESIGN.md`): 180–220 px/s.
## Valor provisório: o sistema de Stats só entra na FASE 6.
@export var move_speed: float = 200.0

## Zoom da câmera. Quanto menor, mais mundo cabe na tela.
##
## Em 1.0 a área visível é a resolução base inteira (1280 x 720 unidades de
## mundo) e o druida ocupa cerca de 13% da altura da tela — proporção adequada
## para um survivor-like, que precisa de espaço para hordas.
##
## Medições feitas em 1920 x 1080:
##
## | zoom | mundo visível | altura do druida |
## |------|---------------|------------------|
## | 2.0  | 640 x 360     | 26,7% da tela    |
## | 1.5  | 853 x 480     | 20,0% da tela    |
## | 1.0  | 1280 x 720    | 13,3% da tela    |
##
## Abaixo de 1.0 a arte passa a ser reduzida abaixo da resolução nativa e a
## pixel art perde definição; nesse caso o certo é gerar sprites menores, não
## diminuir mais o zoom.
@export var camera_zoom: float = 1.0

var facing: Facing = Facing.SOUTH

var _is_moving := false
var _is_dead := false

@onready var _camera: Camera2D = $Camera2D
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	# Garante que a camada visual comece coerente com o estado inicial.
	facing_changed.emit(facing)
	movement_state_changed.emit(_is_moving)


func _physics_process(_delta: float) -> void:
	if _is_dead:
		return

	# `Input.get_vector` já limita o comprimento a 1, então a diagonal não é
	# mais rápida que os eixos. Não multiplicar por delta: em CharacterBody2D
	# `velocity` é px/s e `move_and_slide()` aplica o passo de física.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * move_speed
	_update_facing(direction)
	_update_movement_state(direction)
	move_and_slide()


## Reage à morte vinda do `HealthComponent`, ligado na própria cena.
##
## O Player continua na árvore, com a câmera funcionando: quem decide o que
## acontece depois é a FASE 9. Aqui ele apenas para de andar e sai do radar das
## hitboxes, para não continuar levando golpes de quem já o matou.
func _on_health_died() -> void:
	if _is_dead:
		return
	_is_dead = true

	velocity = Vector2.ZERO
	_hurtbox.set_vulnerable(false)
	_update_movement_state(Vector2.ZERO)

	died.emit()


func is_dead() -> bool:
	return _is_dead


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
