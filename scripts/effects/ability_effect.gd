class_name AbilityEffect
extends Node2D
## Efeito de habilidade de vida curta — raio, vinha, e o que vier.
##
## Toca a animação uma vez, liga a hitbox no frame em que o golpe encosta, e se
## libera no fim. Não persegue, não tem alvo e não guarda estado: quem decide
## onde e para onde é quem o criou.
##
## Substituiu o antigo `lightning_strike.gd`, que era o mesmo comportamento com
## nome de uma habilidade só. Duas habilidades depois, o nome já mentia.
##
## Provisório no mesmo sentido do resto: quando o `WeaponManager` existir
## (FASE 4, DEC-009), isto vira o "ataque" de uma arma de verdade, com dano
## vindo de `Resource` (DEC-010).

## Frame em que o golpe encosta. Antes disso é preparação — nuvem se formando,
## broto saindo da terra — e dar dano ali pareceria injusto.
@export var impact_frame: int = 4

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	# A hitbox só entra em cena no impacto.
	_hitbox.monitoring = false
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play(&"strike")


## Aponta o efeito para uma direção, mantendo o desenho de pé.
##
## A arte é desenhada apontando para a **direita**, então girar o nó pelo ângulo
## do alvo já resolve a direção — inclusive da hitbox, que gira junto.
##
## O que sobra é o desenho: apontando para a esquerda, girar 180° deixaria a
## rosa de cabeça para baixo. Aí o espelho vertical entra **na sprite**, não no
## nó. Espelhar o nó com `scale.y = -1` também endireitaria o desenho, mas
## inverteria a colisão junto e a Godot reclama de escala negativa em forma de
## colisão. Como a cápsula é simétrica no próprio eixo, espelhar só a arte não
## muda nada no golpe.
func aim(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	var angulo := direction.angle()
	rotation = angulo
	_sprite.flip_v = absf(angulo) > PI * 0.5


## Define o dano deste ataque.
##
## Chamado logo depois de instanciar, **antes** do nó entrar na árvore, então
## não dá para usar o `@onready`: `get_node` direto é o que funciona nos dois
## momentos. É por aqui que o nível da arma chega ao golpe, sem que a cena
## precise saber que existe arma ou nível.
func set_damage(value: float) -> void:
	var hitbox := get_node_or_null("Hitbox") as HitboxComponent
	if hitbox != null:
		hitbox.damage = value


func _on_frame_changed() -> void:
	if _hitbox.monitoring or _sprite.frame < impact_frame:
		return
	# `set_deferred` porque a troca pode cair dentro do processamento de sinais
	# de física, onde a Godot bloqueia mexer em monitoramento de área.
	_hitbox.set_deferred(&"monitoring", true)


func _on_animation_finished() -> void:
	queue_free()
