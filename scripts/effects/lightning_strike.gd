class_name LightningStrike
extends Node2D
## Raio — primeira habilidade, em teste.
##
## Efeito de vida curta: toca a animação uma vez, causa dano no momento do
## impacto e some. Não persegue, não tem alvo e não guarda estado; quem escolhe
## onde cair é quem o criou.
##
## A origem do nó é o **ponto de impacto**, no chão. A sprite é deslocada para
## cima para que a explosão da base fique na origem.
##
## Provisório: quando o `WeaponManager` existir (FASE 4, DEC-009), este nó vira
## o "ataque" de uma arma de verdade, com dano vindo de `Resource` (DEC-010).

## Frame em que o raio encosta no chão. Antes disso é só nuvem se formando, e
## dar dano ali pareceria injusto.
@export var impact_frame: int = 4

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	# A hitbox só entra em cena no impacto.
	_hitbox.monitoring = false
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play(&"strike")


func _on_frame_changed() -> void:
	if _hitbox.monitoring or _sprite.frame < impact_frame:
		return
	# `set_deferred` porque a troca pode cair dentro do processamento de sinais
	# de física, onde a Godot bloqueia mexer em monitoramento de área.
	_hitbox.set_deferred(&"monitoring", true)


func _on_animation_finished() -> void:
	queue_free()
