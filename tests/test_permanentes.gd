extends SceneTree
## Verificação dos upgrades permanentes (FASE 13).
##
## Uso:
##   godot --headless --path . --script res://tests/test_permanentes.gd
##
## O que se cobra aqui, em ordem de importância:
##
## **O dinheiro.** Comprar desconta o preço exato, e comprar sem ter não gasta
## nada nem sobe nível. Um erro aqui apaga progresso que o jogador levou várias
## partidas para juntar, e o save já está gravado quando ele percebe.
##
## **O bônus chega na partida.** Não basta o save dizer "vida 3": o druida tem
## de entrar em campo com mais vida. É a ponta que costuma ficar solta, porque
## funciona no menu e ninguém confere em jogo.
##
## Roda num save próprio: a suíte não pode gastar a moeda de quem joga.

const TESTE := "user://teste_permanentes.json"
const GAME_SCENE := "res://scenes/game/game.tscn"

var _failures: Array[String] = []
var _game: Node = null
var _frames := 3


func _initialize() -> void:
	SaveJogo.usar_caminho(TESTE)
	SaveJogo.apagar()

	_check_catalogo()
	_check_preco()
	_check_compra()
	_check_persistencia()
	_check_stats()
	_check_loja()

	# Deixa dois níveis de vida comprados para conferir o efeito em partida.
	SaveJogo.apagar()
	SaveJogo.dados()["moedas"] = 9999
	Permanentes.comprar(&"vida")
	Permanentes.comprar(&"vida")
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false
	_check_na_partida()

	SaveJogo.apagar()
	SaveJogo.usar_caminho(SaveJogo.CAMINHO)
	_report()
	quit(0 if _failures.is_empty() else 1)
	return true


## O catálogo precisa estar inteiro: a loja e o save leem daqui.
func _check_catalogo() -> void:
	var vistos := {}
	for linha in Permanentes.CATALOGO:
		for campo in ["id", "nome", "descricao", "stat", "ganho", "niveis", "preco_base", "preco_passo"]:
			if not linha.has(campo):
				_fail("O item %s não tem o campo '%s'" % [str(linha.get("id", "?")), campo])
		if vistos.has(linha["id"]):
			_fail("Dois itens com o id '%s'" % linha["id"])
		vistos[linha["id"]] = true
		if int(linha["niveis"]) <= 0 or float(linha["ganho"]) <= 0.0:
			_fail("O item %s não dá nada: %d níveis, ganho %.2f" % [
				linha["id"], linha["niveis"], linha["ganho"]])
	if Permanentes.item(&"nao_existe").size() != 0:
		_fail("Um id inventado deveria devolver um item vazio")


## O preço sobe a cada nível e some no teto.
func _check_preco() -> void:
	SaveJogo.apagar()
	var vida := Permanentes.item(&"vida")
	if Permanentes.preco(&"vida") != int(vida["preco_base"]):
		_fail("O primeiro nível deveria custar %d, custa %d" % [
			vida["preco_base"], Permanentes.preco(&"vida")])

	SaveJogo.dados()["moedas"] = 99999
	var anterior := Permanentes.preco(&"vida")
	for i in int(vida["niveis"]):
		var custo := Permanentes.preco(&"vida")
		if i > 0 and custo <= anterior:
			_fail("O nível %d custa %d, não mais que o anterior (%d)" % [i + 1, custo, anterior])
		anterior = custo
		Permanentes.comprar(&"vida")

	if Permanentes.preco(&"vida") != 0:
		_fail("No teto o preço deveria ser zero, é %d" % Permanentes.preco(&"vida"))
	if Permanentes.pode_comprar(&"vida"):
		_fail("No teto ainda dá para comprar")
	if Permanentes.comprar(&"vida"):
		_fail("Comprou acima do teto")
	if SaveJogo.nivel_permanente(&"vida") != int(vida["niveis"]):
		_fail("O nível passou do teto: %d" % SaveJogo.nivel_permanente(&"vida"))


## Sem moeda não se compra, e não se perde nada tentando.
func _check_compra() -> void:
	SaveJogo.apagar()
	var custo := Permanentes.preco(&"dano")
	SaveJogo.dados()["moedas"] = custo - 1
	if Permanentes.comprar(&"dano"):
		_fail("Comprou sem ter o preço todo")
	if int(SaveJogo.dados()["moedas"]) != custo - 1:
		_fail("A tentativa frustrada mexeu na carteira: %d" % SaveJogo.dados()["moedas"])
	if SaveJogo.nivel_permanente(&"dano") != 0:
		_fail("A tentativa frustrada subiu o nível")

	SaveJogo.dados()["moedas"] = custo + 30
	if not Permanentes.comprar(&"dano"):
		_fail("Não comprou tendo o dinheiro")
	if int(SaveJogo.dados()["moedas"]) != 30:
		_fail("Deveria sobrar 30 moedas, sobrou %d" % SaveJogo.dados()["moedas"])
	if SaveJogo.nivel_permanente(&"dano") != 1:
		_fail("O nível não subiu: %d" % SaveJogo.nivel_permanente(&"dano"))


