extends SceneTree
## Verificação da FASE 12 — Mobile.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase12.gd
##
## O que dá para provar sem um celular:
##
## - **o joystick move o druida pelas mesmas ações do teclado**, com a força de
##   quanto o polegar se afastou, e ignora o segundo dedo e o toque na metade
##   direita da tela;
## - **o druida não volta da pausa andando sozinho**. Pausado, o joystick não
##   recebe o toque de soltar; se ele não soltar as ações ao pausar, a partida
##   volta com o druida correndo para o lado em que o polegar estava;
## - **o botão de pausa por toque pausa a partida**, e só aparece em tela de
##   toque;
## - **a área segura empurra cada borda conforme a âncora**, e reaplicar não
##   acumula;
## - **a orientação é paisagem e existe um preset de exportação Android**.
##
## O que só o aparelho responde — desempenho, memória, o entalhe de verdade —
## fica registrado como pendente no HANDOFF.
##
## Os toques são entregues direto ao `_input` do joystick. Sem janela, a Godot
## não garante o caminho do evento pela fila de entrada, e o teste mediria a
## fila em vez do joystick.

const GAME_SCENE := "res://scenes/game/game.tscn"
const PRESETS := "res://export_presets.cfg"

var _failures: Array[String] = []

var _game: Node = null
var _hud: Hud = null
var _joystick: JoystickVirtual = null
var _player: Player = null
var _manager: GameManager = null
var _stage := 0
var _frames := 0
var _posicao := Vector2.ZERO


func _initialize() -> void:
	_check_projeto()
	_check_area_segura()

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)
	_hud = _game.get_node_or_null("Hud") as Hud
	_player = _game.get_node_or_null("Player") as Player
	_manager = _game.get_node_or_null("GameManager") as GameManager
	_joystick = _hud.get_node_or_null("Joystick") as JoystickVirtual if _hud != null else null
	if _hud == null or _player == null or _manager == null or _joystick == null:
		_fail("Partida incompleta para a FASE 12 (Hud, Player, GameManager ou Joystick)")
		_report()
		quit(1)
		return

	# Nada nasce e ninguém atrapalha: só o druida e o joystick.
	(_game.get_node("SpawnManager") as SpawnManager).enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false
	# As conferências do começo esperam o `_ready` da cena: antes dele os nós
	# ainda estão como saíram do arquivo, e ligar o toque não faria nada.
	_stage = -1
	_frames = 3


func _physics_process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false

	match _stage:
		-1:
			_check_nascimento()
			_hud.set_toque(true)
			_proximo(3)
		0:
			_posicao = _player.global_position
			_tocar(0, Vector2(200.0, 500.0), true)
			_arrastar(0, Vector2(200.0 + _joystick.raio, 500.0))
			_check_forca("polegar todo para a direita", 1.0, 0.0)
			# Um segundo dedo não rouba o joystick.
			_tocar(1, Vector2(1000.0, 300.0), true)
			_arrastar(1, Vector2(900.0, 200.0))
			_check_forca("com um segundo dedo na tela", 1.0, 0.0)
			_tocar(1, Vector2(900.0, 200.0), false)
			_proximo(30)
		1:
			var andou := _player.global_position - _posicao
			if andou.x < 60.0 or absf(andou.y) > 10.0:
				_fail("O joystick para a direita deveria mover o druida para a direita; andou %s" % str(andou))
			# Metade para baixo: força 0,5 no eixo vertical, direita solta.
			_arrastar(0, Vector2(200.0, 500.0 + _joystick.raio * 0.5))
			_check_forca("polegar meio para baixo", 0.0, 0.5)
			_manager.pausar()
			_proximo(4)
		2:
			if not paused:
				_fail("pausar() não parou a árvore: o resto do teste não provaria nada")
			for acao in [&"move_left", &"move_right", &"move_up", &"move_down"]:
				if Input.get_action_strength(acao) > 0.0:
					_fail("A pausa deixou %s apertado: o druida voltaria andando sozinho" % acao)
			_manager.retomar()
			_proximo(4)
		3:
			_posicao = _player.global_position
			_proximo(20)
		4:
			var deriva := _player.global_position.distance_to(_posicao)
			if deriva > 1.0:
				_fail("Depois da pausa o druida andou %.1f px sozinho" % deriva)
			# A metade direita da tela não começa o joystick.
			_tocar(2, Vector2(1000.0, 400.0), true)
			_arrastar(2, Vector2(1100.0, 400.0))
			if not _joystick.get_direcao().is_zero_approx() or Input.get_action_strength(&"move_right") > 0.0:
				_fail("Um toque na metade direita da tela ligou o joystick")
			_tocar(2, Vector2(1100.0, 400.0), false)
			# O botão de pausa por toque.
			var pausa := _hud.get_node_or_null("Pausa") as Button
			if pausa == null or not pausa.visible:
				_fail("O botão de pausa por toque não apareceu com o toque ligado")
			if pausa != null:
				pausa.pressed.emit()
			_proximo(4)
		5:
			if _manager.estado != GameManager.Estado.PAUSADO:
				_fail("O botão de pausa por toque não pausou: estado %d" % _manager.estado)
			paused = false
			_report()
			quit(0 if _failures.is_empty() else 1)
			return true
	return false


func _proximo(frames: int) -> void:
	_stage += 1
	_frames = frames


