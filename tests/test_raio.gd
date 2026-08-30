extends SceneTree
## Verificação do **raio** — habilidade em teste, ainda fora do ROADMAP.
##
## Uso:
##   godot --headless --path . --script res://tests/test_raio.gd
##
## O raio e o `RaioTeste` são andaime: existem para ver a habilidade em jogo
## antes da FASE 4. Quando o `WeaponManager` existir (DEC-009), este arquivo é
## absorvido por `tests/test_phase4.gd` e some.
##
## O que ele protege enquanto isso: o modo de **golpe único** do
## `HitboxComponent` (que o raio estreou e as armas vão usar), o dano só a
## partir do frame de impacto, e o efeito não deixar nó eterno na cena.

const GAME_SCENE := "res://scenes/game/game.tscn"
const STRIKE_SCENE := "res://scenes/effects/lightning_strike.tscn"
const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"

## Layer 5 — PlayerAttack, e layer 4 — EnemyHurtbox (DEC-014).
const LAYER_PLAYER_ATTACK := 1 << 4
const LAYER_ENEMY_HURTBOX := 1 << 3

## Onde os inimigos-cobaia ficam, e onde o raio cai.
const TARGET_POSITION := Vector2(0.0, 120.0)

var _failures: Array[String] = []

var _game: Node = null
var _container: Node = null
var _effects: Node = null
var _enemy: CharacterBody2D = null
var _health: HealthComponent = null
var _strike: Node2D = null

var _stage := 0
var _frames_left := 0
var _damage := 0.0
var _health_at_start := 0.0
var _health_before_impact := -1.0
var _casts := 0


func _initialize() -> void:
	_check_strike_scene()
	_check_caster_scene()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_start_strike()
		1:
			# Antes do impacto o raio é só nuvem: não pode tirar vida.
			if is_instance_valid(_strike) and _strike.get_node("Sprite").frame < _strike.impact_frame:
				_health_before_impact = _health.current_health
			_frames_left -= 1
			if _frames_left <= 0:
				_check_strike_damage()
				_start_caster_watch()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_caster()
				_finish()
				return true
	return false


# ---------------------------------------------------------------- estrutura --


func _check_strike_scene() -> void:
	if not ResourceLoader.exists(STRIKE_SCENE):
		_fail("Cena do raio não encontrada: %s" % STRIKE_SCENE)
		return

	var strike: Node = (load(STRIKE_SCENE) as PackedScene).instantiate()

	var hitbox := strike.get_node_or_null("Hitbox") as HitboxComponent
	if hitbox == null:
		_fail("Raio sem HitboxComponent")
	else:
		if hitbox.collision_layer != LAYER_PLAYER_ATTACK:
			_fail("Hitbox do raio deveria estar na layer PlayerAttack (%d), está em %d" % [
				LAYER_PLAYER_ATTACK, hitbox.collision_layer])
		if hitbox.collision_mask != LAYER_ENEMY_HURTBOX:
			_fail("Hitbox do raio deveria mirar EnemyHurtbox (%d), mira %d" % [
				LAYER_ENEMY_HURTBOX, hitbox.collision_mask])
		if hitbox.hit_interval != 0.0:
			_fail("O raio é golpe único: hit_interval deveria ser 0, é %.2f" % hitbox.hit_interval)
		if hitbox.damage <= 0.0:
			_fail("Raio com dano inválido: %s" % hitbox.damage)

	var sprite := strike.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		_fail("Raio sem AnimatedSprite2D com SpriteFrames")
	elif sprite.sprite_frames.has_animation(&"strike"):
		if sprite.sprite_frames.get_animation_loop(&"strike"):
			_fail("A animação do raio não pode estar em loop: ela acontece e acaba")
	else:
		_fail("SpriteFrames do raio sem a animação 'strike'")

	strike.free()


