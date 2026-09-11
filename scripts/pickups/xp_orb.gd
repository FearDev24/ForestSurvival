class_name XpOrb
extends Area2D
## Fragmento de experiência largado por um inimigo morto
## (`docs/03_SYSTEMS.md` §11).
##
## Fica parado no mundo esperando ser coletado. Não procura ninguém e não roda
## lógica por frame: quem detecta é a área de coleta do Player, que é uma só
## (mesmo princípio da DEC-017 — o custo fica em quem é minoria).
##
## Visual **PLACEHOLDER**: um losango desenhado em código. Não é arte
## (DEC-013); trocar por sprite não muda nada aqui.

## Emitido quando alguém coleta. O orbe se libera logo depois.
signal collected(value: float)

## Quanto de XP este fragmento vale.
@export var value: float = 1.0

const _COR := Color(0.35, 0.85, 0.45)
const _COR_BORDA := Color(0.75, 1.0, 0.8)
const _RAIO := 7.0


func _draw() -> void:
	# Losango: lê como gema mesmo em 14 px, e não depende de arte para existir.
	var pontos := PackedVector2Array([
		Vector2(0.0, -_RAIO),
		Vector2(_RAIO * 0.7, 0.0),
		Vector2(0.0, _RAIO),
		Vector2(-_RAIO * 0.7, 0.0),
	])
	# Uma textura só para todos os fragmentos, e não polígono mais contorno por
	# fragmento: a Godot agrupa numa chamada de desenho tudo que usa a mesma
	# textura, e 300 fragmentos no chão passaram de 331 chamadas extras para
	# nenhuma (FASE 10, docs/HANDOFF.md). O losango de `pontos` continua sendo
	# a referência da forma: é ele que `textura_compartilhada()` pinta.
	var gema := textura_compartilhada()
	draw_texture(gema, -gema.get_size() * 0.5)


## Chamado pela área de coleta do Player.
func collect() -> void:
	collected.emit(value)
	queue_free()


## A gema de todos os fragmentos, pintada uma vez na primeira vez que faz falta.
##
## É estática de propósito: uma textura por instância quebraria o agrupamento
## de novo — cada fragmento viraria uma chamada de desenho própria, que é o que
## a FASE 10 mediu e tirou. `tests/test_phase10.gd` confere que é a mesma.
static var _textura: Texture2D = null


static func textura_compartilhada() -> Texture2D:
	if _textura != null:
		return _textura
	var lado := 15
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := (lado - 1) / 2.0
	for y in lado:
		for x in lado:
			# Mesmo losango do `_draw` antigo: 0,7 do raio na horizontal.
			var d := absf(x - centro) / (_RAIO * 0.7) + absf(y - centro) / _RAIO
			if d <= 1.0:
				img.set_pixel(x, y, _COR_BORDA if d > 0.78 else _COR)
	_textura = ImageTexture.create_from_image(img)
	return _textura
