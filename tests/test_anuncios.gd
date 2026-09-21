extends SceneTree
## Verificação do anúncio premiado (FASE 15).
##
## Uso:
##   godot --headless --path . --script res://tests/test_anuncios.gd
##
## Não há anúncio de verdade aqui: fora do Android, `Anuncios` não liga
## provedor nenhum, e é a primeira coisa conferida — o PC e as outras suítes não
## podem depender da rede nem do plugin. O resto usa um provedor falso, que
## deixa o teste decidir quando o anúncio "carregou" e quando o jogador
## "assistiu até o fim".
##
## O que se cobra, em ordem de importância:
##
## **O prêmio só vem de anúncio assistido.** Tocar no botão não paga; fechar o
## anúncio antes do fim não paga; e assistir paga uma vez só, por mais que o
## aviso de "assistiu" chegue repetido. Moeda de graça ou em dobro desfaz a
## loja inteira.
##
## **Botão só com anúncio pronto.** Um botão que toca e não mostra nada é pior
## que não ter botão — e se o anúncio carregar com a tela já aberta, o botão
## tem de aparecer sozinho.
##
## Roda num save próprio, como as outras suítes que mexem em moeda.

const TESTE := "user://teste_anuncios.json"
const GAME_SCENE := "res://scenes/game/game.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const ABATES := 1043
## O texto da placa, igual ao de `result_screen.gd`.
const DOBRAR := "DOBRAR (ANÚNCIO)"
const TEMPO := 489.0


## Faz o papel do plugin: carregado quando o teste manda, e só chama o prêmio
## quando o teste diz que o jogador assistiu.
class Falso:
	extends RefCounted
	var pronto := false
	var privacidade := false
	var exibicoes := 0
	var ao_ganhar := Callable()

	func premiado_pronto() -> bool:
		return pronto

	func mostrar_premiado(cb: Callable) -> bool:
		exibicoes += 1
		ao_ganhar = cb
		pronto = false
		return true

	func privacidade_necessaria() -> bool:
		return privacidade

	func mostrar_privacidade() -> void:
		pass


var _failures: Array[String] = []
var _falso := Falso.new()
var _stage := 0
var _frames := 0
var _ganho := 0


func _initialize() -> void:
	SaveJogo.usar_caminho(TESTE)
	SaveJogo.apagar()
	_check_sem_provedor_no_pc()
	_ganho = int(SaveJogo.recompensa(ABATES, TEMPO, true)["total"])

	Anuncios.usar_provedor(_falso)
	_falso.pronto = true
	change_scene_to_file(GAME_SCENE)
	_frames = 8


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false

	match _stage:
		0:
			_terminar_partida()
			_proximo(3)
		1:
			_check_botao_e_premio()
			# Segunda partida: o anúncio ainda não carregou quando ela acaba.
			paused = false
			change_scene_to_file(GAME_SCENE)
			_proximo(8)
		2:
			_falso.pronto = false
			_terminar_partida()
			_proximo(3)
		3:
			if _tem(_resultado(), DOBRAR):
				_fail("Sem anúncio carregado, o botão de dobrar apareceu")
			_falso.pronto = true
			_proximo(3)
		4:
			if not _tem(_resultado(), DOBRAR):
				_fail("O anúncio carregou com a tela aberta e o botão não apareceu")
			_check_fechar_sem_assistir()
			paused = false
			_falso.privacidade = true
			change_scene_to_file(MENU_SCENE)
			_proximo(6)
		5:
			_check_privacidade()
			_encerrar()
			return true
	return false


func _proximo(frames: int) -> void:
	_stage += 1
	_frames = frames


## Fim de partida de verdade: o `GameManager` avisa, o jogo grava e a tela abre.
func _terminar_partida() -> void:
	var manager := current_scene.get_node("GameManager") as GameManager
	(current_scene.get_node("SpawnManager") as SpawnManager).enabled = false
	manager.set("_abates", ABATES)
	manager.emit_signal("ended", true, TEMPO, 21)
	paused = true


