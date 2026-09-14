class_name BotMobile
extends Node
## Teste automático no celular: joga partidas sozinho e escreve no log.
##
## Liga **só** numa build de depuração aberta com `--bot` na linha de comando.
## Quem põe esse argumento é o preset de exportação "Android Bot", que gera um
## APK com pacote próprio (`com.feardev24.forestsurvival.bot`) — ele convive com
## o jogo normal no mesmo aparelho, e o jogo normal nunca passa por aqui.
##
## Argumentos (em `command_line/extra_args` do preset):
##   --bot                 liga o teste;
##   --bot-partidas=N      quantas partidas seguidas (padrão 2);
##   --bot-invulneravel    o druida não cai: a partida chega à horda cheia e ao
##                         Guardião, que é o caso que o desempenho precisa medir;
##   --bot-minutos=M       teto de tempo de jogo por partida (padrão 9);
##   --bot-armas=a,b       dá estas armas ao druida no começo da partida, pelo
##                         id do `WeaponData`. Serve para olhar uma habilidade
##                         **no aparelho** sem esperar a fase que a libera: o
##                         Anel de Esporos, por exemplo, só é oferecido aos
##                         150 s (DEC-025).
##
## Lido pelo `adb logcat -s godot`:
##   FS_BOT_INICIO / FS_BOT_FIM / FS_BOT_ACABOU — cada partida e o fim do teste;
##   FS_PERF e FS_TELA — do `MonitorDesempenho`, que a partida já liga sozinha
##   em build de depuração num aparelho móvel.
##
## Fica na raiz da árvore, fora das cenas: sobrevive à troca de cena entre uma
## partida e outra.

const GAME_SCENE := "res://scenes/game/game.tscn"

var _partidas := 2
var _invulneravel := false
var _minutos := 9.0
var _armas_pedidas: PackedStringArray = []
var _atual := 0
var _jogo: Node = null
var _piloto: BotPiloto = null
var _espera := -1.0
var _terminou := false


static func pedido() -> bool:
	return OS.is_debug_build() and "--bot" in OS.get_cmdline_args()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--bot-partidas="):
			_partidas = maxi(1, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--bot-minutos="):
			_minutos = maxf(1.0, float(arg.get_slice("=", 1)))
		elif arg == "--bot-invulneravel":
			_invulneravel = true
		elif arg.begins_with("--bot-armas="):
			_armas_pedidas = arg.get_slice("=", 1).split(",", false)
	print("FS_BOT_CONFIG partidas=%d invulneravel=%s minutos=%.0f armas=%s" % [
		_partidas, str(_invulneravel), _minutos, ",".join(_armas_pedidas)])
	_proxima_partida()


func _proxima_partida() -> void:
	_atual += 1
	if _atual > _partidas:
		_terminou = true
		print("FS_BOT_ACABOU partidas=%d" % _partidas)
		return
	seed(_atual)
	_jogo = null
	_piloto = null
	get_tree().change_scene_to_file(GAME_SCENE)


func _process(delta: float) -> void:
	if _terminou:
		return
	var cena := get_tree().current_scene
	if _jogo == null and cena != null and cena.scene_file_path == GAME_SCENE and cena.is_node_ready():
		_preparar(cena)

	if _jogo != null and _espera < 0.0:
		var manager := _jogo.get_node_or_null("GameManager") as GameManager
		if manager != null and manager.get_elapsed() >= _minutos * 60.0 and not manager.esta_no_fim():
			_registrar_fim("tempo_esgotado", manager.get_elapsed(), manager.get_nivel())

	if _espera >= 0.0:
		_espera -= delta
		if _espera < 0.0:
			_proxima_partida()


func _preparar(jogo: Node) -> void:
	_jogo = jogo
	_piloto = BotPiloto.new()
	_piloto.name = "BotPiloto"
	jogo.add_child(_piloto)
	_piloto.configure(jogo, _atual)
	if _invulneravel:
		for filho in jogo.get_node("Player").get_children():
			if filho is HurtboxComponent:
				(filho as HurtboxComponent).set_vulnerable(false)
	_dar_armas(jogo)
	(jogo.get_node("GameManager") as GameManager).ended.connect(_on_fim)
	print("FS_BOT_INICIO partida=%d semente=%d invulneravel=%s" % [_atual, _atual, str(_invulneravel)])


## Entrega as armas pedidas em `--bot-armas`, e diz no log quais entraram.
func _dar_armas(jogo: Node) -> void:
	if _armas_pedidas.is_empty():
		return
	var armas := jogo.get_node("Player/WeaponManager") as WeaponManager
	for id in _armas_pedidas:
		var caminho := "res://resources/weapons/%s.tres" % id
		if not ResourceLoader.exists(caminho):
			print("FS_BOT_ARMA ausente=%s" % id)
			continue
		armas.add_weapon(load(caminho) as WeaponData)
		print("FS_BOT_ARMA dada=%s" % id)


func _on_fim(vitoria: bool, tempo: float, nivel: int) -> void:
	_registrar_fim("vitoria" if vitoria else "derrota", tempo, nivel)


func _registrar_fim(desfecho: String, tempo: float, nivel: int) -> void:
	if _espera >= 0.0:
		return
	var armas := []
	var gerente := _jogo.get_node_or_null("Player/WeaponManager") as WeaponManager
	if gerente != null:
		for id in [&"orbe_do_cajado", &"cajado_raio", &"vinha_espinhosa", &"corvo_espiritual",
				&"anel_de_esporos", &"vagalumes_guardioes"]:
			var n := gerente.get_weapon_level(id)
			if n > 0:
				armas.append("%s:%d" % [id, n])
	print("FS_BOT_FIM partida=%d desfecho=%s tempo=%.0f nivel=%d armas=%s escolhas=%d" % [
		_atual, desfecho, tempo, nivel, ",".join(armas), _piloto.escolhas.size() if _piloto else 0])
	# Uns segundos na tela de resultado, e a próxima partida.
	_espera = 3.0
