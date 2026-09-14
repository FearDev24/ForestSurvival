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

## Passivas do jogador. Pode faltar — uma arma num teste solto funciona sem
## nenhuma, com os números crus do `WeaponData`.
var stats: StatComponent = null

var _target: Node2D = null
var _enemies: Node = null
var _effects: Node = null
var _time_since_attack := 0.0


func _ready() -> void:
	set_physics_process(false)


## Ligada pelo `WeaponManager`, que por sua vez é ligado pela raiz da partida.
func configure(target: Node2D, enemy_container: Node, effect_container: Node,
		stat_component: StatComponent = null) -> void:
	_target = target
	_enemies = enemy_container
	_effects = effect_container
	stats = stat_component
	set_physics_process(data != null and data.is_valid() and _enemies != null and _effects != null)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_time_since_attack += delta
	if _time_since_attack < cooldown_efetivo():
		return

	var alvos := _find_targets()
	if alvos.is_empty():
		return # Sem alvo o cooldown não é gasto.

	_time_since_attack = 0.0
	# Uma vez por salva, e não por alvo: com `amount` 3 saem três efeitos, e três
	# cópias do mesmo som no mesmo frame só somam amplitude.
	Audio.tocar(data.som)
	for alvo in alvos:
		_attack(alvo)


## Dano deste disparo, já com as passivas.
##
## Lido a cada tiro, não guardado: assim uma passiva escolhida no meio da
## partida vale no disparo seguinte, sem ninguém precisar avisar a arma.
func damage_efetivo() -> float:
	var base := data.damage_at(level)
	return stats.apply(StatComponent.Stat.DAMAGE, base) if stats != null else base


## Intervalo entre disparos, já com as passivas.
func cooldown_efetivo() -> float:
	var base := data.cooldown_at(level)
	return stats.apply(StatComponent.Stat.COOLDOWN, base) if stats != null else base


## Fator de tamanho do golpe. 1.0 é o tamanho desenhado.
func area_efetiva() -> float:
	return stats.apply(StatComponent.Stat.AREA, 1.0) if stats != null else 1.0


## Quantos alvos este disparo atende.
##
## Arredonda para baixo e nunca desce de 1: uma passiva de quantidade que
## deixasse a arma sem alvo nenhum a desligaria em vez de enfraquecê-la.
func amount_efetivo() -> int:
	var base := float(maxi(1, data.amount))
	var total := stats.apply(StatComponent.Stat.AMOUNT, base) if stats != null else base
	return maxi(1, int(floorf(total)))


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
	for i in mini(amount_efetivo(), candidatos.size()):
		escolhidos.append(candidatos[i][1])
	return escolhidos


func _attack(alvo: Node2D) -> void:
	var origem := _spawn_position(alvo)
	if data.grounded:
		var livre: Variant = _achar_chao_livre(alvo)
		if livre == null:
			# Nenhum ponto em volta tem chão livre: melhor nenhum golpe do que
			# um golpe atravessando pedra.
			return
		origem = livre

	var efeito := data.effect_scene.instantiate() as Node2D
	if efeito == null:
		push_warning("effect_scene de '%s' não é uma cena 2D." % data.id)
		return

	efeito.global_position = origem
	# Área é escala do nó inteiro: a hitbox é filha do efeito, então cresce
	# junto com o desenho sem que a cena precise saber que existe passiva.
	# Escala uniforme e positiva de propósito — negativa inverteria a colisão e
	# a Godot reclama de forma com escala negativa.
	var area := area_efetiva()
	if not is_equal_approx(area, 1.0):
		efeito.scale = Vector2(area, area)
	_effects.add_child(efeito)

	# O dano vem do nível, não da cena: a mesma cena serve a arma nível 1 e
	# nível 5.
	if efeito.has_method("set_damage"):
		efeito.call("set_damage", damage_efetivo())

	# Campos de família. Cada efeito atende só o que lhe diz respeito, e o
	# `WeaponData` usa zero para dizer "fica com o valor da cena" — assim uma
	# família nova não obriga as armas antigas a preencher nada.
	if data.projectile_speed > 0.0 and efeito.has_method("set_speed"):
		var velocidade := data.projectile_speed
		if stats != null:
			velocidade = stats.apply(StatComponent.Stat.PROJECTILE_SPEED, velocidade)
		efeito.call("set_speed", velocidade)

	if data.projectile_pierce > 0 and efeito.has_method("set_pierce"):
		efeito.call("set_pierce", data.projectile_pierce)

	if data.effect_duration > 0.0 and efeito.has_method("set_duration"):
		var duracao := data.effect_duration
		if stats != null:
			duracao = stats.apply(StatComponent.Stat.DURATION, duracao)
		efeito.call("set_duration", duracao)

	# Ataque que acompanha precisa saber quem seguir. É o único que recebe uma
	# referência de nó, e não um número — por isso vale a guarda: nenhuma outra
	# família responde a este método.
	if efeito.has_method("set_follow"):
		efeito.call("set_follow", _target)

	var direcao := _aim_direction(alvo, origem)
	if direcao != Vector2.ZERO and efeito.has_method("aim"):
		efeito.call("aim", direcao)

	attacked.emit(efeito, alvo)


