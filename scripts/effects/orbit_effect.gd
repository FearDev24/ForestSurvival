class_name OrbitEffect
extends Node2D
## Ataque que **acompanha** (`docs/ROADMAP.md`, FASE 7).
##
## Quarta família. As outras três são presas ao lugar onde nasceram: o golpe
## acontece num ponto, o projétil sai em linha reta, a zona fica no chão. Esta
## gira em volta do druida e vai junto com ele.
##
## É orbital **temporário**, não permanente: nasce no cooldown da arma, gira por
## `duration` segundos e some. Isso não é limitação, é o que permite a família
## caber no mesmo modelo das outras — arma dispara, efeito vive, efeito morre —
## em vez de exigir um segundo modelo só para ela.
##
## Contrato com a arma: `set_damage()`, `set_duration()` e `set_follow()`.
##
## O visual vem da cena — um vagalume em cada orbe. O desenho em código abaixo
## é o que sobra quando não há sprite nenhum (DEC-013).

## Emitido quando os orbes somem.
signal expired

## Segundos girando.
@export var duration: float = 4.0

## Distância de cada orbe até o druida.
@export var radius: float = 96.0

## Radianos por segundo. Negativo gira ao contrário.
@export var angular_speed: float = 2.2

@export var orb_color: Color = Color(0.75, 1.0, 0.55, 0.95)
@export var orb_radius: float = 9.0

var _alvo: Node2D = null
var _angulo := 0.0
var _vivo := 0.0
var _orbes: Array[Area2D] = []


func _ready() -> void:
	_resolver()


## Os orbes são procurados na primeira vez que fazem falta, não em `_ready`.
##
## `set_damage()` e `set_follow()` são chamados **antes** de o nó entrar na
## árvore, e `_ready` também não dispara em nó acrescentado de dentro de
## `SceneTree._initialize()`. É a mesma inicialização preguiçosa do
## `HealthComponent` e do `Hud`, pela mesma razão.
func _resolver() -> void:
	if not _orbes.is_empty():
		return
	for filho in get_children():
		var area := filho as Area2D
		if area != null:
			_orbes.append(area)
	_posicionar()


func _physics_process(delta: float) -> void:
	_vivo += delta
	if _vivo >= duration:
		set_physics_process(false)
		expired.emit()
		queue_free()
		return

	_resolver()
	_angulo += angular_speed * delta
	# Acompanha o druida em coordenada de mundo. Ser filho dele resolveria o
	# acompanhamento, mas colocaria o ataque dentro do Player — e o Player não
	# conhece arma nem efeito (`docs/02_ARCHITECTURE.md`).
	if is_instance_valid(_alvo):
		global_position = _alvo.global_position
	_posicionar()
	queue_redraw()


func _draw() -> void:
	# Com arte nos orbes — um `Sprite` em cada —, o desenho em código sai
	# (DEC-013). Basta olhar o primeiro: a cena põe sprite em todos ou nenhum.
	if not _orbes.is_empty() and _orbes[0].get_node_or_null("Sprite") != null:
		return
	var restante := 1.0 - clampf(_vivo / maxf(0.01, duration), 0.0, 1.0)
	var cor := orb_color
	# Desvanece no fim, para os orbes não sumirem de estalo.
	cor.a *= clampf(restante * 3.0, 0.0, 1.0)
	for orbe in _orbes:
		draw_circle(orbe.position, orb_radius, cor)
		var halo := cor
		halo.a *= 0.35
		draw_circle(orbe.position, orb_radius * 1.9, halo)


## Espalha os orbes em ângulos iguais. Com três, ficam a 120° um do outro.
func _posicionar() -> void:
	var total := _orbes.size()
	if total == 0:
		return
	for i in total:
		var passo := TAU * float(i) / float(total)
		_orbes[i].position = Vector2(radius, 0.0).rotated(_angulo + passo)


## Quem os orbes acompanham. Chamado pela arma logo depois de instanciar.
func set_follow(node: Node2D) -> void:
	_resolver()
	_alvo = node
	if is_instance_valid(node):
		global_position = node.global_position


## Chamado antes de o nó entrar na árvore, então `_orbes` ainda está vazio: a
## busca é feita aqui de novo, direto nos filhos.
func set_damage(value: float) -> void:
	_resolver()
	for filho in get_children():
		var hitbox := filho as HitboxComponent
		if hitbox != null:
			hitbox.damage = value


func set_duration(value: float) -> void:
	if value > 0.0:
		duration = value
