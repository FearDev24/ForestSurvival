extends SceneTree
## Verificação da FASE 2 — Primeiro inimigo.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase2.gd
##
## Cobre estrutura (componentes, layers e masks), o `HealthComponent` isolado e
## o comportamento em execução: perseguição, dano por contato com intervalo,
## morte única e ausência de erro depois que o Player morre.
##
## Não testa arte: escala, sprite e animação podem mudar sem quebrar este teste
## (DEC-013).

const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const PLAYER_FRAMES := "res://assets/characters/druida_sprite_frames.tres"

## Layers da DEC-014, em valor de bit.
const LAYER_PLAYER_BODY := 1 << 0
const LAYER_ENEMY_BODY := 1 << 1
const LAYER_PLAYER_HURTBOX := 1 << 2
const LAYER_ENEMY_HURTBOX := 1 << 3
const LAYER_ENEMY_ATTACK := 1 << 5
## Layer 8 — WorldStatic (DEC-016).
const LAYER_WORLD_STATIC := 1 << 7

## Distância inicial entre inimigo e Player na medição de perseguição.
const CHASE_DISTANCE := 300.0
## Quanto tempo perseguir, em segundos simulados.
const CHASE_SECONDS := 1.0
## Quanto o inimigo deve pelo menos encurtar nesse tempo. A 110 px/s ele
## percorreria 110 px; exigir 60 absorve variação sem aceitar "parado".
const CHASE_MIN_PROGRESS := 60.0

## Tempo encostado no Player, em segundos simulados. Com `hit_interval` de 1 s,
## 1,2 s tem de render exatamente dois golpes: o da entrada e mais um.
const CONTACT_SECONDS := 1.2
const EXPECTED_CONTACT_HITS := 2

## Onde o inimigo é plantado no teste de travessia, à direita do Player.
const PASSTHROUGH_ENEMY_X := 100.0
## Quanto tempo o Player anda para a direita, em segundos simulados.
const PASSTHROUGH_SECONDS := 1.0
## A 200 px/s ele percorreria 200 px. Exigir 160 absorve arredondamento; se o
## inimigo bloqueasse, o Player pararia por volta de 72 px (raio 14 + raio 14).
const PASSTHROUGH_MIN_X := 160.0

## Quanto esperar pelo game over depois da morte, em frames. A animação de
## morte tem 27 frames a 15 fps, ou seja, 1,8 s; 200 frames dão folga de sobra.
const GAME_OVER_TIMEOUT_FRAMES := 200

## Distância inicial entre dois inimigos no teste de separação. Quase colados,
## mas não no mesmo ponto: sobreposição exata é caso degenerado de física.
const SEPARATION_START_GAP := 6.0
## Quanto eles precisam ter se afastado depois de conviver. Os corpos têm raio
## 14, então encostados ficam a 28 px; 20 dá folga sem aceitar sprites empilhadas.
const SEPARATION_MIN_DISTANCE := 20.0

var _failures: Array[String] = []

var _game: Node = null
var _player: CharacterBody2D = null
var _enemy: CharacterBody2D = null

var _stage := 0
var _frames_left := 0
var _chase_start_distance := 0.0
var _player_health_before := 0.0
var _second_enemy: CharacterBody2D = null
var _death_position := Vector2.ZERO
var _game_over_frame := -1
var _frames_since_death := 0
var _enemy_died_count := 0
## Contador do teste unitário do `HealthComponent`. É campo, e não variável
## local, porque lambdas em GDScript capturam locais **por valor**: um contador
## local nunca enxergaria o incremento feito dentro do sinal.
var _unit_death_count := 0
var _enemy_path := NodePath()


func _initialize() -> void:
	_check_enemy_scene()
	_check_render_order()
	_check_death_presentation()
	_check_player_scene()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			# O teste do HealthComponent roda aqui, e não em `_initialize`, para
			# que o componente passe de verdade pelo ciclo de vida da árvore —
			# inclusive `_ready`.
			_check_health_component()
			_chase_start_distance = _player.global_position.distance_to(_enemy.global_position)
			_frames_left = roundi(CHASE_SECONDS * 60.0)
			_stage = 1
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_chase()
				_start_contact()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_contact_damage()
				_start_passthrough()
		3:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_passthrough()
				_start_separation()
		4:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_separation()
				_start_enemy_death()
		5:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_enemy_death()
				_start_player_death()
		6:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_after_player_death()
				_start_game_over_watch()
		8:
			_frames_since_death += 1
			_frames_left -= 1
			var game_over := _game.get_node_or_null("GameOver") as CanvasItem
			if _game_over_frame < 0 and game_over != null and game_over.visible:
				_game_over_frame = _frames_since_death
			if _game_over_frame >= 0 or _frames_left <= 0:
				_check_game_over()
				_start_target_removal()
		7:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_after_target_removal()
				_finish()
				return true
	return false


