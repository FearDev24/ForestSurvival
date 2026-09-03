extends SceneTree
## Verificação da FASE 1 — Movimento e mundo.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase1.gd
##
## Cobre estrutura (cenas, nós, grupo, layers) e comportamento de movimento
## (diagonal normalizada e independência de FPS). Não testa arte: o placeholder
## pode mudar a qualquer momento sem quebrar este teste (DEC-013).

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"

const EXPECTED_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"pause",
]

## Layer 1 (PlayerBody) — DEC-014.
const EXPECTED_PLAYER_LAYER := 1
## Mask apenas na layer 8 (WorldStatic) — DEC-016.
## O Player **não** colide com o corpo do inimigo: atravessa a horda e leva
## dano por contato, não empurrão (DEC-018).
const EXPECTED_PLAYER_MASK := 1 << 7

## Duração de cada medição de deslocamento, em segundos simulados.
const MEASURE_SECONDS := 0.5
## Tolerância do deslocamento medido, em pixels. Absorve o arredondamento de
## um frame; um bug de delta erraria por duas ordens de grandeza.
const DISTANCE_TOLERANCE := 8.0

## Quanto tempo empurrar o Player contra a parede, em segundos simulados.
const WALL_PUSH_SECONDS := 2.2
## De onde começar a empurrar, medido a partir da borda direita do mundo.
const WALL_PUSH_MARGIN := 140.0

var _failures: Array[String] = []
var _player: CharacterBody2D
var _game: Node
var _measurements: Dictionary = {}

var _pending_rates: Array[int] = [60, 30]
var _stage := 0
var _current_rate := 0
var _frames_left := 0
var _start_position := Vector2.ZERO


func _initialize() -> void:
	_check_input_actions()
	_check_player_scene()
	_check_game_scene()

	_player = _spawn_isolated_player()
	if _player == null:
		_report()
		quit(1)
		return

	# Anda só para a direita: isola o deslocamento em um eixo.
	Input.action_press("move_right")


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			if _pending_rates.is_empty():
				_stage = 3
				return false
			_current_rate = _pending_rates.pop_front()
			Engine.physics_ticks_per_second = _current_rate
			_stage = 1
		1:
			# Um frame de folga para a nova taxa de física valer.
			_start_position = _player.global_position
			_frames_left = roundi(MEASURE_SECONDS * float(_current_rate))
			_stage = 2
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_measurements[_current_rate] = _player.global_position.distance_to(_start_position)
				_stage = 0
		3:
			_check_speed()
			_check_diagonal()
			_start_world_run()
		4:
			_frames_left -= 1
			if _frames_left <= 0:
				_stage = 5
		5:
			_check_camera_limits()
			_check_world_walls()
			_finish()
			return true
	return false


## Troca o Player isolado pela cena completa, posicionado perto da borda
## direita, e continua empurrando para a direita contra a parede.
func _start_world_run() -> void:
	Input.action_release("move_down")
	_player.queue_free()
	_player = null

	Engine.physics_ticks_per_second = 60

	if not ResourceLoader.exists(GAME_SCENE):
		_stage = 5
		return

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	var player := _game.get_node_or_null("Player") as Node2D
	var world := _game.get_node_or_null("World/TestWorld")
	if player == null or world == null:
		_stage = 5
		return

	var bounds: Rect2 = world.get_bounds()
	player.global_position = Vector2(bounds.end.x - WALL_PUSH_MARGIN, bounds.get_center().y)

	_frames_left = roundi(WALL_PUSH_SECONDS * 60.0)
	_stage = 4


