class_name Permanentes
extends RefCounted
## Upgrades permanentes: o que a moeda compra (FASE 13).
##
## São três, e mexem nos mesmos stats que as passivas de partida mexem —
## `MAX_HEALTH`, `DAMAGE` e `MOVE_SPEED`. A diferença é quando: a passiva vale
## até o fim daquela partida, e o permanente vale em todas as próximas.
##
## **Por que percentual e não valor fixo.** O `StatComponent` já soma percentual
## por cima da base, e é assim que as passivas funcionam. Um bônus fixo de vida
## seria enorme no início e irrelevante depois; o percentual mantém o mesmo peso
## a partida inteira.
##
## **Por que cinco níveis e preço crescente.** O primeiro nível custa cerca de
## uma partida mediana (89 moedas) e o último, cerca de cinco. Assim a primeira
## compra chega rápido — o jogador precisa sentir que a meta-progressão existe —
## e a última é uma meta de verdade.
##
## Ao máximo, os três juntos dão +50% de vida, +40% de dano e +25% de
## velocidade. **Isso mexe na dificuldade** e a sonda ainda não foi rodada com
## eles ligados: está registrado no HANDOFF como pendência.

## O catálogo. Ordem = ordem de exibição na loja.
const CATALOGO := [
	{
		"id": &"vida",
		"nome": "Vitalidade",
		"descricao": "+10% de vida máxima por nível",
		"stat": StatComponent.Stat.MAX_HEALTH,
		"ganho": 0.10,
		"niveis": 5,
		"preco_base": 100,
		"preco_passo": 80,
	},
	{
		"id": &"dano",
		"nome": "Força da Mata",
		"descricao": "+8% de dano por nível",
		"stat": StatComponent.Stat.DAMAGE,
		"ganho": 0.08,
		"niveis": 5,
		"preco_base": 120,
		"preco_passo": 100,
	},
	{
		"id": &"velocidade",
		"nome": "Passo Leve",
		"descricao": "+5% de velocidade por nível",
		"stat": StatComponent.Stat.MOVE_SPEED,
		"ganho": 0.05,
		"niveis": 5,
		"preco_base": 80,
		"preco_passo": 60,
	},
]


## O item do catálogo, ou um dicionário vazio se o id não existir.
static func item(id: StringName) -> Dictionary:
	for linha in CATALOGO:
		if linha["id"] == id:
			return linha
	return {}


## Quanto custa o **próximo** nível. Zero quando já está no máximo.
static func preco(id: StringName) -> int:
	var linha := item(id)
	if linha.is_empty():
		return 0
	var nivel := SaveJogo.nivel_permanente(id)
	if nivel >= int(linha["niveis"]):
		return 0
	return int(linha["preco_base"]) + int(linha["preco_passo"]) * nivel


## Dá para comprar o próximo nível agora?
static func pode_comprar(id: StringName) -> bool:
	var custo := preco(id)
	return custo > 0 and int(SaveJogo.dados()["moedas"]) >= custo


## Compra o próximo nível. Devolve `false` sem gastar nada se não der.
static func comprar(id: StringName) -> bool:
	if not pode_comprar(id):
		return false
	return SaveJogo.gastar_no_permanente(id, preco(id))


## Põe os bônus comprados no `StatComponent` da partida.
##
## Multiplicativo, como as passivas: quem tem três níveis de vida entra com
## +30% sobre a base, e as passivas da partida continuam somando por cima.
static func aplicar(stats: StatComponent) -> void:
	if stats == null:
		return
	for linha in CATALOGO:
		var nivel := SaveJogo.nivel_permanente(linha["id"])
		if nivel > 0:
			stats.add_mult(linha["stat"], float(linha["ganho"]) * nivel)


## Resumo legível do que está comprado, para a loja e para o log.
static func resumo() -> String:
	var partes: Array[String] = []
	for linha in CATALOGO:
		partes.append("%s %d/%d" % [linha["nome"], SaveJogo.nivel_permanente(linha["id"]),
			int(linha["niveis"])])
	return "  ·  ".join(partes)
