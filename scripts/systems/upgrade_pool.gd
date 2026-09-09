class_name UpgradePool
extends Node
## Catálogo de opções do level up (`docs/03_SYSTEMS.md` §13).
##
## Decide **o que pode ser oferecido** e **o que acontece ao escolher**. Não
## desenha nada: a tela pede a lista e manda o id de volta.
##
## A separação importa porque as duas coisas mudam por motivos diferentes. A
## regra de "o que é oferecível" muda quando entra conteúdo novo; o desenho da
## tela muda quando entra arte. Juntas num arquivo só, uma mexida arrastaria a
## outra.
##
## Aqui mora também a resposta à §13, "evitar opções impossíveis": nada entra na
## lista sem antes responder que ainda pode ser aplicado.

## Emitido quando uma opção é aplicada de verdade.
signal applied(upgrade: UpgradeData)

## Quantas opções mostrar por vez, no máximo.
const MAX_OPCOES := 3

## Tudo que existe para ser oferecido. Passivas e armas convivem na mesma lista
## de propósito: para o jogador é uma escolha só, e separar em duas listas
## obrigaria a tela a decidir a proporção entre elas — que é regra de jogo, não
## de desenho.
@export var catalogo: Array[UpgradeData] = []

var _stats: StatComponent = null
var _weapons: WeaponManager = null
## Quantas vezes cada opção já foi escolhida, por id.
var _escolhidas: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Ligado pela raiz da partida.
func configure(stats: StatComponent, weapons: WeaponManager) -> void:
	_stats = stats
	_weapons = weapons


## Quantas vezes esta opção já foi levada.
func stacks(id: StringName) -> int:
	return int(_escolhidas.get(id, 0))


## A opção ainda muda alguma coisa se for escolhida agora?
##
## É a pergunta que impede a tela de oferecer o que não faz nada: uma passiva no
## teto, uma arma no nível máximo, ou uma arma nova sem slot livre.
func is_applicable(upgrade: UpgradeData) -> bool:
	if upgrade == null or not upgrade.is_valid():
		return false

	if upgrade.kind == UpgradeData.Kind.ARMA:
		if _weapons == null:
			return false
		if _weapons.has_weapon(upgrade.weapon.id):
			return _weapons.get_weapon_level(upgrade.weapon.id) < upgrade.weapon.max_level
		return _weapons.get_weapon_count() < _weapons.max_slots

	return _stats != null and stacks(upgrade.id) < upgrade.max_stacks


## Todas as opções que poderiam ser oferecidas agora.
func aplicaveis() -> Array[UpgradeData]:
	var lista: Array[UpgradeData] = []
	for upgrade in catalogo:
		if is_applicable(upgrade):
			lista.append(upgrade)
	return lista


## Sorteia até `MAX_OPCOES` opções distintas para uma tela.
##
## Sem repetição na mesma tela — oferecer a mesma passiva duas vezes gastaria
## uma das três escolhas sem dar alternativa nenhuma.
##
## O sorteio é uniforme. Raridade e peso por opção são conteúdo, não estrutura,
## e entram como campo do `UpgradeData` quando houver opções suficientes para
## isso importar.
func sortear(quantas: int = MAX_OPCOES) -> Array[UpgradeData]:
	var disponiveis := aplicaveis()
	var escolhidas: Array[UpgradeData] = []
	while not disponiveis.is_empty() and escolhidas.size() < quantas:
		escolhidas.append(disponiveis.pop_at(_rng.randi_range(0, disponiveis.size() - 1)))
	return escolhidas


## Aplica a opção. Devolve falso se ela já não valia mais.
func apply(id: StringName) -> bool:
	for upgrade in catalogo:
		if upgrade == null or upgrade.id != id:
			continue
		if not is_applicable(upgrade):
			return false

		if upgrade.kind == UpgradeData.Kind.ARMA:
			if not _weapons.add_weapon(upgrade.weapon):
				return false
		else:
			_stats.add_flat(upgrade.stat, upgrade.flat)
			_stats.add_mult(upgrade.stat, upgrade.mult)

		_escolhidas[id] = stacks(id) + 1
		applied.emit(upgrade)
		return true
	return false


## Semente fixa, para teste. Sem isto, um teste de sorteio seria diferente a
## cada execução e não teria como falhar de forma reproduzível.
func set_seed(valor: int) -> void:
	_rng.seed = valor
