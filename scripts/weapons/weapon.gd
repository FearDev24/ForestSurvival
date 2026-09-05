class_name Weapon
extends Node
## Uma arma em funcionamento: cooldown, mira e criação do ataque.
##
## Não conhece arma específica. Todo o comportamento sai de `WeaponData`
## (DEC-009): trocar o `.tres` troca a arma, sem tocar aqui.
##
## Substituiu o `lightning_caster.gd`, que era o mesmo trabalho em forma de
## andaime, sem nível e sem dados.

## Emitido a cada ataque criado. HUD, som e contagem se penduram aqui.
signal attacked(effect: Node2D, target: Node2D)

var data: WeaponData = null
var level: int = 1

var _target: Node2D = null
var _enemies: Node = null
var _effects: Node = null
var _time_since_attack := 0.0


func _ready() -> void:
	set_physics_process(false)


## Ligada pelo `WeaponManager`, que por sua vez é ligado pela raiz da partida.
func configure(target: Node2D, enemy_container: Node, effect_container: Node) -> void:
	_target = target
	_enemies = enemy_container
	_effects = effect_container
	set_physics_process(data != null and data.is_valid() and _enemies != null and _effects != null)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_time_since_attack += delta
	if _time_since_attack < data.cooldown_at(level):
		return

	var alvos := _find_targets()
	if alvos.is_empty():
		return # Sem alvo o cooldown não é gasto.

	_time_since_attack = 0.0
	for alvo in alvos:
		_attack(alvo)


## Os `amount` inimigos mais próximos dentro do alcance.
##
## A varredura acontece **só no instante do disparo**, nunca a cada frame: com o
## cooldown atual são poucas dezenas de varreduras por minuto, contra milhares
## se fosse por frame (`docs/02_ARCHITECTURE.md`, DEC-011).
##
## Guardar o alvo entre disparos não serviria: o mais próximo muda o tempo todo,
## e ele pode ter morrido.
func _find_targets() -> Array[Node2D]:
	var origem := _target.global_position
	var limite := data.attack_range * data.attack_range
	var candidatos: Array = []

	for filho in _enemies.get_children():
		var inimigo := filho as Node2D
		if inimigo == null:
			continue
		var distancia := origem.distance_squared_to(inimigo.global_position)
		if distancia <= limite:
			candidatos.append([distancia, inimigo])

	candidatos.sort_custom(func(a, b): return a[0] < b[0])

	var escolhidos: Array[Node2D] = []
	for i in mini(maxi(1, data.amount), candidatos.size()):
		escolhidos.append(candidatos[i][1])
	return escolhidos


func _attack(alvo: Node2D) -> void:
	var efeito := data.effect_scene.instantiate() as Node2D
	if efeito == null:
		push_warning("effect_scene de '%s' não é uma cena 2D." % data.id)
		return

	var origem := _spawn_position(alvo)
	efeito.global_position = origem
	_effects.add_child(efeito)

	# O dano vem do nível, não da cena: a mesma cena serve a arma nível 1 e
	# nível 5.
	if efeito.has_method("set_damage"):
		efeito.call("set_damage", data.damage_at(level))

	var direcao := _aim_direction(alvo, origem)
	if direcao != Vector2.ZERO and efeito.has_method("aim"):
		efeito.call("aim", direcao)

	attacked.emit(efeito, alvo)


## Onde o ataque nasce, conforme o modo da arma.
func _spawn_position(alvo: Node2D) -> Vector2:
	match data.spawn_mode:
		WeaponData.Spawn.NO_ALVO:
			return alvo.global_position
		WeaponData.Spawn.EM_VOLTA:
			# Ponto sorteado no anel em volta do druida. O sorteio é o que faz
			# a vinha brotar do chão em lugares diferentes a cada golpe, em vez
			# de sair sempre do mesmo ponto do corpo dele.
			var angulo := randf() * TAU
			var distancia := data.spawn_radius * randf_range(0.45, 1.0)
			return _target.global_position + Vector2(distancia, 0.0).rotated(angulo)
		_:
			return _target.global_position


## Para onde o ataque aponta. `Vector2.ZERO` significa "não aponta".
func _aim_direction(alvo: Node2D, origem: Vector2) -> Vector2:
	match data.aim_mode:
		WeaponData.Aim.PARA_O_ALVO:
			return (alvo.global_position - origem).normalized()
		WeaponData.Aim.HORIZONTAL:
			# Nunca na diagonal: o alvo só decide o lado.
			return Vector2.LEFT if alvo.global_position.x < origem.x else Vector2.RIGHT
		_:
			return Vector2.ZERO
