class_name PickupArea
extends Area2D
## Área que coleta o que estiver no chão (`docs/03_SYSTEMS.md` §11).
##
## Quem procura é esta área, não cada fragmento: o Player é um só e os
## fragmentos são muitos, então o custo fica com a minoria — mesmo princípio da
## DEC-017 para hitbox e hurtbox.
##
## O raio é o "alcance de coleta" que a FASE 6 vai querer aumentar por passiva
## (`Essência Viva`, `docs/04_CONTENT_PLAN.md`).

## Emitido a cada coleta, com o valor já lido do fragmento.
signal collected(value: float)

func _ready() -> void:
	area_entered.connect(_on_area_entered)


## Raio de coleta atual, em pixels.
##
## Busca a forma com `get_node`, não com `@onready`: assim funciona também numa
## cena recém-instanciada que ainda não entrou na árvore — que é como um teste
## olha a estrutura antes de rodar qualquer coisa.
func get_radius() -> float:
	var circulo := _get_circle()
	return circulo.radius if circulo != null else 0.0


## Muda o raio de coleta. A passiva de alcance da FASE 6 chama isto.
func set_radius(value: float) -> void:
	var circulo := _get_circle()
	if circulo != null:
		circulo.radius = maxf(1.0, value)


func _get_circle() -> CircleShape2D:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	return forma.shape as CircleShape2D if forma != null else null


func _on_area_entered(area: Area2D) -> void:
	# `collect()` é o contrato: qualquer coisa coletável responde a ele. Assim a
	# área não precisa saber que existe XP, moeda ou baú.
	if not area.has_method("collect"):
		return
	if "value" in area:
		collected.emit(area.value)
	area.call("collect")
