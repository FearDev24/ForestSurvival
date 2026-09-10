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

## Emitido quando a apresentação da morte termina. Só é pedido para inimigos
## de morte encenada (DEC-024); os comuns somem sem passar por aqui.
signal death_animation_finished

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

## Nome da animação de morte no `SpriteFrames`. Quando a arte da queda do
## Guardião chegar, ela entra com este nome e substitui a queda provisória
## sozinha, sem tocar em código.
const _DEATH_ANIMATION := &"death"

## Duração da queda provisória: três lampejos e o corpo afundando no chão.
const _FLASH_IDA := 0.07
const _FLASH_VOLTA := 0.13
const _AFUNDAR := 1.3
const _REPOUSO := 0.3

var _facing: Enemy.Facing = Enemy.Facing.SOUTH
var _moving := false
var _morrendo := false

## Procurado na primeira vez que faz falta, não em `@onready`: `set_frames()` é
## chamado **antes** de o nó entrar na árvore, e `_ready` também não dispara em
## nó acrescentado de dentro de `SceneTree._initialize()`. Mesma inicialização
## preguiçosa do `HealthComponent` e do `Hud`.
var _sprite: AnimatedSprite2D = null


func _ready() -> void:
	_apply()


func _resolver() -> AnimatedSprite2D:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	return _sprite


## Troca as animações deste inimigo.
##
## É o único ponto por onde a arte entra: `enemy.gd` passa o que o `EnemyData`
## traz e não sabe o que é um `SpriteFrames`. Trocar a arte de um tipo é trocar
## o `.tres`, não mexer em lógica (DEC-013).
func set_frames(frames: SpriteFrames) -> void:
	if frames == null:
		return
	var sprite := _resolver()
	if sprite == null:
		return
	sprite.sprite_frames = frames
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


## Toca a morte encenada.
##
## Com arte — uma animação `death` no `SpriteFrames` —, toca ela uma vez. Sem
## arte, a queda provisória abaixo, que é PLACEHOLDER declarado (DEC-013): o
## fluxo de fim de partida já espera por ela, e trocar pela arte é só trocar o
## `.tres`.
func play_death() -> void:
	if _morrendo:
		return
	_morrendo = true

	var sprite := _resolver()
	var frames := sprite.sprite_frames if sprite != null else null
	if frames == null or not frames.has_animation(_DEATH_ANIMATION):
		_queda_provisoria()
		return

	sprite.play(_DEATH_ANIMATION)
	if frames.get_animation_loop(_DEATH_ANIMATION):
		# Em loop, `animation_finished` nunca dispara e a vitória nunca viria.
		# A queda termina pelo tempo de uma volta, e o aviso diz o que corrigir.
		push_warning("A animação 'death' está em loop; desligue o loop no SpriteFrames.")
		var fps := maxf(1.0, frames.get_animation_speed(_DEATH_ANIMATION))
		var duracao := frames.get_frame_count(_DEATH_ANIMATION) / fps
		get_tree().create_timer(duracao, false).timeout.connect(_terminar_morte)
	else:
		sprite.animation_finished.connect(_terminar_morte, CONNECT_ONE_SHOT)


## Três lampejos, e o corpo afunda no chão e escurece.
##
## Afundar é encolher só na vertical: a origem do nó está nos pés, então o
## corpo desce em direção ao chão em vez de encolher para o centro — lê como
## desabar, não como sumir.
func _queda_provisoria() -> void:
	if _sprite != null:
		_sprite.pause()

	var escala := scale
	var tween := create_tween()
	for i in 3:
		tween.tween_property(self, "modulate", Color(2.2, 2.2, 2.2), _FLASH_IDA)
		tween.tween_property(self, "modulate", Color.WHITE, _FLASH_VOLTA)
	tween.set_parallel(true)
	var afundar := tween.tween_property(self, "scale", Vector2(escala.x * 1.25, escala.y * 0.12), _AFUNDAR)
	afundar.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var apagar := tween.tween_property(self, "modulate", Color(0.25, 0.08, 0.05, 0.0), _AFUNDAR)
	apagar.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_interval(_REPOUSO)
	tween.tween_callback(_terminar_morte)


func _terminar_morte() -> void:
	death_animation_finished.emit()


func _apply() -> void:
	# Morrendo, a animação é a da morte: virar ou parar não troca mais nada.
	if _morrendo:
		return
	if _resolver() == null or _sprite.sprite_frames == null:
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
