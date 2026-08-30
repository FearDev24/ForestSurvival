extends SceneTree
## Verificação da FASE 3 — Spawn e horda.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase3.gd
##
## Cobre estrutura do `SpawnManager`, spawn fora da câmera, teto de população,
## aumento de densidade ao longo da partida e um teste de carga com centenas de
## inimigos, com os números impressos.
##
## Não testa arte (DEC-013). O teste de carga roda `--headless`, então mede o
## custo de lógica e física, **não** o de renderização.

const GAME_SCENE := "res://scenes/game/game.tscn"

## Quanto tempo deixar o spawn correr para conferir que ele acontece.
const SPAWN_WATCH_SECONDS := 3.0
## Teto artificial usado para provar que o limite de população é respeitado.
const CAP_UNDER_TEST := 12
## Quanto tempo observar depois de encostar no teto.
const CAP_WATCH_SECONDS := 4.0

## Tamanhos de horda medidos no teste de carga.
const STRESS_STEPS := [50, 100, 250, 500]
## Frames ignorados depois de criar a leva, antes de começar a medir. Instanciar
## centenas de cenas de uma vez custa caro no frame em que acontece, e esse custo
## não é o que interessa: o que interessa é o custo de manter a horda viva.
const STRESS_WARMUP_FRAMES := 30
## Frames medidos em cada patamar.
const STRESS_FRAMES := 60
## Tempo de relógio máximo aceito por frame, em milissegundos.
##
## A 60 Hz cada frame dura 16,6 ms, e a Godot dorme o que sobra. Enquanto o
## motor **dá conta**, a medição fica colada nesse valor; quando não dá, ela
## sobe. É por isso que 20 ms é o limite: passar disso significa que a simulação
## deixou de acompanhar o tempo real.
##
## Este número não diz quanta folga existe — só que ainda existe. A medição de
## folga (FPS, frametime) precisa de renderização e está registrada no HANDOFF.
const STRESS_BUDGET_MS := 20.0

var _failures: Array[String] = []

var _game: Node = null
var _player: CharacterBody2D = null
var _spawner: SpawnManager = null
var _container: Node = null

var _stage := 0
var _frames_left := 0
var _spawn_positions: Array[Vector2] = []
var _spawn_count := 0
var _peak_population := 0
var _stress_index := 0
var _warmup_left := 0
var _stress_started_usec := 0
var _stress_results: Array[String] = []


func _initialize() -> void:
	_check_scene_structure()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_start_spawn_watch()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_spawning()
				_start_cap_watch()
		2:
			_frames_left -= 1
			_peak_population = maxi(_peak_population, _container.get_child_count())
			if _frames_left <= 0:
				_check_population_cap()
				_check_density_ramp()
				_start_stress()
		3:
			# `TIME_PHYSICS_PROCESS` mede o custo real do frame de física. Medir
			# tempo de relógio não serviria: `--headless` continua rodando a
			# 60 Hz e dormiria o resto do frame, dando sempre ~16,6 ms.
			if _warmup_left > 0:
				_warmup_left -= 1
				if _warmup_left == 0:
					_stress_started_usec = Time.get_ticks_usec()
			else:
				_frames_left -= 1
				if _frames_left <= 0:
					_finish_stress_step()
		4:
			_report_stress()
			_finish()
			return true
		5:
			# Um frame de folga para os `queue_free` do teste anterior saírem da
			# árvore antes de a contagem começar.
			_frames_left -= 1
			if _frames_left <= 0:
				_stress_index = 0
				_stress_next_step()
	return false


# ---------------------------------------------------------------- estrutura --


