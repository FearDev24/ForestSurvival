extends Node2D
## Raiz da partida.
##
## Nesta fase é apenas o ponto de composição: liga a área de protótipo à câmera
## do Player, para que nem o Player conheça o mapa nem o mapa alcance dentro do
## Player.
##
## Não é um manager e não guarda estado de jogo: só liga as pontas. O
## `SpawnManager` recebe daqui o alvo, o container e os limites do mundo, em vez
## de procurar qualquer um dos três sozinho.
##
## Desde a FASE 9 o estado da partida — e o relógio — moram no `GameManager`.
## Esta cena voltou a ser só o ponto de composição que sempre quis ser.

@onready var _test_world: TestWorld = $World/TestWorld
@onready var _player: Player = $Player
@onready var _enemy_container: Node2D = $EnemyContainer
@onready var _effect_container: Node2D = $EffectContainer
@onready var _spawn_manager: SpawnManager = $SpawnManager
@onready var _wave_manager: WaveManager = $WaveManager
## As armas moram dentro do Player (`docs/02_ARCHITECTURE.md`), mas quem as liga
## ao mundo é esta cena: o Player não conhece o container de inimigos nem o de
## efeitos, e não deve conhecer.
@onready var _weapons: WeaponManager = $Player/WeaponManager
@onready var _pickup_container: Node2D = $PickupContainer
@onready var _pickup_spawner: PickupSpawner = $PickupSpawner
@onready var _level: LevelComponent = $Player/Level
@onready var _player_health: HealthComponent = $Player/Health
@onready var _stats: StatComponent = $Player/Stats
@onready var _upgrade_pool: UpgradePool = $UpgradePool
@onready var _pickup_area: PickupArea = $Player/PickupArea
@onready var _hud: Hud = $Hud
@onready var _level_up_menu: CanvasLayer = $LevelUpMenu
@onready var _game_manager: GameManager = $GameManager
@onready var _pause_menu: CanvasLayer = $PauseMenu
@onready var _result_screen: CanvasLayer = $ResultScreen


func _ready() -> void:
	# `_ready` dos filhos roda antes do `_ready` do pai, então a câmera do
	# Player já existe aqui.
	var bounds := _test_world.get_bounds()
	# A câmera enxerga além da área jogável, até onde vai a vegetação que fecha o
	# mapa; o spawn fica restrito ao jogável, para não nascer inimigo na parede.
	_player.apply_camera_limits(_test_world.get_camera_bounds())
	_spawn_manager.configure(_player, _enemy_container, bounds)
	_wave_manager.configure(_spawn_manager)
	_weapons.configure(_player, _enemy_container, _effect_container, _stats)
	_pickup_spawner.configure(_spawn_manager, _pickup_container)
	# A trilha começa com a partida e fica; trocar de cena para o menu e voltar
	# não a reinicia, porque o `Audio` ignora pedido da faixa que já toca.
	Audio.musica(Audio.TRILHA)
	_pickup_area.collected.connect(_level.add_xp)
	# Os dois sons que o Game tem na mão. Combate é mudo por decisão do jogador:
	# nem arma, nem morte de criatura, nem dano no druida.
	_pickup_area.collected.connect(func(_valor: float) -> void: Audio.tocar(&"coleta_orbe"))
	_level.leveled_up.connect(func(_nivel: int) -> void: Audio.tocar(&"nivel"))
	_upgrade_pool.configure(_stats, _weapons, _game_manager)
	_level_up_menu.configure(_upgrade_pool, _level)
	_hud.configure(_player_health, _level)
	# O botão de pausa por toque (FASE 12) pede, e o manager decide: ele segue
	# sendo o único que mexe na pausa.
	_hud.pausa_pedida.connect(_game_manager.pausar)
	_game_manager.configure(_player, _spawn_manager, _wave_manager, _weapons,
		_level, _level_up_menu, _enemy_container, _pickup_container)
	_pause_menu.configure(_game_manager)
	_result_screen.configure(_game_manager)

	# Só em build de depuração num aparelho móvel (FASE 12): mede a partida e
	# escreve no log, lido pelo `adb logcat`. No PC e nos testes nem existe.
	if MonitorDesempenho.deve_rodar():
		var monitor := MonitorDesempenho.new()
		monitor.name = "MonitorDesempenho"
		monitor.configure(_enemy_container, _pickup_container, _game_manager)
		add_child(monitor)


## O relógio é do `GameManager`; esta cena só o repassa ao HUD.
##
## O HUD continua sem saber o que é uma partida: ele recebe segundos e desenha.
func _physics_process(_delta: float) -> void:
	_hud.set_time(_game_manager.get_elapsed())
