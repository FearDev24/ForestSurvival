class_name HurtboxComponent
extends Area2D
## Área que **recebe** dano (`docs/03_SYSTEMS.md` §4).
##
## Fluxo: `HitboxComponent` -> `HurtboxComponent` -> `HealthComponent` -> morte.
##
## A hurtbox não procura ninguém e não roda lógica por frame: ela apenas existe
## para ser encontrada. Quem detecta é a hitbox. Em uma horda, isso significa
## que o custo fica no atacante, não em cada um dos inimigos.
##
## Por isso `monitoring` é `false` e `monitorable` é `true` nas cenas: ela é
## detectável, mas não detecta.

## Emitido quando a hurtbox recebe dano, antes do `HealthComponent` processar.
## Útil para feedback visual (piscar, número de dano) sem acoplar a arte à vida.
signal hit(amount: float, source: Node)

## Vida que este corpo alimenta. Sem ela a hurtbox continua funcionando e
## emitindo `hit`, apenas não tira vida de ninguém.
@export var health: HealthComponent


## Chamado pela hitbox. Único ponto de entrada de dano da entidade.
func take_damage(amount: float, source: Node = null) -> void:
	if amount <= 0.0:
		return
	if health != null and health.is_dead():
		return

	hit.emit(amount, source)

	if health != null:
		health.damage(amount)


## Uma entidade morta não deve continuar levando golpes nem disparando efeitos.
## Desligar `monitorable` a tira do radar das hitboxes sem removê-la da cena.
func set_vulnerable(vulnerable: bool) -> void:
	monitorable = vulnerable