## O que foi comprado sobrevive ao disco.
func _check_persistencia() -> void:
	var nivel := SaveJogo.nivel_permanente(&"dano")
	var moedas := int(SaveJogo.dados()["moedas"])
	SaveJogo.usar_caminho(TESTE)
	if SaveJogo.nivel_permanente(&"dano") != nivel:
		_fail("O nível comprado não voltou do disco: %d virou %d" % [
			nivel, SaveJogo.nivel_permanente(&"dano")])
	if int(SaveJogo.dados()["moedas"]) != moedas:
		_fail("A carteira não voltou do disco")


## O bônus entra no `StatComponent` como as passivas entram.
func _check_stats() -> void:
	SaveJogo.apagar()
	var stats := StatComponent.new()
	Permanentes.aplicar(stats)
	if not stats.is_untouched(StatComponent.Stat.MAX_HEALTH):
		_fail("Sem nada comprado, o stat já veio mexido")

	SaveJogo.dados()["moedas"] = 9999
	Permanentes.comprar(&"vida")
	Permanentes.comprar(&"vida")
	Permanentes.comprar(&"vida")
	stats = StatComponent.new()
	Permanentes.aplicar(stats)
	var esperado := 1.0 + 3.0 * float(Permanentes.item(&"vida")["ganho"])
	if not is_equal_approx(stats.factor(StatComponent.Stat.MAX_HEALTH), esperado):
		_fail("Três níveis de vida deveriam dar fator %.2f, dão %.2f" % [
			esperado, stats.factor(StatComponent.Stat.MAX_HEALTH)])


## A ponta que costuma ficar solta: o druida entra em campo mais forte.
func _check_na_partida() -> void:
	var saude := _game.get_node("Player/Health") as HealthComponent
	var stats := _game.get_node("Player/Stats") as StatComponent
	var ganho := 2.0 * float(Permanentes.item(&"vida")["ganho"])

	if not is_equal_approx(stats.factor(StatComponent.Stat.MAX_HEALTH), 1.0 + ganho):
		_fail("A partida não recebeu os dois níveis comprados: fator %.2f" % [
			stats.factor(StatComponent.Stat.MAX_HEALTH)])

	# A vida base do druida está na cena; o que importa é que o máximo em campo
	# esteja acima dela na mesma proporção.
	var base: float = (load("res://scenes/player/player.tscn") as PackedScene) \
		.instantiate().get_node("Health").max_health
	if saude.max_health <= base:
		_fail("Com dois níveis de vida o druida entrou com %.0f, e a base é %.0f" % [
			saude.max_health, base])
	elif not is_equal_approx(saude.max_health, base * (1.0 + ganho)):
		_fail("O máximo deveria ser %.0f, é %.0f" % [base * (1.0 + ganho), saude.max_health])
	if saude.current_health < saude.max_health:
		_fail("O druida entrou com %.0f de %.0f: vida máxima comprada tem de vir cheia" % [
			saude.current_health, saude.max_health])


## A loja mostra o catálogo, compra pelo botão e trava o que não cabe na carteira.
##
## A tela é o único lugar onde o jogador encosta nisso: um preço certo no código
## e errado na placa vale zero.
func _check_loja() -> void:
	SaveJogo.apagar()
	var loja := (load("res://scenes/ui/loja.tscn") as PackedScene).instantiate()
	root.add_child(loja)
	# `_ready` não dispara em nó acrescentado de dentro de `_initialize`.
	loja.call("_montar")

	var botoes: Array = loja.call("botoes")
	if botoes.size() != Permanentes.CATALOGO.size() + 1:
		_fail("A loja deveria ter %d placas (catálogo + VOLTAR), tem %d" % [
			Permanentes.CATALOGO.size() + 1, botoes.size()])
		loja.free()
		return
	if String(botoes[botoes.size() - 1].text) != "VOLTAR":
		_fail("A última placa deveria ser VOLTAR, é '%s'" % botoes[botoes.size() - 1].text)

	# Sem moeda, nada é clicável.
	for i in Permanentes.CATALOGO.size():
		if not botoes[i].disabled:
			_fail("Sem moeda, a placa '%s' continua clicável" % botoes[i].text)

	var primeiro: Dictionary = Permanentes.CATALOGO[0]
	if not String(botoes[0].text).contains(str(Permanentes.preco(primeiro["id"]))):
		_fail("A placa não mostra o preço: '%s'" % botoes[0].text)

	# Com moeda, comprar pelo botão sobe o nível e desconta.
	SaveJogo.dados()["moedas"] = 10000
	loja.call("_montar")
	botoes = loja.call("botoes")
	var custo := Permanentes.preco(primeiro["id"])
	botoes[0].pressed.emit()
	if SaveJogo.nivel_permanente(primeiro["id"]) != 1:
		_fail("O botão da loja não comprou: nível %d" % SaveJogo.nivel_permanente(primeiro["id"]))
	if int(SaveJogo.dados()["moedas"]) != 10000 - custo:
		_fail("A loja descontou errado: sobrou %d de %d" % [SaveJogo.dados()["moedas"], 10000 - custo])

	# E o texto acompanha: nível novo e preço novo.
	botoes = loja.call("botoes")
	if not String(botoes[0].text).contains("1/"):
		_fail("A placa não mostrou o nível comprado: '%s'" % botoes[0].text)
	loja.free()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("PERMANENTES OK — preço sobe, compra desconta, o teto segura e o bônus entra em campo.")
		return
	printerr("PERMANENTES FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
