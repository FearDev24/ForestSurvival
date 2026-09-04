extends SceneTree
## Verificação do HUD da partida (`docs/ROADMAP.md`, FASE 9 — HP, XP, nível e tempo).
##
## Uso:
##   godot --headless --path . --script res://tests/test_hud.gd
##
## Cobre a arte das barras (o par precisa ter o mesmo tamanho, senão o
## preenchimento sai deslocado da moldura), o relógio, e o painel ligado a uma
## partida de verdade: vida caindo, XP subindo, nível trocando e o cronômetro
## congelando quando a tela de level up pausa o jogo.
##
## Não julga se a arte está bonita (DEC-013). Julga se ela encaixa.

const GAME_SCENE := "res://scenes/game/game.tscn"
const HUD_SCENE := "res://scenes/ui/hud.tscn"

var _failures: Array[String] = []

var _game: Node = null
var _hud: Hud = null
var _health: HealthComponent = null
var _level: LevelComponent = null
var _menu: CanvasLayer = null

var _stage := 0
var _frames_left := 0
var _tempo_ao_pausar := ""


func _initialize() -> void:
	_check_texturas()
	_check_relogio()
	_check_configure()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			# Um frame para o `_process` da partida rodar ao menos uma vez.
			_frames_left -= 1
			if _frames_left <= 0:
				_check_valores_iniciais()
				_start_dano_e_xp()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_dano_e_xp()
				_start_pausa()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_pausa()
				_finish()
				return true
	return false


# ----------------------------------------------------------------- texturas --


## As duas peças de cada barra precisam ter o mesmo tamanho: o
## `TextureProgressBar` desenha o preenchimento no mesmo retângulo do fundo, e
## tamanhos diferentes deslocam o líquido para fora do vão da moldura.
##
## Também precisam caber na viewport de 1280x720 — a textura é o tamanho mínimo
## do controle, então uma textura maior que a tela não teria como ser encolhida.
func _check_texturas() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		_fail("Cena do HUD não encontrada")
		return

	var hud: Node = (load(HUD_SCENE) as PackedScene).instantiate()
	var largura_tela: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var altura_tela: int = ProjectSettings.get_setting("display/window/size/viewport_height", 720)

	for nome in ["BarraXp", "BarraVida"]:
		var barra := hud.get_node_or_null(nome) as TextureProgressBar
		if barra == null:
			_fail("HUD sem %s" % nome)
			continue
		if barra.texture_under == null or barra.texture_progress == null:
			_fail("%s sem moldura ou sem preenchimento" % nome)
			continue

		var fundo := barra.texture_under.get_size()
		var cheio := barra.texture_progress.get_size()
		if fundo != cheio:
			_fail("%s: moldura %.0fx%.0f e preenchimento %.0fx%.0f têm tamanhos diferentes"
				% [nome, fundo.x, fundo.y, cheio.x, cheio.y])
		if fundo.x > float(largura_tela) or fundo.y > float(altura_tela):
			_fail("%s: textura %.0fx%.0f não cabe na viewport %dx%d"
				% [nome, fundo.x, fundo.y, largura_tela, altura_tela])
		if barra.fill_mode != TextureProgressBar.FILL_LEFT_TO_RIGHT:
			_fail("%s deveria esvaziar da direita para a esquerda" % nome)
		# A arte do HUD não é pixel art: reduzida com NEAREST, serrilha.
		if barra.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
			_fail("%s deveria usar filtro LINEAR, usa %d" % [nome, barra.texture_filter])

	for nome in ["Nivel", "Tempo"]:
		if hud.get_node_or_null(nome) as Label == null:
			_fail("HUD sem o rótulo %s" % nome)

	hud.free()


# ------------------------------------------------------------------ relógio --


func _check_relogio() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		return

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as Hud
	root.add_child(hud)
	var rotulo := hud.get_node_or_null("Tempo") as Label

	var casos := [[0.0, "00:00"], [9.9, "00:09"], [65.0, "01:05"], [599.0, "09:59"], [3725.0, "1:02:05"]]
	for caso in casos:
		var segundos: float = caso[0]
		var esperado: String = caso[1]
		hud.set_time(segundos)
		if rotulo.text != esperado:
			_fail("Relógio: %.1f s deveria mostrar %s, mostra %s" % [segundos, esperado, rotulo.text])

	hud.free()


# --------------------------------------------------------------- configure --


