extends SceneTree
## Verificação da FASE 6 — Sistema de upgrades.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase6.gd
##
## Cobre o `StatComponent` (`docs/03_SYSTEMS.md` §14) com as três bases que
## passam por ele — velocidade, vida máxima e alcance de coleta —, o catálogo
## de `UpgradeData` e a validação de opções da §13.
##
## Cobre também as seis passivas da primeira lista do `docs/04_CONTENT_PLAN.md`:
## as três do Player (vida, velocidade, coleta), as duas que passam pela arma
## (dano/cooldown e área) e a regeneração no `HealthComponent`.

const PLAYER_SCENE := "res://scenes/player/player.tscn"

var _failures: Array[String] = []

var _player: Node2D = null
var _stats: StatComponent = null
var _health: HealthComponent = null
var _pickup: PickupArea = null

var _stage := 0
var _frames_left := 0
var _velocidade_base := 0.0
var _vida_base := 0.0
var _raio_base := 0.0


func _initialize() -> void:
	_check_conta()
	_check_piso()
	_check_sinal()
	_check_arma()
	_check_regeneracao()
	_check_catalogo()

	if not _build_player():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_sem_bonus()
				_start_bonus()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_bonus()
				_start_recalculo()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_recalculo()
				_finish()
				return true
	return false


# --------------------------------------------------------------------- conta --


## `efetivo = (base + plano) * (1 + percentual)`, e os percentuais somam entre si.
func _check_conta() -> void:
	var stats := StatComponent.new()
	var stat := StatComponent.Stat.MOVE_SPEED

	if not is_equal_approx(stats.apply(stat, 200.0), 200.0):
		_fail("Sem bônus, o stat deveria devolver a base: %.2f" % stats.apply(stat, 200.0))
	if not stats.is_untouched(stat):
		_fail("Um stat recém-criado deveria estar intocado")

	stats.add_flat(stat, 20.0)
	if not is_equal_approx(stats.apply(stat, 200.0), 220.0):
		_fail("+20 plano sobre 200 deveria dar 220: %.2f" % stats.apply(stat, 200.0))

	# O plano soma antes do percentual: (200 + 20) * 1.1 = 242, e não 200*1.1+20.
	stats.add_mult(stat, 0.1)
	if not is_equal_approx(stats.apply(stat, 200.0), 242.0):
		_fail("Plano deveria somar antes do percentual: %.2f, esperado 242" % stats.apply(stat, 200.0))

	# Dois percentuais somam entre si: +10% e +10% dão +20%, não +21%.
	stats.add_mult(stat, 0.1)
	if not is_equal_approx(stats.apply(stat, 200.0), 264.0):
		_fail("Percentuais deveriam somar entre si: %.2f, esperado 264" % stats.apply(stat, 200.0))

	if stats.is_untouched(stat):
		_fail("O stat recebeu bônus e ainda se diz intocado")
	if not stats.is_untouched(StatComponent.Stat.DAMAGE):
		_fail("Mexer em MOVE_SPEED não deveria sujar DAMAGE")

	# Bônus zerado não é bônus.
	var antes := stats.apply(stat, 200.0)
	stats.add_flat(stat, 0.0)
	stats.add_mult(stat, 0.0)
	if not is_equal_approx(stats.apply(stat, 200.0), antes):
		_fail("Somar zero mudou o resultado")

	stats.free()


## Redução percentual não pode zerar nem inverter o valor: cooldown zero faria a
## arma disparar todo frame, cooldown negativo é pior ainda.
func _check_piso() -> void:
	var stats := StatComponent.new()
	var stat := StatComponent.Stat.COOLDOWN

	stats.add_mult(stat, -3.0)
	var resultado := stats.apply(stat, 1.5)
	if resultado <= 0.0:
		_fail("Redução exagerada zerou ou inverteu o stat: %.4f" % resultado)
	if resultado > 1.5:
		_fail("Redução não deveria aumentar o stat: %.4f" % resultado)

	stats.free()


## Quem depende de stat precisa ser avisado; o componente não recalcula nada
## por ninguém.
func _check_sinal() -> void:
	var stats := StatComponent.new()
	var recebidos: Array[int] = []
	stats.stat_changed.connect(func(stat: StatComponent.Stat) -> void: recebidos.append(stat))

	stats.add_flat(StatComponent.Stat.MAX_HEALTH, 10.0)
	stats.add_mult(StatComponent.Stat.AREA, 0.2)
	stats.add_flat(StatComponent.Stat.AREA, 0.0)  # não avisa: não mudou nada

	if recebidos.size() != 2:
		_fail("Esperava 2 avisos de mudança, vieram %d" % recebidos.size())
	elif recebidos[0] != StatComponent.Stat.MAX_HEALTH or recebidos[1] != StatComponent.Stat.AREA:
		_fail("Os avisos vieram com o stat errado: %s" % str(recebidos))

	stats.free()


