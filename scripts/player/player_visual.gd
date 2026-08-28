extends Node2D
## Camada visual do Player.
##
## Estado do asset: **CANDIDATE** (`docs/ASSET_WORKFLOW.md`, DEC-013).
## As sprites do druida estão no jogo para avaliação de leitura, escala e
## animação. Ainda não são `APPROVED`.
##
## Este nó é o único ponto de troca de arte do Player. Trocar as sprites
## significa trocar `assets/characters/druida_sprite_frames.tres` — nada em
## `player.gd` muda.
##
## Contrato com o gameplay: a lógica informa **intenção** (direção encarada, se
## está andando); a representação é decidida aqui. `player.gd` não sabe quantas
## animações existem, nem quais direções têm arte.

## Sufixo de animação por direção.
const _DIRECTION_SUFFIX := {
	Player.Facing.SOUTH: "south",
	Player.Facing.NORTH: "north",
	Player.Facing.WEST: "west",
	Player.Facing.EAST: "east",
}

## Direção usada quando a pedida não tem nenhuma animação (regra 9 do
## `ASSET_WORKFLOW`: falta de direção permite fallback temporário).
const _FALLBACK_SUFFIX := "south"

var _facing: Player.Facing = Player.Facing.SOUTH
var _moving := false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_apply()


## Recebe a direção encarada pelo jogador.
func set_facing(facing: Player.Facing) -> void:
	if facing == _facing:
		return
	_facing = facing
	_apply()


## Recebe se o jogador está em movimento.
func set_moving(moving: bool) -> void:
	if moving == _moving:
		return
	_moving = moving
	_apply()


func _apply() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return

	var animation := _pick_animation()
	if animation.is_empty():
		return

	# Só existe `idle_south`. Nas outras direções o parado reaproveita o
	# primeiro frame da caminhada, congelado — melhor preservar a direção
	# correta do que trocar para uma pose frontal errada.
	var freeze := not _moving and animation.begins_with("walk_")

	if _sprite.animation != animation:
		_sprite.animation = animation
		_sprite.frame = 0

	if freeze:
		_sprite.frame = 0
		_sprite.pause()
	elif not _sprite.is_playing():
		_sprite.play()


## Escolhe a animação mais específica que existir, degradando em ordem:
## estado + direção, caminhada da mesma direção, estado no sul, caminhada sul.
func _pick_animation() -> StringName:
	var frames := _sprite.sprite_frames
	var suffix: String = _DIRECTION_SUFFIX.get(_facing, _FALLBACK_SUFFIX)
	var state := "walk" if _moving else "idle"

	for candidate in [
		"%s_%s" % [state, suffix],
		"walk_%s" % suffix,
		"%s_%s" % [state, _FALLBACK_SUFFIX],
		"walk_%s" % _FALLBACK_SUFFIX,
	]:
		if frames.has_animation(candidate):
			return candidate

	push_warning("Nenhuma animação disponível para o Player (direção '%s')." % suffix)
	return &""
