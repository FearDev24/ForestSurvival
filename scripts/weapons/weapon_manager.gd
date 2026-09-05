class_name WeaponManager
extends Node
## Armas que o druida carrega (`docs/03_SYSTEMS.md` §8).
##
## Responsável por: guardar as armas equipadas, acrescentar, melhorar, consultar
## nível e limitar slots.
##
## **Não** implementa comportamento de arma nenhuma (DEC-009). Cada arma é um nó
## `Weapon` alimentado por um `WeaponData`; acrescentar uma arma nova ao jogo é
## criar um `.tres`, não escrever código.

## Emitido quando uma arma entra pela primeira vez.
signal weapon_added(data: WeaponData)

## Emitido quando uma arma já equipada sobe de nível.
signal weapon_upgraded(data: WeaponData, level: int)

## Emitido quando a arma pedida não cabe: todos os slots ocupados. A FASE 6 usa
## isto para não oferecer arma nova quando não há espaço.
signal weapon_rejected(data: WeaponData)

## Limite de armas simultâneas.
@export var max_slots: int = 6

## Armas com que a partida começa. Provisório: o menu de escolha de personagem
## da FASE 13 decidirá isso.
@export var starting_weapons: Array[WeaponData] = []

## Liga e desliga todas as armas de uma vez. O game over da FASE 9 usa isto, e
## os testes também.
##
## É estado do **manager**, não de cada arma: desligado antes de `configure()`,
## continua valendo para as armas criadas depois. Sem isso, quem desliga cedo
## demais não desliga nada — e um teste que faz isso passa a falhar por motivo
## invisível.
var enabled: bool = true:
	set(value):
		enabled = value
		_apply_enabled()

var _target: Node2D = null
var _enemies: Node = null
var _effects: Node = null
## Arma por id. Também é a fonte da contagem de slots.
var _weapons: Dictionary = {}


## Ligado pela raiz da partida, como o `SpawnManager`.
##
## As armas só começam a atirar aqui: antes disso não existe alvo, nem lugar
## onde pôr os ataques.
func configure(target: Node2D, enemy_container: Node, effect_container: Node) -> void:
	_target = target
	_enemies = enemy_container
	_effects = effect_container

	for data in starting_weapons:
		if data != null:
			add_weapon(data)

	for arma in _weapons.values():
		(arma as Weapon).configure(_target, _enemies, _effects)

	_apply_enabled()


## Acrescenta a arma, ou sobe o nível dela se já estiver equipada.
##
## Pedir de novo a mesma arma **melhora** em vez de duplicar: é assim que a tela
## de level up da FASE 5 vai funcionar, e duplicar armaria duas cópias atirando
## em paralelo sem que ninguém tivesse pedido isso.
func add_weapon(data: WeaponData) -> bool:
	if data == null or not data.is_valid():
		push_warning("WeaponData inválido ignorado pelo WeaponManager.")
		return false

	if _weapons.has(data.id):
		return upgrade_weapon(data.id)

	if _weapons.size() >= max_slots:
		weapon_rejected.emit(data)
		return false

	var arma := Weapon.new()
	arma.name = "Weapon_%s" % data.id
	arma.data = data
	arma.level = 1
	_weapons[data.id] = arma
	add_child(arma)

	if _target != null:
		arma.configure(_target, _enemies, _effects)
	arma.set_physics_process(enabled and _target != null)

	weapon_added.emit(data)
	return true


## Sobe uma arma de nível, respeitando o teto de `max_level`.
func upgrade_weapon(id: StringName) -> bool:
	var arma := _weapons.get(id) as Weapon
	if arma == null or arma.level >= arma.data.max_level:
		return false

	arma.level += 1
	weapon_upgraded.emit(arma.data, arma.level)
	return true


## Nível atual, ou 0 se a arma não estiver equipada.
func get_weapon_level(id: StringName) -> int:
	var arma := _weapons.get(id) as Weapon
	return arma.level if arma != null else 0


func has_weapon(id: StringName) -> bool:
	return _weapons.has(id)


## Quantas armas estão realmente equipadas.
##
## Conta os nós filhos, não o dicionário: se um dia entrar arma duplicada por
## engano, o dicionário esconderia — a segunda sobrescreve a entrada da primeira
## e o total continua parecendo certo, enquanto duas armas atiram.
func get_weapon_count() -> int:
	var total := 0
	for filho in get_children():
		if filho is Weapon:
			total += 1
	return total


## Existe alguma arma que ainda pode subir de nível?
##
## A FASE 6 precisa disto para não oferecer melhoria impossível
## (`docs/03_SYSTEMS.md` §13: "evitar opções impossíveis").
func has_upgradable_weapon() -> bool:
	for arma in _weapons.values():
		if (arma as Weapon).level < (arma as Weapon).data.max_level:
			return true
	return false


## Atalho para `enabled`, mais legível na chamada.
func set_weapons_enabled(value: bool) -> void:
	enabled = value


func _apply_enabled() -> void:
	for arma in _weapons.values():
		var w := arma as Weapon
		w.set_physics_process(enabled and w.data != null and _target != null)