# --------------------------------------------------------------------- arma --


## Dano, cooldown e área saem do `WeaponData` **passados pelo StatComponent**.
##
## Lidos a cada disparo, não guardados: uma passiva escolhida no meio da partida
## precisa valer no tiro seguinte, sem ninguém avisar a arma.
func _check_arma() -> void:
	var data := load("res://resources/weapons/cajado_raio.tres") as WeaponData
	if data == null:
		_fail("cajado_raio.tres não carregou como WeaponData")
		return

	var arma := Weapon.new()
	arma.data = data
	arma.level = 1
	root.add_child(arma)

	# Sem StatComponent, a arma continua funcionando com os números crus.
	if not is_equal_approx(arma.damage_efetivo(), data.damage_at(1)):
		_fail("Sem stats, o dano deveria ser o do WeaponData: %.2f" % arma.damage_efetivo())
	if not is_equal_approx(arma.area_efetiva(), 1.0):
		_fail("Sem stats, a área deveria ser 1.0: %.2f" % arma.area_efetiva())

	var stats := StatComponent.new()
	root.add_child(stats)
	arma.stats = stats

	stats.add_mult(StatComponent.Stat.DAMAGE, 0.5)
	if not is_equal_approx(arma.damage_efetivo(), data.damage_at(1) * 1.5):
		_fail("+50%% de dano: esperado %.2f, veio %.2f"
			% [data.damage_at(1) * 1.5, arma.damage_efetivo()])

	stats.add_mult(StatComponent.Stat.COOLDOWN, -0.25)
	if not is_equal_approx(arma.cooldown_efetivo(), data.cooldown_at(1) * 0.75):
		_fail("-25%% de cooldown: esperado %.3f, veio %.3f"
			% [data.cooldown_at(1) * 0.75, arma.cooldown_efetivo()])

	stats.add_mult(StatComponent.Stat.AREA, 0.15)
	if not is_equal_approx(arma.area_efetiva(), 1.15):
		_fail("+15%% de área: esperado 1.15, veio %.3f" % arma.area_efetiva())

	# Nível da arma e passiva se compõem, não se substituem.
	arma.level = 3
	var esperado := data.damage_at(3) * 1.5
	if not is_equal_approx(arma.damage_efetivo(), esperado):
		_fail("Nível 3 com +50%% de dano: esperado %.2f, veio %.2f" % [esperado, arma.damage_efetivo()])

	arma.free()
	stats.free()


# ------------------------------------------------------------- regeneração --


## O `HealthComponent` só processa quando tem o que regenerar. É o que impede
## uma horda de duzentos inimigos de rodar duzentos `_process` inúteis.
func _check_regeneracao() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	root.add_child(health)

	# Atribuir explicitamente, e não confiar no `_ready`: nó acrescentado à
	# árvore de dentro de `SceneTree._initialize()` não dispara `_ready`, e a
	# primeira versão deste teste passava sem verificar nada por causa disso.
	health.regeneration = 0.0
	if health.is_processing():
		_fail("Vida sem regeneração não deveria processar nada")

	health.damage(50.0)
	health.regeneration = 30.0
	if not health.is_processing():
		_fail("Com regeneração, o componente deveria processar")

	# Um passo curto não fecha um ponto de vida inteiro: nada muda ainda.
	health._process(0.01)
	if not is_equal_approx(health.current_health, 50.0):
		_fail("0,3 de vida acumulada não deveria virar cura: %.2f" % health.current_health)

	health._process(1.0)
	if not is_equal_approx(health.current_health, 80.0):
		_fail("Um segundo a 30/s deveria curar 30: %.2f" % health.current_health)

	# Não passa do máximo.
	health._process(5.0)
	if health.current_health > health.max_health:
		_fail("Regeneração passou do máximo: %.2f" % health.current_health)

	# Zerar a regeneração desliga o processamento de volta.
	health.regeneration = 0.0
	if health.is_processing():
		_fail("Zerar a regeneração deveria desligar o processamento")

	# Morto não volta. Quem garante é o `heal()`, não o tique — vale testar
	# pelo efeito, porque é o efeito que o jogo precisa.
	var morto := HealthComponent.new()
	morto.max_health = 10.0
	root.add_child(morto)
	morto.regeneration = 100.0
	morto.damage(20.0)
	morto._process(1.0)
	morto.heal(50.0)
	if morto.current_health > 0.0:
		_fail("Quem morreu voltou a ganhar vida: %.2f" % morto.current_health)
	if not morto.is_dead():
		_fail("O componente deixou de se considerar morto")

	health.free()
	morto.free()


