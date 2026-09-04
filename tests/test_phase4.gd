extends SceneTree
## Verificação da FASE 4 — Primeira arma.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase4.gd
##
## Cobre os dados (`WeaponData`), o gerenciamento (`WeaponManager`) e o
## comportamento em execução: a arma dispara sozinha em cooldown, mira sem
## varrer o mundo por frame, o dano acompanha o nível e o ataque não deixa nó
## eterno na cena.
##
## Absorveu o antigo `tests/test_raio.gd`, que protegia o mesmo em forma de
## andaime. Não testa arte (DEC-013).

const GAME_SCENE := "res://scenes/game/game.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const ARMAS := [
	"res://resources/weapons/cajado_raio.tres",
	"res://resources/weapons/vinha_espinhosa.tres",
]

## Layer 5 — PlayerAttack, e layer 4 — EnemyHurtbox (DEC-014).
const LAYER_PLAYER_ATTACK := 1 << 4
const LAYER_ENEMY_HURTBOX := 1 << 3

## Distância do inimigo-cobaia. Dentro do alcance das duas armas.
const DISTANCIA_ALVO := 150.0
## Quanto tempo observar uma arma disparando sozinha.
const OBSERVA_SEGUNDOS := 4.0

var _failures: Array[String] = []

var _game: Node = null
var _player: Node2D = null
var _armas: WeaponManager = null
var _container: Node = null
var _effects: Node = null
var _enemy: CharacterBody2D = null
var _health: HealthComponent = null

var _stage := 0
var _frames_left := 0
var _ataques := 0
var _vida_antes := 0.0
var _dano_esperado := 0.0


func _initialize() -> void:
	_check_weapon_data()
	_check_scenes()
	_check_manager_isolado()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_start_observa()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_disparo_automatico()
				_finish()
				return true
	return false


# ---------------------------------------------------------------- estrutura --


## Os `.tres` das armas são editados à mão com frequência; um valor zerado passa
## despercebido e a arma simplesmente não atira.
func _check_weapon_data() -> void:
	var ids: Array[StringName] = []
	for caminho in ARMAS:
		if not ResourceLoader.exists(caminho):
			_fail("Arma não encontrada: %s" % caminho)
			continue

		var data: WeaponData = load(caminho)
		if data == null:
			_fail("%s não é um WeaponData" % caminho)
			continue

		if not data.is_valid():
			_fail("WeaponData inválido: %s (id '%s', dano %.1f, cooldown %.2f)" % [
				caminho, data.id, data.base_damage, data.cooldown])
		if data.id in ids:
			_fail("Duas armas com o mesmo id: '%s'" % data.id)
		ids.append(data.id)

		if data.attack_range <= 0.0:
			_fail("Alcance inválido em %s: %.1f" % [caminho, data.attack_range])
		if data.max_level < 1:
			_fail("max_level inválido em %s: %d" % [caminho, data.max_level])

		# Progressão tem de progredir: sem isto, subir de nível não faz nada e
		# o jogador não percebe a diferença.
		if data.damage_at(2) <= data.damage_at(1):
			_fail("%s não ganha dano ao subir de nível" % data.id)
		if data.cooldown_at(2) >= data.cooldown_at(1):
			_fail("%s não fica mais rápida ao subir de nível" % data.id)
		if data.cooldown_at(data.max_level) <= 0.0:
			_fail("%s chega a cooldown zero no nível máximo" % data.id)


