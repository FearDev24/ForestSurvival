extends Node2D
## Camada visual do Player — conteúdo PLACEHOLDER.
##
## Ver `docs/ASSET_WORKFLOW.md` e DEC-013.
##
## Este nó é o único ponto de troca de arte do Player. Quando a sprite oficial
## do druida for aprovada, ela substitui os filhos deste nó (e, se necessário,
## este script). Nada em `player.gd` precisa mudar.
##
## Contrato com o gameplay: recebe `set_facing()` quando a direção muda. A
## lógica informa a intenção; a representação é decidida aqui.

## Distância do marcador de direção ao centro do corpo, em pixels.
## Só faz sentido para o placeholder; a sprite final não usará marcador.
const _MARKER_DISTANCE := 20.0

@onready var _marker: Polygon2D = $PlaceholderFacingMarker


## Recebe a direção encarada pelo jogador.
##
## Placeholder: reposiciona e gira um marcador triangular. Quando existirem
## sprites direcionais, esta função passará a trocar a textura/animação.
func set_facing(facing: Player.Facing) -> void:
	if _marker == null:
		return

	var offset := Vector2.ZERO
	var angle := 0.0

	match facing:
		Player.Facing.SOUTH:
			offset = Vector2(0.0, _MARKER_DISTANCE)
			angle = PI
		Player.Facing.NORTH:
			offset = Vector2(0.0, -_MARKER_DISTANCE)
			angle = 0.0
		Player.Facing.WEST:
			offset = Vector2(-_MARKER_DISTANCE, 0.0)
			angle = -PI * 0.5
		Player.Facing.EAST:
			offset = Vector2(_MARKER_DISTANCE, 0.0)
			angle = PI * 0.5

	_marker.position = offset
	_marker.rotation = angle
