class_name OrbeProjetil
extends ProjectileEffect
## O Orbe do Cajado: o ataque com que o druida começa a partida (DEC-025).
##
## Um orbe de energia verde disparado do cajado no inimigo mais próximo. É
## redondo, e por isso pode mirar em qualquer direção — o caso que a DEC-022
## deixou reservado para "arte desenhada para girar". Viaja e acerta como o
## corvo: é da mesma família (`ProjectileEffect`), só troca o desenho.
##
## Visual: PLACEHOLDER desenhado em código (DEC-013). A colisão tem o raio do
## que é desenhado (`raio_desenho`), e `tests/test_progressao.gd` confere que os
## dois continuam casando — a mesma regra das outras habilidades.

## Raio do núcleo desenhado. O brilho em volta é fraco e não conta para acerto.
@export var raio_desenho := 9.0
@export var cor := Color(0.55, 1.0, 0.55, 1.0)
@export var cor_brilho := Color(0.75, 1.0, 0.7, 0.3)


func _draw() -> void:
	draw_circle(Vector2.ZERO, raio_desenho * 1.8, cor_brilho)
	draw_circle(Vector2.ZERO, raio_desenho, cor)