func _check_caster_scene() -> void:
	if not ResourceLoader.exists(GAME_SCENE):
		_fail("Cena principal não encontrada: %s" % GAME_SCENE)
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	var caster := game.get_node_or_null("RaioTeste") as LightningCaster
	if caster == null:
		_fail("game.tscn sem o RaioTeste")
	else:
		if caster.strike_scene == null:
			_fail("RaioTeste sem strike_scene")
		if caster.cast_interval <= 0.0:
			_fail("cast_interval inválido: %s" % caster.cast_interval)
		if caster.cast_range <= 0.0:
			_fail("cast_range inválido: %s" % caster.cast_range)

	# O raio não pode morar dentro do Player: arma dentro do Player é
	# exatamente o acoplamento que a DEC-009 proíbe.
	var player := game.get_node_or_null("Player")
	if player != null and player.get_node_or_null("RaioTeste") != null:
		_fail("O disparo do raio não pode ficar dentro do Player (DEC-009)")

	game.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE) or not ResourceLoader.exists(ENEMY_SCENE):
		_fail("Cenas necessárias ausentes")
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_container = _game.get_node_or_null("EnemyContainer")
	_effects = _game.get_node_or_null("EffectContainer")
	var player := _game.get_node_or_null("Player") as Node2D
	var spawner := _game.get_node_or_null("SpawnManager") as SpawnManager
	if _container == null or _effects == null or player == null:
		_fail("game.tscn sem EnemyContainer, EffectContainer ou Player")
		return false

	if spawner != null:
		spawner.enabled = false

	player.global_position = Vector2.ZERO
	_enemy = (load(ENEMY_SCENE) as PackedScene).instantiate() as CharacterBody2D
	_container.add_child(_enemy)
	_enemy.global_position = TARGET_POSITION
	# Parado: perseguir tiraria o inimigo de baixo do raio.
	_enemy.set_physics_process(false)
	_health = _enemy.get_node_or_null("Health") as HealthComponent
	if _health == null:
		_fail("Inimigo sem HealthComponent")
		return false

	return true


## Deixa o raio cair em cima do inimigo e acompanha frame a frame.
func _start_strike() -> void:
	_strike = (load(STRIKE_SCENE) as PackedScene).instantiate() as Node2D
	_effects.add_child(_strike)
	_strike.global_position = TARGET_POSITION

	var hitbox := _strike.get_node_or_null("Hitbox") as HitboxComponent
	_damage = hitbox.damage if hitbox != null else 0.0
	# Vida alta de proposito: o inimigo tem de sobreviver ao raio para dar para
	# medir *quantas* vezes ele foi atingido.
	_health.max_health = 9999.0
	_health.current_health = 9999.0
	_health_at_start = _health.current_health

	# A animação tem 8 frames a 14 fps: 0,57 s. 60 frames cobrem com folga.
	_frames_left = 60
	_stage = 1


func _check_strike_damage() -> void:
	if _health_before_impact >= 0.0 and _health_before_impact < _health_at_start:
		_fail("O raio causou dano antes do frame de impacto")

	var taken := _health_at_start - _health.current_health
	if taken <= 0.0:
		_fail("O raio não causou dano ao inimigo embaixo dele")
	elif not is_equal_approx(taken, _damage):
		# É este o ponto do golpe único: o alvo continua dentro da área o tempo
		# todo, e mesmo assim leva dano uma vez só.
		_fail("Golpe único deveria tirar %.1f, tirou %.1f (%.1f golpes)" % [
			_damage, taken, taken / maxf(1.0, _damage)])

	if is_instance_valid(_strike):
		_fail("O raio não sumiu depois da animação: efeito virou nó eterno")

	if _effects.get_child_count() != 0:
		_fail("EffectContainer deveria ficar vazio, tem %d nós" % _effects.get_child_count())


## O `RaioTeste` tem de disparar sozinho, mirando quem está perto.
func _start_caster_watch() -> void:
	var caster := _game.get_node_or_null("RaioTeste") as LightningCaster
	if caster == null:
		_stage = 2
		_frames_left = 1
		return

	caster.enabled = true
	caster.cast.connect(_on_cast)
	_casts = 0
	_frames_left = roundi((caster.cast_interval + 0.5) * 60.0)
	_stage = 2


func _on_cast(_strike_node: Node2D) -> void:
	_casts += 1


func _check_caster() -> void:
	if _casts == 0:
		_fail("O RaioTeste não disparou sozinho com um inimigo no alcance")


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("RAIO OK — golpe único, dano no impacto e efeito temporário validados.")
		return
	printerr("RAIO FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
