class_name ProjectileEffect
extends Node2D
## Ataque que **viaja** (`docs/ROADMAP.md`, FASE 7).
##
## Segunda família de arma. A primeira, `AbilityEffect`, acontece num lugar e
## some quando a animação acaba; esta anda em linha reta até acertar o que tinha
## de acertar ou até o tempo dela esgotar.
##
## A diferença que justifica outro script — e não mais um campo no
## `AbilityEffect` — é o fim de vida: um golpe morre pela animação, um projétil
## morre por distância percorrida ou por alvos atravessados. Empilhar as duas
## regras num nó só faria cada uma carregar a condição da outra.
##
## Contrato com a arma: `set_damage()`, `aim()`, `set_speed()`, `set_lifetime()`
## e `set_pierce()`. Nenhum é obrigatório — a arma só chama o que o nó tiver.

## Emitido quando o projétil some, por qualquer motivo.
signal expired

## Pixels por segundo.
@export var speed: float = 420.0

## Segundos de voo antes de sumir sozinho. É o que impede um projétil que não
## acerta ninguém de viajar para sempre e continuar custando física.
@export var lifetime: float = 2.0

## Quantos inimigos atravessa antes de sumir. 1 é o comum: acerta e some.
@export var pierce: int = 1

var _direcao := Vector2.RIGHT
var _restantes := 1
var _vivo := 0.0


func _ready() -> void:
	_restantes = maxi(1, pierce)
	var hitbox := get_node_or_null("Hitbox") as HitboxComponent
	if hitbox != null:
		hitbox.hit_landed.connect(_on_hit_landed)
	var sprite := get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite != null:
		sprite.play(&"fly")


func _physics_process(delta: float) -> void:
	_vivo += delta
	if _vivo >= lifetime:
		_sumir()
		return
	global_position += _direcao * speed * delta


## Aponta o voo. A arte é desenhada apontando para a **direita**, então girar o
## nó já resolve direção e hitbox de uma vez; o espelho vertical fica na sprite,
## para o corvo não voar de cabeça para baixo indo para a esquerda.
##
## Mesmo raciocínio de `AbilityEffect.aim()`, e pela mesma razão: espelhar o nó
## inverteria a forma de colisão junto, e a Godot recusa escala negativa em
## forma de colisão.
func aim(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	_direcao = direction.normalized()
	var angulo := _direcao.angle()
	rotation = angulo
	var sprite := get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_v = absf(angulo) > PI * 0.5


## Chamado logo depois de instanciar, **antes** de o nó entrar na árvore, então
## `@onready` não serve — mesma razão do `AbilityEffect`.
func set_damage(value: float) -> void:
	var hitbox := get_node_or_null("Hitbox") as HitboxComponent
	if hitbox != null:
		hitbox.damage = value


func set_speed(value: float) -> void:
	speed = maxf(1.0, value)


func set_lifetime(value: float) -> void:
	if value > 0.0:
		lifetime = value


func set_pierce(value: int) -> void:
	pierce = maxi(1, value)
	_restantes = pierce


## Cada inimigo atravessado gasta uma perfuração. Quando acabam, o projétil some.
func _on_hit_landed(_hurtbox: HurtboxComponent, _amount: float) -> void:
	_restantes -= 1
	if _restantes <= 0:
		_sumir()


func _sumir() -> void:
	set_physics_process(false)
	expired.emit()
	queue_free()
