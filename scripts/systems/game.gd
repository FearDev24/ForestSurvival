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
@onready var _effect_container: Node2D = $EffectContainer
@onready var _spawn_manager: SpawnManager = $SpawnManager
@onready var _lightning_caster: LightningCaster = $RaioTeste
@onready var _vine_caster: LightningCaster = $VinhaTeste
@onready var _game_over: Sprite2D = $GameOver
@onready var _restart_button: Button = $CanvasLayer/RestartButton


func _ready() -> void:
	# `_ready` dos filhos roda antes do `_ready` do pai, então a câmera do
	# Player já existe aqui.
	var bounds := _test_world.get_bounds()
	# A câmera enxerga além da área jogável, até onde vai a vegetação que fecha o
	# mapa; o spawn fica restrito ao jogável, para não nascer inimigo na parede.
	_player.apply_camera_limits(_test_world.get_camera_bounds())
	_spawn_manager.configure(_player, _enemy_container, bounds)
	_lightning_caster.configure(_player, _enemy_container, _effect_container)
	_vine_caster.configure(_player, _enemy_container, _effect_container)
	_player.death_finished.connect(_on_player_death_finished)
	_restart_button.pressed.connect(_on_restart_pressed)


## Mostra o game over no lugar exato onde o druida caiu.
##
## Fica em coordenada de mundo, não na `CanvasLayer`: a ideia é marcar o ponto
## da morte, e a câmera já está parada ali junto com o corpo.
##
## Isto é o mínimo para ver a sequência morte -> game over funcionando. A tela
## de verdade — tempo de partida, level alcançado, reiniciar, voltar ao menu —
## é da FASE 9, com o `GameManager` e o estado `GAME_OVER`
## (`docs/03_SYSTEMS.md` §16).
func _on_player_death_finished() -> void:
	_spawn_manager.enabled = false
	_lightning_caster.enabled = false
	_vine_caster.enabled = false

	# O sprite do druida tem 96 px e a origem fica nos pés: subir meia altura
	# centraliza a arte sobre o corpo, em vez de sobre o chão.
	_game_over.global_position = _player.global_position + Vector2(0.0, -48.0)
	_game_over.visible = true

	# O botão fica na `CanvasLayer`, em coordenada de tela: um botão no mundo
	# sairia de vista se a câmera se mexesse, e clicar nele dependeria do zoom.
	_restart_button.visible = true
	_restart_button.grab_focus()


## Recomeça a partida do zero.
##
## `reload_current_scene()` recria `game.tscn` inteira: Player com vida cheia,
## nenhum inimigo, spawn zerado. Serve enquanto não há nada para preservar entre
## partidas — meta-progressão é FASE 13, e o `GameManager` com os estados de
## partida é FASE 9.
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
