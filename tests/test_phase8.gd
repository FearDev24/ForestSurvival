extends SceneTree
## Verificação da FASE 8 — Waves.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase8.gd
##
## Cobre a tabela em `Resource` (`docs/03_SYSTEMS.md` §7), os tipos de inimigo
## em `EnemyData`, o elite, o boss e a divisão de trabalho entre o `WaveManager`
## e o `SpawnManager`: um decide **quem e quando**, o outro **onde e se cabe**.
##
## Não julga se a partida está divertida. Julga se o arco existe e obedece ao
## que os `.tres` dizem.

const INIMIGOS := "res://resources/enemies/"
const WAVES := "res://resources/waves/"

var _failures: Array[String] = []

var _game: Node = null
var _waves: WaveManager = null
var _spawn: SpawnManager = null
var _container: Node = null

var _stage := 0
var _frames_left := 0
var _wave_avisadas: Array[int] = []
var _bosses := 0
var _elites := 0


func _initialize() -> void:
	_check_tipos()
	_check_tabela()
	_check_progressao_isolada()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_wave_inicial()
				_start_salto()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_salto()
				_finish()
				return true
	return false


# ------------------------------------------------------------------- tipos --


## Os tipos são dados, não código, e precisam ser **sensivelmente diferentes**
## entre si — três `.tres` com os mesmos números não seriam três inimigos.
func _check_tipos() -> void:
	var dir := DirAccess.open(INIMIGOS)
	if dir == null:
		_fail("Pasta de inimigos não encontrada em %s" % INIMIGOS)
		return

	var lista: Array[EnemyData] = []
	for arquivo in dir.get_files():
		if not arquivo.ends_with(".tres"):
			continue
		var tipo := load(INIMIGOS + arquivo) as EnemyData
		if tipo == null:
			_fail("%s não carregou como EnemyData" % arquivo)
			continue
		if not tipo.is_valid():
			_fail("%s é um EnemyData inválido" % arquivo)
		lista.append(tipo)

	if lista.size() < 5:
		_fail("Esperava ao menos 5 tipos (3 comuns, elite e boss), achei %d" % lista.size())
		return

	var ids := {}
	var vidas := {}
	for tipo in lista:
		if ids.has(tipo.id):
			_fail("Dois tipos com o mesmo id: %s" % tipo.id)
		ids[tipo.id] = true
		vidas[snappedf(tipo.max_health, 0.1)] = true
		if tipo.xp_value <= 0.0:
			_fail("%s não larga XP: %.1f" % [tipo.id, tipo.xp_value])

	if vidas.size() < lista.size():
		_fail("Há tipos com a mesma vida: um inimigo novo precisa ser sensivelmente diferente")

	# O elite e o boss precisam justificar o nome.
	var comum := load(INIMIGOS + "imp_corrompido.tres") as EnemyData
	var elite := load(INIMIGOS + "elite_corrompida.tres") as EnemyData
	var boss := load(INIMIGOS + "guardiao_profanado.tres") as EnemyData
	if comum == null or elite == null or boss == null:
		_fail("Faltando imp, elite ou boss")
		return
	if elite.max_health <= comum.max_health * 3.0:
		_fail("Elite com %.0f de vida contra %.0f do comum: pouco" % [elite.max_health, comum.max_health])
	if elite.xp_value <= comum.xp_value * 3.0:
		_fail("Elite deveria largar bem mais XP: %.1f contra %.1f" % [elite.xp_value, comum.xp_value])
	if boss.max_health <= elite.max_health * 3.0:
		_fail("Boss com %.0f de vida contra %.0f do elite: pouco" % [boss.max_health, elite.max_health])


# ------------------------------------------------------------------ tabela --


