class_name Enemy
extends CharacterBody2D
## Diabrete — primeiro inimigo.
##
## Locomoção, direção e morte. Vida e dano ficam nos componentes irmãos
## (`Health`, `Hitbox`, `Hurtbox`): este script só reage à morte.
##
## Perseguição direta simples, sem NavigationAgent2D e sem pathfinding
## (DEC-008).
##
## Desacoplamento de arte (DEC-013 / `docs/ASSET_WORKFLOW.md`): este script
## nunca lê textura, sprite, tamanho de imagem ou animação. Ele informa
## intenção pelos sinais; o nó `Visual` decide a representação.

## Direção encarada. Mesma convenção do Player, mas declarada aqui: o inimigo
## não deve depender do jogador para existir.
enum Facing { SOUTH, NORTH, WEST, EAST }

## Emitido somente quando a direção muda, não a cada frame.
signal facing_changed(facing: Facing)

## Emitido somente quando o inimigo começa ou para de se mover.
signal movement_state_changed(is_moving: bool)

## Emitido uma única vez, quando o inimigo morre. Existe para que XP, efeitos e
## contagem de wave possam se pendurar aqui nas fases seguintes, sem que este
## script precise conhecer nenhum deles.
signal died

## Emitido quando o inimigo sai de vez da partida. Nos comuns, no mesmo quadro
## de `died`; no Guardião, quando a queda termina (DEC-024). A vitória da
## FASE 9 espera por este, e não por `died`.
signal death_finished

## Velocidade em pixels por segundo. Mais lento que o Player (200 px/s), para
## que dê para fugir. Valor provisório: o sistema de Stats só entra na FASE 6.
@export var move_speed: float = 110.0

## Quanto de XP o fragmento deste inimigo vale. Quem lê é o `PickupSpawner`.
## Preenchido por `apply_data()`; o valor da cena é o do diabrete comum.
var xp_value: float = 1.0

## O tipo que originou este inimigo, ou nulo se ele veio direto da cena.
var data: EnemyData = null

var facing: Facing = Facing.SOUTH

var _is_moving := false
## Impede que a morte seja processada duas vezes. `HealthComponent` já garante
## que `died` só é emitido uma vez; este guarda cobre também uma chamada
## direta a `kill()`.
var _is_dying := false
## Referência ao alvo, resolvida **uma vez**. Nunca buscar por grupo dentro de
## `_physics_process`: o jogo precisa suportar centenas de inimigos
## (`docs/02_ARCHITECTURE.md`, DEC-011).
var _target: Node2D = null

## Recuo quando uma habilidade acerta sem matar: o jogador precisa ver que o
## golpe pegou. Leve de propósito — uns 18 px — e com intervalo, para uma zona
## que acerta várias vezes não virar uma parede que empurra a horda.
## Gradiente radial da aura do chefe. E recurso gerado pela Godot, nao arte: nao
## ha PNG nenhum para trocar aqui.
const AURA_TEXTURA := "res://assets/effects/aura_gradiente.tres"

const _RECUO_VELOCIDADE := 260.0
const _RECUO_DURACAO := 0.14
const _RECUO_INTERVALO := 0.2
var _recuo := Vector2.ZERO
var _recuo_tempo := 0.0
var _recuo_espera := 0.0

@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	_hurtbox.hit.connect(_on_atingido)
	facing_changed.emit(facing)
	movement_state_changed.emit(_is_moving)


