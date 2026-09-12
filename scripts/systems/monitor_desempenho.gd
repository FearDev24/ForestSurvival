class_name MonitorDesempenho
extends Node
## Mede a partida no aparelho e escreve no log (FASE 12, "performance device").
##
## A FASE 10 mediu no PC com a sonda; no celular a sonda não roda. Este nó faz
## a parte dela que cabe num aparelho: a cada 5 segundos escreve **uma linha no
## log**, lida pelo `adb logcat` enquanto alguém joga, e nada aparece na tela.
##
## Só existe numa build de **depuração** rodando em **aparelho móvel**
## (`deve_rodar()`). No PC e nos testes ele nem é criado, e o APK de lançamento
## não o tem.
##
## Linhas do log:
##   FS_TELA  — uma vez: tamanho da tela, área segura e margens em viewport;
##   FS_PERF  — a cada janela: quadro (média, p95, pior) medido pelo relógio,
##              FPS, pico de física, memória, nós, inimigos, orbes e desenhos.

const JANELA := 5.0

var _inimigos: Node = null
var _orbes: Node = null
var _manager: GameManager = null

var _quadros: Array[float] = []
var _ultimo := 0
var _acumulado := 0.0
var _inicio := 0


static func deve_rodar() -> bool:
	return OS.is_debug_build() and OS.has_feature("mobile")


func configure(inimigos: Node, orbes: Node, manager: GameManager) -> void:
	_inimigos = inimigos
	_orbes = orbes
	_manager = manager


func _ready() -> void:
	# Mede também com a partida pausada: a tela de level up e a pausa custam
	# quadro do mesmo jeito, e o log diz em que estado cada janela estava.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicio = Time.get_ticks_msec()
	_registrar_tela()


func _process(delta: float) -> void:
	var agora := Time.get_ticks_usec()
	if _ultimo > 0:
		_quadros.append((agora - _ultimo) / 1000.0)
	_ultimo = agora
	_acumulado += delta
	if _acumulado >= JANELA:
		_acumulado = 0.0
		_registrar_janela()


func _registrar_tela() -> void:
	var viewport := get_viewport()
	var margens := AreaSegura.margens(viewport)
	print("FS_TELA tela=%s segura=%s visivel=%s margens=cima:%.0f baixo:%.0f esq:%.0f dir:%.0f" % [
		str(DisplayServer.screen_get_size()), str(DisplayServer.get_display_safe_area()),
		str(viewport.get_visible_rect().size if viewport else Vector2.ZERO),
		margens.cima, margens.baixo, margens.esquerda, margens.direita])


func _registrar_janela() -> void:
	if _quadros.is_empty():
		return
	var q := _quadros.duplicate()
	_quadros.clear()
	q.sort()
	var soma := 0.0
	for v in q:
		soma += v
	var estado := "-"
	if _manager != null:
		estado = GameManager.Estado.keys()[_manager.estado]
	print("FS_PERF t=%d estado=%s fps=%d quadro_med=%.2f p95=%.2f max=%.2f fisica_pico=%.2f mem=%.1fMB vram=%.1fMB nos=%d inimigos=%d orbes=%d desenhos=%d" % [
		(Time.get_ticks_msec() - _inicio) / 1000,
		estado,
		int(Performance.get_monitor(Performance.TIME_FPS)),
		soma / q.size(),
		q[int((q.size() - 1) * 0.95)],
		q[-1],
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		_inimigos.get_child_count() if _inimigos != null else -1,
		_orbes.get_child_count() if _orbes != null else -1,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
	])
