extends SceneTree
## Verificação do bot de teste no celular, rodando no PC.
##
## Uso:
##   godot --headless --path . --script res://tests/test_bot.gd
##
## O `BotPiloto` é o que joga no aparelho; lá ninguém vê se ele parou de andar
## ou travou num menu de level up — o log só mostraria uma partida estranha.
## Aqui ele joga 20 s de verdade e o teste confere que o druida anda, que o
## menu de level up não fica aberto e que as ações apertadas são soltas ao sair.
##
## E o jogo normal não pode acionar o bot: sem `--bot`, `BotMobile.pedido()` é
## falso.

const GAME_SCENE := "res://scenes/game/game.tscn"
const QUADROS := 1200

var _failures: Array[String] = []
var _game: Node = null
var _piloto: BotPiloto = null
var _player: Node2D = null
var _manager: GameManager = null
var _quadro := 0
var _inicio := Vector2.ZERO
var _percorrido := 0.0
var _anterior := Vector2.ZERO
var _travado := 0
var _saiu_em := -1


func _initialize() -> void:
	if BotMobile.pedido():
		_fail("O bot ligou sem --bot na linha de comando")
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _physics_process(_delta: float) -> bool:
	_quadro += 1
	# O piloto saiu: confere depois de uns quadros, quando ele já deixou a
	# árvore. Conferir no mesmo quadro veria o nó ainda lá.
	if _saiu_em >= 0:
		if _quadro - _saiu_em >= 3:
			_check_soltou()
			return true
		return false
	if _quadro == 3:
		_player = _game.get_node("Player")
		_manager = _game.get_node("GameManager")
		# O druida não cai: o teste é sobre o piloto, não sobre sobreviver.
		for filho in _player.get_children():
			if filho is HurtboxComponent:
				(filho as HurtboxComponent).set_vulnerable(false)
		_piloto = BotPiloto.new()
		_game.add_child(_piloto)
		_piloto.configure(_game, 1)
		_inicio = _player.global_position
		_anterior = _inicio
		return false
	if _quadro < 3:
		return false

	_percorrido += _player.global_position.distance_to(_anterior)
	_anterior = _player.global_position
	# Menu de level up aberto por muito tempo = o piloto não escolheu.
	if _manager.estado == GameManager.Estado.ESCOLHENDO:
		_travado += 1
		if _travado == 120:
			_fail("O menu de level up ficou 2 s aberto: o piloto não escolheu")
	else:
		_travado = 0

	if _quadro < QUADROS:
		return false

	if _percorrido < 400.0:
		_fail("Em 20 s o piloto andou só %.0f px com o druida" % _percorrido)
	if _piloto.escolhas.is_empty():
		_fail("Em 20 s o piloto não escolheu nenhum upgrade")
	_piloto.queue_free()
	_piloto = null
	_saiu_em = _quadro
	return false


func _check_soltou() -> void:
	for acao in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if Input.get_action_strength(acao) > 0.0:
			_fail("O piloto saiu e deixou %s apertado" % acao)
	paused = false
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("BOT OK — o piloto anda, escolhe upgrade, solta as ações ao sair, e não liga sem --bot.")
		return
	printerr("BOT FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