func _resultado() -> Node:
	return current_scene.get_node_or_null("ResultScreen")


# ---------------------------------------------------------------- verificações --


## No PC, iniciar não liga nada: nenhuma suíte pode depender do plugin.
func _check_sem_provedor_no_pc() -> void:
	Anuncios.usar_provedor(null)
	Anuncios.iniciar(self)
	if Anuncios.premiado_pronto():
		_fail("Fora do Android, `Anuncios` disse ter anúncio pronto")
	if Anuncios.mostrar_premiado(func() -> void: _fail("Pagou prêmio sem provedor")):
		_fail("Fora do Android, `mostrar_premiado` disse ter mostrado")
	if Anuncios.privacidade_necessaria():
		_fail("Fora do Android, o menu pediria o botão de privacidade")


func _check_botao_e_premio() -> void:
	var tela := _resultado()
	var botoes: Array = tela.call("botoes")
	if botoes.is_empty() or String(botoes[0].text) != DOBRAR:
		_fail("Com anúncio pronto, a primeira placa deveria ser '%s'" % DOBRAR)
		return

	var depois_da_partida := int(SaveJogo.dados()["moedas"])
	if depois_da_partida != _ganho:
		_fail("A partida deveria ter rendido %d moedas, rendeu %d" % [_ganho, depois_da_partida])

	botoes[0].pressed.emit()
	if _falso.exibicoes != 1:
		_fail("Tocar em dobrar não pediu o anúncio")
	if int(SaveJogo.dados()["moedas"]) != depois_da_partida:
		_fail("Tocar no botão já pagou, antes de o anúncio terminar")

	# O jogador assistiu até o fim — e o aviso chega duas vezes.
	_falso.ao_ganhar.call()
	_falso.ao_ganhar.call()
	if int(SaveJogo.dados()["moedas"]) != 2 * _ganho:
		_fail("Assistir deveria dobrar para %d, a carteira tem %d" % [
			2 * _ganho, SaveJogo.dados()["moedas"]])
	if _tem(tela, DOBRAR):
		_fail("Depois de dobrar, o botão continua lá")

	# O anúncio seguinte carrega, mas esta partida já foi dobrada.
	_falso.pronto = true
	tela.call("_process", 0.0)
	if _tem(tela, DOBRAR):
		_fail("A mesma partida ofereceu dobrar de novo")

	# E o prêmio ficou gravado, não só em memória.
	var em_memoria := int(SaveJogo.dados()["moedas"])
	SaveJogo.usar_caminho(TESTE)
	if int(SaveJogo.dados()["moedas"]) != em_memoria:
		_fail("O prêmio do anúncio não foi gravado no disco")


## Fechar antes do fim: o plugin nunca chama o prêmio, e nada entra.
func _check_fechar_sem_assistir() -> void:
	var antes := int(SaveJogo.dados()["moedas"])
	var botoes: Array = _resultado().call("botoes")
	botoes[0].pressed.emit()
	if int(SaveJogo.dados()["moedas"]) != antes:
		_fail("Fechar o anúncio sem assistir pagou o prêmio")


func _check_privacidade() -> void:
	if not _tem(current_scene, "PRIVACIDADE"):
		_fail("Com consentimento exigido, o menu não ofereceu PRIVACIDADE")
	var textos := []
	for botao in current_scene.call("botoes"):
		textos.append(String(botao.text))
	if textos.size() > 0 and textos[textos.size() - 1] != "SAIR":
		_fail("SAIR deveria continuar por último, a ordem é %s" % str(textos))


func _tem(no: Node, texto: String) -> bool:
	if no == null:
		return false
	for botao in no.call("botoes"):
		if String(botao.text) == texto:
			return true
	return false


func _encerrar() -> void:
	Anuncios.usar_provedor(null)
	SaveJogo.apagar()
	SaveJogo.usar_caminho(SaveJogo.CAMINHO)
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ANUNCIOS OK — sem plugin no PC, botão só com anúncio pronto, prêmio só assistindo e uma vez só.")
		return
	printerr("ANUNCIOS FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
