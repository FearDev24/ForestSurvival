extends SceneTree
## Verificação da FASE 0 — Fundação.
##
## Uso:
##   godot --headless --path . --script res://tests/test_foundation.gd
##
## Não testa gameplay. Apenas confirma que a base técnica está no lugar.

const EXPECTED_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"pause",
]

const EXPECTED_LAYERS := {
	1: "PlayerBody",
	2: "EnemyBody",
	3: "PlayerHurtbox",
	4: "EnemyHurtbox",
	5: "PlayerAttack",
	6: "EnemyAttack",
	7: "Pickup",
}

const EXPECTED_GAME_NODES := [
	"World",
	"EnemyContainer",
	"ProjectileContainer",
	"PickupContainer",
	"EffectContainer",
	"CanvasLayer",
]

var _failures: Array[String] = []


func _init() -> void:
	_check_main_scene()
	_check_window()
	_check_input_actions()
	_check_physics_layers()
	_check_game_scene()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _check_main_scene() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene != "res://scenes/game/game.tscn":
		_fail("Main Scene inesperada: '%s'" % main_scene)


func _check_window() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	if width != 1280 or height != 720:
		_fail("Viewport esperado 1280x720, encontrado %dx%d" % [width, height])
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	if stretch_mode != "canvas_items":
		_fail("Stretch mode esperado 'canvas_items', encontrado '%s'" % stretch_mode)
	var aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect", "")
	if aspect != "expand":
		_fail("Stretch aspect esperado 'expand', encontrado '%s'" % aspect)


func _check_input_actions() -> void:
	for action in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			_fail("Ação de input ausente: %s" % action)
			continue
		if InputMap.action_get_events(action).is_empty():
			_fail("Ação de input sem tecla vinculada: %s" % action)


func _check_physics_layers() -> void:
	for index in EXPECTED_LAYERS:
		var key := "layer_names/2d_physics/layer_%d" % index
		var name_value: String = ProjectSettings.get_setting(key, "")
		if name_value != EXPECTED_LAYERS[index]:
			_fail("Layer 2D %d esperada '%s', encontrada '%s'" % [index, EXPECTED_LAYERS[index], name_value])


func _check_game_scene() -> void:
	var path := "res://scenes/game/game.tscn"
	if not ResourceLoader.exists(path):
		_fail("Cena principal não encontrada: %s" % path)
		return
	var packed: PackedScene = load(path)
	var game: Node = packed.instantiate()
	if game.name != "Game":
		_fail("Node raiz esperado 'Game', encontrado '%s'" % game.name)
	if not game is Node2D:
		_fail("Node raiz deveria ser Node2D")
	for child_name in EXPECTED_GAME_NODES:
		if game.get_node_or_null(NodePath(child_name)) == null:
			_fail("Node ausente em game.tscn: %s" % child_name)
	game.free()


func _report() -> void:
	if _failures.is_empty():
		print("FASE 0 OK — fundação validada.")
		return
	print("FASE 0 FALHOU — %d problema(s):" % _failures.size())
	for failure in _failures:
		print("  - %s" % failure)
