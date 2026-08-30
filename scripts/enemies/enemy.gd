class_name Enemy
extends CharacterBody2D
## Diabrete — primeiro inimigo.
##
## Locomoção, direção e morte. Vida e dano ficam nos componentes irmãos
## (`Health`, `Hitbox`, `Hurtbox`): este script só reage à morte.
##
## Perseguição direta simples, sem NavigationAgent2D e sem pathfinding
## (DEC-008).
##
## Desacoplamento de arte (DEC-013 / `docs/ASSET_WORKFLOW.md`): este script
## nunca lê textura, sprite, tamanho de imagem ou animação. Ele informa
## intenção pelos sinais; o nó `Visual` decide a representação.

## Direção encarada. Mesma convenção do Player, mas declarada aqui: o inimigo
## não deve depender do jogador para existir.
enum Facing { SOUTH, NORTH, WEST, EAST }

## Emitido somente quando a direção muda, não a cada frame.
signal facing_changed(facing: Facing)

## Emitido somente quando o inimigo começa ou para de se mover.
signal movement_state_changed(is_moving: bool)

## Emitido uma única vez, quando o inimigo morre. Existe para que XP, efeitos e
## contagem de wave possam se pendurar aqui nas fases seguintes, sem que este
## script precise conhecer nenhum deles.
signal died

## Velocidade em pixels por segundo. Mais lento que o Player (200 px/s), para
## que dê para fugir. Valor provisório: o sistema de Stats só entra na FASE 6.
@export var move_speed: float = 110.0

var facing: Facing = Facing.SOUTH

var _is_moving := false
## Impede que a morte seja processada duas vezes. `HealthComponent` já garante
## que `died` só é emitido uma vez; este guarda cobre também uma chamada
## direta a `kill()`.
var _is_dying := false
## Referência ao alvo, resolvida **uma vez**. Nunca buscar por grupo dentro de
## `_physics_process`: o jogo precisa suportar centenas de inimigos
## (`docs/02_ARCHITECTURE.md`, DEC-011).
var _target: Node2D = null

@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	facing_changed.emit(facing)
	movement_state_changed.emit(_is_moving)


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	# `is_instance_valid` cobre o caso do alvo ser removido da árvore (morte do
	# Player, troca de cena): o inimigo apenas para, sem erro.
	if is_instance_valid(_target):
		direction = global_position.direction_to(_target.global_position)

	velocity = direction * move_speed
	_update_facing(direction)
	_update_movement_state(direction)
	move_and_slide()


## Reage à morte vinda do `HealthComponent`, ligado na própria cena.
##
## Some da partida de uma vez: um cadáver que continua colidindo e perseguindo
## seria pior que nenhum feedback. Efeito de morte e drop de XP entram nas
## FASES 5 e 11, penduradas no sinal `died`.
func _on_health_died() -> void:
	if _is_dying:
		return
	_is_dying = true

	set_physics_process(false)
	velocity = Vector2.ZERO
	_hurtbox.set_vulnerable(false)
	_hitbox.monitoring = false

	died.emit()
	queue_free()


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
		# Empate resolve para o eixo vertical, mesma regra fixa do Player.
		new_facing = Facing.SOUTH if direction.y > 0.0 else Facing.NORTH

	if new_facing == facing:
		return

	facing = new_facing
	facing_changed.emit(facing)
