extends SceneTree
## Verificação do save local (FASE 13, `docs/03_SYSTEMS.md` §18).
##
## Uso:
##   godot --headless --path . --script res://tests/test_save.gd
##
## O save é a base da meta-progressão: moeda, desbloqueios e upgrades
## permanentes vão morar nele. Por isso o que se cobra aqui não é só "grava e
## lê", e sim o que acontece quando o arquivo está **errado** — ausente,
## quebrado, de outra versão, com um campo de tipo trocado. Save é o único
## arquivo do jogo que o jogador pode ter de uma versão antiga, e um save
## ilegível não pode virar tela preta.
##
## Roda num arquivo próprio (`usar_caminho`): a suíte não pode apagar o
## progresso de quem joga na mesma máquina.

const TESTE := "user://teste_save.json"
const GAME_SCENE := "res://scenes/game/game.tscn"

var _failures: Array[String] = []
var _game: Node = null
var _frames := 3


func _initialize() -> void:
	SaveJogo.usar_caminho(TESTE)
	SaveJogo.apagar()

	_check_padrao()
	_check_registro()
	_check_persistencia()
	_check_arquivo_quebrado()
	_check_versao_desconhecida()
	_check_campo_com_tipo_errado()
	_check_recompensa()
	_check_moedas_acumulam()

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false
	_check_abates_da_partida()
	_check_fim_de_partida()

	SaveJogo.apagar()
	SaveJogo.usar_caminho(SaveJogo.CAMINHO)
	_report()
	quit(0 if _failures.is_empty() else 1)
	return true


## Sem arquivo, valem os padrões — e não um dicionário vazio.
func _check_padrao() -> void:
	var d := SaveJogo.dados()
	for chave in SaveJogo.PADRAO:
		if not d.has(chave):
			_fail("Save novo sem o campo '%s'" % chave)
	if int(d.get("partidas", -1)) != 0 or int(d.get("vitorias", -1)) != 0:
		_fail("Save novo deveria começar zerado, veio %s" % str(d))


## Cada partida conta; recorde só sobe.
func _check_registro() -> void:
	SaveJogo.registrar_partida(false, 120.0, 8)
	var d := SaveJogo.dados()
	if int(d["partidas"]) != 1 or int(d["vitorias"]) != 0:
		_fail("Depois de uma derrota: %d partidas, %d vitórias" % [d["partidas"], d["vitorias"]])
	if not is_equal_approx(float(d["melhor_tempo"]), 120.0):
		_fail("O melhor tempo deveria ser 120, é %.0f" % d["melhor_tempo"])

	# Partida pior não pode baixar o recorde.
	SaveJogo.registrar_partida(false, 30.0, 3)
	d = SaveJogo.dados()
	if not is_equal_approx(float(d["melhor_tempo"]), 120.0) or int(d["melhor_nivel"]) != 8:
		_fail("Uma partida pior derrubou o recorde: tempo %.0f, nível %d" % [
			d["melhor_tempo"], d["melhor_nivel"]])

	if not SaveJogo.registrar_partida(true, 300.0, 20):
		_fail("Uma partida melhor deveria ser avisada como recorde")
	d = SaveJogo.dados()
	if int(d["vitorias"]) != 1 or int(d["partidas"]) != 3:
		_fail("Depois da vitória: %d partidas, %d vitórias" % [d["partidas"], d["vitorias"]])
	if not is_equal_approx(float(d["tempo_total"]), 450.0):
		_fail("O tempo total deveria somar 450 s, soma %.0f" % d["tempo_total"])


## O que foi gravado tem de voltar do disco, e não da memória.
func _check_persistencia() -> void:
	var antes := SaveJogo.dados().duplicate()
	# Reapontar para o mesmo arquivo esquece o que está em memória.
	SaveJogo.usar_caminho(TESTE)
	var depois := SaveJogo.dados()
	for chave in antes:
		if str(antes[chave]) != str(depois[chave]):
			_fail("O campo '%s' não sobreviveu ao disco: %s virou %s" % [
				chave, str(antes[chave]), str(depois[chave])])


## Arquivo quebrado não derruba o jogo: vale o padrão.
func _check_arquivo_quebrado() -> void:
	_escrever("{isso não é json")
	var d := SaveJogo.dados()
	if int(d["partidas"]) != 0:
		_fail("Save quebrado deveria virar padrão, veio %d partidas" % d["partidas"])


## Versão desconhecida não é adivinhada.
func _check_versao_desconhecida() -> void:
	_escrever(JSON.stringify({"versao": 99, "partidas": 7, "vitorias": 7}))
	var d := SaveJogo.dados()
	if int(d["partidas"]) != 0:
		_fail("Save de versão 99 foi lido assim mesmo: %d partidas" % d["partidas"])


