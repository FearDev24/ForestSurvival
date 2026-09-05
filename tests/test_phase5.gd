extends SceneTree
## Verificação da FASE 5 — XP e Level Up.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase5.gd
##
## Cobre a curva de XP isolada — inclusive o ponto marcado como IMPORTANTE no
## `docs/03_SYSTEMS.md` §12, que é **não perder XP excedente** —, o drop ao
## morrer, a coleta, e a tela de escolha: pausa, opções válidas, uma escolha
## aplicada e a fila de níveis acumulados.
##
## Não testa arte (DEC-013): o orbe é um losango desenhado em código.

const GAME_SCENE := "res://scenes/game/game.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const ORB_SCENE := "res://scenes/pickups/xp_orb.tscn"

## Layer 7 — Pickup (DEC-014).
const LAYER_PICKUP := 1 << 6

var _failures: Array[String] = []

var _game: Node = null
var _player: Node2D = null
var _level: LevelComponent = null
var _menu: CanvasLayer = null
var _weapons: WeaponManager = null
var _pickups: Node = null
var _enemies: Node = null
var _spawner: PickupSpawner = null

var _stage := 0
var _frames_left := 0
var _xp_antes := 0.0
var _orbes_largados := 0


func _initialize() -> void:
	_check_curva()
	_check_estrutura()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_start_drop()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_drop()
				_start_coleta()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_coleta()
				_start_level_up()
		3:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_level_up()
				_start_sem_opcao()
		4:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_sem_opcao()
				_finish()
				return true
	return false


# ------------------------------------------------------------------ curva --


## `LevelComponent` sozinho, sem cena: é onde mora a regra que a §12 marca como
## IMPORTANTE.
func _check_curva() -> void:
	var level := LevelComponent.new()
	level.base_xp = 10.0
	level.xp_growth = 2.0
	root.add_child(level)

	if level.level != 1:
		_fail("Nível inicial deveria ser 1, é %d" % level.level)
	if not is_equal_approx(level.xp_to_next(), 10.0):
		_fail("Custo do primeiro nível deveria ser 10, é %.1f" % level.xp_to_next())

	# Ganho pequeno não sobe nível.
	level.add_xp(4.0)
	if level.level != 1 or not is_equal_approx(level.xp, 4.0):
		_fail("4 de XP não deveria subir nível: nível %d, xp %.1f" % [level.level, level.xp])

	# Fechar o nível exato deixa a sobra em zero.
	level.add_xp(6.0)
	if level.level != 2:
		_fail("10 de XP deveria fechar o nível 1, está no %d" % level.level)
	if not is_equal_approx(level.xp, 0.0):
		_fail("Sobra deveria ser zero, é %.1f" % level.xp)

	# O ponto da §12: um ganho grande sobe vários níveis **e guarda o resto**.
	# Do nível 2, os custos são 20 e 40; 65 paga os dois e sobra 5.
	var niveis_antes := level.level
	level.add_xp(65.0)
	if level.level != niveis_antes + 2:
		_fail("65 de XP deveria subir dois níveis, subiu %d" % (level.level - niveis_antes))
	if not is_equal_approx(level.xp, 5.0):
		_fail("XP excedente perdido: sobrou %.1f, esperado 5.0" % level.xp)

	# Curva mal configurada não pode travar o jogo em laço infinito.
	var quebrado := LevelComponent.new()
	quebrado.base_xp = 1.0
	quebrado.xp_growth = 0.0
	root.add_child(quebrado)
	quebrado.add_xp(1000.0)
	if quebrado.level < 2:
		_fail("Curva degenerada deveria ao menos subir de nível")
	quebrado.free()

	level.free()


# ---------------------------------------------------------------- estrutura --


