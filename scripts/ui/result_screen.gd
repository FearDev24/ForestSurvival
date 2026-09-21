extends CanvasLayer
## Tela de fim de partida, de vitória e de derrota (`docs/03_SYSTEMS.md` §16, §17).
##
## É a mesma tela para os dois desfechos: o que muda é o título e a cor dele. A
## §16 e a §17 pedem as mesmas informações — tempo, level, reiniciar, menu — e
## duas cenas quase iguais divergiriam na primeira mexida.
##
## Substitui a imagem de game over solta no mundo, que marcava o ponto da morte
## mas não dizia nada sobre a partida.

## Menor que o do menu de pausa: aqui a palavra de fim ocupa a parte de cima
## do painel, e botao grande empurrava tudo para fora do interior dele.
## A proporcao e a da placa desenhada, 5,97:1 -- esticar deformaria as pedras.
const TAMANHO_BOTAO := Vector2(330.0, 55.0)

@export var textura_placa: Texture2D
@export var textura_placa_destaque: Texture2D

## A palavra desenhada de cada desfecho. Podem ser nulas: aí o rótulo escrito
## assume e a tela continua inteira (DEC-013).
@export var titulo_derrota: Texture2D
@export var titulo_vitoria: Texture2D

var _manager: GameManager = null

@onready var _titulo: Label = $Caixa/Titulo
@onready var _titulo_arte: TextureRect = $Caixa/TituloArte
@onready var _tempo: Label = $Caixa/Tempo
@onready var _nivel: Label = $Caixa/Nivel
@onready var _moedas: Label = $Caixa/Moedas
@onready var _em_breve: Label = $Caixa/EmBreve
@onready var _opcoes: VBoxContainer = $Caixa/Opcoes


func configure(manager: GameManager) -> void:
	_manager = manager
	if manager != null and not manager.ended.is_connected(_on_ended):
		manager.ended.connect(_on_ended)
	_montar()
	visible = false


func _montar() -> void:
	for antigo in _opcoes.get_children():
		antigo.queue_free()
	for texto in ["REINICIAR", "MENU"]:
		var botao := PlacaUI.criar(texto, TAMANHO_BOTAO, textura_placa, textura_placa_destaque)
		botao.pressed.connect(_on_escolha.bind(texto))
		_opcoes.add_child(botao)


func botoes() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in _opcoes.get_children():
		var botao := filho as Button
		if botao != null:
			lista.append(botao)
	return lista


## Formata o relógio igual ao do HUD, para o jogador reconhecer o número.
## O ganho da partida, com as parcelas à vista.
##
## Discriminado de propósito: "+90 moedas" não diz ao jogador o que o jogo
## premia, e é justamente isso que decide como ele joga a próxima partida.
func _mostrar_moedas(vitoria: bool, tempo: float) -> void:
	var abates := _manager.get_abates() if _manager != null else 0
	var r := SaveJogo.recompensa(abates, tempo, vitoria)
	var partes := ["%d abates  +%d" % [abates, r["abates"]],
		"%s  +%d" % [_relogio(tempo), r["tempo"]]]
	if vitoria:
		partes.append("vitoria  +%d" % r["vitoria"])
	_moedas.text = "+%d moedas     %s" % [r["total"], "   ".join(partes)]


func _relogio(segundos: float) -> String:
	var total := int(maxf(0.0, segundos))
	if segundos >= 3600.0:
		return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
	return "%02d:%02d" % [total / 60, total % 60]


func _on_ended(vitoria: bool, tempo: float, nivel: int) -> void:
	# O rótulo é preenchido sempre, mesmo escondido: é ele que responde se a
	# arte faltar, e um rótulo em branco por baixo seria uma falha silenciosa.
	_titulo.text = "A FLORESTA RESISTIU" if vitoria else "A FLORESTA CAIU"
	_titulo.add_theme_color_override("font_color",
		Color(0.65, 1.0, 0.6) if vitoria else Color(1.0, 0.55, 0.5))

	var arte: Texture2D = titulo_vitoria if vitoria else titulo_derrota
	_titulo_arte.texture = arte
	_titulo_arte.visible = arte != null
	_titulo.visible = arte == null
	_tempo.text = "Tempo   %s" % _relogio(tempo)
	_nivel.text = "Nivel   %d" % nivel
	_mostrar_moedas(vitoria, tempo)
	# O Guardião é o último chefe desta versão. Na vitória o jogador acabou de
	# ver o fim do jogo; é a hora de dizer que ele não acaba aqui.
	_em_breve.visible = vitoria

	var viewport := get_viewport()
	if viewport != null and viewport.gui_get_focus_owner() != null:
		viewport.gui_release_focus()
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if PlacaUI.focar_no_teclado(event, botoes(), get_viewport()):
		get_viewport().set_input_as_handled()


func _on_escolha(texto: String) -> void:
	if _manager == null:
		return
	if texto == "REINICIAR":
		_manager.reiniciar()
	else:
		_manager.voltar_ao_menu()
