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
const LOJA_SCENE := "res://scenes/ui/loja.tscn"

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
	for texto in ["JOGAR", "MELHORIAS", "SAIR"]:
		var botao := PlacaUI.criar(texto, TAMANHO_BOTAO, textura_placa, textura_placa_destaque, 28)
		botao.pressed.connect(_on_escolha.bind(texto))
		_opcoes.add_child(botao)
	_montar_recorde()


## Linha do recorde, embaixo das placas. Só aparece depois da primeira partida:
## num jogo recém-instalado, "0 partidas" não informa nada.
func _montar_recorde() -> void:
	var save := SaveJogo.dados()
	if int(save["partidas"]) <= 0:
		return
	var rotulo := Label.new()
	rotulo.text = "%s  ·  %d partida%s  ·  %d vitória%s" % [
		_tempo(float(save["melhor_tempo"])),
		int(save["partidas"]), "" if int(save["partidas"]) == 1 else "s",
		int(save["vitorias"]), "" if int(save["vitorias"]) == 1 else "s"]
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", 22)
	rotulo.add_theme_color_override("font_color", Color(0.87, 0.96, 0.82))
	rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo.add_theme_constant_override("outline_size", 6)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opcoes.add_child(rotulo)


func _tempo(segundos: float) -> String:
	return "melhor tempo %02d:%02d" % [int(segundos) / 60, int(segundos) % 60]


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
		"MELHORIAS":
			get_tree().change_scene_to_file(LOJA_SCENE)
		"SAIR":
			get_tree().quit()
