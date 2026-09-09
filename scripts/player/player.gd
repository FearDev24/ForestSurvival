class_name Player
extends CharacterBody2D
## Druida Guardião — jogador.
##
## Movimento, câmera e morte. A vida está no componente irmão `Health` e o dano
## chega pela `Hurtbox`; este script só reage à morte.
##
## Armas e coleta ainda não existem — entram nas FASES 4 e 5 do
## `docs/ROADMAP.md`.
##
## Desacoplamento de arte (DEC-013 / `docs/ASSET_WORKFLOW.md`):
## este script nunca lê textura, sprite, tamanho de imagem ou animação.
## Ele apenas informa a direção encarada pelo sinal `facing_changed`; o nó
## `Visual` decide como representá-la. Trocar o placeholder pela sprite
## definitiva do druida não deve exigir nenhuma alteração aqui.
##
## Input (DEC-005 / `docs/ANDROID.md`): o movimento usa exclusivamente Input
## Actions. Nenhuma tecla é lida diretamente, de modo que um joystick virtual
## no Android possa alimentar o mesmo código sem reescrita.

## Direção encarada. Existe para permitir integrar as sprites direcionais
## (south/north/west/east) mais tarde sem mexer na lógica de movimento.
enum Facing { SOUTH, NORTH, WEST, EAST }

## Emitido somente quando a direção muda, não a cada frame.
signal facing_changed(facing: Facing)

## Emitido uma única vez, quando o jogador morre. O nó **não** é removido da
## árvore: game over, tela de resultado e restart são da FASE 9. Aqui o Player
## apenas para de responder e deixa de ser alvo.
signal died

## Emitido quando a apresentação da morte acaba — hoje, quando a animação de
## morte chega ao fim. Repassa o aviso da camada visual sem que a lógica saiba o
## que foi apresentado, nem quanto tempo durou (DEC-013).
signal death_finished

## Emitido somente quando o jogador começa ou para de se mover.
## A camada visual usa isto para alternar entre parado e caminhando; a lógica
## não sabe que animações existem.
signal movement_state_changed(is_moving: bool)

## Velocidade **base**, em pixels por segundo, antes de qualquer passiva.
## Faixa planejada no GDD (`docs/01_GAME_DESIGN.md`): 180–220 px/s.
##
## O que o movimento usa é `_move_speed_efetiva`, que é este valor passado pelo
## `StatComponent`. Mexer aqui muda o ponto de partida do druida; mexer no stat
## muda o que as passivas somaram por cima.
@export var move_speed: float = 200.0:
	set(value):
		move_speed = value
		_aplicar_stats()

## Zoom da câmera. Quanto menor, mais mundo cabe na tela.
##
## Em 1.0 a área visível é a resolução base inteira (1280 x 720 unidades de
## mundo) e o druida ocupa cerca de 13% da altura da tela — proporção adequada
## para um survivor-like, que precisa de espaço para hordas.
##
## Medições feitas em 1920 x 1080:
##
## | zoom | mundo visível | altura do druida |
## |------|---------------|------------------|
## | 2.0  | 640 x 360     | 26,7% da tela    |
## | 1.5  | 853 x 480     | 20,0% da tela    |
## | 1.0  | 1280 x 720    | 13,3% da tela    |
##
## Abaixo de 1.0 a arte passa a ser reduzida abaixo da resolução nativa e a
## pixel art perde definição; nesse caso o certo é gerar sprites menores, não
## diminuir mais o zoom.
@export var camera_zoom: float = 1.0

var facing: Facing = Facing.SOUTH

var _is_moving := false
var _is_dead := false

## Velocidade depois das passivas. É o que `_physics_process` usa.
var _move_speed_efetiva := 0.0

## Bases guardadas na primeira aplicação, porque aplicar um stat **escreve por
## cima** do valor do componente: se `HealthComponent.max_health` virasse a base
## da conta seguinte, cada bônus se somaria ao anterior e a vida cresceria em
## composto a cada recálculo.
var _base_max_health := 0.0
var _base_pickup_radius := 0.0
var _bases_lidas := false

@onready var _camera: Camera2D = $Camera2D
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	var stats := _stats()
	if stats != null:
		stats.stat_changed.connect(_on_stat_changed)
	_aplicar_stats()
	# Garante que a camada visual comece coerente com o estado inicial.
	facing_changed.emit(facing)
	movement_state_changed.emit(_is_moving)