# ----------------------------------------------------------------- catálogo --


const CATALOGO := "res://resources/upgrades/"


## As opções são dados, não código: cada uma é um `.tres` válido.
func _check_recursos() -> Array[UpgradeData]:
	var lista: Array[UpgradeData] = []
	var dir := DirAccess.open(CATALOGO)
	if dir == null:
		_fail("Pasta de upgrades não encontrada em %s" % CATALOGO)
		return lista

	for arquivo in dir.get_files():
		if not arquivo.ends_with(".tres"):
			continue
		var upgrade := load(CATALOGO + arquivo) as UpgradeData
		if upgrade == null:
			_fail("%s não carregou como UpgradeData" % arquivo)
			continue
		if not upgrade.is_valid():
			_fail("%s é um UpgradeData inválido (sem id, sem efeito ou sem arma)" % arquivo)
		lista.append(upgrade)

	if lista.size() < 8:
		_fail("Esperava ao menos 8 opções no catálogo, achei %d" % lista.size())
	return lista


## O catálogo não pode oferecer o que não muda nada (§13), nem repetir opção na
## mesma tela.
func _check_catalogo() -> void:
	var lista := _check_recursos()
	if lista.is_empty():
		return

	var ids := {}
	for upgrade in lista:
		if ids.has(upgrade.id):
			_fail("Dois upgrades com o mesmo id: %s" % upgrade.id)
		ids[upgrade.id] = true

	var pool := UpgradePool.new()
	pool.catalogo = lista
	pool.set_seed(1234)
	root.add_child(pool)

	var stats := StatComponent.new()
	root.add_child(stats)
	var weapons := WeaponManager.new()
	root.add_child(weapons)
	pool.configure(stats, weapons)

	var oferta := pool.sortear(3)
	if oferta.size() != 3:
		_fail("Com o catálogo cheio, a tela deveria oferecer 3 opções, ofereceu %d" % oferta.size())
	var vistos := {}
	for upgrade in oferta:
		if vistos.has(upgrade.id):
			_fail("A mesma opção apareceu duas vezes na mesma tela: %s" % upgrade.id)
		vistos[upgrade.id] = true

	var passiva: UpgradeData = null
	var arma: UpgradeData = null
	for upgrade in lista:
		if passiva == null and upgrade.kind == UpgradeData.Kind.PASSIVA:
			passiva = upgrade
		if arma == null and upgrade.kind == UpgradeData.Kind.ARMA:
			arma = upgrade

	if passiva == null:
		_fail("Nenhuma passiva no catálogo")
	else:
		var antes := stats.apply(passiva.stat, 100.0)
		if not pool.apply(passiva.id):
			_fail("Aplicar %s falhou" % passiva.id)
		if is_equal_approx(stats.apply(passiva.stat, 100.0), antes):
			_fail("%s não mexeu no stat: %.2f antes e depois" % [passiva.id, antes])
		if pool.stacks(passiva.id) != 1:
			_fail("Contador de repetição não subiu: %d" % pool.stacks(passiva.id))

		# Guarda contra laço infinito: se o teto deixar de valer, este teste
		# rodaria para sempre em vez de falhar. Mesmo princípio do
		# `_MAX_NIVEIS_POR_GANHO` no `LevelComponent`.
		var voltas := 0
		while pool.stacks(passiva.id) < passiva.max_stacks and voltas < 100:
			pool.apply(passiva.id)
			voltas += 1
		if voltas >= 100:
			_fail("%s: 100 escolhas e o contador não chegou ao teto de %d (está em %d)"
				% [passiva.id, passiva.max_stacks, pool.stacks(passiva.id)])
		if pool.is_applicable(passiva):
			_fail("%s continuou oferecível depois de %d escolhas" % [passiva.id, passiva.max_stacks])
		if pool.apply(passiva.id):
			_fail("%s foi aplicada acima do teto" % passiva.id)

	if arma == null:
		_fail("Nenhuma arma no catálogo")
	else:
		weapons.max_slots = 0
		if pool.is_applicable(arma):
			_fail("%s foi oferecida sem slot livre" % arma.id)
		weapons.max_slots = 6
		if not pool.is_applicable(arma):
			_fail("%s deveria ser oferecível com slot livre" % arma.id)

	# Catálogo esgotado: a tela não tem o que oferecer.
	weapons.max_slots = 0
	for upgrade in lista:
		if upgrade.kind != UpgradeData.Kind.PASSIVA:
			continue
		var voltas := 0
		while pool.apply(upgrade.id) and voltas < 100:
			voltas += 1
		if voltas >= 100:
			_fail("%s aceitou 100 escolhas seguidas: o teto não está valendo" % upgrade.id)
	if not pool.sortear(3).is_empty():
		_fail("Com tudo no teto, o sorteio ainda devolveu opções")

	pool.free()
	stats.free()
	weapons.free()


