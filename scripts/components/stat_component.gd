class_name StatComponent
extends Node
## Onde os bônus do jogador se somam (`docs/03_SYSTEMS.md` §14).
##
## Componente puro: não conhece Player, Health, PickupArea nem arma nenhuma.
## Guarda bônus e sabe aplicá-los a um número — quem tem o número decide quando
## perguntar.
##
## **Não guarda as bases.** A velocidade base continua em `Player.move_speed`, a
## vida base em `HealthComponent.max_health`, o alcance de coleta no raio da
## forma da `PickupArea`. Cada um desses valores já está documentado e ajustado
## onde vive; duplicá-los aqui criaria duas fontes de verdade, e a pergunta "qual
## das duas vale?" não tem resposta boa.
##
## A conta é sempre a mesma:
##
##     efetivo = (base + plano) * (1 + percentual)
##
## O plano soma antes, o percentual multiplica depois. É a ordem que faz
## "+20 de vida" e "+10% de vida" se comportarem como o jogador espera quando as
## duas passivas estão equipadas.
##
## Um stat multiplicador — dano, cooldown, área — é só um stat cuja base é 1.0.
## Não precisa de tratamento próprio.

## Emitido quando um bônus muda. Quem depende do stat recalcula; o componente
## não sabe recalcular nada por ninguém.
signal stat_changed(stat: Stat)

## Os stats da §14. A ordem não importa: o valor do enum é só índice interno.
enum Stat {
	MAX_HEALTH,
	MOVE_SPEED,
	PICKUP_RADIUS,
	DAMAGE,
	COOLDOWN,
	AREA,
	DURATION,
	PROJECTILE_SPEED,
	AMOUNT,
	## Vida por segundo. Não está na lista da §14 — entrou porque a passiva
	## Coração Verde do `docs/04_CONTENT_PLAN.md` precisa dela.
	##
	## Acrescentado **no fim** de propósito: os `.tres` guardam o stat como
	## número, então inserir no meio remapearia silenciosamente as passivas já
	## existentes.
	REGEN,
}

## Piso do fator percentual, contra passiva mal configurada.
##
## Sem ele, redução de cooldown somando -100% zeraria o intervalo entre ataques
## e a arma dispararia todo frame; -120% deixaria o cooldown negativo, que é
## pior ainda. O piso troca um bug de travar o jogo por um teto de poder.
const _FATOR_MINIMO := 0.05

var _plano := PackedFloat32Array()
var _percentual := PackedFloat32Array()


func _init() -> void:
	_plano.resize(Stat.size())
	_percentual.resize(Stat.size())


## Soma um bônus plano: "+20 de vida máxima" é `add_flat(Stat.MAX_HEALTH, 20.0)`.
func add_flat(stat: Stat, amount: float) -> void:
	if is_zero_approx(amount):
		return
	_plano[stat] += amount
	stat_changed.emit(stat)


## Soma um bônus percentual, em fração: `0.1` é +10%, `-0.15` é -15%.
##
## Vários bônus percentuais **somam entre si** antes de multiplicar: +10% e +10%
## dão +20%, não +21%. É a regra do gênero, e é a que o jogador consegue prever
## de cabeça olhando a tela de escolha.
func add_mult(stat: Stat, fraction: float) -> void:
	if is_zero_approx(fraction):
		return
	_percentual[stat] += fraction
	stat_changed.emit(stat)


## Bônus plano acumulado.
func flat(stat: Stat) -> float:
	return _plano[stat]


## Fator percentual acumulado, já com o piso aplicado. 1.0 significa "sem bônus".
func factor(stat: Stat) -> float:
	return maxf(_FATOR_MINIMO, 1.0 + _percentual[stat])


## Aplica os bônus deste stat a um valor base.
func apply(stat: Stat, base: float) -> float:
	return (base + _plano[stat]) * factor(stat)


## Verdadeiro enquanto nenhum bônus foi somado a este stat. Serve para a tela de
## escolha não oferecer o que não muda nada.
func is_untouched(stat: Stat) -> bool:
	return is_zero_approx(_plano[stat]) and is_zero_approx(_percentual[stat])
