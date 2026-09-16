extends Control
## Menu principal: a porta de entrada da partida, e para onde ela volta
## (`docs/03_SYSTEMS.md` §16, "permitir voltar ao menu").
##
## É a cena principal do projeto. JOGAR carrega a partida; SAIR fecha o jogo.
## De dentro da partida, o botão MENU da pausa e da tela de resultado traz o
## jogador de volta para cá.
##
## Não mexe em `get_tree().paused`. Quem pausa e despausa é só o
## `GameManager` — dois lugares mexendo nisso foi o que a FASE 9 veio
## desfazer —, e ele despausa antes de trocar de cena para cá.
##
## Arte: o nome do jogo e o fundo são vagas (`TituloArte`, `FundoArte`).
## Enquanto a textura for nula, o rótulo escrito e a cor de fundo assumem, e a
## tela funciona inteira (DEC-013).

const GAME_SCENE := "res://scenes/game/game.tscn"

## Mesma placa e mesmo tamanho da pausa: 5,97:1, a proporção da arte.
const TAMANHO_BOTAO := Vector2(400.0, 67.0)

@export var textura_placa: Texture2D
@export var textura_placa_destaque: Texture2D

@onready var _opcoes: VBoxContainer = $Caixa/Opcoes
@onready var _titulo: Label = $Caixa/Titulo
@onready var _titulo_arte: TextureRect = $Caixa/TituloArte


func _ready() -> void:
	# Teste automático no celular (`BotMobile`): só numa build de depuração
	# aberta com `--bot`, que é o APK "Android Bot". O jogo normal nunca entra
	# aqui. Adiado porque a raiz ainda está montando os filhos neste momento.
	if BotMobile.pedido():
		get_tree().root.add_child.call_deferred(BotMobile.new())
		return
	var com_arte := _titulo_arte.texture != null
	_titulo_arte.visible = com_arte
	_titulo.visible = not com_arte
	_montar()


func _montar() -> void:
	for antigo in _opcoes.get_children():
		antigo.queue_free()
	for texto in ["JOGAR", "SAIR"]:
		var botao := PlacaUI.criar(texto, TAMANHO_BOTAO, textura_placa, textura_placa_destaque, 28)
		botao.pressed.connect(_on_escolha.bind(texto))
		_opcoes.add_child(botao)


func botoes() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in _opcoes.get_children():
		var botao := filho as Button
		if botao != null:
			lista.append(botao)
	return lista


## Nada nasce aceso: o foco só entra quando o jogador usa o teclado.
func _unhandled_input(event: InputEvent) -> void:
	if PlacaUI.focar_no_teclado(event, botoes(), get_viewport()):
		get_viewport().set_input_as_handled()


func _on_escolha(texto: String) -> void:
	match texto:
		"JOGAR":
			get_tree().change_scene_to_file(GAME_SCENE)
		"SAIR":
			get_tree().quit()
