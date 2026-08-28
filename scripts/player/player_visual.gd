extends Node2D
## Camada visual do Player.
##
## Estado do asset: **CANDIDATE** (`docs/ASSET_WORKFLOW.md`, DEC-013).
## `assets/characters/druidwalkesquerda-walk-west.png` está no jogo apenas para
## avaliar leitura, escala e contraste. Não é asset aprovado e não deve servir
## de base para ajustes definitivos de offset, escala ou colisão.
##
## Este nó é o único ponto de troca de arte do Player. Quando o conjunto
## completo de direções for aprovado, o mais provável é trocar este `Sprite2D`
## por um `AnimatedSprite2D` com `SpriteFrames`. Nada em `player.gd` muda:
## o contrato continua sendo `set_facing()` e `set_moving()`.
##
## Contrato com o gameplay: a lógica informa **intenção** (direção encarada,
## se está andando); a representação é decidida aqui.

## Direção usada quando a direção pedida ainda não tem arte (regra 9 do
## `ASSET_WORKFLOW`: falta de direção permite fallback temporário).
const _FALLBACK_FACING := Player.Facing.SOUTH

## Direções que já possuem arte, mapeadas para a faixa de frames do sheet.
##
## Hoje só existe um sheet. O nome do arquivo diz "west", mas o desenho é de
## frente, então ele entra como SOUTH. Quando chegarem north/west/east, basta
## acrescentar entradas aqui.
const _FRAMES_BY_FACING := {
	Player.Facing.SOUTH: Vector2i(0, 120),
}

## Frames por segundo da caminhada.
@export var walk_fps: float = 18.0

## Frame exibido parado, relativo ao início da faixa da direção atual.
@export var idle_frame: int = 0

var _facing: Player.Facing = _FALLBACK_FACING
var _moving := false
var _elapsed := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_apply_frame()


func _process(delta: float) -> void:
	if not _moving:
		return
	_elapsed += delta
	_apply_frame()


## Recebe a direção encarada pelo jogador.
func set_facing(facing: Player.Facing) -> void:
	if facing == _facing:
		return
	_facing = facing
	_apply_frame()


## Recebe se o jogador está em movimento.
func set_moving(moving: bool) -> void:
	if moving == _moving:
		return
	_moving = moving
	if not _moving:
		_elapsed = 0.0
	_apply_frame()


## Faixa de frames da direção atual, caindo no fallback quando não há arte.
func _current_range() -> Vector2i:
	if _FRAMES_BY_FACING.has(_facing):
		return _FRAMES_BY_FACING[_facing]
	return _FRAMES_BY_FACING[_FALLBACK_FACING]


func _apply_frame() -> void:
	if _sprite == null:
		return

	var range_ := _current_range()
	var first := range_.x
	var count := maxi(range_.y, 1)

	if not _moving:
		_sprite.frame = first + clampi(idle_frame, 0, count - 1)
		return

	var step := int(_elapsed * walk_fps) % count
	_sprite.frame = first + step
