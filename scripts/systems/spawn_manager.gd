class_name SpawnManager
extends Node
## Criação de inimigos ao longo da partida (`docs/03_SYSTEMS.md` §6).
##
## Responsabilidades: escolher o ponto de spawn, mantê-lo fora da câmera,
## respeitar a taxa da wave e limitar a população.
##
## **Não** decide quais inimigos existem, nem quando a partida acaba, nem o que
## acontece quando um inimigo morre. A tabela de waves e os tipos de inimigo são
## do `WaveManager`, na FASE 8; aqui há um único inimigo e uma rampa linear.
##
## ## Custo por frame
##
## Uma soma de delta e uma comparação. Não há `Timer`, não há busca por grupo e
## não há varredura da lista de inimigos: a população é lida em
## `get_child_count()` do container, que é O(1) (`docs/02_ARCHITECTURE.md`,
## DEC-011).

## Emitido a cada inimigo criado. Serve para HUD, contagem de wave e testes.
signal enemy_spawned(enemy: Node2D)

## Cena instanciada a cada spawn. Trocar isto troca o inimigo, sem tocar em
## código — é o mesmo princípio do nó `Visual` para arte (DEC-013).
@export var enemy_scene: PackedScene

@export_group("Ritmo")
## Segundos entre spawns no início da partida.
@export var initial_spawn_interval: float = 1.2
## Segundos entre spawns no fim da rampa. Menor = mais denso.
@export var final_spawn_interval: float = 0.2
## Quantos inimigos podem existir ao mesmo tempo no início.
@export var initial_population_cap: int = 40
## Teto de população no fim da rampa.
@export var final_population_cap: int = 200
## Em quanto tempo a partida vai do ritmo inicial ao final.
@export var ramp_seconds: float = 300.0

@export_group("Posição")
## Folga além da borda da tela, em pixels de mundo. Garante que o inimigo nasça
## fora do campo de visão mesmo em telas mais largas que a resolução base.
@export var offscreen_margin: float = 96.0
## Distância mínima que o ponto de spawn deve manter das paredes do mundo, para
## o inimigo não nascer preso na borda.
@export var bounds_margin: float = 64.0
## Quantos ângulos tentar antes de aceitar o melhor candidato disponível. Só
## importa quando o Player está encurralado num canto do mapa.
@export var spawn_attempts: int = 8

## Liga e desliga a criação de inimigos. A FASE 9 usará isto no game over
## ("interromper spawn"); os testes usam para medir sem interferência.
var enabled: bool = true

var _target: Node2D = null
var _container: Node = null
var _bounds: Rect2 = Rect2()
var _elapsed := 0.0
var _time_since_spawn := 0.0


func _ready() -> void:
	set_physics_process(false)


## Ligado pela cena que compõe a partida (`scripts/systems/game.gd`).
##
## O manager não procura o Player nem o mapa por conta própria: quem conhece a
## composição é a raiz da partida. Assim, trocar o mapa ou o alvo não mexe aqui.
func configure(target: Node2D, container: Node, bounds: Rect2) -> void:
	_target = target
	_container = container
	_bounds = bounds
	set_physics_process(_container != null and enemy_scene != null)


func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(_target):
		return

	_elapsed += delta
	_time_since_spawn += delta

	if _time_since_spawn < get_spawn_interval():
		return

	_time_since_spawn = 0.0

	if get_population() >= get_population_cap():
		return

	spawn_one()


## Progresso da rampa de dificuldade, de 0 a 1.
func get_ramp_progress() -> float:
	if ramp_seconds <= 0.0:
		return 1.0
	return clampf(_elapsed / ramp_seconds, 0.0, 1.0)


## Intervalo entre spawns neste instante da partida.
func get_spawn_interval() -> float:
	return lerpf(initial_spawn_interval, final_spawn_interval, get_ramp_progress())


## Teto de população neste instante da partida.
func get_population_cap() -> int:
	return roundi(lerpf(float(initial_population_cap), float(final_population_cap), get_ramp_progress()))


## População viva. O container só tem inimigos, então contar filhos basta e
## custa O(1) — nada de `get_nodes_in_group()`.
func get_population() -> int:
	if _container == null:
		return 0
	return _container.get_child_count()


## Raio a partir do qual um ponto está fora da tela, em unidades de mundo.
##
## Sai do viewport e do zoom da câmera ativa, não de constantes: em Android a
## proporção de tela varia muito, e `stretch/aspect = expand` (DEC-015) mostra
## mais mundo em telas mais largas. Um raio fixo faria o inimigo nascer visível
## nesses aparelhos.
func get_spawn_distance() -> float:
	var visible_size := Vector2(1280.0, 720.0)

	var viewport := get_viewport()
	if viewport != null:
		visible_size = viewport.get_visible_rect().size
		var camera := viewport.get_camera_2d()
		if camera != null and camera.zoom.x > 0.0 and camera.zoom.y > 0.0:
			visible_size /= camera.zoom

	# Meia diagonal cobre o pior caso: o canto da tela.
	return visible_size.length() * 0.5 + offscreen_margin


## Cria um inimigo agora, ignorando intervalo e teto de população.
## Usado pelo próprio manager, pelos testes de stress e, no futuro, por eventos
## de wave que precisem de uma leva imediata.
func spawn_one() -> Node2D:
	if enemy_scene == null or _container == null or not is_instance_valid(_target):
		return null

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		push_warning("enemy_scene do SpawnManager não é uma cena 2D.")
		return null

	enemy.global_position = pick_spawn_position()
	_container.add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy


## Cria vários de uma vez. Cada um recebe um ponto próprio, então nunca nascem
## na mesma coordenada — sobreposição exata é o caso degenerado que a física de
## corpos cinemáticos não resolve sozinha (DEC-018).
func spawn_burst(count: int) -> void:
	for i in maxi(0, count):
		spawn_one()


## Escolhe um ponto fora da tela, dentro do mapa e longe das paredes.
##
## Sorteia um ângulo, tenta alguns, e fica com o primeiro que continue fora do
## campo de visão depois de ser limitado ao mapa. Se nenhum servir — Player
## encurralado num canto —, fica com o mais distante que conseguiu.
func pick_spawn_position() -> Vector2:
	var origin := _target.global_position
	var distance := get_spawn_distance()

	var best := origin
	var best_distance := -1.0

	for attempt in maxi(1, spawn_attempts):
		var angle := randf() * TAU
		var candidate := origin + Vector2(distance, 0.0).rotated(angle)
		candidate = _clamp_to_bounds(candidate)

		var candidate_distance := origin.distance_to(candidate)
		if candidate_distance >= distance:
			return candidate

		if candidate_distance > best_distance:
			best = candidate
			best_distance = candidate_distance

	return best


func _clamp_to_bounds(point: Vector2) -> Vector2:
	if _bounds.size == Vector2.ZERO:
		return point

	return Vector2(
		clampf(point.x, _bounds.position.x + bounds_margin, _bounds.end.x - bounds_margin),
		clampf(point.y, _bounds.position.y + bounds_margin, _bounds.end.y - bounds_margin),
	)