func _check_tabela() -> void:
	var dir := DirAccess.open(WAVES)
	if dir == null:
		_fail("Pasta de waves não encontrada em %s" % WAVES)
		return

	var lista: Array[WaveData] = []
	for arquivo in dir.get_files():
		if not arquivo.ends_with(".tres"):
			continue
		var wave := load(WAVES + arquivo) as WaveData
		if wave == null:
			_fail("%s não carregou como WaveData" % arquivo)
			continue
		if not wave.is_valid():
			_fail("%s é uma WaveData inválida" % arquivo)
		lista.append(wave)

	if lista.size() < 4:
		_fail("Esperava ao menos 4 waves, achei %d" % lista.size())
		return

	lista.sort_custom(func(a: WaveData, b: WaveData) -> bool: return a.start_time < b.start_time)

	if not is_zero_approx(lista[0].start_time):
		_fail("A primeira wave deveria começar em 0 s, começa em %.1f" % lista[0].start_time)

	# O arco tem de subir: mais denso e mais gente ao longo da partida.
	for i in range(1, lista.size()):
		if lista[i].start_time <= lista[i - 1].start_time:
			_fail("Duas waves começam no mesmo instante: %s e %s" % [lista[i - 1].id, lista[i].id])
	if lista[-1].population_cap <= lista[0].population_cap:
		_fail("O teto de população não cresce: %d no fim contra %d no começo"
			% [lista[-1].population_cap, lista[0].population_cap])

	# O teto de 200 saiu de medição: 250 já custam 14,03 ms contra 16,6 de
	# orçamento por quadro. Nenhuma wave pode passar disso.
	for wave in lista:
		if wave.population_cap > 200:
			_fail("%s pede %d inimigos, acima do teto medido de 200" % [wave.id, wave.population_cap])

	var com_boss := lista.filter(func(w: WaveData) -> bool: return w.boss != null)
	if com_boss.is_empty():
		_fail("Nenhuma wave tem boss")
	elif com_boss.size() > 1:
		_fail("Mais de uma wave com boss: %d" % com_boss.size())


## A progressão, sem cena de partida: a wave certa para cada instante.
##
## `_atualizar_wave()` percorre a tabela em vez de somar um, porque um salto no
## relógio — pausa longa, ou um teste como este — pode atravessar duas waves de
## uma vez.
func _check_progressao_isolada() -> void:
	var manager := WaveManager.new()
	var tabela: Array[WaveData] = []
	for nome in ["wave_1_chegada", "wave_2_matilha", "wave_3_brutos", "wave_4_cerco", "wave_5_guardiao"]:
		var w := load(WAVES + nome + ".tres") as WaveData
		if w != null:
			tabela.append(w)
	if tabela.size() < 5:
		_fail("Não consegui carregar as cinco waves")
		return

	# De trás para a frente, para provar que `configure()` ordena.
	tabela.reverse()
	manager.waves = tabela
	manager.set_seed(99)
	root.add_child(manager)

	var spawn := SpawnManager.new()
	root.add_child(spawn)
	manager.configure(spawn)

	if manager.waves[0].start_time > manager.waves[-1].start_time:
		_fail("configure() não ordenou a tabela por start_time")
	if not spawn.driven_by_waves:
		_fail("O WaveManager não assumiu o ritmo do SpawnManager")

	if manager.get_wave_index() != -1:
		_fail("Antes do primeiro quadro não deveria haver wave: %d" % manager.get_wave_index())

	# Sem alvo nem container, nada nasce — mas o relógio anda igual.
	manager._physics_process(0.1)
	if manager.get_wave_index() != 0:
		_fail("No instante zero deveria valer a primeira wave, vale %d" % manager.get_wave_index())

	manager._physics_process(300.0)
	var atual := manager.get_current_wave()
	if atual == null or atual.id != &"wave_4_cerco":
		_fail("Aos 300 s deveria valer a wave_4_cerco, vale %s" % (atual.id if atual else "nenhuma"))

	# Desligar devolve a rampa ao SpawnManager, em vez de calar os dois.
	manager.enabled = false
	if spawn.driven_by_waves:
		_fail("Wave desligado deveria devolver a rampa ao SpawnManager")

	manager.free()
	spawn.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists("res://scenes/game/game.tscn"):
		_fail("game.tscn não encontrada")
		return false

	_game = (load("res://scenes/game/game.tscn") as PackedScene).instantiate()
	root.add_child(_game)

	_waves = _game.get_node_or_null("WaveManager") as WaveManager
	_spawn = _game.get_node_or_null("SpawnManager") as SpawnManager
	_container = _game.get_node_or_null("EnemyContainer")
	if _waves == null or _spawn == null or _container == null:
		_fail("game.tscn sem WaveManager, SpawnManager ou EnemyContainer")
		return false

	# As armas matariam os inimigos no meio da contagem.
	var armas := _game.get_node_or_null("Player/WeaponManager") as WeaponManager
	if armas != null:
		armas.set_weapons_enabled(false)

	_waves.set_seed(4242)
	_waves.wave_started.connect(func(i: int, _d: WaveData) -> void: _wave_avisadas.append(i))
	_waves.boss_spawned.connect(func(_e: Node2D) -> void: _bosses += 1)
	_waves.elite_spawned.connect(func(_e: Node2D) -> void: _elites += 1)

	_frames_left = 90
	_stage = 0
	return true


