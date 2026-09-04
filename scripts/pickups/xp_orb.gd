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
	draw_colored_polygon(pontos, _COR)
	draw_polyline(pontos + PackedVector2Array([pontos[0]]), _COR_BORDA, 1.0)


## Chamado pela área de coleta do Player.
func collect() -> void:
	collected.emit(value)
	queue_free()