# ---------------------------------------------------------------- estrutura --


## `HealthComponent` isolado, sem cena e sem física: `damage`, `heal`, limites e
## — o ponto crítico do critério de aceite — morte uma única vez.
func _check_health_component() -> void:
	var health := HealthComponent.new()
	health.max_health = 30.0
	root.add_child(health)

	if not is_equal_approx(health.current_health, 30.0):
		_fail("HealthComponent deveria começar com a vida cheia, está em %s" % health.current_health)

	health.damage(10.0)
	if not is_equal_approx(health.current_health, 20.0):
		_fail("damage(10) deveria deixar 20 de vida, deixou %s" % health.current_health)

	health.heal(5.0)
	if not is_equal_approx(health.current_health, 25.0):
		_fail("heal(5) deveria deixar 25 de vida, deixou %s" % health.current_health)

	health.heal(999.0)
	if not is_equal_approx(health.current_health, 30.0):
		_fail("heal não deveria ultrapassar max_health, chegou a %s" % health.current_health)

	health.damage(-5.0)
	if not is_equal_approx(health.current_health, 30.0):
		_fail("dano negativo não deveria curar, vida ficou em %s" % health.current_health)

	_unit_death_count = 0
	health.died.connect(func() -> void: _unit_death_count += 1)

	# Dois golpes letais no mesmo frame: exatamente o caso que faria um inimigo
	# morrer duas vezes se não houvesse guarda.
	health.damage(100.0)
	health.damage(100.0)

	if _unit_death_count != 1:
		_fail("HealthComponent emitiu 'died' %d vez(es), esperado 1" % _unit_death_count)
	if not is_equal_approx(health.current_health, 0.0):
		_fail("Vida deveria parar em 0, está em %s" % health.current_health)
	if not health.is_dead():
		_fail("is_dead() deveria ser true depois da morte")

	health.heal(50.0)
	if not is_equal_approx(health.current_health, 0.0):
		_fail("heal não deveria ressuscitar, vida foi para %s" % health.current_health)

	health.free()