## Um campo com tipo trocado vira padrão; o resto do save sobrevive.
func _check_campo_com_tipo_errado() -> void:
	_escrever(JSON.stringify({
		"versao": SaveJogo.VERSAO, "partidas": 5, "vitorias": "duas",
		"melhor_tempo": 88.0, "melhor_nivel": 9, "tempo_total": 100.0,
	}))
	var d := SaveJogo.dados()
	if int(d["partidas"]) != 5 or not is_equal_approx(float(d["melhor_tempo"]), 88.0):
		_fail("Os campos bons deveriam sobreviver: %s" % str(d))
	if int(d["vitorias"]) != 0:
		_fail("O campo com tipo errado deveria virar padrão, virou %s" % str(d["vitorias"]))


## O fim da partida chega ao save sozinho — é a ligação que o jogo usa.
func _check_fim_de_partida() -> void:
	SaveJogo.apagar()
	var manager := _game.get_node("GameManager") as GameManager
	manager.emit_signal("ended", true, 234.0, 17)
	var d := SaveJogo.dados()
	if int(d["partidas"]) != 1 or int(d["vitorias"]) != 1:
		_fail("O fim da partida não chegou ao save: %s" % str(d))
	elif not is_equal_approx(float(d["melhor_tempo"]), 234.0):
		_fail("O tempo da partida não foi registrado: %.0f" % d["melhor_tempo"])


## A moeda vem de três fontes, e a conta é a mesma para todo mundo.
##
## O número importa: ele decide o preço dos desbloqueios. Uma partida mediana da
## sonda (823 abates, 478 s, sem vitória) tem de render 89 moedas — mudar a
## fórmula sem mudar os preços quebra o ritmo da meta-progressão.
func _check_recompensa() -> void:
	var r := SaveJogo.recompensa(823, 478.0, false)
	if int(r["abates"]) != 82 or int(r["tempo"]) != 7 or int(r["vitoria"]) != 0:
		_fail("Partida mediana: %s" % str(r))
	if int(r["total"]) != 89:
		_fail("Partida mediana deveria render 89 moedas, rende %d" % r["total"])

	var v := SaveJogo.recompensa(1000, 550.0, true)
	if int(v["vitoria"]) != SaveJogo.MOEDAS_POR_VITORIA or int(v["total"]) != 159:
		_fail("Vitória típica: %s" % str(v))

	# Partida de nada rende nada, e número negativo não vira moeda.
	if int(SaveJogo.recompensa(0, 0.0, false)["total"]) != 0:
		_fail("Partida vazia rendeu moeda")
	if int(SaveJogo.recompensa(-5, -10.0, false)["total"]) != 0:
		_fail("Número negativo virou moeda")


## Moeda e abates somam entre partidas; é disso que a loja vai viver.
func _check_moedas_acumulam() -> void:
	SaveJogo.apagar()
	SaveJogo.registrar_partida(false, 120.0, 8, 200)
	SaveJogo.registrar_partida(true, 300.0, 20, 400)
	var d := SaveJogo.dados()
	var esperado := int(SaveJogo.recompensa(200, 120.0, false)["total"]) 		+ int(SaveJogo.recompensa(400, 300.0, true)["total"])
	if int(d["moedas"]) != esperado:
		_fail("As moedas deveriam somar %d, somam %d" % [esperado, d["moedas"]])
	if int(d["abates_total"]) != 600:
		_fail("Os abates deveriam somar 600, somam %d" % d["abates_total"])


## A partida conta os abates, e a limpeza do fim não conta como abate.
##
## O contêiner é esvaziado de uma vez quando a partida acaba; se a contagem não
## olhasse o estado, cada partida terminaria com dezenas de abates de brinde.
func _check_abates_da_partida() -> void:
	var manager := _game.get_node("GameManager") as GameManager
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	spawn.enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false
	var antes := manager.get_abates()

	var dados := load("res://resources/enemies/imp_corrompido.tres") as EnemyData
	var nascidos: Array[Node] = []
	for i in 3:
		var bicho := spawn.spawn_data(dados)
		if bicho != null:
			nascidos.append(bicho)
	if nascidos.size() != 3:
		_fail("Não consegui fazer nascer as três criaturas do teste")
		return
	for bicho in nascidos:
		(bicho.get_node("Health") as HealthComponent).damage(99999.0)
		bicho.free()

	if manager.get_abates() != antes + 3:
		_fail("Três criaturas morreram e a contagem foi de %d para %d" % [antes, manager.get_abates()])


func _escrever(texto: String) -> void:
	var arquivo := FileAccess.open(TESTE, FileAccess.WRITE)
	arquivo.store_string(texto)
	arquivo.close()
	# Força a releitura do disco.
	SaveJogo.usar_caminho(TESTE)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("SAVE OK — padrões seguros, recorde só sobe, sobrevive ao disco e o fim da partida chega nele.")
		return
	printerr("SAVE FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
