class_name ZoneEffect
extends Node2D
## Ataque que **fica** (`docs/ROADMAP.md`, FASE 7).
##
## Terceira família de arma. O golpe acontece e some, o projétil viaja e some;
## esta cai no chão e machuca tudo que passar por cima enquanto durar.
##
## O dano repetido não é código daqui: o `HitboxComponent` já sabe bater a cada
## `hit_interval` enquanto o alvo continua dentro (`docs/03_SYSTEMS.md` §4). A
## zona só precisa existir por um tempo e sumir — por isso este script é curto.
##
## O visual é PLACEHOLDER desenhado em código (DEC-013): um círculo de esporos
## que pulsa e some no fim. Trocar por arte não deve exigir mudança aqui.

## Emitido quando a zona acaba.
signal expired

## Segundos que a zona dura.
@export var duration: float = 3.0

## Raio do desenho. A colisão é separada, e é ela que manda no golpe (DEC-013).
@export var visual_radius: float = 64.0

@export var fill_color: Color = Color(0.35, 0.75, 0.35, 0.22)
@export var edge_color: Color = Color(0.65, 1.0, 0.6, 0.55)

var _vivo := 0.0


func _physics_process(delta: float) -> void:
	_vivo += delta
	if _vivo >= duration:
		set_physics_process(false)
		expired.emit()
		queue_free()
		return
	# Só redesenha porque o placeholder pulsa. Com arte no lugar, não redesenha.
	if get_node_or_null("Sprite") == null:
		queue_redraw()


func _draw() -> void:
	# Com arte no lugar, o círculo em código sai de cena (DEC-013).
	if get_node_or_null("Sprite") != null:
		return
	var restante := 1.0 - clampf(_vivo / maxf(0.01, duration), 0.0, 1.0)
	# Pulso lento, e desvanece no fim para a zona não sumir de estalo.
	var pulso := 0.92 + 0.08 * sin(_vivo * 6.0)
	var raio := visual_radius * pulso

	var dentro := fill_color
	dentro.a *= restante
	draw_circle(Vector2.ZERO, raio, dentro)

	var borda := edge_color
	borda.a *= restante
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, borda, 3.0, true)


## Chamado logo depois de instanciar, **antes** de o nó entrar na árvore — por
## isso `get_node_or_null` e não `@onready`, como nos outros efeitos.
func set_damage(value: float) -> void:
	var hitbox := get_node_or_null("Hitbox") as HitboxComponent
	if hitbox != null:
		hitbox.damage = value


func set_duration(value: float) -> void:
	if value > 0.0:
		duration = value
