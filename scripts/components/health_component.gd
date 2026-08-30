class_name HealthComponent
extends Node
## Vida de uma entidade (`docs/03_SYSTEMS.md` §3).
##
## Componente puro: não conhece Player, Enemy, arte, colisão nem física. Quem
## quiser reagir à morte conecta `died`.
##
## A morte acontece **uma única vez**: depois que `current_health` chega a zero,
## `damage()` e `heal()` param de ter efeito e `died` não é reemitido. Isso é o
## que impede um inimigo atingido por dois ataques no mesmo frame de morrer duas
## vezes, dar XP em dobro ou chamar `queue_free()` duas vezes.

## Emitido sempre que a vida muda, inclusive na cura.
signal health_changed(current: float, maximum: float)

## Emitido a cada dano efetivamente aplicado, antes de `died`.
signal damaged(amount: float)

## Emitido no exato momento em que a vida chega a zero. Nunca mais de uma vez.
signal died

@export var max_health: float = 30.0:
	set(value):
		max_health = maxf(1.0, value)
		if _started:
			current_health = minf(current_health, max_health)

var current_health: float = 0.0

var _is_dead := false
## A vida só pode ser preenchida depois que `max_health` chegou — e `max_health`
## chega de formas diferentes: da cena, de um `@export` no editor, ou de uma
## atribuição logo após `new()`. Por isso a inicialização é preguiçosa em vez de
## presumir que `_ready()` roda antes de qualquer uso.
var _started := false


func _ready() -> void:
	_start()


## Preenche a vida na primeira vez que o componente é usado ou entra na árvore.
func _start() -> void:
	if _started:
		return
	_started = true
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Aplica dano. Valores nulos ou negativos são ignorados.
func damage(amount: float) -> void:
	_start()
	if _is_dead or amount <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		_is_dead = true
		died.emit()


## Cura, limitada a `max_health`. Não ressuscita: quem morreu continua morto.
func heal(amount: float) -> void:
	_start()
	if _is_dead or amount <= 0.0:
		return

	var healed := minf(max_health, current_health + amount)
	if is_equal_approx(healed, current_health):
		return

	current_health = healed
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return _is_dead


## Fração de vida, de 0 a 1. Serve para barra de HP na FASE 9.
func get_ratio() -> float:
	_start()
	return current_health / max_health