func _physics_process(_delta: float) -> void:
	if _is_dead:
		return

	# `Input.get_vector` já limita o comprimento a 1, então a diagonal não é
	# mais rápida que os eixos. Não multiplicar por delta: em CharacterBody2D
	# `velocity` é px/s e `move_and_slide()` aplica o passo de física.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * _move_speed_efetiva
	_update_facing(direction)
	_update_movement_state(direction)
	move_and_slide()


## Reage à morte vinda do `HealthComponent`, ligado na própria cena.
##
## O Player continua na árvore, com a câmera funcionando: quem decide o que
## acontece depois é a FASE 9. Aqui ele apenas para de andar e sai do radar das
## hitboxes, para não continuar levando golpes de quem já o matou.
func _on_health_died() -> void:
	if _is_dead:
		return
	_is_dead = true

	velocity = Vector2.ZERO
	_hurtbox.set_vulnerable(false)
	_update_movement_state(Vector2.ZERO)

	died.emit()


## Repassa o fim da apresentação da morte, vindo do nó `Visual`.
func _on_visual_death_animation_finished() -> void:
	death_finished.emit()


func is_dead() -> bool:
	return _is_dead


# ---------------------------------------------------------------- passivas --


## Recalcula tudo que depende de stat.
##
## É chamado inteiro a cada mudança, e não por stat, de propósito: são três
## contas triviais, acontecem quando o jogador escolhe uma passiva — não todo
## frame —, e um caminho só é mais fácil de conferir que três.
func _aplicar_stats() -> void:
	var stats := _stats()
	if stats == null:
		# Antes de entrar na árvore, ou num Player montado sem o componente: o
		# druida continua funcionando com os valores base.
		_move_speed_efetiva = move_speed
		return

	_ler_bases()
	_move_speed_efetiva = stats.apply(StatComponent.Stat.MOVE_SPEED, move_speed)

	var health := get_node_or_null("Health") as HealthComponent
	if health != null:
		var novo_maximo := stats.apply(StatComponent.Stat.MAX_HEALTH, _base_max_health)
		var ganho := novo_maximo - health.max_health
		health.max_health = novo_maximo
		# Vida máxima ganha também cura o mesmo tanto. Sem isso, a passiva de
		# vida só aumentaria o teto e o jogador não sentiria nada na hora de
		# escolher — o efeito apareceria vários minutos depois.
		if ganho > 0.0:
			health.heal(ganho)

		# Regeneração é o único stat cuja base é zero: sem passiva, o druida não
		# regenera nada, e `(0 + plano) * fator` devolve exatamente isso.
		health.regeneration = stats.apply(StatComponent.Stat.REGEN, 0.0)

	var pickup := get_node_or_null("PickupArea") as PickupArea
	if pickup != null:
		pickup.set_radius(stats.apply(StatComponent.Stat.PICKUP_RADIUS, _base_pickup_radius))


## Guarda os valores originais uma única vez, antes de qualquer bônus.
func _ler_bases() -> void:
	if _bases_lidas:
		return
	_bases_lidas = true

	var health := get_node_or_null("Health") as HealthComponent
	if health != null:
		_base_max_health = health.max_health

	var pickup := get_node_or_null("PickupArea") as PickupArea
	if pickup != null:
		_base_pickup_radius = pickup.get_radius()


## Velocidade depois das passivas, em pixels por segundo. É o número que o
## movimento realmente usa — `move_speed` é só a base.
func get_move_speed() -> float:
	return _move_speed_efetiva


func _stats() -> StatComponent:
	return get_node_or_null("Stats") as StatComponent


func _on_stat_changed(_stat: StatComponent.Stat) -> void:
	_aplicar_stats()


# ------------------------------------------------------------------ câmera --


## Aplica os limites do mundo à câmera.
##
## Quem chama é a cena que compõe a partida: o Player não conhece o mapa, e o
## mapa não alcança dentro do Player. Ver `scripts/systems/game.gd`.
func apply_camera_limits(bounds: Rect2) -> void:
	_camera.limit_left = roundi(bounds.position.x)
	_camera.limit_top = roundi(bounds.position.y)
	_camera.limit_right = roundi(bounds.end.x)
	_camera.limit_bottom = roundi(bounds.end.y)


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
		# Empate (diagonal exata) resolve para o eixo vertical. Regra fixa,
		# para que a direção não oscile enquanto o jogador anda na diagonal.
		new_facing = Facing.SOUTH if direction.y > 0.0 else Facing.NORTH

	if new_facing == facing:
		return

	facing = new_facing
	facing_changed.emit(facing)