## O ataque de cada arma tem de mirar o inimigo, e só ele.
func _check_scenes() -> void:
	for caminho in ARMAS:
		if not ResourceLoader.exists(caminho):
			continue
		var data: WeaponData = load(caminho)
		if data == null or data.effect_scene == null:
			continue

		var efeito: Node = data.effect_scene.instantiate()
		if not efeito.has_method("set_damage"):
			_fail("O ataque de '%s' não aceita set_damage(): o nível da arma não chegaria nele" % data.id)
		if data.aim_mode != WeaponData.Aim.NENHUMA and not efeito.has_method("aim"):
			_fail("'%s' aponta, mas o ataque dela não tem aim()" % data.id)
		if data.spawn_mode == WeaponData.Spawn.EM_VOLTA and data.spawn_radius <= 0.0:
			_fail("'%s' nasce em volta do druida, mas com raio %.1f" % [data.id, data.spawn_radius])

		var hitbox := efeito.get_node_or_null("Hitbox") as HitboxComponent
		if hitbox == null:
			_fail("O ataque de '%s' não tem HitboxComponent" % data.id)
		else:
			if hitbox.collision_layer != LAYER_PLAYER_ATTACK:
				_fail("Hitbox de '%s' fora da layer PlayerAttack: %d" % [data.id, hitbox.collision_layer])
			if hitbox.collision_mask != LAYER_ENEMY_HURTBOX:
				_fail("Hitbox de '%s' não mira EnemyHurtbox: %d" % [data.id, hitbox.collision_mask])
			if hitbox.hit_interval != 0.0:
				_fail("Ataque de arma é golpe único: hit_interval de '%s' é %.2f" % [data.id, hitbox.hit_interval])
		efeito.free()

	# O WeaponManager mora no Player (docs/02_ARCHITECTURE.md), mas nenhuma arma
	# específica pode estar dentro dele (DEC-009).
	if ResourceLoader.exists(PLAYER_SCENE):
		var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
		var manager := player.get_node_or_null("WeaponManager") as WeaponManager
		if manager == null:
			_fail("Player sem WeaponManager")
		elif manager.starting_weapons.is_empty():
			_fail("WeaponManager sem armas iniciais: a partida começaria sem como atacar")
		player.free()


## `WeaponManager` fora de cena, para checar as regras sem física no meio.
func _check_manager_isolado() -> void:
	if not ResourceLoader.exists(ARMAS[0]) or not ResourceLoader.exists(ARMAS[1]):
		return

	var raio: WeaponData = load(ARMAS[0])
	var vinha: WeaponData = load(ARMAS[1])

	var manager := WeaponManager.new()
	manager.max_slots = 2
	root.add_child(manager)

	if not manager.add_weapon(raio):
		_fail("Não aceitou a primeira arma")
	if manager.get_weapon_level(raio.id) != 1:
		_fail("Arma nova deveria entrar no nível 1, entrou no %d" % manager.get_weapon_level(raio.id))

	# Pedir a mesma arma de novo melhora, não duplica: é assim que a tela de
	# level up vai funcionar, e duplicar armaria duas cópias atirando juntas.
	manager.add_weapon(raio)
	if manager.get_weapon_count() != 1:
		_fail("Arma repetida duplicou: %d armas equipadas" % manager.get_weapon_count())
	if manager.get_weapon_level(raio.id) != 2:
		_fail("Arma repetida deveria subir para o nível 2, está no %d" % manager.get_weapon_level(raio.id))

	manager.add_weapon(vinha)
	if manager.get_weapon_count() != 2:
		_fail("Segunda arma não entrou")

	# Slots cheios: a terceira tem de ser recusada, não trocar ninguém.
	var terceira := WeaponData.new()
	terceira.id = &"teste_slot"
	terceira.effect_scene = raio.effect_scene
	terceira.base_damage = 1.0
	terceira.cooldown = 1.0
	if manager.add_weapon(terceira):
		_fail("Aceitou arma além do limite de slots")
	if manager.get_weapon_count() != 2:
		_fail("O limite de slots deixou passar: %d armas" % manager.get_weapon_count())

	# Teto de nível.
	for i in raio.max_level + 3:
		manager.upgrade_weapon(raio.id)
	if manager.get_weapon_level(raio.id) != raio.max_level:
		_fail("Nível passou do teto: %d de %d" % [manager.get_weapon_level(raio.id), raio.max_level])

	if manager.get_weapon_level(&"nao_existe") != 0:
		_fail("Arma inexistente deveria reportar nível 0")

	manager.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE) or not ResourceLoader.exists(ENEMY_SCENE):
		_fail("Cenas necessárias ausentes")
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_player = _game.get_node_or_null("Player") as Node2D
	_armas = _game.get_node_or_null("Player/WeaponManager") as WeaponManager
	_container = _game.get_node_or_null("EnemyContainer")
	_effects = _game.get_node_or_null("EffectContainer")
	var spawner := _game.get_node_or_null("SpawnManager") as SpawnManager
	if _player == null or _armas == null or _container == null or _effects == null:
		_fail("game.tscn sem Player, WeaponManager, EnemyContainer ou EffectContainer")
		return false

	if spawner != null:
		spawner.enabled = false

	_player.global_position = Vector2.ZERO
	return true