func _check_enemy_scene() -> void:
	if not ResourceLoader.exists(ENEMY_SCENE):
		_fail("Cena do Enemy não encontrada: %s" % ENEMY_SCENE)
		return

	var enemy: Node = (load(ENEMY_SCENE) as PackedScene).instantiate()

	if not enemy is CharacterBody2D:
		_fail("Raiz do Enemy deveria ser CharacterBody2D, é %s" % enemy.get_class())
	if enemy.get_script() == null:
		_fail("Enemy está sem script")
	if not enemy.is_in_group("enemy"):
		_fail("Enemy não pertence ao grupo 'enemy'")

	var body := enemy as CharacterBody2D
	if body != null:
		if body.collision_layer != LAYER_ENEMY_BODY:
			_fail("collision_layer do Enemy esperado %d, encontrado %d" % [LAYER_ENEMY_BODY, body.collision_layer])
		# DEC-018: o inimigo separa-se dos outros inimigos e é barrado pelo
		# cenário, mas **não** colide com o corpo do Player.
		var expected_mask := LAYER_ENEMY_BODY | LAYER_WORLD_STATIC
		if body.collision_mask != expected_mask:
			_fail("collision_mask do Enemy esperado %d, encontrado %d" % [expected_mask, body.collision_mask])
		if (body.collision_mask & LAYER_PLAYER_BODY) != 0:
			_fail("Enemy não pode colidir com o corpo do Player: o Player atravessa a horda (DEC-018)")

	if enemy.get_node_or_null("Visual") == null:
		_fail("Enemy sem nó 'Visual' (camada de arte substituível)")

	var collision := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		_fail("Enemy sem CollisionShape2D com shape")

	var health := enemy.get_node_or_null("Health") as HealthComponent
	if health == null:
		_fail("Enemy sem HealthComponent em 'Health'")
	elif health.max_health <= 0.0:
		_fail("max_health do Enemy inválido: %s" % health.max_health)

	var hitbox := enemy.get_node_or_null("Hitbox") as HitboxComponent
	if hitbox == null:
		_fail("Enemy sem HitboxComponent em 'Hitbox'")
	else:
		if hitbox.collision_layer != LAYER_ENEMY_ATTACK:
			_fail("Hitbox do Enemy deveria estar na layer EnemyAttack (%d), está em %d" % [LAYER_ENEMY_ATTACK, hitbox.collision_layer])
		if hitbox.collision_mask != LAYER_PLAYER_HURTBOX:
			_fail("Hitbox do Enemy deveria mirar PlayerHurtbox (%d), mira %d" % [LAYER_PLAYER_HURTBOX, hitbox.collision_mask])
		if hitbox.damage <= 0.0:
			_fail("Hitbox do Enemy com dano inválido: %s" % hitbox.damage)
		if hitbox.hit_interval <= 0.0:
			_fail("Hitbox de contato precisa de hit_interval > 0, está em %s" % hitbox.hit_interval)
		if hitbox.get_node_or_null("CollisionShape2D") == null:
			_fail("Hitbox do Enemy sem forma de colisão")

	var hurtbox := enemy.get_node_or_null("Hurtbox") as HurtboxComponent
	if hurtbox == null:
		_fail("Enemy sem HurtboxComponent em 'Hurtbox'")
	else:
		if hurtbox.collision_layer != LAYER_ENEMY_HURTBOX:
			_fail("Hurtbox do Enemy deveria estar na layer EnemyHurtbox (%d), está em %d" % [LAYER_ENEMY_HURTBOX, hurtbox.collision_layer])
		if hurtbox.collision_mask != 0:
			_fail("Hurtbox não deve procurar ninguém: mask esperada 0, encontrada %d" % hurtbox.collision_mask)
		if hurtbox.health != health:
			_fail("Hurtbox do Enemy não está ligada ao HealthComponent")

	# Regra do `02_ARCHITECTURE`: colisão e caixas são irmãs de `Visual`.
	var visual := enemy.get_node_or_null("Visual")
	if visual != null and (visual.get_node_or_null("Hitbox") != null or visual.get_node_or_null("Hurtbox") != null):
		_fail("Hitbox/Hurtbox não podem ser filhas de 'Visual'")

	enemy.free()


func _check_player_scene() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		_fail("Cena do Player não encontrada: %s" % PLAYER_SCENE)
		return

	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()

	var body := player as CharacterBody2D
	if body != null and (body.collision_mask & LAYER_ENEMY_BODY) != 0:
		_fail("Player não pode colidir com o corpo do inimigo: ele atravessa a horda levando dano (DEC-018), mask %d" % body.collision_mask)

	var health := player.get_node_or_null("Health") as HealthComponent
	if health == null:
		_fail("Player sem HealthComponent em 'Health'")

	var hurtbox := player.get_node_or_null("Hurtbox") as HurtboxComponent
	if hurtbox == null:
		_fail("Player sem HurtboxComponent em 'Hurtbox'")
	else:
		if hurtbox.collision_layer != LAYER_PLAYER_HURTBOX:
			_fail("Hurtbox do Player deveria estar na layer PlayerHurtbox (%d), está em %d" % [LAYER_PLAYER_HURTBOX, hurtbox.collision_layer])
		if hurtbox.collision_mask != 0:
			_fail("Hurtbox do Player não deve procurar ninguém: mask %d" % hurtbox.collision_mask)
		if hurtbox.health != health:
			_fail("Hurtbox do Player não está ligada ao HealthComponent")

	player.free()


## Ordem de desenho: entidades ordenadas por Y, chão numa camada abaixo.
##
## Só dá para checar a configuração, não o resultado: `--headless` não desenha e
## a Godot não expõe consulta de ordem de desenho. A conferência visual foi feita
## à parte, com render (ver HANDOFF).
func _check_render_order() -> void:
	if not ResourceLoader.exists(GAME_SCENE):
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()

	var root_node := game as Node2D
	if root_node != null and not root_node.y_sort_enabled:
		_fail("Raiz de game.tscn sem y_sort_enabled: sprites altas não se ordenam por Y")

	var container := game.get_node_or_null("EnemyContainer") as Node2D
	if container == null:
		_fail("game.tscn sem EnemyContainer")
	elif not container.y_sort_enabled:
		_fail("EnemyContainer sem y_sort_enabled: a horda seria desenhada como um bloco só")

	var world := game.get_node_or_null("World") as Node2D
	if world == null:
		_fail("game.tscn sem World")
	elif world.z_index >= 0:
		_fail("World precisa de z_index negativo para ficar abaixo das entidades, está em %d" % world.z_index)

	game.free()