func _check_scene_structure() -> void:
	if not ResourceLoader.exists(GAME_SCENE):
		_fail("Cena principal não encontrada: %s" % GAME_SCENE)
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()

	var spawner := game.get_node_or_null("SpawnManager") as SpawnManager
	if spawner == null:
		_fail("game.tscn sem SpawnManager")
		game.free()
		return

	if spawner.enemy_scene == null:
		_fail("SpawnManager sem enemy_scene definida")

	if spawner.initial_spawn_interval <= 0.0 or spawner.final_spawn_interval <= 0.0:
		_fail("Intervalos de spawn precisam ser positivos")
	elif spawner.final_spawn_interval > spawner.initial_spawn_interval:
		_fail("A partida tem de ficar mais densa: intervalo final (%.2f s) deveria ser menor que o inicial (%.2f s)" % [
			spawner.final_spawn_interval, spawner.initial_spawn_interval])

	if spawner.initial_population_cap <= 0:
		_fail("Teto inicial de população inválido: %d" % spawner.initial_population_cap)
	elif spawner.final_population_cap < spawner.initial_population_cap:
		_fail("Teto final de população (%d) menor que o inicial (%d)" % [
			spawner.final_population_cap, spawner.initial_population_cap])

	if spawner.offscreen_margin <= 0.0:
		_fail("offscreen_margin precisa ser positiva para o inimigo nascer fora da tela")

	if game.get_node_or_null("EnemyContainer") == null:
		_fail("game.tscn sem EnemyContainer")

	# Um inimigo fixo na cena voltaria a atrapalhar o SpawnManager.
	var container := game.get_node_or_null("EnemyContainer")
	if container != null and container.get_child_count() > 0:
		_fail("EnemyContainer deveria começar vazio: quem cria inimigos agora é o SpawnManager")

	game.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE):
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_player = _game.get_node_or_null("Player") as CharacterBody2D
	_spawner = _game.get_node_or_null("SpawnManager") as SpawnManager
	_container = _game.get_node_or_null("EnemyContainer")

	if _player == null or _spawner == null or _container == null:
		_fail("game.tscn sem Player, SpawnManager ou EnemyContainer")
		return false

	_spawner.enemy_spawned.connect(_on_enemy_spawned)
	return true


func _on_enemy_spawned(enemy: Node2D) -> void:
	_spawn_count += 1
	_spawn_positions.append(enemy.global_position)


func _start_spawn_watch() -> void:
	_frames_left = roundi(SPAWN_WATCH_SECONDS * 60.0)
	_stage = 1


## Spawn tem de acontecer, e **nunca** dentro do campo de visão do Player.
func _check_spawning() -> void:
	if _spawn_count == 0:
		_fail("Nenhum inimigo foi criado em %.1f s" % SPAWN_WATCH_SECONDS)
		return

	var minimum := _spawner.get_spawn_distance()
	var closest := INF
	for position in _spawn_positions:
		closest = minf(closest, _player.global_position.distance_to(position))

	# Tolerância de 1 px: o ponto é limitado ao mapa antes de ser aceito.
	if closest < minimum - 1.0:
		_fail("Inimigo nasceu dentro da tela: %.1f px do Player, mínimo %.1f px" % [closest, minimum])

	print("  spawn: %d inimigos em %.1f s, o mais próximo a %.0f px (mínimo %.0f)" % [
		_spawn_count, SPAWN_WATCH_SECONDS, closest, minimum])


## Encosta no teto de população e confirma que ele segura.
func _start_cap_watch() -> void:
	_spawner.initial_population_cap = CAP_UNDER_TEST
	_spawner.final_population_cap = CAP_UNDER_TEST
	_spawner.initial_spawn_interval = 0.05
	_spawner.final_spawn_interval = 0.05

	_peak_population = _container.get_child_count()
	_frames_left = roundi(CAP_WATCH_SECONDS * 60.0)
	_stage = 2


func _check_population_cap() -> void:
	if _peak_population > CAP_UNDER_TEST:
		_fail("População passou do teto: %d vivos, teto %d" % [_peak_population, CAP_UNDER_TEST])

	if _peak_population < CAP_UNDER_TEST:
		_fail("População não chegou ao teto em %.1f s: parou em %d de %d" % [
			CAP_WATCH_SECONDS, _peak_population, CAP_UNDER_TEST])

	print("  teto de população: %d vivos, limite %d" % [_peak_population, CAP_UNDER_TEST])


