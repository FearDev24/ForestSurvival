class_name WaveManager
extends Node
## Tabela de waves da partida (`docs/03_SYSTEMS.md` §7).
##
## Responsabilidades: tempo, tabela, tipos disponíveis, frequência, elites e
## boss.
##
## A divisão com o `SpawnManager` segue a que a §6 e a §7 já pediam:
##
## | Quem | Decide |
## |---|---|
## | `WaveManager` | **quem** nasce e **quando** |
## | `SpawnManager` | **onde** nasce e **se cabe** |
##
## Enquanto este nó existir, a rampa linear do `SpawnManager` fica desligada —
## dois relógios mandando na mesma horda dariam dificuldade que ninguém escreveu.

## Emitido quando a partida entra numa wave nova.
signal wave_started(index: int, data: WaveData)

## Emitido a cada elite criado.
signal elite_spawned(enemy: Node2D)

## Emitido quando o boss nasce. A condição de vitória da FASE 9 se pendura aqui.
signal boss_spawned(enemy: Node2D)

## As waves da partida. Podem vir em qualquer ordem: são ordenadas por
## `start_time` no `configure()`.
@export var waves: Array[WaveData] = []

## Liga e desliga a progressão. O game over da FASE 9 usa isto, e os testes
## também.
##
## Desligar **devolve a rampa ao `SpawnManager`**. Se não devolvesse, um wave
## desligado calaria os dois relógios e a partida ficaria sem inimigo nenhum —
## que é pior que qualquer um dos dois mandando sozinho.
var enabled: bool = true:
	set(value):
		enabled = value
		if _spawn != null:
			_spawn.driven_by_waves = value

var _spawn: SpawnManager = null
var _elapsed := 0.0
var _time_since_spawn := 0.0
var _time_since_elite := 0.0
var _index := -1
## Ids das waves cujo boss já nasceu. Sem isto, o boss renasceria a cada quadro
## enquanto a wave dele estivesse valendo.
var _bosses_criados: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_physics_process(false)


## Ligado pela raiz da partida, como o `SpawnManager`.
func configure(spawn_manager: SpawnManager) -> void:
	_spawn = spawn_manager
	waves = waves.filter(func(w: WaveData) -> bool: return w != null and w.is_valid())
	waves.sort_custom(func(a: WaveData, b: WaveData) -> bool: return a.start_time < b.start_time)

	if _spawn != null:
		# A rampa própria do SpawnManager sai de cena: quem manda no ritmo
		# agora é a tabela. Só se este nó estiver ligado — ver `enabled`.
		_spawn.driven_by_waves = enabled

	set_physics_process(_spawn != null and not waves.is_empty())


func _physics_process(delta: float) -> void:
	if not enabled or _spawn == null:
		return

	_elapsed += delta
	_atualizar_wave()

	var wave := get_current_wave()
	if wave == null:
		return

	_time_since_spawn += delta
	if _time_since_spawn >= wave.spawn_interval:
		_time_since_spawn = 0.0
		_tentar_nascer(wave)

	if wave.elite != null and wave.elite_interval > 0.0:
		_time_since_elite += delta
		if _time_since_elite >= wave.elite_interval:
			_time_since_elite = 0.0
			var elite := _spawn.spawn_data(wave.elite)
			if elite != null:
				elite_spawned.emit(elite)


## Segundos decorridos de partida, do ponto de vista das waves.
func get_elapsed() -> float:
	return _elapsed


## Índice da wave atual, ou -1 antes da primeira.
##
## Não se chama `get_index()`: esse nome já é do `Node`, e sobrescrevê-lo faria
## a engine chamar o método errado sem avisar.
func get_wave_index() -> int:
	return _index


func get_current_wave() -> WaveData:
	return waves[_index] if _index >= 0 and _index < waves.size() else null


## Avança para a última wave cujo `start_time` já passou.
##
## Percorre em vez de somar um: uma partida que ficasse pausada por muito tempo,
## ou um teste que salte no relógio, pode atravessar duas waves de uma vez.
func _atualizar_wave() -> void:
	var alvo := _index
	for i in waves.size():
		if _elapsed >= waves[i].start_time:
			alvo = i
	if alvo == _index:
		return

	_index = alvo
	var wave := get_current_wave()
	_time_since_spawn = 0.0
	_time_since_elite = 0.0
	if wave.trilha != &"":
		Audio.musica(wave.trilha)
	wave_started.emit(_index, wave)

	if wave.burst_on_start > 0:
		for _i in wave.burst_on_start:
			_tentar_nascer(wave)

	# O boss ignora o teto de população: uma horda cheia não pode impedir o
	# encontro que fecha a partida.
	if wave.boss != null and not _bosses_criados.has(wave.id):
		_bosses_criados[wave.id] = true
		var boss := _spawn.spawn_data(wave.boss)
		if boss != null:
			boss_spawned.emit(boss)


## Um nascimento comum, respeitando o teto da wave.
##
## O teto é da wave, mas quem sabe quantos estão vivos é o `SpawnManager` — a
## contagem é `get_child_count()` do container, que custa O(1) (DEC-011).
func _tentar_nascer(wave: WaveData) -> void:
	if _spawn.get_population() >= wave.population_cap:
		return
	var tipo := wave.sortear(_rng)
	if tipo != null:
		_spawn.spawn_data(tipo)


## Semente fixa, para teste: sem isso o sorteio de tipo mudaria a cada execução.
func set_seed(valor: int) -> void:
	_rng.seed = valor