## Arte da morte e imagem de game over. Só a configuração: o resultado na tela
## foi conferido com render (ver HANDOFF).
func _check_death_presentation() -> void:
	if ResourceLoader.exists(PLAYER_FRAMES):
		var frames: SpriteFrames = load(PLAYER_FRAMES)
		if not frames.has_animation(&"death_south"):
			_fail("SpriteFrames do druida sem a animação 'death_south'")
		else:
			if frames.get_animation_loop(&"death_south"):
				_fail("A morte não pode estar em loop: ela toca uma vez e acaba")
			if frames.get_frame_count(&"death_south") < 2:
				_fail("Animação de morte com menos de 2 frames")
	else:
		_fail("SpriteFrames do druida não encontrado: %s" % PLAYER_FRAMES)

	if not ResourceLoader.exists(GAME_SCENE):
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	var game_over := game.get_node_or_null("GameOver") as Sprite2D
	if game_over == null:
		_fail("game.tscn sem o nó GameOver")
	else:
		if game_over.visible:
			_fail("GameOver deveria começar invisível")
		if game_over.texture == null:
			_fail("GameOver sem textura")
		if game_over.z_index <= 0:
			_fail("GameOver precisa de z_index positivo para ficar acima de tudo")

	var restart := game.get_node_or_null("CanvasLayer/RestartButton") as Button
	if restart == null:
		_fail("game.tscn sem o botão de reiniciar em CanvasLayer/RestartButton")
	else:
		if restart.visible:
			_fail("O botão de reiniciar deveria começar invisível")
		if restart.text.strip_edges().is_empty():
			_fail("Botão de reiniciar sem texto")

	game.free()


# ------------------------------------------------------------ comportamento --


## Monta a partida real, mas com um único inimigo controlado: os diabretes de
## `game.tscn` existem para teste manual e atrapalhariam a medição.
func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE) or not ResourceLoader.exists(ENEMY_SCENE):
		_fail("Cenas necessárias ausentes para o teste em execução")
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_player = _game.get_node_or_null("Player") as CharacterBody2D
	var container := _game.get_node_or_null("EnemyContainer")
	if _player == null or container == null:
		_fail("game.tscn sem Player ou EnemyContainer")
		return false

	# O SpawnManager encheria a cena de inimigos no meio das medições, e o raio
	# de teste mataria justamente o inimigo que está sendo medido.
	var spawner := _game.get_node_or_null("SpawnManager") as SpawnManager
	if spawner != null:
		spawner.enabled = false
	var caster := _game.get_node_or_null("RaioTeste") as LightningCaster
	if caster != null:
		caster.enabled = false

	for child in container.get_children():
		child.free()

	_player.global_position = Vector2.ZERO
	_enemy = _spawn_enemy(Vector2(CHASE_DISTANCE, 0.0))
	return _enemy != null


func _spawn_enemy(position: Vector2) -> CharacterBody2D:
	var container := _game.get_node_or_null("EnemyContainer")
	if container == null:
		return null
	var enemy := (load(ENEMY_SCENE) as PackedScene).instantiate() as CharacterBody2D
	container.add_child(enemy)
	enemy.global_position = position
	return enemy


func _check_chase() -> void:
	var distance := _player.global_position.distance_to(_enemy.global_position)
	var progress := _chase_start_distance - distance
	if progress < CHASE_MIN_PROGRESS:
		_fail("Inimigo não perseguiu: encurtou %.1f px em %.1f s (mínimo %.1f)" % [
			progress, CHASE_SECONDS, CHASE_MIN_PROGRESS])


## Encosta o inimigo no Player e mede o dano por contato.
func _start_contact() -> void:
	var health := _player.get_node_or_null("Health") as HealthComponent
	if health == null:
		_fail("Player sem Health na cena em execução")
		_stage = 7
		_frames_left = 1
		return

	_player_health_before = health.current_health
	_enemy.global_position = _player.global_position
	_frames_left = roundi(CONTACT_SECONDS * 60.0)
	_stage = 2


