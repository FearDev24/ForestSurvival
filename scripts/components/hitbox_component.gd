class_name HitboxComponent
extends Area2D
## Área que **causa** dano (`docs/03_SYSTEMS.md` §4).
##
## Fluxo: `HitboxComponent` -> `HurtboxComponent` -> `HealthComponent` -> morte.
##
## Este é o lado ativo do combate: a hitbox detecta hurtboxes, a hurtbox não
## detecta nada. `monitoring` é `true` e `monitorable` é `false` nas cenas.
##
## ## Custo por frame
##
## O `_physics_process` fica **desligado** enquanto não há nada sobreposto, e
## volta a desligar quando o último alvo sai. Um diabrete perseguindo o jogador
## do outro lado do mapa não gasta nada; só os que estão encostando pagam o
## custo. Isso importa porque a meta é centenas de inimigos em tela (DEC-011).
##
## Também não existe `Timer` por hitbox: o intervalo é contado por delta
## acumulado. Centenas de nós `Timer` seriam pior que centenas de somas
## (`docs/02_ARCHITECTURE.md`, "Evitar").

## Emitido a cada golpe efetivamente aplicado.
signal hit_landed(hurtbox: HurtboxComponent, amount: float)

## Dano por golpe.
@export var damage: float = 10.0

## Segundos entre golpes enquanto o alvo continua encostado.
##
## É o que separa "dano por contato" de "dano por frame": sem isso, encostar em
## um inimigo a 60 FPS tiraria 60 vezes o dano por segundo.
@export var hit_interval: float = 1.0

## Se o alvo leva dano no instante em que entra na área. Com `false`, o primeiro
## golpe só sai depois de `hit_interval`.
@export var hit_on_enter: bool = true

var _overlapping: Array[HurtboxComponent] = []
var _cooldown := 0.0


func _ready() -> void:
	set_physics_process(false)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0:
		_strike()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox in _overlapping:
		return

	_overlapping.append(hurtbox)
	_update_processing()

	if hit_on_enter and _cooldown <= 0.0:
		_strike()


func _on_area_exited(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null:
		return

	_overlapping.erase(hurtbox)
	_update_processing()


## Aplica o dano a todos os alvos sobrepostos e reinicia o intervalo.
func _strike() -> void:
	var index := _overlapping.size() - 1
	while index >= 0:
		var hurtbox := _overlapping[index]
		# O alvo pode ter sido liberado da árvore entre um golpe e outro.
		if not is_instance_valid(hurtbox):
			_overlapping.remove_at(index)
		else:
			hurtbox.take_damage(damage, self)
			hit_landed.emit(hurtbox, damage)
		index -= 1

	_cooldown = hit_interval
	_update_processing()


func _update_processing() -> void:
	set_physics_process(not _overlapping.is_empty() and hit_interval > 0.0)
