class_name LevelComponent
extends Node
## Experiência e nível do jogador (`docs/03_SYSTEMS.md` §12).
##
## Componente puro: não conhece Player, HUD nem menu. Quem quiser reagir conecta
## os sinais.
##
## O ponto delicado da §12 está resolvido aqui: **XP excedente não se perde**.
## Ganhar XP suficiente para três níveis de uma vez sobe três níveis e guarda o
## resto para o próximo — nada é descartado no caminho.

## Emitido sempre que o XP muda, inclusive quando muda por causa de um nível.
signal xp_changed(current: float, needed: float)

## Emitido uma vez **por nível**, na ordem. Três níveis de uma vez emitem três
## vezes, para que a tela de escolha possa oferecer três escolhas.
signal leveled_up(level: int)

## XP exigido para sair do nível 1.
@export var base_xp: float = 5.0

## Quanto o custo cresce a cada nível. 1.20 significa 20% a mais por nível.
##
## Era 1.35, número de raciocínio. A sonda de balanceamento mostrou a
## progressão travando justo quando a pressão sobe -- nível 8 aos 2 min e
## depois um por minuto, com os brutos entrando aos 150 s. Com 1.20 o nível
## aos 3 min sobe de 9 para 12, e a sobrevivência média de 204 para 283 s
## (10 partidas cada, z = 2,6). Ver docs/HANDOFF.md, "Balanceamento medido".
@export var xp_growth: float = 1.20

## Teto de segurança contra curva mal configurada: sem ele, `xp_growth` igual a
## zero faria o laço de subir de nível rodar para sempre no primeiro ganho.
const _MAX_NIVEIS_POR_GANHO := 50

var level: int = 1
var xp: float = 0.0


func _ready() -> void:
	xp_changed.emit(xp, xp_to_next())


## XP que falta para o próximo nível, a partir do nível atual.
func xp_to_next() -> float:
	return maxf(1.0, base_xp * pow(maxf(1.01, xp_growth), float(level - 1)))


## Soma experiência e sobe quantos níveis couberem.
func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return

	xp += amount

	var subidas := 0
	while xp >= xp_to_next() and subidas < _MAX_NIVEIS_POR_GANHO:
		xp -= xp_to_next()
		level += 1
		subidas += 1
		leveled_up.emit(level)

	xp_changed.emit(xp, xp_to_next())


## Fração do nível atual, de 0 a 1. Serve para a barra de XP na FASE 9.
func get_ratio() -> float:
	return clampf(xp / xp_to_next(), 0.0, 1.0)