## O contato tem de tirar vida, e tem de respeitar `hit_interval`: sem ele o
## dano sairia a cada frame de física, cerca de 60 golpes por segundo.
func _check_contact_damage() -> void:
	var health := _player.get_node_or_null("Health") as HealthComponent
	var hitbox := _enemy.get_node_or_null("Hitbox") as HitboxComponent
	if health == null or hitbox == null:
		_fail("Não foi possível medir o dano por contato")
		return

	var taken := _player_health_before - health.current_health
	if taken <= 0.0:
		_fail("Contato com o inimigo não causou dano ao Player")
		return

	var hits := taken / hitbox.damage
	if not is_equal_approx(hits, float(EXPECTED_CONTACT_HITS)):
		_fail("Dano por contato em %.1f s foi de %.1f (%.1f golpes), esperado %d golpes" % [
			CONTACT_SECONDS, taken, hits, EXPECTED_CONTACT_HITS])


## O Player tem de atravessar o inimigo, não ser barrado por ele (DEC-018).
## O inimigo fica parado no caminho: a perseguição atrapalharia a medição.
func _start_passthrough() -> void:
	var health := _player.get_node_or_null("Health") as HealthComponent
	if health == null:
		_fail("Player sem Health na cena em execução")
		_stage = 7
		_frames_left = 1
		return

	# Inimigo novo: o anterior está com o intervalo entre golpes correndo, e a
	# travessia dura menos que esse intervalo. Aqui interessa saber se encostar
	# machuca, não se o mesmo inimigo pode golpear duas vezes seguidas.
	_enemy.queue_free()
	_player.global_position = Vector2.ZERO
	_enemy = _spawn_enemy(Vector2(PASSTHROUGH_ENEMY_X, 0.0))
	if _enemy == null:
		_fail("Não foi possível criar o inimigo do teste de travessia")
		_stage = 7
		_frames_left = 1
		return
	# Parado: perseguir atrapalharia a medição de deslocamento.
	_enemy.set_physics_process(false)
	_player_health_before = health.current_health

	Input.action_press("move_right")
	_frames_left = roundi(PASSTHROUGH_SECONDS * 60.0)
	_stage = 3


func _check_passthrough() -> void:
	Input.action_release("move_right")

	var final_x := _player.global_position.x
	if final_x < PASSTHROUGH_MIN_X:
		_fail("Player foi barrado pelo inimigo: parou em x=%.1f, esperado passar de %.1f" % [
			final_x, PASSTHROUGH_MIN_X])

	var health := _player.get_node_or_null("Health") as HealthComponent
	if health != null and health.current_health >= _player_health_before:
		_fail("Atravessar o inimigo não causou dano ao Player")


## Dois inimigos quase colados têm de se separar: sprite em cima de sprite não.
func _start_separation() -> void:
	_enemy.queue_free()
	_player.global_position = Vector2.ZERO

	_enemy = _spawn_enemy(Vector2(200.0, 0.0))
	_second_enemy = _spawn_enemy(Vector2(200.0 + SEPARATION_START_GAP, 0.0))
	if _enemy == null or _second_enemy == null:
		_fail("Não foi possível criar os inimigos do teste de separação")
		_stage = 7
		_frames_left = 1
		return

	_frames_left = 120
	_stage = 4


func _check_separation() -> void:
	if not is_instance_valid(_enemy) or not is_instance_valid(_second_enemy):
		_fail("Um dos inimigos do teste de separação sumiu")
		return

	var distance := _enemy.global_position.distance_to(_second_enemy.global_position)
	if distance < SEPARATION_MIN_DISTANCE:
		_fail("Inimigos ficaram empilhados: %.1f px de distância, mínimo %.1f" % [
			distance, SEPARATION_MIN_DISTANCE])

	# O segundo já cumpriu o papel; o resto do teste usa um inimigo só.
	_second_enemy.queue_free()
	_second_enemy = null