## `configure()` precisa **ler** o estado atual, não só conectar os sinais: os
## componentes já emitiram os deles antes de o HUD existir.
##
## Feito com componentes soltos, em estado que não é o inicial de ninguém. Se
## este teste dependesse do que `hud.tscn` traz por padrão, ele passaria mesmo
## com o `configure()` vazio — foi o que aconteceu na primeira versão.
func _check_configure() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		return

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as Hud
	root.add_child(hud)

	var health := HealthComponent.new()
	health.max_health = 200.0
	root.add_child(health)
	health.damage(150.0)          # sobra um quarto

	var level := LevelComponent.new()
	level.base_xp = 100.0
	root.add_child(level)
	level.add_xp(30.0)            # 30% do nível 1
	level.add_xp(level.xp_to_next() - level.xp)  # fecha e sobe para o nível 2
	level.add_xp(level.xp_to_next() * 0.4)

	hud.configure(health, level)

	var vida: float = hud.get_node("BarraVida").value
	if not is_equal_approx(snappedf(vida, 0.5), 25.0):
		_fail("configure() não leu a vida atual: barra em %.1f, esperado 25" % vida)

	var xp: float = hud.get_node("BarraXp").value
	if not is_equal_approx(snappedf(xp, 0.5), 40.0):
		_fail("configure() não leu o XP atual: barra em %.1f, esperado 40" % xp)

	var nivel := (hud.get_node("Nivel") as Label).text
	if nivel != "NIVEL 2":
		_fail("configure() não leu o nível atual: mostra %s, esperado NIVEL 2" % nivel)

	health.free()
	level.free()
	hud.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists(GAME_SCENE):
		_fail("game.tscn não encontrada")
		return false

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)

	_hud = _game.get_node_or_null("Hud") as Hud
	_health = _game.get_node_or_null("Player/Health") as HealthComponent
	_level = _game.get_node_or_null("Player/Level") as LevelComponent
	_menu = _game.get_node_or_null("LevelUpMenu") as CanvasLayer

	if _hud == null or _health == null or _level == null or _menu == null:
		_fail("game.tscn sem Hud, Health, Level ou LevelUpMenu")
		return false

	var spawn := _game.get_node_or_null("SpawnManager") as SpawnManager
	if spawn != null:
		spawn.enabled = false

	_frames_left = 2
	_stage = 0
	return true


## O HUD é ligado depois que os componentes já emitiram os sinais deles. Se
## `configure()` só conectasse os sinais sem ler o estado atual, as barras
## ficariam vazias até o primeiro dano e o primeiro fragmento.
func _check_valores_iniciais() -> void:
	var vida: float = _hud.get_node("BarraVida").value
	if not is_equal_approx(vida, 100.0):
		_fail("Vida cheia deveria encher a barra: %.1f" % vida)

	var xp: float = _hud.get_node("BarraXp").value
	if not is_equal_approx(xp, 0.0):
		_fail("Sem XP, a barra deveria estar vazia: %.1f" % xp)

	if (_hud.get_node("Nivel") as Label).text != "NIVEL 1":
		_fail("Nível inicial errado: %s" % (_hud.get_node("Nivel") as Label).text)
	if (_hud.get_node("Tempo") as Label).text != "00:00":
		_fail("O relógio deveria começar em 00:00, está em %s" % (_hud.get_node("Tempo") as Label).text)


func _start_dano_e_xp() -> void:
	_health.damage(_health.max_health * 0.25)
	_level.add_xp(_level.xp_to_next() * 0.5)
	_frames_left = 2
	_stage = 1


func _check_dano_e_xp() -> void:
	var vida: float = _hud.get_node("BarraVida").value
	if not is_equal_approx(snappedf(vida, 0.5), 75.0):
		_fail("Perder um quarto da vida deveria deixar a barra em 75: está em %.1f" % vida)

	var xp: float = _hud.get_node("BarraXp").value
	if not is_equal_approx(snappedf(xp, 0.5), 50.0):
		_fail("Metade do XP do nível deveria deixar a barra em 50: está em %.1f" % xp)


## O cronômetro é da partida, não do HUD: quando a tela de escolha pausa o jogo,
## o `_process` de `game.gd` para junto e o relógio congela sozinho.
func _start_pausa() -> void:
	_tempo_ao_pausar = (_hud.get_node("Tempo") as Label).text
	_level.add_xp(_level.xp_to_next() * 3.0)
	# Mais de um segundo de física: menos que isso, um relógio que continuasse
	# correndo ainda mostraria o mesmo número inteiro de segundos e passaria.
	_frames_left = 75
	_stage = 2


func _check_pausa() -> void:
	if not _menu.visible:
		_fail("A tela de level up não abriu; o teste da pausa não valeria nada")
	if not paused:
		_fail("A tela de level up deveria ter pausado a partida")

	var agora := (_hud.get_node("Tempo") as Label).text
	if agora != _tempo_ao_pausar:
		_fail("O relógio andou com o jogo pausado (%s -> %s)" % [_tempo_ao_pausar, agora])

	var nivel := (_hud.get_node("Nivel") as Label).text
	if nivel != "NIVEL %d" % _level.level:
		_fail("O rótulo de nível não acompanhou: mostra %s, o nível é %d" % [nivel, _level.level])

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
		print("HUD OK — barras encaixadas, vida, XP, nível e relógio acompanham a partida.")
		return
	printerr("HUD FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
