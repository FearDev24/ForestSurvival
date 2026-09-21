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

## Texto do botão do anúncio premiado. Diz que é anúncio de propósito: a
## política da AdMob exige que o jogador saiba o que vai ver antes de tocar.
const TEXTO_DOBRAR := "DOBRAR (ANÚNCIO)"

var _manager: GameManager = null
## O ganho desta partida, que o anúncio premiado repete uma vez.
var _ganho := 0
var _dobrou := false

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
		# Sai da árvore na hora: a tela se remonta quando o anúncio acaba de
		# carregar, e placa velha ainda na árvore responderia ao toque (ver loja).
		_opcoes.remove_child(antigo)
		antigo.queue_free()
	var textos := ["REINICIAR", "MENU"]
	if _oferecer_anuncio():
		textos.push_front(TEXTO_DOBRAR)
	for texto in textos:
		var botao := PlacaUI.criar(texto, TAMANHO_BOTAO, textura_placa, textura_placa_destaque,
			20 if texto == TEXTO_DOBRAR else 24)
		botao.pressed.connect(_on_escolha.bind(texto))
		_opcoes.add_child(botao)


## O botão do anúncio só aparece se há o que dobrar, se ainda não dobrou e se o
## anúncio já está carregado — botão que toca e não mostra nada é pior que
## botão nenhum.
func _oferecer_anuncio() -> bool:
	return _ganho > 0 and not _dobrou and Anuncios.premiado_pronto()


func _tem_botao_anuncio() -> bool:
	for botao in botoes():
		if botao.text == TEXTO_DOBRAR:
			return true
	return false


## O anúncio pode terminar de carregar com a tela já aberta. Aí o botão entra
## sem o jogador precisar fazer nada.
func _process(_delta: float) -> void:
	if visible and _oferecer_anuncio() != _tem_botao_anuncio():
		_montar()


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
	_ganho = int(r["total"])
	_dobrou = false
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
	_montar()

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
	if texto == TEXTO_DOBRAR:
		Anuncios.mostrar_premiado(_premio_assistido)
	elif texto == "REINICIAR":
		_manager.reiniciar()
	else:
		_manager.voltar_ao_menu()


## O jogador assistiu até o fim: o ganho da partida entra de novo.
func _premio_assistido() -> void:
	if _dobrou:
		return
	_dobrou = true
	SaveJogo.somar_moedas(_ganho)
	_moedas.text = "+%d moedas     dobrado pelo anúncio" % (_ganho * 2)
	_montar()