## Mata o inimigo pelo caminho oficial — a Hurtbox — e conta as mortes.
func _start_enemy_death() -> void:
	var hurtbox := _enemy.get_node_or_null("Hurtbox") as HurtboxComponent
	var health := _enemy.get_node_or_null("Health") as HealthComponent
	if hurtbox == null or health == null:
		_fail("Inimigo sem Hurtbox/Health na cena em execução")
		_stage = 7
		_frames_left = 1
		return

	_enemy_path = _enemy.get_path()
	_enemy.died.connect(func() -> void: _enemy_died_count += 1)

	var lethal := health.max_health + 1.0
	# Dois golpes letais no mesmo frame: o segundo não pode matar de novo.
	hurtbox.take_damage(lethal)
	hurtbox.take_damage(lethal)

	_frames_left = 5
	_stage = 5


func _check_enemy_death() -> void:
	if _enemy_died_count != 1:
		_fail("Inimigo emitiu 'died' %d vez(es), esperado 1" % _enemy_died_count)
	if is_instance_valid(_enemy):
		_fail("Inimigo morto continua na árvore")
	if _game.get_node_or_null(_enemy_path) != null:
		_fail("Nó do inimigo morto ainda é acessível por caminho")


## Mata o Player e coloca um inimigo novo perto dele: nada pode quebrar.
func _start_player_death() -> void:
	var hurtbox := _player.get_node_or_null("Hurtbox") as HurtboxComponent
	var health := _player.get_node_or_null("Health") as HealthComponent
	if hurtbox == null or health == null:
		_fail("Player sem Hurtbox/Health na cena em execução")
		_stage = 7
		_frames_left = 1
		return

	hurtbox.take_damage(health.max_health + 1.0)
	_enemy = _spawn_enemy(_player.global_position + Vector2(120.0, 0.0))
	_frames_left = 60
	_stage = 6


func _check_after_player_death() -> void:
	var health := _player.get_node_or_null("Health") as HealthComponent
	if health == null:
		return

	if not is_equal_approx(health.current_health, 0.0):
		_fail("Player deveria estar com 0 de vida, tem %s" % health.current_health)
	if not _player.is_dead():
		_fail("Player não marcou o próprio estado como morto")
	if not is_equal_approx(_player.velocity.length(), 0.0):
		_fail("Player morto continua com velocidade %s" % _player.velocity)
	if not is_instance_valid(_enemy):
		_fail("Inimigo sumiu depois da morte do Player")


## A imagem de game over só pode aparecer **depois** que a morte termina de ser
## apresentada, e no lugar onde o druida caiu.
func _start_game_over_watch() -> void:
	_death_position = _player.global_position
	_game_over_frame = -1
	_frames_since_death = 0
	_frames_left = GAME_OVER_TIMEOUT_FRAMES
	_stage = 8


func _check_game_over() -> void:
	var game_over := _game.get_node_or_null("GameOver") as Sprite2D
	if game_over == null:
		_fail("game.tscn sem o nó GameOver na cena em execução")
		return

	if _game_over_frame < 0:
		_fail("Game over não apareceu em %d frames depois da morte" % GAME_OVER_TIMEOUT_FRAMES)
		return

	# 60 frames já haviam corrido antes desta etapa; a animação tem 108.
	if _game_over_frame <= 5:
		_fail("Game over apareceu cedo demais: %d frames, antes de a morte terminar" % _game_over_frame)

	var offset := game_over.global_position.distance_to(_death_position)
	if offset > 96.0:
		_fail("Game over apareceu a %.0f px de onde o druida morreu" % offset)

	var restart := _game.get_node_or_null("CanvasLayer/RestartButton") as Button
	if restart == null:
		_fail("Botão de reiniciar ausente na cena em execução")
	elif not restart.visible:
		_fail("Botão de reiniciar não apareceu junto com o game over")
	elif restart.pressed.get_connections().is_empty():
		_fail("Botão de reiniciar não está ligado a nada")


## Último caso: o alvo deixa de existir. O inimigo tem de parar, não estourar.
func _start_target_removal() -> void:
	_player.queue_free()
	_player = null
	_frames_left = 30
	_stage = 7


func _check_after_target_removal() -> void:
	if not is_instance_valid(_enemy):
		_fail("Inimigo foi removido junto com o Player")
		return
	if not is_equal_approx(_enemy.velocity.length(), 0.0):
		_fail("Inimigo sem alvo deveria parar, velocidade %s" % _enemy.velocity)


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	Input.action_release("move_right")
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 2 OK — inimigo, vida, dano e morte validados.")
		return
	printerr("FASE 2 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
