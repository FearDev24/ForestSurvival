extends SceneTree
## Verificação do menu principal (`docs/03_SYSTEMS.md` §16).
##
## Uso:
##   godot --headless --path . --script res://tests/test_menu.gd
##
## Percorre o ciclo inteiro pelos próprios botões, como um jogador:
## menu → JOGAR → partida → pausa → MENU → menu → JOGAR → fim de partida →
## MENU → menu.
##
## O que importa em cada volta ao menu não é só a cena ter trocado: é a árvore
## estar **andando**. Uma partida pausada que troca de cena deixa a árvore
## parada, e o menu nasceria sem responder a clique — a tela certa, travada.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"

var _failures: Array[String] = []
var _stage := 0
var _frames := 0


func _initialize() -> void:
	_check_estrutura()
	change_scene_to_file(MENU_SCENE)
	_frames = 6


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false

	match _stage:
		0:
			_check_no_menu("ao abrir o jogo")
			_apertar(_botao(current_scene, "JOGAR"))
			_proximo(12)
		1:
			_check_na_partida("vindo do menu")
			var manager := _manager()
			if manager != null:
				manager.pausar()
			_proximo(6)
		2:
			if not paused:
				_fail("Pausar não parou a árvore: o resto do teste não provaria nada")
			_apertar(_botao(current_scene.get_node_or_null("PauseMenu"), "MENU"))
			_proximo(12)
		3:
			_check_no_menu("voltando da pausa")
			_apertar(_botao(current_scene, "JOGAR"))
			_proximo(12)
		4:
			_check_na_partida("pela segunda vez")
			# O fim de partida pausa a árvore; a tela de resultado aparece com
			# ela parada, e é dali que o MENU tem de funcionar.
			paused = true
			_apertar(_botao(current_scene.get_node_or_null("ResultScreen"), "MENU"))
			_proximo(12)
		5:
			_check_no_menu("voltando da tela de resultado")
			_report()
			quit(0 if _failures.is_empty() else 1)
			return true
	return false


func _proximo(frames: int) -> void:
	_stage += 1
	_frames = frames


# --------------------------------------------------------------- estrutura --


func _check_estrutura() -> void:
	var principal: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if principal != MENU_SCENE:
		_fail("A cena principal deveria ser o menu, é '%s'" % principal)
	for cena in [MENU_SCENE, GAME_SCENE]:
		if not ResourceLoader.exists(cena):
			_fail("Cena não encontrada: %s" % cena)


# ----------------------------------------------------------------- estados --


func _check_no_menu(quando: String) -> void:
	if current_scene == null or current_scene.scene_file_path != MENU_SCENE:
		_fail("Deveria estar no menu %s, está em '%s'"
			% [quando, current_scene.scene_file_path if current_scene else "nada"])
		return
	if paused:
		_fail("O menu nasceu com a árvore parada %s: nenhum botão responderia" % quando)
	var textos: Array[String] = []
	for botao in current_scene.botoes():
		textos.append(botao.text)
		if not botao.can_process():
			_fail("O botão %s do menu não processa %s" % [botao.text, quando])
	if textos != ["JOGAR", "SAIR"]:
		_fail("O menu deveria oferecer JOGAR e SAIR %s, oferece %s" % [quando, str(textos)])


func _check_na_partida(quando: String) -> void:
	if current_scene == null or current_scene.scene_file_path != GAME_SCENE:
		_fail("JOGAR deveria levar à partida %s, está em '%s'"
			% [quando, current_scene.scene_file_path if current_scene else "nada"])
		return
	if paused:
		_fail("A partida começou parada %s" % quando)
	var manager := _manager()
	if manager == null:
		_fail("A partida não tem GameManager %s" % quando)
	elif manager.estado != GameManager.Estado.JOGANDO:
		_fail("A partida deveria começar JOGANDO %s, está em %d" % [quando, manager.estado])


# ------------------------------------------------------------------ apoio --


func _manager() -> GameManager:
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("GameManager") as GameManager


## O botão com este texto numa tela. Falha — e devolve nulo — se ele não
## existir: é assim que "SAIR que não virou MENU" aparece.
func _botao(tela: Node, texto: String) -> Button:
	if tela == null or not tela.has_method("botoes"):
		_fail("Tela sem botões ao procurar '%s'" % texto)
		return null
	var achados: Array[String] = []
	for botao in tela.botoes():
		achados.append(botao.text)
		if botao.text == texto:
			return botao
	_fail("'%s' não tem o botão %s, tem %s" % [tela.name, texto, str(achados)])
	return null


func _apertar(botao: Button) -> void:
	if botao == null:
		return
	if botao.pressed.get_connections().is_empty():
		_fail("O botão %s não está ligado a nada" % botao.text)
	botao.pressed.emit()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("MENU OK — entra na partida, volta da pausa e do fim, sempre com a árvore andando.")
		return
	printerr("MENU FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
