class_name UpgradeData
extends Resource
## Uma opção da tela de level up (`docs/03_SYSTEMS.md` §13; DEC-010).
##
## Aqui não há comportamento: só o que a opção é e o que ela soma. Acrescentar
## uma passiva ao jogo é criar um `.tres`, não escrever código — mesmo princípio
## do `WeaponData`.
##
## Uma passiva é **um stat mais um número**, e nada além disso. Se alguma
## precisar de campo próprio, é sinal de que virou caso especial — e era
## exatamente isso que o `StatComponent` existia para evitar.

## O que a opção faz quando escolhida.
enum Kind {
	## Soma bônus num stat do jogador.
	PASSIVA,
	## Entrega uma arma. Se o druida já a tiver, sobe o nível dela.
	ARMA,
}

## Identificador estável. É por ele que o catálogo conta repetições — nunca pelo
## nome de exibição, que muda com tradução.
@export var id: StringName = &""

## Nome mostrado ao jogador.
@export var display_name: String = ""

## Uma linha explicando o efeito. Aparece abaixo do nome, em fonte menor.
@export_multiline var description: String = ""

## Ícone de 128x128 (DEC-023 trata dos tamanhos do HUD). Pode faltar: a tela
## desenha só o texto enquanto a arte não chega, sem quebrar (DEC-013).
@export var icon: Texture2D

@export var kind: Kind = Kind.PASSIVA

## Segundos de partida a partir dos quais esta opção pode ser oferecida. Zero:
## desde o começo. É o que dá a cada fase as suas habilidades (DEC-025) — a
## vinha chega aos 30 s, o cajado aos 60, e assim por diante.
@export var unlock_time: float = 0.0

@export_group("Passiva")
## Qual stat recebe o bônus.
@export var stat: StatComponent.Stat = StatComponent.Stat.MAX_HEALTH

## Bônus plano, somado antes do percentual.
@export var flat: float = 0.0

## Bônus percentual, em fração: `0.1` é +10%.
@export var mult: float = 0.0

## Quantas vezes a passiva pode ser escolhida. Sem teto, uma só passiva
## dominaria a partida inteira e as outras nunca seriam vistas.
@export var max_stacks: int = 5

@export_group("Arma")
## A arma entregue quando `kind` é `ARMA`.
@export var weapon: WeaponData


## Uma opção sem identificador ou sem efeito não tem como ser oferecida.
func is_valid() -> bool:
	if id == &"":
		return false
	if kind == Kind.ARMA:
		return weapon != null and weapon.is_valid()
	return not (is_zero_approx(flat) and is_zero_approx(mult)) and max_stacks > 0


## Texto curto do efeito, para quando a descrição estiver vazia.
func resumo() -> String:
	if kind == Kind.ARMA:
		return weapon.display_name if weapon != null else ""
	var partes: Array[String] = []
	if not is_zero_approx(flat):
		partes.append("%+.0f" % flat)
	if not is_zero_approx(mult):
		partes.append("%+.0f%%" % (mult * 100.0))
	return " e ".join(partes)