## A câmera deve ter recebido os limites do mundo pela cena de composição.
func _check_camera_limits() -> void:
	if _game == null:
		return
	var world := _game.get_node_or_null("World/TestWorld")
	var camera := _game.get_node_or_null("Player/Camera2D") as Camera2D
	if world == null or camera == null:
		_fail("Não foi possível checar os limites da câmera")
		return

	# A câmera usa o retângulo com a borda de vegetação, não o jogável: senão a
	# mata que fecha o mapa ficaria cortada fora da tela.
	var bounds: Rect2 = world.get_camera_bounds()
	var expected := [roundi(bounds.position.x), roundi(bounds.position.y), roundi(bounds.end.x), roundi(bounds.end.y)]
	var actual := [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
	if actual != expected:
		_fail("Limites da câmera %s não correspondem ao mundo %s" % [actual, expected])


## Empurrado contra a borda, o Player deve avançar e depois ser barrado dentro
## do mundo — é isso que valida as paredes de teste.
func _check_world_walls() -> void:
	if _game == null:
		return
	var player := _game.get_node_or_null("Player") as Node2D
	var world := _game.get_node_or_null("World/TestWorld")
	if player == null or world == null:
		_fail("Não foi possível checar os limites do mundo")
		return

	var bounds: Rect2 = world.get_bounds()
	var start_x := bounds.end.x - WALL_PUSH_MARGIN
	var final_x := player.global_position.x

	if final_x <= start_x + 1.0:
		_fail("Player não se moveu ao ser empurrado contra a parede (x=%.1f)" % final_x)
	if final_x > bounds.end.x:
		_fail("Player atravessou a parede: x=%.1f, borda em %.1f" % [final_x, bounds.end.x])


func _finish() -> void:
	Input.action_release("move_right")
	Input.action_release("move_down")
	if _player != null:
		_player.queue_free()
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _spawn_isolated_player() -> CharacterBody2D:
	if not ResourceLoader.exists(PLAYER_SCENE):
		_fail("Cena do Player não encontrada: %s" % PLAYER_SCENE)
		return null
	var scene: PackedScene = load(PLAYER_SCENE)
	var instance: Node = scene.instantiate()
	if not instance is CharacterBody2D:
		_fail("Raiz do Player deveria ser CharacterBody2D")
		instance.free()
		return null
	# Sem paredes ao redor: mede o movimento livre, sem interferência de colisão.
	root.add_child(instance)
	return instance as CharacterBody2D


func _check_input_actions() -> void:
	for action in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			_fail("Ação de input ausente: %s" % action)


func _check_player_scene() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		_fail("Cena do Player não encontrada: %s" % PLAYER_SCENE)
		return

	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()

	if not player is CharacterBody2D:
		_fail("Raiz do Player deveria ser CharacterBody2D, é %s" % player.get_class())
	if player.get_script() == null:
		_fail("Player está sem script")
	if not player.is_in_group("player"):
		_fail("Player não pertence ao grupo 'player'")

	var body := player as CharacterBody2D
	if body != null:
		if body.collision_layer != EXPECTED_PLAYER_LAYER:
			_fail("collision_layer do Player esperado %d, encontrado %d" % [EXPECTED_PLAYER_LAYER, body.collision_layer])
		if body.collision_mask != EXPECTED_PLAYER_MASK:
			_fail("collision_mask do Player esperado %d, encontrado %d" % [EXPECTED_PLAYER_MASK, body.collision_mask])
		if not "move_speed" in body:
			_fail("Player não expõe 'move_speed'")
		elif body.move_speed <= 0.0:
			_fail("move_speed inválido: %s" % body.move_speed)

	if player.get_node_or_null("Visual") == null:
		_fail("Player sem nó 'Visual' (camada de arte substituível)")

	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		_fail("Player sem CollisionShape2D")
	elif collision.shape == null:
		_fail("CollisionShape2D do Player está sem shape")

	if player.get_node_or_null("Camera2D") == null:
		_fail("Player sem Camera2D")

	player.free()


func _check_game_scene() -> void:
	if not ResourceLoader.exists(GAME_SCENE):
		_fail("Cena principal não encontrada: %s" % GAME_SCENE)
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()

	var player := game.get_node_or_null("Player")
	if player == null:
		_fail("game.tscn não instancia o Player")
	elif not player.is_in_group("player"):
		_fail("Player em game.tscn fora do grupo 'player'")

	var world := game.get_node_or_null("World/TestWorld")
	if world == null:
		_fail("game.tscn não contém a área de teste em World/TestWorld")
	elif not world.has_method("get_bounds"):
		_fail("TestWorld não expõe get_bounds()")
	else:
		var bounds: Rect2 = world.get_bounds()
		if bounds.size.x <= 1280.0 or bounds.size.y <= 720.0:
			_fail("Área de teste %s não é maior que a viewport 1280x720" % bounds.size)

	game.free()


func _check_speed() -> void:
	var expected: float = _player.move_speed * MEASURE_SECONDS

	for rate in _measurements:
		var measured: float = _measurements[rate]
		if absf(measured - expected) > DISTANCE_TOLERANCE:
			_fail("A %d Hz o Player andou %.1f px em %.2fs; esperado ~%.1f px" % [rate, measured, MEASURE_SECONDS, expected])

	if _measurements.size() == 2:
		var rates := _measurements.keys()
		var difference: float = absf(_measurements[rates[0]] - _measurements[rates[1]])
		if difference > DISTANCE_TOLERANCE:
			_fail("Deslocamento depende do FPS: %.1f px a %d Hz contra %.1f px a %d Hz" % [_measurements[rates[0]], rates[0], _measurements[rates[1]], rates[1]])


func _check_diagonal() -> void:
	var cardinal := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	Input.action_press("move_down")
	var diagonal := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if absf(cardinal.length() - 1.0) > 0.001:
		_fail("Input cardinal deveria ter magnitude 1.0, tem %.4f" % cardinal.length())
	if diagonal.length() > 1.0 + 0.001:
		_fail("Input diagonal com magnitude %.4f: a diagonal ficaria mais rápida" % diagonal.length())
	if absf(diagonal.length() - cardinal.length()) > 0.001:
		_fail("Diagonal (%.4f) e cardinal (%.4f) deveriam ter a mesma magnitude" % [diagonal.length(), cardinal.length()])


func _report() -> void:
	if not _measurements.is_empty():
		for rate in _measurements:
			print("  %d Hz: %.1f px em %.2fs" % [rate, _measurements[rate], MEASURE_SECONDS])
	if _failures.is_empty():
		print("FASE 1 OK — movimento e mundo validados.")
		return
	print("FASE 1 FALHOU — %d problema(s):" % _failures.size())
	for failure in _failures:
		print("  - %s" % failure)
