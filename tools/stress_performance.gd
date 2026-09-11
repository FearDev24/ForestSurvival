extends SceneTree
## FASE 10 — estresse de carga com a partida de verdade.
##
## Uso (com janela, para medir também o desenho):
##   godot --path . --resolution 1280x720 --script res://tools/stress_performance.gd -- --patamares=100,200,300,500 --orbes=0 --saida=C:/caminho/stress.json
##
## Repete o método da tabela de carga da FASE 3 (docs/HANDOFF.md, "Carga:
## quantos diabretes cabem"), para os números se compararem: vsync desligado,
## druida parado, cada patamar criado e deixado convergir 5,5 s sobre ele — a
## horda **empilhada**, que é o pior caso — e só então medido por 5 s.
##
## Diferenças deliberadas em relação à FASE 3:
## - o druida não leva dano e as armas ficam desligadas: com elas, os inimigos
##   morreriam e o patamar não se sustentaria. O custo das armas em carga real
##   é medido pela sonda (`tools/sonda_balanceamento.gd -- --perf`);
## - `--orbes=N` espalha N fragmentos de XP no chão, longe do druida, para
##   medir o custo deles isolado — a sonda viu até 163 parados numa partida.
##
## Rode sozinha: outra Godot rodando junto faz o tempo de quadro medir a
## disputa pelo processador, e não o jogo.
##
## Não é teste: não passa nem falha. Imprime a tabela e grava o JSON.

const GAME_SCENE := "res://scenes/game/game.tscn"
const ORBE_SCENE := "res://scenes/pickups/xp_orb.tscn"

## Passos de física (60 por segundo) de convergência e de medição.
const CONVERGIR := 330
const MEDIR := 300

var _patamares: Array[int] = [100, 200, 300, 500]
var _orbes := 0
var _saida := "user://stress.json"

var _game: Node = null
var _spawn: SpawnManager = null
var _inimigos: Node = null
var _indice := -1
var _restam := 30
var _fisica: Array[float] = []
var _processo: Array[float] = []
var _fps: Array[float] = []
var _resultados: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--patamares="):
			_patamares.clear()
			for parte in arg.get_slice("=", 1).split(",", false):
				_patamares.append(int(parte))
		elif arg.begins_with("--orbes="):
			_orbes = int(arg.get_slice("=", 1))
		elif arg.begins_with("--saida="):
			_saida = arg.get_slice("=", 1)

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(1)

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)
	_spawn = _game.get_node("SpawnManager")
	_inimigos = _game.get_node("EnemyContainer")

	# Só a horda: nada nasce sozinho, ninguém atira, o druida não cai.
	_spawn.enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false
	(_game.get_node("Player/WeaponManager") as WeaponManager).set_weapons_enabled(false)
	for filho in _game.get_node("Player").get_children():
		if filho is HurtboxComponent:
			(filho as HurtboxComponent).set_vulnerable(false)

	_espalhar_orbes()
	print("estresse: patamares %s, %d orbes" % [str(_patamares), _orbes])


func _espalhar_orbes() -> void:
	if _orbes <= 0:
		return
	var cena := load(ORBE_SCENE) as PackedScene
	var pickups := _game.get_node("PickupContainer")
	var centro := (_game.get_node("Player") as Node2D).global_position
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in _orbes:
		var orbe := cena.instantiate() as Node2D
		# Longe do raio de coleta (48 px): o druida fica parado e não os pega.
		var distancia := rng.randf_range(160.0, 900.0)
		orbe.global_position = centro + Vector2(distancia, 0.0).rotated(rng.randf() * TAU)
		pickups.add_child(orbe)


func _physics_process(_delta: float) -> bool:
	_restam -= 1

	# Os últimos MEDIR passos de cada patamar são a janela de medição; antes
	# disso a horda está convergindo e não conta.
	if _indice >= 0 and _restam < MEDIR:
		_fisica.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_processo.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		_fps.append(Performance.get_monitor(Performance.TIME_FPS))

	if _restam > 0:
		return false

	if _indice >= 0:
		_registrar()

	_indice += 1
	if _indice >= _patamares.size():
		_encerrar()
		return true

	var faltam := _patamares[_indice] - _inimigos.get_child_count()
	if faltam > 0:
		# `spawn_burst` ignora o teto de população, como no estresse da FASE 3:
		# o objetivo aqui é justamente passar dele.
		_spawn.spawn_burst(faltam)
	_restam = CONVERGIR + MEDIR
	_fisica.clear()
	_processo.clear()
	_fps.clear()
	return false


func _media(valores: Array[float]) -> float:
	var total := 0.0
	for v in valores:
		total += v
	return total / maxf(1.0, float(valores.size()))


func _registrar() -> void:
	var ordenados := _fisica.duplicate()
	ordenados.sort()
	var p95: float = ordenados[int((ordenados.size() - 1) * 0.95)] if not ordenados.is_empty() else 0.0
	var linha := {
		"inimigos": _inimigos.get_child_count(),
		"orbes": _game.get_node("PickupContainer").get_child_count(),
		"fps": snappedf(_media(_fps), 1.0),
		"processo_ms": snappedf(_media(_processo), 0.01),
		"fisica_ms": snappedf(_media(_fisica), 0.01),
		"fisica_p95_ms": snappedf(p95, 0.01),
		"desenhos": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"nos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"fisica_ativos": int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
		"pares": int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)),
		"memoria_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
	}
	_resultados.append(linha)
	print("  %4d inimigos, %4d orbes | %5.0f FPS | processo %5.2f ms | fisica %5.2f ms (p95 %5.2f) | %4d desenhos | %5d nos | %4d pares | %.1f MB" % [
		linha.inimigos, linha.orbes, linha.fps, linha.processo_ms, linha.fisica_ms,
		linha.fisica_p95_ms, linha.desenhos, linha.nos, linha.pares, linha.memoria_mb])


func _encerrar() -> void:
	var f := FileAccess.open(_saida, FileAccess.WRITE)
	f.store_string(JSON.stringify({"orbes": _orbes, "patamares": _resultados}, "  "))
	f.close()
	quit(0)
