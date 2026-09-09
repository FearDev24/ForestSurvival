class_name PlacaUI
extends RefCounted
## Botão vestido com a placa desenhada, para as telas que pausam a partida.
##
## Existe porque três telas — level up, pausa e resultado — precisam do mesmo
## botão, e a terceira cópia do mesmo código seria a hora em que uma delas
## começaria a divergir das outras sem ninguém notar.
##
## O que está aqui é só apresentação: quem monta a tela decide o texto, o
## tamanho e o que o clique faz.

## Só `hover` e `pressed` acendem a placa. O foco **não** — a Godot desenha o
## estilo de foco por cima do estado, e uma placa acesa ali deixaria o primeiro
## botão parecendo escolhido antes de o jogador tocar em nada.
const _ACESOS := ["hover", "pressed"]
const _ESTADOS := ["normal", "hover", "pressed", "focus", "disabled"]


## Troca o visual padrão do botão pela placa.
##
## `destaque` pode ser nulo: aí todos os estados usam a placa apagada, e o botão
## continua funcionando — só não acende.
static func vestir(botao: Button, normal: Texture2D, destaque: Texture2D) -> void:
	if normal == null:
		return
	for estado in _ESTADOS:
		var caixa := StyleBoxTexture.new()
		var aceso: bool = estado in _ACESOS and destaque != null
		caixa.texture = destaque if aceso else normal
		botao.add_theme_stylebox_override(estado, caixa)


## Um botão pronto: placa, texto centrado e tamanho fixo.
##
## O tamanho é fixo porque a proporção da placa é 5,97:1 — deixar o container
## esticá-la até a largura toda deformaria as pedras das pontas.
static func criar(texto: String, tamanho: Vector2, normal: Texture2D,
		destaque: Texture2D, fonte: int = 24) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = tamanho
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.focus_mode = Control.FOCUS_ALL
	botao.text = texto
	botao.add_theme_font_size_override("font_size", fonte)
	botao.add_theme_color_override("font_color", Color(0.93, 0.98, 0.88))
	botao.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	botao.add_theme_color_override("font_focus_color", Color(0.93, 0.98, 0.88))
	botao.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	botao.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	botao.add_theme_constant_override("outline_size", 6)
	vestir(botao, normal, destaque)
	return botao


## Dá o foco ao primeiro botão só quando o jogador usa o teclado.
##
## Focar ao abrir faria o primeiro botão parecer escolhido antes de qualquer
## toque. Esta função é chamada de `_unhandled_input` e devolve `true` quando
## consumiu a tecla — que serve para entrar na lista, não para escolher às cegas.
static func focar_no_teclado(evento: InputEvent, botoes: Array[Button],
		viewport: Viewport) -> bool:
	if botoes.is_empty() or viewport == null or viewport.gui_get_focus_owner() != null:
		return false
	for acao in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept"]:
		if evento.is_action_pressed(acao):
			botoes[0].grab_focus()
			return true
	return false
