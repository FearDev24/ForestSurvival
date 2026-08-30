extends Node2D
## Camada visual do Enemy.
##
## Estado do asset: **CANDIDATE** (`docs/ASSET_WORKFLOW.md`, DEC-013).
## As sprites do diabrete estão no jogo para avaliação de leitura, escala e
## animação. Ainda não são `APPROVED`.
##
## Único ponto de troca de arte do inimigo: trocar a arte significa trocar
## `assets/characters/inimigos/diabrete_sprite_frames.tres` — nada em
## `enemy.gd` muda.
##
## Mesmo contrato da camada visual do Player: a lógica informa **intenção**
## (direção encarada, se está andando); a representação é decidida aqui.
##
## Escala: o nó `Visual` está em 0.5 na cena. O diabrete é uma criatura pequena,
## de cerca de metade da altura do druida, mas a arte veio no mesmo quadro de
## 64 x 96 (silhueta de ~92 px de altura, contra ~86 px do druida). Reduzir aqui
## é solução provisória e custa definição de pixel art: o certo é reexportar as
## sprites em 32 x 48 e devolver a escala para 1. Está registrado em
## `docs/TODO.md`. A escala fica no nó visual, nunca em `enemy.gd`.

## Sufixo de animação por direção.
const _DIRECTION_SUFFIX := {
	Enemy.Facing.SOUTH: "south",
	Enemy.Facing.NORTH: "north",
	Enemy.Facing.WEST: "west",
	Enemy.Facing.EAST: "east",
}

## Direção usada quando a pedida não tem nenhuma animação (regra 9 do
## `ASSET_WORKFLOW`: falta de direção permite fallback temporário).
const _FALLBACK_SUFFIX := "south"

var _facing: Enemy.Facing = Enemy.Facing.SOUTH
var _moving := false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_apply()


## Recebe a direção encarada pelo inimigo.
func set_facing(facing: Enemy.Facing) -> void:
	if facing == _facing:
		return
	_facing = facing
	_apply()


## Recebe se o inimigo está em movimento.
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

	# Inimigo não tem `idle`, e não vai ter (DEC-019). Parado, congela no
	# primeiro frame da caminhada da direção atual — preserva a direção certa e
	# não inventa pose. A tentativa de `idle_<direção>` continua na cadeia de
	# fallback porque não custa nada: se um inimigo específico um dia ganhar
	# pose parada, o passo 1 de `_pick_animation` passa a valer sozinho.
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

	push_warning("Nenhuma animação disponível para o Enemy (direção '%s')." % suffix)
	return &""
