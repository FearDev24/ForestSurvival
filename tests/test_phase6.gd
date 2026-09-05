extends SceneTree
## Verificação da FASE 6 — Sistema de upgrades.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase6.gd
##
## Por enquanto cobre só o primeiro item da fase: o `StatComponent`
## (`docs/03_SYSTEMS.md` §14) e as três bases que já migraram para ele —
## velocidade, vida máxima e alcance de coleta. `UpgradeData`, passivas em
## `Resource` e a validação de opções entram aqui conforme forem feitas.

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
		print("FASE 6 (parcial) OK — StatComponent soma bônus e velocidade, vida e coleta obedecem.")
		return
	printerr("FASE 6 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
