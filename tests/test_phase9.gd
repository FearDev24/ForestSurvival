extends SceneTree
## Verificação da FASE 9 — Loop completo.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase9.gd
##
## O critério da fase é ter **um estado de partida só**, em lugar dos quatro
## `enabled` que precisavam concordar sozinhos, e que dê para pausar, perder e
## vencer — cada um levando a uma tela.
##
## O que este teste checa, então, não é "a tela apareceu": é que o estado manda
## nos sistemas. Uma tela que aparecesse com o spawn ainda correndo passaria num
## teste de visibilidade e falharia aqui.

const GAME_SCENE := "res://scenes/game/game.tscn"

var _failures: Array[String] = []

var _game: Node = null
var _manager: GameManager = null
var _spawn: SpawnManager = null
var _waves: WaveManager = null
var _weapons: WeaponManager = null
var _pausa: CanvasLayer = null
var _resultado: CanvasLayer = null

var _stage := 0
var _frames_left := 0
var _estados: Array[int] = []
var _fins: Array[Array] = []
var _tempo_ao_pausar := 0.0


func _initialize() -> void:
	_check_estrutura()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_jogando()
				_start_pausa()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_pausa()
				_start_retomar()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_retomou()
				_start_vitoria()
		3:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_vitoria()
				_finish()
				return true
	return false


# --------------------------------------------------------------- estrutura --


func _check_estrutura() -> void:
	if not ResourceLoader.exists(GAME_SCENE):
		_fail("game.tscn não encontrada")
		return

	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()

	for nome in ["GameManager", "PauseMenu", "ResultScreen"]:
		if game.get_node_or_null(nome) == null:
			_fail("game.tscn sem o nó %s" % nome)

	# As três telas que pausam precisam responder **enquanto a árvore está
	# parada**, que é justamente quando elas aparecem. Sem isso os botões não
	# recebem clique e a partida trava de vez.
	for nome in ["GameManager", "PauseMenu", "ResultScreen", "LevelUpMenu"]:
		var no := game.get_node_or_null(nome)
		if no != null and no.process_mode != Node.PROCESS_MODE_ALWAYS:
			_fail("%s precisa de process_mode ALWAYS: ele age com a árvore parada" % nome)

	for nome in ["PauseMenu", "ResultScreen"]:
		var tela := game.get_node_or_null(nome) as CanvasLayer
		if tela != null and tela.visible:
			_fail("%s deveria começar escondida" % nome)

	# A tela de resultado fica acima da de pausa, que fica acima do level up.
	var camadas := {}
	for nome in ["Hud", "LevelUpMenu", "PauseMenu", "ResultScreen"]:
		var tela := game.get_node_or_null(nome) as CanvasLayer
		if tela != null:
			camadas[nome] = tela.layer
	if camadas.size() == 4:
		var ordem := [camadas["Hud"], camadas["LevelUpMenu"], camadas["PauseMenu"],
			camadas["ResultScreen"]]
		for i in range(1, ordem.size()):
			if ordem[i] <= ordem[i - 1]:
				_fail("As camadas se atropelam: %s" % str(camadas))
				break

	# A tela de escolha não pausa mais sozinha — quem pausa é o GameManager.
	var menu := game.get_node_or_null("LevelUpMenu")
	if menu != null and not menu.has_signal("opened"):
		_fail("LevelUpMenu sem o sinal 'opened': o GameManager não saberia quando pausar")

	game.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_manager = _game.get_node_or_null("GameManager") as GameManager
	_spawn = _game.get_node_or_null("SpawnManager") as SpawnManager
	_waves = _game.get_node_or_null("WaveManager") as WaveManager
	_weapons = _game.get_node_or_null("Player/WeaponManager") as WeaponManager
	_pausa = _game.get_node_or_null("PauseMenu") as CanvasLayer
	_resultado = _game.get_node_or_null("ResultScreen") as CanvasLayer

	if _manager == null or _spawn == null or _waves == null or _weapons == null \
			or _pausa == null or _resultado == null:
		_fail("game.tscn incompleta para a FASE 9")
		return false

	_manager.state_changed.connect(func(e: GameManager.Estado) -> void: _estados.append(e))
	_manager.ended.connect(func(v: bool, t: float, n: int) -> void: _fins.append([v, t, n]))

	_frames_left = 4
	_stage = 0
	return true


