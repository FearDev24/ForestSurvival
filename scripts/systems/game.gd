extends Node2D
## Raiz da partida.
##
## Nesta fase é apenas o ponto de composição: liga a área de protótipo à câmera
## do Player, para que nem o Player conheça o mapa nem o mapa alcance dentro do
## Player.
##
## Não é um manager e não guarda estado de jogo: só liga as pontas. O
## `SpawnManager` recebe daqui o alvo, o container e os limites do mundo, em vez
## de procurar qualquer um dos três sozinho. GameManager e WaveManager entram nas
## fases previstas em `docs/ROADMAP.md`.

@onready var _test_world: TestWorld = $World/TestWorld
@onready var _player: Player = $Player
@onready var _enemy_container: Node2D = $EnemyContainer
@onready var _spawn_manager: SpawnManager = $SpawnManager


func _ready() -> void:
	# `_ready` dos filhos roda antes do `_ready` do pai, então a câmera do
	# Player já existe aqui.
	var bounds := _test_world.get_bounds()
	_player.apply_camera_limits(bounds)
	_spawn_manager.configure(_player, _enemy_container, bounds)
