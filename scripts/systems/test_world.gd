class_name TestWorld
extends Node2D
## Área de protótipo — PLACEHOLDER (`docs/ASSET_WORKFLOW.md`, DEC-013).
##
## Não é o mapa do jogo. Serve apenas para perceber o movimento do Player e o
## acompanhamento da câmera durante a FASE 1. Não usa TileSet, não usa assets
## e não define a direção de arte da floresta.
##
## O mapa definitivo do survivor-like poderá ser muito maior, rolar
## infinitamente ou funcionar de outra forma; nada aqui é arquitetura final.
##
## `world_size` é a única fonte de verdade das dimensões: o chão desenhado, as
## paredes de colisão e os limites da câmera derivam todos deste valor.

## Camada de física da geometria estática do mundo. Ver DEC-016.
const WORLD_STATIC_LAYER := 8

const _GROUND_COLOR := Color(0.129, 0.196, 0.153)
const _GRID_COLOR := Color(0.196, 0.290, 0.227)
const _BORDER_COLOR := Color(0.349, 0.451, 0.302)

## Dimensões da área jogável, centrada na origem deste nó.
@export var world_size: Vector2 = Vector2(3072.0, 3072.0)

## Espaçamento do grid de referência visual.
@export var grid_step: float = 256.0

## Espessura das paredes de colisão da borda.
@export var wall_thickness: float = 64.0


func _ready() -> void:
	_build_walls()


## Retângulo jogável em coordenadas locais deste nó.
func get_bounds() -> Rect2:
	return Rect2(-world_size * 0.5, world_size)


func _draw() -> void:
	var bounds := get_bounds()

	draw_rect(bounds, _GROUND_COLOR, true)

	# O grid existe só para tornar o deslocamento perceptível sem arte.
	var x := bounds.position.x
	while x <= bounds.end.x:
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), _GRID_COLOR, 2.0)
		x += grid_step

	var y := bounds.position.y
	while y <= bounds.end.y:
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), _GRID_COLOR, 2.0)
		y += grid_step

	draw_rect(bounds, _BORDER_COLOR, false, 6.0)


## Cria as quatro paredes de borda a partir de `world_size`.
##
## Construídas em código de propósito: assim as dimensões não ficam duplicadas
## entre a cena, o desenho do chão e os limites da câmera.
func _build_walls() -> void:
	var bounds := get_bounds()
	var center := bounds.get_center()
	var half := wall_thickness * 0.5
	var horizontal := Vector2(world_size.x + wall_thickness * 2.0, wall_thickness)
	var vertical := Vector2(wall_thickness, world_size.y + wall_thickness * 2.0)

	_add_wall("WallTop", Vector2(center.x, bounds.position.y - half), horizontal)
	_add_wall("WallBottom", Vector2(center.x, bounds.end.y + half), horizontal)
	_add_wall("WallLeft", Vector2(bounds.position.x - half, center.y), vertical)
	_add_wall("WallRight", Vector2(bounds.end.x + half, center.y), vertical)


func _add_wall(wall_name: String, at: Vector2, size: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size

	var collision := CollisionShape2D.new()
	collision.shape = rectangle

	var body := StaticBody2D.new()
	body.name = wall_name
	body.position = at
	body.collision_layer = 1 << (WORLD_STATIC_LAYER - 1)
	# Parede não precisa detectar nada; quem detecta é o corpo que se move.
	body.collision_mask = 0
	body.add_child(collision)

	add_child(body)