## A rampa tem de deixar a partida mais densa com o tempo — mais inimigos vivos
## e menos tempo entre spawns.
func _check_density_ramp() -> void:
	var probe := SpawnManager.new()
	probe.initial_spawn_interval = 1.2
	probe.final_spawn_interval = 0.2
	probe.initial_population_cap = 40
	probe.final_population_cap = 200
	probe.ramp_seconds = 10.0
	root.add_child(probe)

	var start_interval := probe.get_spawn_interval()
	var start_cap := probe.get_population_cap()

	# Empurra a rampa até o fim sem esperar: o alvo aqui é a curva, não o tempo.
	probe.configure(null, null, Rect2())
	probe._elapsed = probe.ramp_seconds
	var end_interval := probe.get_spawn_interval()
	var end_cap := probe.get_population_cap()

	if end_interval >= start_interval:
		_fail("Intervalo entre spawns não diminuiu: %.2f s -> %.2f s" % [start_interval, end_interval])
	if end_cap <= start_cap:
		_fail("Teto de população não aumentou: %d -> %d" % [start_cap, end_cap])

	var middle := SpawnManager.new()
	middle.initial_spawn_interval = 1.2
	middle.final_spawn_interval = 0.2
	middle.ramp_seconds = 10.0
	root.add_child(middle)
	middle._elapsed = 5.0
	var half := middle.get_spawn_interval()
	if half <= end_interval or half >= start_interval:
		_fail("A rampa deveria ser gradual: no meio o intervalo é %.2f s, fora de (%.2f, %.2f)" % [
			half, end_interval, start_interval])

	print("  rampa: intervalo %.2f s -> %.2f s -> %.2f s | teto %d -> %d" % [
		start_interval, half, end_interval, start_cap, end_cap])

	probe.free()
	middle.free()


# ------------------------------------------------------------------ stress --


## Sobe a horda em patamares e mede o custo de um frame de física em cada um.
func _start_stress() -> void:
	_spawner.enabled = false
	for child in _container.get_children():
		child.queue_free()

	_frames_left = 2
	_stage = 5


func _stress_next_step() -> void:
	if _stress_index >= STRESS_STEPS.size():
		_stage = 4
		return

	var target: int = STRESS_STEPS[_stress_index]
	var missing: int = target - _container.get_child_count()
	_spawner.spawn_burst(missing)

	_frames_left = STRESS_FRAMES
	_warmup_left = STRESS_WARMUP_FRAMES
	_stage = 3


func _finish_stress_step() -> void:
	var per_frame := float(Time.get_ticks_usec() - _stress_started_usec) / 1000.0 / float(STRESS_FRAMES)
	var population := _container.get_child_count()
	var target: int = STRESS_STEPS[_stress_index]

	_stress_results.append("  %4d inimigos: %.2f ms de relógio por frame, %d nodes na cena" % [
		population, per_frame, _count_nodes(_game)])

	if population != target:
		_fail("Deveriam existir %d inimigos no patamar, existem %d" % [target, population])

	if per_frame > STRESS_BUDGET_MS:
		_fail("Com %d inimigos o motor deixou de acompanhar o tempo real: %.2f ms por frame, limite %.1f ms" % [
			population, per_frame, STRESS_BUDGET_MS])

	# A horda tem de continuar viva e funcionando, não só existir.
	var moving := 0
	for child in _container.get_children():
		var enemy := child as CharacterBody2D
		if enemy != null and enemy.velocity.length() > 1.0:
			moving += 1
	if moving < population / 2:
		_fail("Com %d inimigos, só %d estavam se movendo: a simulação parou" % [population, moving])

	_stress_index += 1
	_stress_next_step()


func _report_stress() -> void:
	print("  carga (headless: lógica e física, sem renderização):")
	for line in _stress_results:
		print(line)


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


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
		print("FASE 3 OK — spawn, horda e carga validados.")
		return
	printerr("FASE 3 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