func _check_jogando() -> void:
	if _manager.estado != GameManager.Estado.JOGANDO:
		_fail("A partida deveria começar JOGANDO, está em %d" % _manager.estado)
	if paused:
		_fail("A partida começou pausada")
	if _manager.get_elapsed() <= 0.0:
		_fail("O relógio não andou: %.3f" % _manager.get_elapsed())


## Pausar tem de parar **tudo**: árvore, spawn, waves e o relógio.
##
## É esse o ponto da fase. Uma tela de pausa que só aparecesse por cima de uma
## partida ainda correndo passaria num teste de visibilidade.
func _start_pausa() -> void:
	_tempo_ao_pausar = _manager.get_elapsed()
	_manager.pausar()
	_frames_left = 30
	_stage = 1


func _check_pausa() -> void:
	if _manager.estado != GameManager.Estado.PAUSADO:
		_fail("Deveria estar PAUSADO, está em %d" % _manager.estado)
	if not paused:
		_fail("A árvore continuou andando com o jogo pausado")
	if _spawn.enabled:
		_fail("O spawn continuou ligado na pausa")
	if _waves.enabled:
		_fail("As waves continuaram ligadas na pausa")
	if not is_equal_approx(_manager.get_elapsed(), _tempo_ao_pausar):
		_fail("O relógio andou %.2f s durante a pausa"
			% (_manager.get_elapsed() - _tempo_ao_pausar))
	if not _pausa.visible:
		_fail("A tela de pausa não apareceu")
	if _pausa.botoes().is_empty():
		_fail("A tela de pausa não ofereceu nenhum botão")


func _start_retomar() -> void:
	_manager.retomar()
	_frames_left = 20
	_stage = 2


func _check_retomou() -> void:
	if _manager.estado != GameManager.Estado.JOGANDO:
		_fail("Retomar deveria voltar a JOGANDO, está em %d" % _manager.estado)
	if paused:
		_fail("A árvore continuou parada depois de retomar")
	if not _spawn.enabled or not _waves.enabled:
		_fail("Retomar não religou spawn e waves")
	if _pausa.visible:
		_fail("A tela de pausa não sumiu ao retomar")
	if _manager.get_elapsed() <= _tempo_ao_pausar:
		_fail("O relógio não voltou a andar depois da pausa")


## A vitória é o boss caindo, e é a única coisa da fase que não dá para provocar
## por chamada direta sem trapacear: o teste mata o boss de verdade.
func _start_vitoria() -> void:
	var wave := load("res://resources/waves/wave_5_guardiao.tres") as WaveData
	if wave == null or wave.boss == null:
		_fail("Não achei a wave do boss")
		_frames_left = 1
		_stage = 3
		return

	var boss := _spawn.spawn_data(wave.boss)
	if boss == null:
		_fail("O boss não nasceu")
		_frames_left = 1
		_stage = 3
		return

	# O `GameManager` escuta `boss_spawned`, e este nasceu à mão: avisa ele.
	_manager._on_boss_spawned(boss)

	var vida := boss.get_node_or_null("Health") as HealthComponent
	if vida == null:
		_fail("O boss não tem HealthComponent")
	else:
		vida.damage(vida.max_health + 1.0)

	_frames_left = 6
	_stage = 3


func _check_vitoria() -> void:
	if _manager.estado != GameManager.Estado.VITORIA:
		_fail("Derrubar o boss deveria dar VITORIA, está em %d" % _manager.estado)
	if _spawn.enabled or _waves.enabled:
		_fail("A partida acabou e o spawn continua ligado")
	if not paused:
		_fail("A partida acabou e a árvore continua andando")
	if not _resultado.visible:
		_fail("A tela de resultado não apareceu")

	if _fins.size() != 1:
		_fail("O fim da partida deveria ser anunciado uma vez, foram %d" % _fins.size())
	else:
		var fim: Array = _fins[0]
		if not bool(fim[0]):
			_fail("O fim veio marcado como derrota")
		if float(fim[1]) <= 0.0:
			_fail("O fim veio sem tempo de partida: %.2f" % float(fim[1]))
		var rotulo := (_resultado.get_node("Caixa/Tempo") as Label).text
		if not rotulo.contains(":"):
			_fail("A tela de resultado não mostrou o tempo: '%s'" % rotulo)

	# Um segundo boss morrendo não pode reabrir nem reanunciar nada.
	var antes := _fins.size()
	_manager._on_boss_morreu()
	if _fins.size() != antes:
		_fail("A vitória foi anunciada duas vezes")

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
		print("FASE 9 OK — um estado só manda na partida, e dá para pausar, perder e vencer.")
		return
	printerr("FASE 9 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
