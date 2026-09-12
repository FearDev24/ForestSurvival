class_name BotPiloto
extends Node
## Piloto automático da partida: o bot da sonda de balanceamento, num nó.
##
## Joga pelas mesmas ações que o teclado e o joystick apertam (`move_*`): foge
## da horda circulando, volta das paredes, busca orbes quando o aperto deixa e
## escolhe upgrades pelo próprio menu de level up. É o que o `BotMobile` põe na
## partida para o teste no celular.
##
## Não é jogador: desvia melhor que ninguém num quadro e pior que qualquer um
## no seguinte. Serve de régua — de desempenho no aparelho, e de nada sobre se
## o jogo é divertido.
##
## Solta só as ações que ele mesmo apertou, pela mesma razão do joystick: soltar
## as quatro pararia um jogador que estivesse segurando uma tecla.

const RAIO_DE_PERIGO := 240.0
const PESO := {
	&"imp_corrompido": 1.0,
	&"cao_demoniaco": 1.0,
	&"bruto_corrompido": 1.8,
	&"elite_corrompida": 2.5,
	&"guardiao_profanado": 4.0,
}
const MARGEM_DA_PAREDE := 320.0
const ALCANCE_DO_ORBE := 520.0

## `sensata`: arma nova até quatro, depois sobe arma, vida quando aperta.
## `aleatoria`: qualquer uma das oferecidas.
var politica := "sensata"

var _player: Node2D = null
var _manager: GameManager = null
var _vida: HealthComponent = null
var _inimigos: Node = null
var _orbes: Node = null
var _menu: CanvasLayer = null
var _armas: WeaponManager = null
var _limites := Rect2()
var _rng := RandomNumberGenerator.new()
var _quadro := 0
var _escolha_pendente := false
var _apertadas := {}
var escolhas: Array = []


func configure(game: Node, semente: int = 1) -> void:
	_player = game.get_node("Player")
	_manager = game.get_node("GameManager")
	_vida = game.get_node("Player/Health")
	_inimigos = game.get_node("EnemyContainer")
	_orbes = game.get_node("PickupContainer")
	_menu = game.get_node("LevelUpMenu")
	_armas = game.get_node("Player/WeaponManager")
	_limites = (game.get_node("World/TestWorld") as TestWorld).get_bounds()
	_rng.seed = semente
	if not _menu.opened.is_connected(_on_menu_aberto):
		_menu.opened.connect(_on_menu_aberto)
	# Com a árvore parada — o menu de level up pausa — é que o bot escolhe.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_menu_aberto() -> void:
	_escolha_pendente = true


func _physics_process(_delta: float) -> void:
	if _manager == null:
		return
	_quadro += 1
	if _escolha_pendente and _menu.visible:
		_escolha_pendente = false
		_escolher()
	if _manager.estado == GameManager.Estado.JOGANDO:
		if _quadro % 2 == 0:
			_dirigir()
	else:
		_soltar()


func _exit_tree() -> void:
	_soltar()


# ------------------------------------------------------------------ direção --


