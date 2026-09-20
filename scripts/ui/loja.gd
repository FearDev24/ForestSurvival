extends Control
## Loja dos upgrades permanentes (FASE 13).
##
## Mostra o catálogo de `Permanentes`, quanto custa o próximo nível de cada um e
## quanto o jogador tem. Comprar desconta e grava na hora — não há "confirmar":
## a compra é de um item só, o preço está à vista e desfazer seria mais confuso
## que refazer.
##
## A tela é montada em código pela mesma razão do menu: as placas vêm do
## `PlacaUI`, e o catálogo pode crescer sem mexer na cena.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Mesma placa e mesmo tamanho do menu.
const TAMANHO_BOTAO := Vector2(560.0, 67.0)
const TAMANHO_VOLTAR := Vector2(400.0, 67.0)

@export var textura_placa: Texture2D
@export var textura_placa_destaque: Texture2D

## Procurados na primeira vez que fazem falta, e não em `@onready`: num script
## de teste a tela é criada dentro de `SceneTree._initialize()`, e `_ready` não
## dispara — a mesma armadilha do `HealthComponent` e do `Hud`.
var _itens: VBoxContainer = null
var _moedas: Label = null


func _ready() -> void:
	_montar()


func _montar() -> void:
	if _itens == null:
		_itens = get_node_or_null("Caixa/Itens") as VBoxContainer
		_moedas = get_node_or_null("Caixa/Moedas") as Label
	if _itens == null or _moedas == null:
		return

	for antigo in _itens.get_children():
		# Tira da árvore **agora**, e não só marca para apagar: `queue_free`
		# apaga no fim do quadro, e a loja se remonta no mesmo instante em que
		# uma compra acontece — as placas velhas responderiam ao clique seguinte.
		_itens.remove_child(antigo)
		antigo.queue_free()

	for linha in Permanentes.CATALOGO:
		var botao := PlacaUI.criar(_texto(linha), TAMANHO_BOTAO,
			textura_placa, textura_placa_destaque, 20)
		botao.disabled = not Permanentes.pode_comprar(linha["id"])
		botao.pressed.connect(_on_comprar.bind(linha["id"]))
		_itens.add_child(botao)

	var voltar := PlacaUI.criar("VOLTAR", TAMANHO_VOLTAR,
		textura_placa, textura_placa_destaque, 28)
	voltar.pressed.connect(_on_voltar)
	_itens.add_child(voltar)

	_moedas.text = "%d moedas" % int(SaveJogo.dados()["moedas"])


## Uma linha por item: nome, nível e o que falta para o próximo.
##
## No teto, o preço some e entra "máximo" — um preço riscado seria mais bonito e
## menos claro.
func _texto(linha: Dictionary) -> String:
	var nivel := SaveJogo.nivel_permanente(linha["id"])
	var teto := int(linha["niveis"])
	if nivel >= teto:
		return "%s   %d/%d   máximo" % [linha["nome"], nivel, teto]
	return "%s   %d/%d   %d moedas" % [linha["nome"], nivel, teto, Permanentes.preco(linha["id"])]


## Os botões, para o teste e para o foco por teclado.
func botoes() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in _itens.get_children():
		var botao := filho as Button
		if botao != null:
			lista.append(botao)
	return lista


func _unhandled_input(event: InputEvent) -> void:
	if PlacaUI.focar_no_teclado(event, botoes(), get_viewport()):
		get_viewport().set_input_as_handled()


func _on_comprar(id: StringName) -> void:
	if Permanentes.comprar(id):
		Audio.tocar(&"escolha")
	# Remonta sempre: mesmo numa compra recusada, os preços dos outros itens
	# podem ter deixado de caber na carteira.
	_montar()


func _on_voltar() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