func _check_estrutura() -> void:
	if ResourceLoader.exists(ORB_SCENE):
		var orbe: Node = (load(ORB_SCENE) as PackedScene).instantiate()
		var area := orbe as Area2D
		if area == null:
			_fail("O orbe de XP deveria ser um Area2D")
		else:
			if area.collision_layer != LAYER_PICKUP:
				_fail("Orbe fora da layer Pickup: %d" % area.collision_layer)
			if area.collision_mask != 0:
				_fail("Orbe não deve procurar ninguém: mask %d" % area.collision_mask)
		if not orbe.has_method("collect"):
			_fail("Orbe sem collect(): a área de coleta não saberia recolher")
		orbe.free()
	else:
		_fail("Cena do orbe não encontrada")

	if not ResourceLoader.exists(PLAYER_SCENE):
		return

	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	if player.get_node_or_null("Level") as LevelComponent == null:
		_fail("Player sem LevelComponent em 'Level'")

	var area := player.get_node_or_null("PickupArea") as PickupArea
	if area == null:
		_fail("Player sem PickupArea")
	else:
		if area.collision_mask != LAYER_PICKUP:
			_fail("PickupArea deveria procurar a layer Pickup, procura %d" % area.collision_mask)
		if area.get_radius() <= 0.0:
			_fail("PickupArea com raio inválido: %.1f" % area.get_radius())
	player.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE) or not ResourceLoader.exists(ENEMY_SCENE):
		_fail("Cenas necessárias ausentes")
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_player = _game.get_node_or_null("Player") as Node2D
	_level = _game.get_node_or_null("Player/Level") as LevelComponent
	_weapons = _game.get_node_or_null("Player/WeaponManager") as WeaponManager
	_menu = _game.get_node_or_null("LevelUpMenu") as CanvasLayer
	_pickups = _game.get_node_or_null("PickupContainer")
	_enemies = _game.get_node_or_null("EnemyContainer")
	_spawner = _game.get_node_or_null("PickupSpawner") as PickupSpawner
	var spawn := _game.get_node_or_null("SpawnManager") as SpawnManager

	if _player == null or _level == null or _menu == null or _pickups == null \
			or _enemies == null or _spawner == null:
		_fail("game.tscn sem Player, Level, LevelUpMenu, PickupContainer, EnemyContainer ou PickupSpawner")
		return false

	if spawn != null:
		spawn.enabled = false
	if _weapons != null:
		# As armas matariam os inimigos antes de o teste mandar.
		_weapons.set_weapons_enabled(false)

	_spawner.dropped.connect(_on_dropped)
	_player.global_position = Vector2.ZERO
	return true


func _on_dropped(_orbe: Node2D) -> void:
	_orbes_largados += 1


## Inimigo que morre longe do Player: o orbe tem de aparecer onde ele estava, e
## **não** ser coletado sozinho.
func _start_drop() -> void:
	var inimigo := (load(ENEMY_SCENE) as PackedScene).instantiate() as CharacterBody2D
	_enemies.add_child(inimigo)
	inimigo.global_position = Vector2(400.0, 0.0)
	inimigo.set_physics_process(false)
	_spawner.watch(inimigo)

	var vida := inimigo.get_node_or_null("Health") as HealthComponent
	if vida == null:
		_fail("Inimigo sem HealthComponent")
	else:
		vida.damage(vida.max_health + 1.0)

	_frames_left = 6
	_stage = 1


func _check_drop() -> void:
	if _orbes_largados != 1:
		_fail("Inimigo morto largou %d orbes, esperado 1" % _orbes_largados)
	if _pickups.get_child_count() != 1:
		_fail("PickupContainer tem %d nós, esperado 1" % _pickups.get_child_count())
		return

	var orbe := _pickups.get_child(0) as Node2D
	if orbe.global_position.distance_to(Vector2(400.0, 0.0)) > 1.0:
		_fail("Orbe apareceu em %s, esperado onde o inimigo morreu" % orbe.global_position)
	if not is_equal_approx(_level.xp, 0.0):
		_fail("XP subiu sem ninguém coletar: %.1f" % _level.xp)


## O Player anda até o orbe e coleta encostando.
func _start_coleta() -> void:
	_xp_antes = _level.xp
	if _pickups.get_child_count() > 0:
		var orbe := _pickups.get_child(0) as Node2D
		_player.global_position = orbe.global_position
	_frames_left = 8
	_stage = 2