## Aplica um tipo de inimigo (`EnemyData`).
##
## Chamado pelo `SpawnManager` logo depois de instanciar, **antes** de o nó
## entrar na árvore: por isso `get_node_or_null` e não `@onready`. É também por
## isso que a vida pode ser trocada sem cuidado — o `HealthComponent` ainda não
## se preencheu, e vai nascer já com o máximo do tipo.
func apply_data(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		return
	data = enemy_data
	move_speed = enemy_data.move_speed
	xp_value = enemy_data.xp_value

	var health := get_node_or_null("Health") as HealthComponent
	if health != null:
		health.max_health = enemy_data.max_health

	var hitbox := get_node_or_null("Hitbox") as HitboxComponent
	if hitbox != null:
		hitbox.damage = enemy_data.contact_damage

	# Só a arte. Colisão é dado de gameplay e se ajusta à parte
	# (`docs/ASSET_WORKFLOW.md`, regra 7).
	var visual := get_node_or_null("Visual") as Node2D
	if visual != null:
		if enemy_data.sprite_frames != null and visual.has_method("set_frames"):
			visual.call("set_frames", enemy_data.sprite_frames)
		if not is_equal_approx(enemy_data.visual_scale, 1.0):
			visual.scale *= enemy_data.visual_scale

	if enemy_data.body_radius > 0.0:
		_redimensionar_corpo(enemy_data.body_radius)

	modulate = enemy_data.tint
	Audio.tocar(enemy_data.som_nascimento)
	_atravessar(enemy_data)
	_acender_aura(enemy_data)


## Tira o corpo da física, nos dois sentidos.
##
## Zerar só a máscara faria o Guardião atravessar a pedra e continuar empurrando
## a horda; zerar só a camada faria o contrário. As duas pontas saem juntas, e o
## dano continua: Hitbox e Hurtbox são áreas próprias, em camadas próprias.
func _atravessar(enemy_data: EnemyData) -> void:
	if not enemy_data.passa_por_tudo:
		return
	collision_layer = 0
	collision_mask = 0


## Acende a luz do chefe, se o `EnemyData` pedir.
##
## O raio vem em pixels de mundo e a textura do gradiente tem 256: a escala é a
## razão entre os dois. `energy` sai do alfa da cor, que é onde se regula a
## força sem mexer no tom.
func _acender_aura(enemy_data: EnemyData) -> void:
	if enemy_data.aura_radius <= 0.0 or enemy_data.aura_color.a <= 0.0:
		return

	# A luz nasce aqui, e nao na cena: um `PointLight2D` apagado em cada inimigo
	# custa quadro quando a horda passa de quinhentos -- foi o teste da FASE 3
	# que mostrou, saltando de 16,7 para 29 ms por quadro.
	var luz := PointLight2D.new()
	luz.name = "Aura"
	luz.texture = load(AURA_TEXTURA)
	add_child(luz)
	# No meio do corpo, e nao nos pes: a luz nasce da criatura. A altura sai do
	# proprio sprite, que ja esta posicionado pela altura do quadro.
	var visual := get_node_or_null("Visual") as Node2D
	var sprite := visual.get_node_or_null("Sprite") as Node2D if visual != null else null
	if sprite != null:
		luz.position.y = sprite.position.y * visual.scale.y

	luz.color = Color(enemy_data.aura_color, 1.0)
	luz.energy = enemy_data.aura_color.a
	luz.texture_scale = enemy_data.aura_radius * 2.0 / 256.0
	if enemy_data.aura_pulso > 0.0:
		var tween := create_tween().set_loops()
		tween.tween_property(luz, "energy", enemy_data.aura_color.a * 0.55,
			enemy_data.aura_pulso * 0.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(luz, "energy", enemy_data.aura_color.a,
			enemy_data.aura_pulso * 0.5).set_trans(Tween.TRANS_SINE)


## Troca o raio das formas de colisão.
##
## **Duplica a forma antes de mexer.** As `CircleShape2D` moram como
## sub-recurso da cena e são compartilhadas entre todas as instâncias dela:
## mudar o raio de um bruto sem duplicar engordaria todo diabrete em tela.
func _redimensionar_corpo(raio: float) -> void:
	for caminho in ["CollisionShape2D", "Hitbox/CollisionShape2D", "Hurtbox/CollisionShape2D"]:
		var forma := get_node_or_null(caminho) as CollisionShape2D
		if forma == null or forma.shape == null:
			continue
		var circulo := forma.shape.duplicate() as CircleShape2D
		if circulo == null:
			continue
		circulo.radius = raio
		forma.shape = circulo


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	# `is_instance_valid` cobre o caso do alvo ser removido da árvore (morte do
	# Player, troca de cena): o inimigo apenas para, sem erro.
	if is_instance_valid(_target):
		direction = global_position.direction_to(_target.global_position)

	velocity = direction * move_speed
	# No recuo a perseguição cede e o empurrão manda, soltando aos poucos.
	if _recuo_tempo > 0.0:
		var peso := _recuo_tempo / _RECUO_DURACAO
		velocity = velocity * (1.0 - peso) + _recuo * peso
		_recuo_tempo -= delta
	_recuo_espera -= delta
	_update_facing(direction)
	_update_movement_state(direction)
	move_and_slide()


## Recua quando uma habilidade acerta sem matar.
##
## O sinal `hit` da hurtbox chega **antes** do dano, e é isso que deixa saber se
## o golpe vai matar: se vai, não empurra — o inimigo some no mesmo quadro, e o
## empurrão não se veria.
##
## Para longe de quem acertou — o centro do raio, o orbe, o corvo —, e encolhe
## com `EnemyData.knockback_scale`: pesado recua menos, o Guardião não recua.
func _on_atingido(quanto: float, fonte: Node) -> void:
	if _is_dying or _recuo_espera > 0.0:
		return
	var vida := get_node_or_null("Health") as HealthComponent
	if vida != null and vida.current_health - quanto <= 0.0:
		return
	var escala := data.knockback_scale if data != null else 1.0
	if escala <= 0.0:
		return
	var origem := global_position
	var fonte_2d := fonte as Node2D
	if fonte_2d != null:
		origem = fonte_2d.global_position
	var direcao := origem.direction_to(global_position)
	if direcao.is_zero_approx():
		direcao = Vector2.RIGHT
	_recuo = direcao * _RECUO_VELOCIDADE * escala
	_recuo_tempo = _RECUO_DURACAO
	_recuo_espera = _RECUO_INTERVALO


## Reage à morte vinda do `HealthComponent`, ligado na própria cena.
##
## Os comuns somem da partida de uma vez: um cadáver que continua colidindo e
## perseguindo seria pior que nenhum feedback, e sumir é o final deles
## (DEC-024). O Guardião para de lutar no mesmo quadro, mas fica para cair.
func _on_health_died() -> void:
	if _is_dying:
		return
	_is_dying = true

	set_physics_process(false)
	velocity = Vector2.ZERO
	_hurtbox.set_vulnerable(false)
	# Adiado pelo mesmo motivo do `set_vulnerable`: a morte costuma chegar de
	# dentro do sinal de uma área, e a Godot bloqueia a troca durante ele.
	_hitbox.set_deferred(&"monitoring", false)

	died.emit()

	if data != null:
		Audio.tocar(data.som_morte)
	if data != null and data.staged_death:
		_encenar_queda()
		return
	_sair()


## Morte encenada (DEC-024): o corpo fica na partida até a queda terminar.
##
## Ganha modo de processamento próprio porque, durante a queda, o
## `GameManager` congela o contêiner dos inimigos — e o Guardião precisa
## continuar caindo enquanto a horda para. PAUSABLE, e não ALWAYS: quando a
## vitória pausa a árvore a queda já terminou, e nada deve andar por baixo da
## tela de resultado. Adiado pelo mesmo motivo do `set_vulnerable` acima.
##
## Quem decide **como** cair é o `Visual`: este script não conhece animação.
func _encenar_queda() -> void:
	set_deferred(&"process_mode", Node.PROCESS_MODE_PAUSABLE)
	var visual := get_node_or_null("Visual")
	if visual == null or not visual.has_method("play_death"):
		_sair()
		return
	visual.connect(&"death_animation_finished", _sair, CONNECT_ONE_SHOT)
	visual.call(&"play_death")


func _sair() -> void:
	death_finished.emit()
	queue_free()


func _update_movement_state(direction: Vector2) -> void:
	var moving := not direction.is_zero_approx()
	if moving == _is_moving:
		return
	_is_moving = moving
	movement_state_changed.emit(_is_moving)


func _update_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return # Parado mantém a última direção válida.

	var new_facing: Facing
	if absf(direction.x) > absf(direction.y):
		new_facing = Facing.EAST if direction.x > 0.0 else Facing.WEST
	else:
		# Empate resolve para o eixo vertical, mesma regra fixa do Player.
		new_facing = Facing.SOUTH if direction.y > 0.0 else Facing.NORTH

	if new_facing == facing:
		return

	facing = new_facing
	facing_changed.emit(facing)
