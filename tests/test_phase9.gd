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
var _boss: Node2D = null
var _tempo_do_golpe := 0.0

## Espera máxima pela vitória depois do golpe final. A queda provisória dura
## ~2,2 s; 240 passos de física são 4 s, folga para a arte de verdade.
const ESPERA_DA_QUEDA := 240


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
				_check_queda()
				_frames_left = ESPERA_DA_QUEDA
				_stage = 4
		4:
			# Espera a vitória **chegar**, com teto: um fluxo que nunca anuncia
			# a vitória falha aqui em vez de travar o teste.
			_frames_left -= 1
			var chegou := _manager.estado == GameManager.Estado.VITORIA
			if chegou and _frames_left > 2:
				_frames_left = 2  # dois passos para a pausa adiada e a tela
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
	_boss = boss
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
		_tempo_do_golpe = _manager.get_elapsed()
		vida.damage(vida.max_health + 1.0)

	_frames_left = 6
	_stage = 3


## O intervalo entre o golpe final e a vitória (DEC-024).
##
## É o que a primeira versão da FASE 9 não tinha: o boss sumia num quadro e a
## tela de resultado vinha por cima. Aqui ele tem de estar **caindo** — ainda
## na árvore, com a horda parada e nada anunciado.
func _check_queda() -> void:
	if _manager.estado != GameManager.Estado.TRIUNFO:
		_fail("Com o boss caindo, a partida deveria estar em TRIUNFO, está em %d" % _manager.estado)
	if not _fins.is_empty():
		_fail("A vitória foi anunciada antes de a queda terminar")
	if _resultado.visible:
		_fail("A tela de resultado apareceu por cima da queda")
	if paused:
		_fail("A árvore parou durante a queda: o boss não teria como cair")
	if _spawn.enabled or _waves.enabled:
		_fail("A horda continuou chegando durante a queda")
	if not is_instance_valid(_boss) or not _boss.is_inside_tree():
		_fail("O boss sumiu no golpe final, sem cair")
	var inimigos := _game.get_node("EnemyContainer")
	if inimigos.process_mode != Node.PROCESS_MODE_DISABLED:
		_fail("Os inimigos continuaram andando durante a queda")
	var orbes := _game.get_node("PickupContainer")
	if orbes.process_mode != Node.PROCESS_MODE_DISABLED:
		_fail("Os orbes continuaram coletáveis durante a queda")


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
		# O tempo da vitória é o do golpe final: a queda não conta.
		if absf(float(fim[1]) - _tempo_do_golpe) > 0.1:
			_fail("O relógio andou durante a queda: golpe aos %.2f s, vitória aos %.2f s"
				% [_tempo_do_golpe, float(fim[1])])
		var rotulo := (_resultado.get_node("Caixa/Tempo") as Label).text
		if not rotulo.contains(":"):
			_fail("A tela de resultado não mostrou o tempo: '%s'" % rotulo)

	_check_titulo(true)

	if is_instance_valid(_boss):
		_fail("A queda terminou e o boss continua na árvore")

	# Um segundo boss morrendo não pode reabrir nem reanunciar nada.
	var antes := _fins.size()
	_manager._on_boss_morreu()
	if _fins.size() != antes:
		_fail("A vitória foi anunciada duas vezes")

	paused = false


## A palavra desenhada tem de ser a do desfecho.
##
## Trocar as duas texturas mostraria "A FLORESTA CAIU" na vitória, e nada mais
## no jogo notaria: os botões, o tempo e o nível continuariam certos. Só quem
## jogasse até o fim veria.
##
## O teste **não** exige que a arte exista — pela DEC-013 ela pode faltar e a
## tela continua inteira pelo rótulo escrito. O que ele exige é coerência: com
## arte, o rótulo se cala; sem arte, o rótulo fala.
func _check_titulo(vitoria: bool) -> void:
	var arte := _resultado.get_node_or_null("Caixa/TituloArte") as TextureRect
	var rotulo := _resultado.get_node_or_null("Caixa/Titulo") as Label
	if arte == null or rotulo == null:
		_fail("A tela de resultado perdeu o título (TituloArte/Titulo)")
		return

	var esperada: Texture2D = _resultado.titulo_vitoria if vitoria else _resultado.titulo_derrota
	if esperada == null:
		if arte.visible:
			_fail("Sem arte do título, a moldura dele não deveria aparecer")
		if not rotulo.visible:
			_fail("Sem arte do título, o rótulo escrito tinha de assumir (DEC-013)")
		return

	# A conferência é pelo **nome do arquivo**, e não pela propriedade exportada.
	#
	# Comparar `arte.texture` com `_resultado.titulo_vitoria` não testa nada: é
	# a mesma propriedade que o script leu para decidir. Trocar as duas na cena
	# deixa os dois lados errados de forma consistente, e o teste passa — foi o
	# que aconteceu na primeira versão desta função.
	var palavra := "resistiu" if vitoria else "caiu"
	var caminho := "" if arte.texture == null else arte.texture.resource_path
	if not caminho.to_lower().contains(palavra):
		_fail("A tela de %s está mostrando '%s', que não é a palavra do desfecho"
			% ["vitória" if vitoria else "derrota", caminho.get_file()])
	if not arte.visible:
		_fail("A arte do título existe e não apareceu")
	if rotulo.visible:
		_fail("O rótulo escrito ficou por baixo da arte, os dois visíveis")


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
