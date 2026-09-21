class_name Anuncios
extends RefCounted
## Porta de entrada dos anúncios (FASE 15).
##
## O jogo só fala com esta classe, e ela só fala com um **provedor**: no
## Android, `anuncios_admob.gd`, que usa o plugin da AdMob; em qualquer outro
## lugar — PC, editor, testes —, nenhum, e tudo aqui responde "não há anúncio".
##
## A separação existe por causa dos testes. As classes do plugin carregam o
## módulo nativo assim que o script é lido, e fora do Android caem num simulador
## de janelas feito para o editor. Com o plugin atrás de um `load` que só roda no
## celular, nenhuma suíte encosta nele — e um teste pode trocar o provedor por um
## falso para conferir a tela de resultado sem anúncio de verdade.
##
## Só existe o formato **premiado**, e só no fim da partida: o jogador escolhe
## ver. Ver `docs/PUBLICACAO.md`, "Como os anúncios devem entrar".

const _ADMOB := "res://scripts/systems/anuncios_admob.gd"

static var _provedor: Object = null
static var _iniciado := false


## Liga o provedor, uma vez por execução. Chamado pelo menu, que é a primeira
## tela: o consentimento e o primeiro anúncio carregam enquanto o jogador ainda
## está escolhendo, e ficam prontos quando a partida acabar.
static func iniciar(arvore: SceneTree) -> void:
	if _iniciado:
		return
	_iniciado = true
	if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
		return
	var script := load(_ADMOB) as Script
	if script == null:
		return
	var no: Node = script.new()
	no.name = "Anuncios"
	# Fica acima das cenas: trocar de tela não pode apagar um anúncio carregado.
	arvore.root.add_child.call_deferred(no)
	_provedor = no


## Para os testes: põe um provedor falso no lugar, ou tira (`null`).
static func usar_provedor(provedor: Object) -> void:
	_provedor = provedor
	_iniciado = provedor != null


static func premiado_pronto() -> bool:
	return _provedor != null and bool(_provedor.call("premiado_pronto"))


## Mostra o premiado. `ao_ganhar` é chamado só se o jogador assistir até o fim;
## fechar antes não dá prêmio — é a regra do formato, e a AdMob confere.
static func mostrar_premiado(ao_ganhar: Callable) -> bool:
	if not premiado_pronto():
		return false
	return bool(_provedor.call("mostrar_premiado", ao_ganhar))


## Na Europa e no Reino Unido o jogador precisa poder rever a escolha de
## consentimento depois — a Google exige um botão para isso.
static func privacidade_necessaria() -> bool:
	return _provedor != null and bool(_provedor.call("privacidade_necessaria"))


static func mostrar_privacidade() -> void:
	if _provedor != null:
		_provedor.call("mostrar_privacidade")