## Sem janela não há tela de toque: os controles nascem escondidos.
##
## E o joystick solta só o que ele mesmo apertou. A primeira versão soltava as
## quatro ações ao desligar, e isso parava o druida de quem segura uma tecla —
## a suíte da FASE 1 pegou antes desta.
func _check_nascimento() -> void:
	if _joystick.ativo or _joystick.visible:
		_fail("O joystick ligou sem tela de toque")
	var pausa := _hud.get_node_or_null("Pausa") as Button
	if pausa == null:
		_fail("HUD sem o botão de pausa por toque")
	elif pausa.visible:
		_fail("O botão de pausa por toque apareceu sem tela de toque")

	Input.action_press(&"move_up")
	_joystick.set_ativo(false)
	if Input.get_action_strength(&"move_up") < 1.0:
		_fail("O joystick soltou uma tecla que ele não apertou: o druida pararia no teclado")
	Input.action_release(&"move_up")


# ------------------------------------------------------------------- toque --


func _tocar(dedo: int, posicao: Vector2, apertado: bool) -> void:
	var evento := InputEventScreenTouch.new()
	evento.index = dedo
	evento.position = posicao
	evento.pressed = apertado
	_joystick._input(evento)


func _arrastar(dedo: int, posicao: Vector2) -> void:
	var evento := InputEventScreenDrag.new()
	evento.index = dedo
	evento.position = posicao
	_joystick._input(evento)


func _check_forca(quando: String, direita: float, baixo: float) -> void:
	var r := Input.get_action_strength(&"move_right")
	var b := Input.get_action_strength(&"move_down")
	if absf(r - direita) > 0.05 or absf(b - baixo) > 0.05:
		_fail("%s: esperava direita %.2f e baixo %.2f, veio %.2f e %.2f" % [quando, direita, baixo, r, b])
	if Input.get_action_strength(&"move_left") > 0.0 or Input.get_action_strength(&"move_up") > 0.0:
		_fail("%s: o lado oposto ficou apertado junto" % quando)


# ------------------------------------------------------------- área segura --


func _check_area_segura() -> void:
	var m := {"cima": 30.0, "baixo": 20.0, "esquerda": 40.0, "direita": 50.0}

	# No PC as margens são zero: o HUD não pode pular por causa da barra de
	# tarefas do Windows.
	var no_pc := AreaSegura.margens(root)
	for lado in no_pc:
		if not is_zero_approx(float(no_pc[lado])):
			_fail("Fora do celular a margem '%s' deveria ser zero, é %.1f" % [lado, float(no_pc[lado])])

	var casos := [
		# [nome, âncoras (esq, cima, dir, baixo), deslocamento esperado (esq, cima, dir, baixo)]
		["centro de cima, como a barra de XP", [0.5, 0.0, 0.5, 0.0], [0.0, 30.0, 0.0, 30.0]],
		["canto de baixo à esquerda, como a vida", [0.0, 1.0, 0.0, 1.0], [40.0, -20.0, 40.0, -20.0]],
		["canto de baixo à direita, como o tempo", [1.0, 1.0, 1.0, 1.0], [-50.0, -20.0, -50.0, -20.0]],
		["tela inteira", [0.0, 0.0, 1.0, 1.0], [40.0, 30.0, -50.0, -20.0]],
	]
	for caso in casos:
		var c := Control.new()
		var a: Array = caso[1]
		c.anchor_left = a[0]
		c.anchor_top = a[1]
		c.anchor_right = a[2]
		c.anchor_bottom = a[3]
		c.offset_left = 10.0
		c.offset_top = 10.0
		c.offset_right = 110.0
		c.offset_bottom = 60.0
		AreaSegura.aplicar(c, m)
		AreaSegura.aplicar(c, m)  # de novo: não pode acumular
		var e: Array = caso[2]
		var veio := [c.offset_left - 10.0, c.offset_top - 10.0, c.offset_right - 110.0, c.offset_bottom - 60.0]
		for i in 4:
			if absf(float(veio[i]) - float(e[i])) > 0.01:
				_fail("Área segura, %s: esperava deslocar %s, deslocou %s" % [caso[0], str(e), str(veio)])
				break
		c.free()


# ----------------------------------------------------------------- projeto --


func _check_projeto() -> void:
	var orientacao := int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
	# Paisagem, paisagem invertida ou paisagem pelo sensor.
	if not orientacao in [DisplayServer.SCREEN_LANDSCAPE, DisplayServer.SCREEN_REVERSE_LANDSCAPE,
			DisplayServer.SCREEN_SENSOR_LANDSCAPE]:
		_fail("A orientação deveria ser paisagem, é %d" % orientacao)

	var presets := ConfigFile.new()
	if presets.load(PRESETS) != OK:
		_fail("Sem export_presets.cfg: não há como exportar para Android")
		return
	var achou := false
	for secao in presets.get_sections():
		if presets.get_value(secao, "platform", "") != "Android":
			continue
		achou = true
		var opcoes := secao + ".options"
		if not bool(presets.get_value(opcoes, "architectures/arm64-v8a", false)):
			_fail("O preset Android não exporta arm64-v8a, a arquitetura dos celulares atuais")
		if str(presets.get_value(opcoes, "package/unique_name", "")).is_empty():
			_fail("O preset Android não tem nome de pacote")
		var fora := str(presets.get_value(secao, "exclude_filter", ""))
		for pasta in ["tools/", "tests/"]:
			if not fora.contains(pasta):
				_fail("O preset Android empacota %s, que é ferramenta de desenvolvimento" % pasta)
	if not achou:
		_fail("export_presets.cfg sem preset Android")


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 12 OK — joystick nas ações do teclado, pausa por toque, área segura e preset Android.")
		return
	printerr("FASE 12 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