## Uma arma só, um alvo só, e vida alta: dá para contar golpes.
func _start_observa() -> void:
	if _armas.get_weapon_count() == 0:
		_fail("Nenhuma arma foi equipada ao começar a partida")
		_frames_left = 1
		_stage = 1
		return

	# Fica só o cajado: com duas armas atirando não dá para atribuir o dano.
	var raio: WeaponData = load(ARMAS[0])
	for arma in _armas.get_children():
		var w := arma as Weapon
		if w != null and w.data.id != raio.id:
			w.set_physics_process(false)
		elif w != null:
			w.attacked.connect(_on_attacked)
			_dano_esperado = w.data.damage_at(w.level)

	_enemy = (load(ENEMY_SCENE) as PackedScene).instantiate() as CharacterBody2D
	_container.add_child(_enemy)
	_enemy.global_position = Vector2(DISTANCIA_ALVO, 0.0)
	_enemy.set_physics_process(false)
	_health = _enemy.get_node_or_null("Health") as HealthComponent
	if _health == null:
		_fail("Inimigo sem HealthComponent")
		_frames_left = 1
		_stage = 1
		return
	_health.max_health = 99999.0
	_health.current_health = 99999.0
	_vida_antes = _health.current_health

	_frames_left = roundi(OBSERVA_SEGUNDOS * 60.0)
	_stage = 1


func _on_attacked(_efeito: Node2D, _alvo: Node2D) -> void:
	_ataques += 1


func _check_disparo_automatico() -> void:
	if _health == null:
		return

	var raio: WeaponData = load(ARMAS[0])
	var esperados := int(OBSERVA_SEGUNDOS / raio.cooldown_at(1))

	if _ataques == 0:
		_fail("A arma não disparou sozinha em %.1f s" % OBSERVA_SEGUNDOS)
		return

	# Um a mais ou a menos é arredondamento de frame; o dobro seria cooldown
	# ignorado, que é o erro que importa pegar.
	if absi(_ataques - esperados) > 1:
		_fail("Disparos fora do cooldown: %d em %.1f s, esperado ~%d" % [
			_ataques, OBSERVA_SEGUNDOS, esperados])

	var tirado := _vida_antes - _health.current_health
	var golpes := tirado / _dano_esperado
	if not is_equal_approx(golpes, float(_ataques)):
		_fail("Dano não bate com o nível: %.1f tirado em %d disparos de %.1f" % [
			tirado, _ataques, _dano_esperado])

	# Efeito é coisa de vida curta: nada pode ficar na cena depois.
	var vivos := _effects.get_child_count()
	if vivos > _ataques:
		_fail("EffectContainer acumulou nós: %d vivos para %d disparos" % [vivos, _ataques])

	print("  cajado: %d disparos em %.1f s (esperado ~%d), %.0f de dano, %.1f por golpe" % [
		_ataques, OBSERVA_SEGUNDOS, esperados, tirado, _dano_esperado])


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
		print("FASE 4 OK — arma dispara sozinha, mira, sobe de nível e limpa a cena.")
		return
	printerr("FASE 4 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
