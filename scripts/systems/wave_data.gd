class_name WaveData
extends Resource
## Uma fase da partida (`docs/03_SYSTEMS.md` §7; DEC-010).
##
## Diz **quem nasce e em que ritmo** a partir de certo minuto. Não diz onde:
## isso é do `SpawnManager`, que conhece a câmera e as paredes.
##
## Acrescentar uma wave ao jogo é criar um `.tres` e pôr na lista do
## `WaveManager` — não escrever código.

## Identificador estável, para log e teste.
@export var id: StringName = &""

## Segundos de partida a partir dos quais esta wave manda. As waves são
## ordenadas por este campo, e vale a última cujo tempo já passou.
@export var start_time: float = 0.0

## Tipos que podem nascer nesta wave. Sorteados um a um, com peso igual.
@export var enemies: Array[EnemyData] = []

@export_group("Ritmo")
## Segundos entre nascimentos.
@export var spawn_interval: float = 1.0

## Quantos inimigos podem existir ao mesmo tempo.
##
## O teto de 200 saiu de medição, não de palpite: 200 custam 8,20 ms de física
## por quadro, 250 custam 14,03 e 300 custam 19,05, contra 16,6 ms de orçamento
## (`docs/HANDOFF.md`). Passar disso derruba o quadro.
@export var population_cap: int = 40

## Leva imediata no instante em que a wave começa. Serve para marcar a virada:
## o jogador sente a wave mudar em vez de só notar depois.
@export var burst_on_start: int = 0

## Trilha que entra quando esta wave começa. Vazio mantém a que está tocando.
##
## É por aqui que a música muda na chegada do Guardião: a wave diz, e ninguém
## precisa perguntar a que altura da partida estamos.
@export var trilha: StringName = &""

@export_group("Especiais")
## Elite desta wave. Nulo desliga.
@export var elite: EnemyData

## Segundos entre elites. **Zero desliga**, mesmo com `elite` preenchido.
@export var elite_interval: float = 0.0

## Boss. Nasce **uma vez**, no começo da wave, e ignora o teto de população —
## uma horda cheia não pode impedir o boss de aparecer.
@export var boss: EnemyData


## Uma wave sem inimigo e sem boss não tem o que fazer.
func is_valid() -> bool:
	if id == &"":
		return false
	if spawn_interval <= 0.0 or population_cap <= 0:
		return false
	return not enemies.is_empty() or boss != null


## Sorteia um tipo desta wave.
func sortear(rng: RandomNumberGenerator) -> EnemyData:
	if enemies.is_empty():
		return null
	return enemies[rng.randi_range(0, enemies.size() - 1)]