## Quantos pontos tentar antes de desistir de achar chão livre.
const _TENTATIVAS_DE_CHAO := 8

## Faixa de chão que o golpe ocupa virado para a direita, a partir da origem.
## Sai da própria colisão do efeito, medida uma vez: a faixa conferida e a faixa
## que acerta são sempre a mesma.
var _faixa_de_chao := Rect2()


## Um ponto de nascimento em que o golpe não atravessa objeto sólido do mapa.
##
## Golpe que corre pelo chão — a vinha (`WeaponData.grounded`) — brota da terra
## e se estende pelo chão. Nascendo de um lado de uma pedra, sairia do outro
## lado por cima dela, flutuando. Então tenta pontos até achar um em que a faixa
## do golpe esteja livre. Nulo se nenhum estiver.
func _achar_chao_livre(alvo: Node2D) -> Variant:
	for i in _TENTATIVAS_DE_CHAO:
		var ponto := _spawn_position(alvo)
		if _chao_livre(ponto, _aim_direction(alvo, ponto)):
			return ponto
	return null


func _chao_livre(ponto: Vector2, direcao: Vector2) -> bool:
	if _target == null or not _target.is_inside_tree():
		return true
	var faixa := _medir_faixa_de_chao()
	if faixa.size == Vector2.ZERO:
		return true
	var escala := area_efetiva()
	var local := Rect2(faixa.position * escala, faixa.size * escala)
	# Virado para a esquerda o golpe espelha no eixo X, em volta da origem.
	if direcao.x < 0.0:
		local.position.x = -local.end.x
	var retangulo := RectangleShape2D.new()
	retangulo.size = local.size
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = retangulo
	consulta.transform = Transform2D(0.0, ponto + local.get_center())
	consulta.collision_mask = 1 << (TestWorld.WORLD_STATIC_LAYER - 1)
	consulta.collide_with_areas = false
	return _target.get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func _medir_faixa_de_chao() -> Rect2:
	if _faixa_de_chao.size != Vector2.ZERO:
		return _faixa_de_chao
	var modelo := data.effect_scene.instantiate() as Node2D
	var hitbox := modelo.get_node_or_null("Hitbox") as Node2D
	var forma := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D if hitbox else null
	if forma != null and forma.shape != null:
		var t := hitbox.transform * forma.transform
		var r := forma.shape.get_rect()
		var pontos := [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]
		var caixa := Rect2(t * pontos[0], Vector2.ZERO)
		for p in pontos:
			caixa = caixa.expand(t * p)
		_faixa_de_chao = caixa
	modelo.free()
	return _faixa_de_chao


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
			return _target.global_position + data.spawn_offset


## Para onde o ataque aponta. `Vector2.ZERO` significa "não aponta".
func _aim_direction(alvo: Node2D, origem: Vector2) -> Vector2:
	match data.aim_mode:
		WeaponData.Aim.PARA_O_ALVO:
			# Mira no inimigo na mesma altura de onde o golpe sai: o orbe nasce na
			# altura do cajado e cruza o corpo do alvo, e não o chão aos pés dele.
			return (alvo.global_position + data.spawn_offset - origem).normalized()
		WeaponData.Aim.HORIZONTAL:
			# Nunca na diagonal: o alvo só decide o lado.
			return Vector2.LEFT if alvo.global_position.x < origem.x else Vector2.RIGHT
		_:
			return Vector2.ZERO