func _dirigir() -> void:
	var p := _player.global_position
	var fuga := Vector2.ZERO
	var perto := 0
	for filho in _inimigos.get_children():
		var inimigo := filho as Node2D
		if inimigo == null:
			continue
		var d := p.distance_to(inimigo.global_position)
		if d > RAIO_DE_PERIGO:
			continue
		perto += 1
		var peso: float = PESO.get(_tipo(inimigo), 1.0)
		fuga += (p - inimigo.global_position).normalized() * pow(1.0 - d / RAIO_DE_PERIGO, 2.0) * peso

	var direcao := Vector2.ZERO
	if fuga.length() > 0.01:
		# Fugir em linha reta leva a um canto: um pouco de lado faz circular a horda.
		direcao = fuga.normalized() + fuga.orthogonal().normalized() * 0.55

	var alvo := _orbe_mais_perto(p)
	if alvo != Vector2.INF:
		direcao += (alvo - p).normalized() * (0.9 / (1.0 + fuga.length() * 1.5))

	var dentro := _limites.grow(-MARGEM_DA_PAREDE)
	if not dentro.has_point(p):
		var fundo := 1.0
		if p.x < dentro.position.x:
			fundo = maxf(fundo, (dentro.position.x - p.x) / MARGEM_DA_PAREDE * 3.0)
		if p.x > dentro.end.x:
			fundo = maxf(fundo, (p.x - dentro.end.x) / MARGEM_DA_PAREDE * 3.0)
		if p.y < dentro.position.y:
			fundo = maxf(fundo, (dentro.position.y - p.y) / MARGEM_DA_PAREDE * 3.0)
		if p.y > dentro.end.y:
			fundo = maxf(fundo, (p.y - dentro.end.y) / MARGEM_DA_PAREDE * 3.0)
		direcao += (_limites.get_center() - p).normalized() * fundo

	if direcao.length() < 0.05 and perto == 0:
		direcao = (_limites.get_center() - p) * 0.002

	var v := direcao.limit_length(1.0)
	_eixo(&"move_right", &"move_left", v.x)
	_eixo(&"move_down", &"move_up", v.y)


func _eixo(positivo: StringName, negativo: StringName, valor: float) -> void:
	if valor > 0.05:
		_largar(negativo)
		Input.action_press(positivo, clampf(valor, 0.0, 1.0))
		_apertadas[positivo] = true
	elif valor < -0.05:
		_largar(positivo)
		Input.action_press(negativo, clampf(-valor, 0.0, 1.0))
		_apertadas[negativo] = true
	else:
		_largar(positivo)
		_largar(negativo)


func _largar(acao: StringName) -> void:
	if _apertadas.has(acao):
		Input.action_release(acao)
		_apertadas.erase(acao)


func _soltar() -> void:
	for acao in _apertadas.keys():
		Input.action_release(acao)
	_apertadas.clear()


func _orbe_mais_perto(p: Vector2) -> Vector2:
	var melhor := Vector2.INF
	var melhor_d := ALCANCE_DO_ORBE
	for filho in _orbes.get_children():
		var orbe := filho as Node2D
		if orbe == null:
			continue
		var d := p.distance_to(orbe.global_position)
		if d < melhor_d:
			melhor_d = d
			melhor = orbe.global_position
	return melhor


func _tipo(inimigo: Node) -> StringName:
	var dados = inimigo.get(&"data")
	if dados is EnemyData:
		return (dados as EnemyData).id
	return &""


# ------------------------------------------------------------------ escolha --


func _escolher() -> void:
	var oferta: Array = _menu.get(&"_oferta")
	if oferta == null or oferta.is_empty():
		return
	var escolhido: UpgradeData = null
	if politica == "aleatoria":
		escolhido = oferta[_rng.randi_range(0, oferta.size() - 1)]
	else:
		escolhido = _melhor(oferta)
	escolhas.append([snappedf(_manager.get_elapsed(), 0.1), String(escolhido.id)])
	_menu.call_deferred(&"_on_escolha", escolhido.id)


func _melhor(oferta: Array) -> UpgradeData:
	var aperto := _vida.current_health / maxf(1.0, _vida.max_health) < 0.5
	var melhor: UpgradeData = oferta[0]
	var melhor_nota := -1.0e9
	for u in oferta:
		var upgrade := u as UpgradeData
		var nota := 0.0
		if upgrade.kind == UpgradeData.Kind.ARMA:
			if not _armas.has_weapon(upgrade.weapon.id):
				nota = 12.0 if _armas.get_weapon_count() < 4 else 3.0
			else:
				nota = 10.0 - _armas.get_weapon_level(upgrade.weapon.id)
		else:
			match String(upgrade.id):
				"ciclo_lunar": nota = 8.0
				"casca_de_carvalho": nota = 7.0 + (5.0 if aperto else 0.0)
				"coracao_verde": nota = 6.0 + (5.0 if aperto else 0.0)
				"semente_ancestral": nota = 6.0
				"passos_do_cervo": nota = 5.0
				"essencia_viva": nota = 4.0
				_: nota = 3.0
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = upgrade
	return melhor
