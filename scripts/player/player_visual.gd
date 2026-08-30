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
## está andando, que morreu); a representação é decidida aqui. `player.gd` não
## sabe quantas animações existem, nem quais direções têm arte, nem quantos
## frames dura a morte — só é avisado quando a apresentação da morte terminou.

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

## Emitido quando a animação de morte termina — ou imediatamente, se não houver
## arte de morte. É o gancho para a tela de game over, sem que ninguém de fora
## precise saber quantos frames a animação tem.
signal death_animation_finished

var _facing: Player.Facing = Player.Facing.SOUTH
var _moving := false
var _dead := false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_apply()


## Recebe o aviso de morte e toca a animação correspondente, uma única vez.
##
## Só existe arte de morte virada para o sul. As outras direções caem nela pela
## mesma cadeia de fallback das outras animações — melhor a pose certa na
## direção errada do que nenhuma pose.
func play_death() -> void:
	if _dead:
		return
	_dead = true

	var animation := _pick_death_animation()
	if animation.is_empty():
		# Sem arte de morte: o druida congela onde está e a partida segue.
		death_animation_finished.emit()
		return

	_sprite.animation = animation
	_sprite.frame = 0
	_sprite.play()


## Recebe a direção encarada pelo jogador.
func set_facing(facing: Player.Facing) -> void:
	if _dead or facing == _facing:
		return
	_facing = facing
	_apply()


## Recebe se o jogador está em movimento.
func set_moving(moving: bool) -> void:
	if _dead or moving == _moving:
		return
	_moving = moving
	_apply()


func _on_sprite_animation_finished() -> void:
	# `animation_finished` só dispara em animação sem loop, ou seja, na morte.
	if _dead:
		death_animation_finished.emit()


## Morte da direção encarada, depois a do sul. Sem nenhuma das duas, vazio.
func _pick_death_animation() -> StringName:
	var frames := _sprite.sprite_frames
	if frames == null:
		return &""

	var suffix: String = _DIRECTION_SUFFIX.get(_facing, _FALLBACK_SUFFIX)
	for candidate in ["death_%s" % suffix, "death_%s" % _FALLBACK_SUFFIX]:
		if frames.has_animation(candidate):
			return candidate
	return &""


func _apply() -> void:
	if _dead or _sprite == null or _sprite.sprite_frames == null:
		return

	var animation := _pick_animation()
	if animation.is_empty():
		return

	# Ainda não existe nenhuma animação de idle. Parado, o druida congela no
	# primeiro frame da caminhada da direção atual — preserva a direção certa
	# e não inventa pose. Quando um `idle_<direção>` entrar no `.tres`, o
	# passo 1 de `_pick_animation` passa a valer sozinho, sem mexer aqui.
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