func _check_coleta() -> void:
	if _pickups.get_child_count() != 0:
		_fail("Orbe continuou no chão depois de o Player encostar nele")
	if _level.xp <= _xp_antes and _level.level == 1:
		_fail("Coletar não somou XP: %.1f antes, %.1f depois" % [_xp_antes, _level.xp])


## Dois níveis de uma vez: a tela tem de pausar, oferecer opção válida e
## atender **um nível por escolha**.
func _start_level_up() -> void:
	if _weapons == null or _weapons.get_weapon_count() == 0:
		_fail("Sem armas equipadas: a tela de escolha não teria o que oferecer")
		_frames_left = 1
		_stage = 3
		return

	# XP com folga para dois níveis de uma vez.
	_level.add_xp(_level.xp_to_next() * 4.0)
	_frames_left = 4
	_stage = 3


func _check_level_up() -> void:
	if not _menu.visible:
		_fail("A tela de level up não apareceu")
		return
	if not paused:
		_fail("A tela de level up não pausou o jogo")

	var opcoes := _menu.get_node_or_null("Caixa/Opcoes")
	if opcoes == null or opcoes.get_child_count() == 0:
		_fail("A tela abriu sem nenhuma opção")
		paused = false
		return

	# Nenhuma opção pode ser impossível de aplicar (§13).
	for filho in opcoes.get_children():
		var botao := filho as Button
		if botao == null or botao.pressed.get_connections().is_empty():
			_fail("Opção sem ação ligada: '%s'" % (botao.text if botao else "?"))

	var primeira := opcoes.get_child(0) as Button
	var arma_antes := 0
	var id_alvo := &""
	for filho in _weapons.get_children():
		var arma := filho as Weapon
		if arma != null and primeira.text.begins_with(arma.data.display_name):
			id_alvo = arma.data.id
			arma_antes = arma.level

	primeira.pressed.emit()

	if id_alvo != &"" and _weapons.get_weapon_level(id_alvo) != arma_antes + 1:
		_fail("A escolha não subiu a arma de nível: %d -> %d" % [
			arma_antes, _weapons.get_weapon_level(id_alvo)])

	# Ainda há nível na fila: a tela continua aberta e o jogo, pausado.
	if not _menu.visible:
		_fail("A tela fechou com nível ainda na fila: escolha por nível se perderia")
	if not paused:
		_fail("O jogo voltou a andar com nível ainda na fila")

	# Escolhe o resto da fila até esvaziar.
	var guarda := 0
	while _menu.visible and guarda < 20:
		var lista := _menu.get_node_or_null("Caixa/Opcoes")
		if lista == null or lista.get_child_count() == 0:
			break
		(lista.get_child(0) as Button).pressed.emit()
		guarda += 1

	if _menu.visible:
		_fail("A tela não fechou depois de esvaziar a fila")
	if paused:
		_fail("O jogo continuou pausado depois de fechar a tela")
	paused = false

	print("  nível %d, %d escolhas atendidas" % [_level.level, guarda + 1])


## Todas as armas no teto: subir de nível não tem o que oferecer.
##
## A §13 pede "evitar opções impossíveis". Oferecer uma arma que já está no
## nível máximo seria uma escolha que não faz nada — e pausar o jogo para isso é
## pior ainda.
func _start_sem_opcao() -> void:
	if _weapons == null:
		_frames_left = 1
		_stage = 4
		return

	for filho in _weapons.get_children():
		var arma := filho as Weapon
		if arma != null:
			arma.level = arma.data.max_level

	_level.add_xp(_level.xp_to_next() * 2.0)
	_frames_left = 4
	_stage = 4


func _check_sem_opcao() -> void:
	if _menu.visible:
		var lista := _menu.get_node_or_null("Caixa/Opcoes")
		var quantas := lista.get_child_count() if lista != null else 0
		_fail("A tela abriu com todas as armas no teto, oferecendo %d opção(ões)" % quantas)
	if paused:
		_fail("O jogo pausou para uma escolha que não existia")
	paused = false


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	paused = false
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 5 OK — XP cai, é coletado, sobe de nível e a escolha vale.")
		return
	printerr("FASE 5 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
