extends Node2D
## Raiz da partida.
##
## Nesta fase é apenas o ponto de composição: liga a área de protótipo à câmera
## do Player, para que nem o Player conheça o mapa nem o mapa alcance dentro do
## Player.
##
## Não é um manager e não guarda estado de jogo. GameManager, SpawnManager e
## WaveManager entram nas fases previstas em `docs/ROADMAP.md`.

@onready var _test_world: TestWorld = $World/TestWorld
@onready var _player: Player = $Player


func _ready() -> void:
	# `_ready` dos filhos roda antes do `_ready` do pai, então a câmera do
	# Player já existe aqui.
	_player.apply_camera_limits(_test_world.get_bounds())