## Um minuto e meio de partida em quadros: a primeira wave tem de estar
## produzindo inimigos do tipo dela, e só dele.
func _check_wave_inicial() -> void:
	if _wave_avisadas.is_empty() or _wave_avisadas[0] != 0:
		_fail("A primeira wave não foi anunciada: %s" % str(_wave_avisadas))
	if _container.get_child_count() == 0:
		_fail("A primeira wave não criou nenhum inimigo em 90 quadros")
		return

	for filho in _container.get_children():
		var inimigo := filho as Enemy
		if inimigo == null:
			continue
		if inimigo.data == null:
			_fail("Inimigo criado sem EnemyData: os tipos não estão chegando")
			break
		if inimigo.data.id != &"imp_corrompido":
			_fail("A primeira wave só tem imp, mas nasceu %s" % inimigo.data.id)
			break
		# O tipo precisa ter alcançado a vida e o XP do inimigo, não só o nome.
		var vida := inimigo.get_node_or_null("Health") as HealthComponent
		if vida != null and not is_equal_approx(vida.max_health, inimigo.data.max_health):
			_fail("Vida do tipo não chegou ao inimigo: %.1f contra %.1f"
				% [vida.max_health, inimigo.data.max_health])
		if not is_equal_approx(inimigo.xp_value, inimigo.data.xp_value):
			_fail("XP do tipo não chegou ao inimigo: %.1f" % inimigo.xp_value)


## Salta o relógio para a wave do boss e confere que ele nasce **uma vez**.
func _start_salto() -> void:
	_waves._physics_process(430.0)
	_frames_left = 30
	_stage = 1


func _check_salto() -> void:
	var atual := _waves.get_current_wave()
	if atual == null or atual.id != &"wave_5_guardiao":
		_fail("Depois do salto deveria valer a wave do boss, vale %s" % (atual.id if atual else "nenhuma"))
	if _bosses != 1:
		_fail("O boss deveria nascer uma vez, nasceu %d" % _bosses)

	var achou_boss := false
	for filho in _container.get_children():
		var inimigo := filho as Enemy
		if inimigo != null and inimigo.data != null and inimigo.data.id == &"guardiao_profanado":
			achou_boss = true
			var vida := inimigo.get_node_or_null("Health") as HealthComponent
			if vida != null and vida.max_health < 1000.0:
				_fail("Boss com vida de inimigo comum: %.0f" % vida.max_health)
			# O raio de corpo do tipo tem de ter sido aplicado — e sem engordar
			# os outros, porque a forma é sub-recurso compartilhado da cena.
			var forma := inimigo.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var circulo := forma.shape as CircleShape2D if forma else null
			if circulo != null and not is_equal_approx(circulo.radius, inimigo.data.body_radius):
				_fail("Raio do boss não foi aplicado: %.1f" % circulo.radius)
			break
	if not achou_boss:
		_fail("O boss não está na cena")

	# Reentrar na wave do boss não pode fazer nascer outro.
	#
	# Hoje `_atualizar_wave()` só age quando o índice muda, então o caso não
	# acontece sozinho — e por isso o teste força a reentrada. Sem isso a guarda
	# de `_bosses_criados` estaria protegendo algo que nada exercita, e remover
	# a guarda passaria despercebido.
	_waves._index = 0
	_waves._physics_process(0.02)
	if _bosses != 1:
		_fail("Reentrar na wave do boss criou outro: %d ao todo" % _bosses)

	# O sub-recurso é compartilhado: se o boss tivesse mexido na forma sem
	# duplicar, todo diabrete em tela teria engordado junto.
	var comum := load(INIMIGOS + "imp_corrompido.tres") as EnemyData
	for filho in _container.get_children():
		var inimigo := filho as Enemy
		if inimigo == null or inimigo.data == null or inimigo.data.id != &"imp_corrompido":
			continue
		var forma := inimigo.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var circulo := forma.shape as CircleShape2D if forma else null
		if circulo != null and circulo.radius > 20.0:
			_fail("Um imp está com raio %.1f: o boss contaminou a forma compartilhada" % circulo.radius)
		break
	if comum == null:
		_fail("imp_corrompido.tres sumiu")


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 8 OK — tabela em dados, tipos distintos, elite e boss no lugar.")
		return
	printerr("FASE 8 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