# ------------------------------------------------------------------- player --


func _build_player() -> bool:
	if not ResourceLoader.exists(PLAYER_SCENE):
		_fail("player.tscn não encontrada")
		return false

	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Node2D
	root.add_child(_player)

	_stats = _player.get_node_or_null("Stats") as StatComponent
	_health = _player.get_node_or_null("Health") as HealthComponent
	_pickup = _player.get_node_or_null("PickupArea") as PickupArea

	if _stats == null:
		_fail("Player sem StatComponent em 'Stats'")
		return false
	if _health == null or _pickup == null:
		_fail("Player sem Health ou PickupArea")
		return false

	_velocidade_base = _player.move_speed
	_vida_base = _health.max_health
	_raio_base = _pickup.get_radius()

	_frames_left = 2
	_stage = 0
	return true


## Sem passiva nenhuma, nada pode ter mudado de valor: o componente entrar na
## cena não é, por si, um bônus.
func _check_sem_bonus() -> void:
	if not is_equal_approx(_velocidade_efetiva(), _velocidade_base):
		_fail("Sem bônus, a velocidade deveria ser a base %.1f, é %.1f"
			% [_velocidade_base, _velocidade_efetiva()])
	if not is_equal_approx(_health.max_health, _vida_base):
		_fail("Sem bônus, a vida máxima deveria ser %.1f, é %.1f" % [_vida_base, _health.max_health])
	if not is_equal_approx(_pickup.get_radius(), _raio_base):
		_fail("Sem bônus, o raio de coleta deveria ser %.1f, é %.1f"
			% [_raio_base, _pickup.get_radius()])


## As três passivas que já têm onde bater: Passos do Cervo, Casca de Carvalho e
## Essência Viva (`docs/04_CONTENT_PLAN.md`).
func _start_bonus() -> void:
	_health.damage(_vida_base * 0.5)  # meia vida, para ver se o ganho de máximo cura

	_stats.add_mult(StatComponent.Stat.MOVE_SPEED, 0.15)
	_stats.add_flat(StatComponent.Stat.MAX_HEALTH, 50.0)
	_stats.add_mult(StatComponent.Stat.PICKUP_RADIUS, 0.5)

	_frames_left = 2
	_stage = 1


func _check_bonus() -> void:
	var esperado_vel := _velocidade_base * 1.15
	if not is_equal_approx(_velocidade_efetiva(), esperado_vel):
		_fail("+15%% de velocidade: esperado %.2f, veio %.2f" % [esperado_vel, _velocidade_efetiva()])

	if not is_equal_approx(_health.max_health, _vida_base + 50.0):
		_fail("+50 de vida máxima: esperado %.1f, veio %.1f" % [_vida_base + 50.0, _health.max_health])

	# Ganhar vida máxima cura o mesmo tanto: estava em metade, sobe 50.
	var esperado_atual := _vida_base * 0.5 + 50.0
	if not is_equal_approx(_health.current_health, esperado_atual):
		_fail("Ganhar vida máxima deveria curar o mesmo tanto: esperado %.1f, veio %.1f"
			% [esperado_atual, _health.current_health])

	var esperado_raio := _raio_base * 1.5
	if not is_equal_approx(_pickup.get_radius(), esperado_raio):
		_fail("+50%% de coleta: esperado %.1f, veio %.1f" % [esperado_raio, _pickup.get_radius()])


## Duas passivas iguais não podem compor sobre o resultado da primeira: a base
## da conta é sempre o valor original, nunca o já modificado.
func _start_recalculo() -> void:
	_stats.add_flat(StatComponent.Stat.MAX_HEALTH, 50.0)
	_frames_left = 2
	_stage = 2


func _check_recalculo() -> void:
	if not is_equal_approx(_health.max_health, _vida_base + 100.0):
		_fail("Dois bônus de +50 deveriam dar base+100 (%.1f), deram %.1f"
			% [_vida_base + 100.0, _health.max_health])

	# A velocidade não recebeu bônus novo; recalcular não pode tê-la mudado.
	if not is_equal_approx(_velocidade_efetiva(), _velocidade_base * 1.15):
		_fail("Recalcular mudou um stat que não recebeu bônus: velocidade em %.2f"
			% _velocidade_efetiva())


## O que o movimento usa de verdade, e não a conta refeita aqui: refazer a conta
## no teste provaria só que o `StatComponent` sabe multiplicar, não que o Player
## chegou a perguntar.
func _velocidade_efetiva() -> float:
	return _player.get_move_speed()


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	if _player != null:
		_player.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 6 OK — seis passivas, catálogo em dados e nada impossível oferecido.")
		return
	printerr("FASE 6 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
