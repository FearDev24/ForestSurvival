class_name LightningCaster
extends Node
## Disparo automático de uma habilidade — **andaime de teste**, não arquitetura.
##
## Serve o raio e a vinha, que caem de formas diferentes: o raio **em cima** do
## inimigo, a vinha **a partir do druida, apontada** para ele. Dois exports
## resolvem a diferença; um segundo script seria duplicação de andaime.
##
## Existe para ver a habilidade em jogo antes da FASE 4. Quando o
## `WeaponManager` existir (DEC-009), isto some: arma vira dado em `Resource`
## (DEC-010) e o Player passa a ter armas de verdade, com nível e upgrade.
##
## Fica fora do Player de propósito. Colocar comportamento de arma dentro dele
## seria exatamente o acoplamento que a DEC-009 proíbe, e sair disso depois
## custaria mais do que escrever certo agora.

## Emitido a cada raio criado.
signal cast(strike: Node2D)

@export var strike_scene: PackedScene
## Segundos entre raios.
@export var cast_interval: float = 1.5
## Alcance máximo, em pixels. Fora disso o druida não acerta nada.
@export var cast_range: float = 640.0

## Onde o efeito nasce: em cima do alvo (raio) ou no próprio druida (vinha).
@export var spawn_on_target: bool = true

## Se o efeito é girado na direção do alvo. Só faz sentido em habilidade com
## direção — a vinha tem, o raio não.
@export var aim_at_target: bool = false

var enabled: bool = true

var _target: Node2D = null
var _enemies: Node = null
var _effects: Node = null
var _time_since_cast := 0.0


func _ready() -> void:
	set_physics_process(false)


## Ligado pela cena que compõe a partida, como o `SpawnManager`.
func configure(target: Node2D, enemy_container: Node, effect_container: Node) -> void:
	_target = target
	_enemies = enemy_container
	_effects = effect_container
	set_physics_process(strike_scene != null and _enemies != null and _effects != null)


func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(_target):
		return

	_time_since_cast += delta
	if _time_since_cast < cast_interval:
		return

	var victim := _find_nearest_enemy()
	if victim == null:
		return # Sem alvo, o cooldown não é gasto.

	_time_since_cast = 0.0
	_strike_at(victim.global_position)


## Cria o efeito e o posiciona conforme a habilidade.
func _spawn_effect(alvo: Vector2) -> Node2D:
	var efeito := strike_scene.instantiate() as Node2D
	if efeito == null:
		return null

	var origem := alvo if spawn_on_target else _target.global_position
	efeito.global_position = origem
	_effects.add_child(efeito)

	if aim_at_target and efeito.has_method("aim"):
		efeito.call("aim", (alvo - origem).normalized())

	cast.emit(efeito)
	return efeito


## Inimigo mais próximo dentro do alcance.
##
## Percorre a lista **só no instante do disparo**, não a cada frame: com o
## intervalo atual são 40 varreduras por minuto, não 3600
## (`docs/02_ARCHITECTURE.md`, DEC-011). Um alvo guardado entre disparos não
## serviria: o mais próximo muda o tempo todo, e ele pode ter morrido.
func _find_nearest_enemy() -> Node2D:
	var origin := _target.global_position
	var best: Node2D = null
	var best_distance := cast_range * cast_range

	for child in _enemies.get_children():
		var enemy := child as Node2D
		if enemy == null:
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy

	return best


func _strike_at(position: Vector2) -> void:
	_spawn_effect(position)
