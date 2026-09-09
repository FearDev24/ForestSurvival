class_name GameManager
extends Node
## Estado da partida (`docs/03_SYSTEMS.md` §16 e §17).
##
## Antes desta fase o estado morava em quatro lugares que precisavam concordar
## sozinhos: `_running` na raiz da partida, e um `enabled` no `SpawnManager`, no
## `WaveManager` e no `WeaponManager`. Nada garantia que concordassem, e cada
## tela nova teria de lembrar de mexer nos quatro.
##
## Agora há um estado só, e quem quiser saber pergunta. Ligar e desligar os
## sistemas passa a ser consequência da transição, não responsabilidade de quem
## a provocou.
##
## O nó **não** desenha nada: as telas escutam `state_changed` e se mostram.

## Emitido a cada mudança de estado.
signal state_changed(estado: Estado)

## Emitido uma única vez, quando a partida acaba. Traz o que a tela de resultado
## precisa mostrar (§16: tempo e level).
signal ended(vitoria: bool, tempo: float, nivel: int)

enum Estado {
	## A partida corre.
	JOGANDO,
	## A tela de level up está aberta. Pausa, mas não é pausa do jogador.
	ESCOLHENDO,
	## O jogador pediu pausa.
	PAUSADO,
	## O druida caiu.
	DERROTA,
	## O Guardião Profanado caiu.
	VITORIA,
}

## Estados em que a árvore fica parada.
const _PARA_A_ARVORE := [Estado.ESCOLHENDO, Estado.PAUSADO, Estado.DERROTA, Estado.VITORIA]

## Estados em que a partida já acabou e não há volta.
const _FIM := [Estado.DERROTA, Estado.VITORIA]

var estado: Estado = Estado.JOGANDO

var _elapsed := 0.0
var _player: Player = null
var _spawn: SpawnManager = null
var _waves: WaveManager = null
var _weapons: WeaponManager = null
var _level: LevelComponent = null


## Ligado pela raiz da partida.
##
## Recebe tudo que precisa ser desligado quando a partida acaba, mais o Player e
## o nível — que são o que a tela de resultado mostra. Nenhum deles é procurado
## por conta própria: quem conhece a composição é `game.gd`.
func configure(player: Player, spawn: SpawnManager, waves: WaveManager,
		weapons: WeaponManager, level: LevelComponent, level_up_menu: Node) -> void:
	_player = player
	_spawn = spawn
	_waves = waves
	_weapons = weapons
	_level = level

	if player != null and not player.death_finished.is_connected(_on_player_death_finished):
		player.death_finished.connect(_on_player_death_finished)

	# A vitória é uma conexão, não um sistema: o wave entrega o nó do boss e o
	# `HealthComponent` dele já emite `died` desde a FASE 2.
	if waves != null and not waves.boss_spawned.is_connected(_on_boss_spawned):
		waves.boss_spawned.connect(_on_boss_spawned)

	# A tela de escolha deixou de pausar sozinha: ela avisa que abriu e fechou,
	# e quem pausa é este nó. Dois lugares mexendo em `get_tree().paused` foi o
	# que esta fase veio desfazer.
	if level_up_menu != null:
		if level_up_menu.has_signal("opened"):
			level_up_menu.opened.connect(_on_level_up_aberto)
		if level_up_menu.has_signal("closed"):
			level_up_menu.closed.connect(_on_level_up_fechado)

	# **Não liga nada aqui.** Quem já estava desligado de propósito — um teste
	# medindo a rampa do spawn com as waves fora, por exemplo — deve continuar
	# desligado. Este nó reage a transições; não impõe um estado inicial.
	#
	# A árvore, sim, começa andando: uma cena recarregada a partir de uma tela
	# de pausa nasceria parada.
	var arvore := get_tree()
	if arvore != null:
		arvore.paused = false


func _physics_process(delta: float) -> void:
	if estado == Estado.JOGANDO:
		_elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if estado == Estado.JOGANDO:
		pausar()
	elif estado == Estado.PAUSADO:
		retomar()
	else:
		return
	get_viewport().set_input_as_handled()


## Tempo decorrido de partida, em segundos.
##
## Conta em passo de física, e não em quadro desenhado: o relógio não depende de
## quantos quadros a máquina consegue desenhar, e um teste sabe exatamente
## quanto tempo passou depois de N passos.
func get_elapsed() -> float:
	return _elapsed


func get_nivel() -> int:
	return _level.level if _level != null else 1


func esta_no_fim() -> bool:
	return estado in _FIM


func pausar() -> void:
	if estado == Estado.JOGANDO:
		_ir_para(Estado.PAUSADO)


func retomar() -> void:
	if estado == Estado.PAUSADO:
		_ir_para(Estado.JOGANDO)


## Recomeça a partida do zero.
##
## `reload_current_scene()` recria a cena inteira: Player com vida cheia,
## nenhum inimigo, relógio zerado. Serve enquanto não há nada para preservar
## entre partidas — meta-progressão é a FASE 13.
##
## Despausa antes, senão a cena nova nasce parada.
func reiniciar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func sair() -> void:
	get_tree().quit()


# ------------------------------------------------------------------ estados --


func _on_player_death_finished() -> void:
	if not esta_no_fim():
		_ir_para(Estado.DERROTA)


## O boss nasce; quando ele cair, a partida está ganha.
func _on_boss_spawned(boss: Node2D) -> void:
	var vida := boss.get_node_or_null("Health") as HealthComponent
	if vida != null and not vida.died.is_connected(_on_boss_morreu):
		vida.died.connect(_on_boss_morreu)


func _on_boss_morreu() -> void:
	if not esta_no_fim():
		_ir_para(Estado.VITORIA)


func _on_level_up_aberto() -> void:
	if estado == Estado.JOGANDO:
		_ir_para(Estado.ESCOLHENDO)


func _on_level_up_fechado() -> void:
	if estado == Estado.ESCOLHENDO:
		_ir_para(Estado.JOGANDO)


func _ir_para(novo: Estado) -> void:
	if novo == estado:
		return
	estado = novo
	_aplicar(novo)
	state_changed.emit(novo)
	if novo in _FIM:
		ended.emit(novo == Estado.VITORIA, _elapsed, get_nivel())


## Liga e desliga o que o estado pede.
##
## A pausa da árvore é adiada de propósito: a vitória chega de dentro da
## detecção de área que matou o boss, e mexer no estado da árvore ali faz a
## Godot recusar — é o mesmo motivo do `call_deferred` no orbe de XP e no menu
## de level up.
func _aplicar(novo: Estado) -> void:
	var correndo := novo == Estado.JOGANDO
	var acabou := novo in _FIM

	if _spawn != null:
		_spawn.enabled = correndo
	if _waves != null:
		_waves.enabled = correndo
	if _weapons != null:
		# Nos estados de pausa a árvore para de qualquer jeito; desligar as
		# armas só no fim evita que voltar da pausa deixe alguma sem religar.
		_weapons.set_weapons_enabled(not acabou)

	var arvore := get_tree()
	if arvore != null:
		arvore.set_deferred(&"paused", novo in _PARA_A_ARVORE)
