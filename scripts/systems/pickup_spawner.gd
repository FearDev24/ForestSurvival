class_name PickupSpawner
extends Node
## Larga XP onde um inimigo morre (`docs/03_SYSTEMS.md` §11).
##
## Não observa o mundo e não varre nada: escuta o `SpawnManager` avisar que um
## inimigo nasceu, e liga uma vez o `died` daquele inimigo. Custo por inimigo:
## uma conexão de sinal.
##
## Fica separado do `SpawnManager` de propósito. Criar inimigo e largar tesouro
## são trabalhos diferentes, e a FASE 8 vai querer que o elite largue mais.

## Emitido a cada fragmento criado.
signal dropped(orb: Node2D)

@export var orb_scene: PackedScene

## Quanto vale cada fragmento. A FASE 8 dará valores por tipo de inimigo.
@export var xp_value: float = 1.0

## Chance de largar, de 0 a 100. Em 100 todo inimigo larga — que é o certo para
## um survivor-like, onde o XP é o combustível do loop.
@export_range(0, 100) var drop_chance: int = 100

var _pickups: Node = null


## Ligado pela raiz da partida.
func configure(spawn_manager: SpawnManager, pickup_container: Node) -> void:
	_pickups = pickup_container
	if spawn_manager != null and not spawn_manager.enemy_spawned.is_connected(_on_enemy_spawned):
		spawn_manager.enemy_spawned.connect(_on_enemy_spawned)


## Também serve para inimigos que não vieram do spawner — os de teste, por
## exemplo, e os que a FASE 8 puser à mão.
func watch(enemy: Node) -> void:
	if enemy == null or not enemy.has_signal("died"):
		return
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_spawned(enemy: Node2D) -> void:
	watch(enemy)


## O inimigo ainda está na árvore quando `died` chega, então dá para ler a
## posição dele — é o último instante em que isso é possível.
func _on_enemy_died(enemy: Node) -> void:
	if orb_scene == null or _pickups == null:
		return
	if randi() % 100 >= drop_chance:
		return

	var corpo := enemy as Node2D
	if corpo == null:
		return

	var orbe := orb_scene.instantiate() as Node2D
	if orbe == null:
		return
	orbe.global_position = corpo.global_position
	if "value" in orbe:
		orbe.value = xp_value

	# Entra na cena **adiado**. A morte chega de dentro da detecção de área que
	# matou o inimigo, e o orbe é uma `Area2D`: registrar a forma dela ali faz a
	# Godot recusar, porque a consulta de física ainda está sendo processada.
	# A posição já está definida, então um frame de atraso não muda nada visível.
	_pickups.add_child.call_deferred(orbe)
	dropped.emit(orbe)
