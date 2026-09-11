class_name AreaSegura
extends RefCounted
## Margens da área segura da tela: entalhe da câmera, cantos arredondados, barra
## de gestos (`docs/ROADMAP.md`, FASE 12).
##
## A Godot informa a área segura em pixels de **tela**, e a UI mora em unidades
## do **viewport** — 1280 x 720 esticado por `canvas_items` (DEC-015).
## `margens()` faz a conversão; `aplicar()` empurra um controle para dentro
## conforme a âncora de cada borda dele: a borda presa em cima desce, a presa
## embaixo sobe, a presa à esquerda anda para a direita. Borda ancorada no meio
## não muda — o meio da tela nunca cai no entalhe.
##
## **Só em aparelho móvel.** No Windows a área segura é a tela menos a barra de
## tarefas: aplicada no PC, ela empurraria o HUD sempre que a janela não
## estivesse em tela cheia. Fora do celular as margens são zero.

const _BASE := &"area_segura_base"


## Margens em unidades de viewport. Zero fora de aparelho móvel.
static func margens(viewport: Viewport) -> Dictionary:
	var zero := {"cima": 0.0, "baixo": 0.0, "esquerda": 0.0, "direita": 0.0}
	if viewport == null or not OS.has_feature("mobile"):
		return zero
	var tela := Vector2(DisplayServer.screen_get_size())
	var segura := Rect2(DisplayServer.get_display_safe_area())
	if tela.x <= 0.0 or tela.y <= 0.0 or segura.size.x <= 0.0 or segura.size.y <= 0.0:
		return zero
	var visivel := viewport.get_visible_rect().size
	var escala := Vector2(visivel.x / tela.x, visivel.y / tela.y)
	return {
		"cima": maxf(0.0, segura.position.y) * escala.y,
		"baixo": maxf(0.0, tela.y - segura.end.y) * escala.y,
		"esquerda": maxf(0.0, segura.position.x) * escala.x,
		"direita": maxf(0.0, tela.x - segura.end.x) * escala.x,
	}


## Reposiciona o controle dentro das margens.
##
## Parte sempre dos offsets originais, guardados na primeira chamada: aplicar
## de novo — numa rotação de tela, por exemplo — não acumula deslocamento.
static func aplicar(controle: Control, m: Dictionary) -> void:
	if controle == null:
		return
	if not controle.has_meta(_BASE):
		controle.set_meta(_BASE, [controle.offset_left, controle.offset_top,
			controle.offset_right, controle.offset_bottom])
	var base: Array = controle.get_meta(_BASE)
	var esquerda := float(m.get("esquerda", 0.0))
	var direita := float(m.get("direita", 0.0))
	var cima := float(m.get("cima", 0.0))
	var baixo := float(m.get("baixo", 0.0))
	controle.offset_left = float(base[0]) + _empurrao(controle.anchor_left, esquerda, direita)
	controle.offset_right = float(base[2]) + _empurrao(controle.anchor_right, esquerda, direita)
	controle.offset_top = float(base[1]) + _empurrao(controle.anchor_top, cima, baixo)
	controle.offset_bottom = float(base[3]) + _empurrao(controle.anchor_bottom, cima, baixo)


## Quanto uma borda anda: para dentro se está presa a uma borda da tela, nada
## se está ancorada no meio.
static func _empurrao(ancora: float, margem_inicio: float, margem_fim: float) -> float:
	if is_zero_approx(ancora):
		return margem_inicio
	if is_equal_approx(ancora, 1.0):
		return -margem_fim
	return 0.0
