extends SceneTree
## Sonda de balanceamento: joga uma partida inteira sozinha e mede.
##
## Uso:
##   godot --headless --fixed-fps 60 --path . --script res://tools/sonda_balanceamento.gd -- --semente=1 --politica=sensata --saida=C:/caminho/run.json
##
## Nao e teste: nao passa nem falha. Carrega a partida real, dirige o druida
## pelas mesmas acoes de input que o teclado usa, escolhe upgrades pelo proprio
## menu de level up e grava a partida em JSON. `--fixed-fps` faz cada quadro
## valer 1/60 s de jogo, e sem janela a Godot roda tao rapido quanto o
## processador deixa.
##
## O que ela responde: a curva de XP acompanha a de inimigos? A populacao
## chega no teto? O Guardiao cai dentro do tempo? E o que ela NAO responde: se
## foi divertido. O bot desvia melhor que ninguem num quadro e pior que
## qualquer um no seguinte -- serve de regua, nao de jogador.
##
## Politicas de escolha:
##   sensata   -- arma nova ate quatro, depois sobe arma; vida quando aperta.
##   aleatoria -- qualquer uma das oferecidas.

const GAME_SCENE := "res://scenes/game/game.tscn"

## Teto de tempo de jogo. A wave do Guardiao comeca aos 420 s; 660 da quatro
## minutos para derruba-lo antes de a sonda desistir.
const TEMPO_MAXIMO := 660.0
const AMOSTRA_A_CADA := 5.0

## Raio em que o bot passa a fugir de um inimigo, e pesos por tipo.
const RAIO_DE_PERIGO := 240.0
const PESO := {
	&"imp_corrompido": 1.0,
	&"cao_demoniaco": 1.0,
	&"bruto_corrompido": 1.8,
	&"elite_corrompida": 2.5,
	&"guardiao_profanado": 4.0,
}
## Distancia das paredes a partir da qual o bot comeca a voltar para dentro.
const MARGEM_DA_PAREDE := 320.0
## Ate onde o bot vai buscar um orbe.
const ALCANCE_DO_ORBE := 520.0

var _semente := 1
var _politica := "sensata"
var _saida := "user://sonda.json"
## Controle: o druida fica parado. Se ele morre no mesmo tempo que o bot,
## a direcao nao esta fazendo nada e os numeros da sonda nao valem.
var _parado := false
## Ajustes em memoria, para testar hipotese sem tocar nos arquivos do jogo:
## `--ajuste=enemies/cao_demoniaco.move_speed=150` carrega o recurso e muda o
## campo antes de a partida nascer. O ResourceLoader devolve a mesma instancia
## a quem carregar depois -- as waves inclusive --, entao o jogo inteiro ve o
## valor novo, e nada vai para o disco.
var _ajustes: Array = []
## Os recursos ajustados ficam presos aqui ate o fim.
##
## Sem isto o ajuste nao valia: o recurso carregado numa variavel local era
## liberado quando `_aplicar_ajuste()` terminava, saia do cache, e a partida
## carregava do disco uma copia nova, com o valor original. A sonda imprimia
## "190.0 -> 150.0" e o cao corria a 190 -- a copia alterada era so a dela.
var _segurados: Array[Resource] = []
## O que cada tipo de inimigo **realmente** teve ao nascer, lido do no e nao
## do recurso. E a prova de que um ajuste chegou ao jogo.
var _vistos := {}
## Teto: o druida nao leva dano. Separa "o bot nao desvia" de "a build nao
## mata o boss" -- a economia de XP e armas corre inteira, e da para ver se
## o Guardiao cai e quando. Nao diz nada sobre dificuldade.
var _invulneravel := false
## Ajuste num no da partida, para o que nao mora em recurso -- a curva de XP
## esta em `Player/Level`: `--no=Player/Level.xp_growth=1.2`. Aplicado depois
## de a partida nascer, e so em memoria.
var _ajustes_de_no: Array = []
var _dano_por_tipo := {}
## Armas com que o druida nasce, trocadas em memória antes de a partida
## entrar na árvore: `--armas_iniciais=corvo_espiritual` (ids de
## `resources/weapons/`). Vazio mantém as da cena do Player.
var _armas_iniciais: Array = []
## FASE 10: mede o custo de cada quadro ao longo da partida inteira.
##
## Rode **uma partida por vez**: com varias em paralelo elas disputam o
## processador e o tempo de quadro mede a disputa, nao o jogo. Com janela a
## medicao inclui o desenho (chamadas de desenho); sem janela, so logica e
## fisica.
var _perf := false
## Custo de cada quadro inteiro, medido pelo relogio entre dois passos. Com
## `--fixed-fps` e sem limite de quadros, o intervalo entre dois passos e
## exatamente o que o quadro custou -- fisica, logica e, com janela, desenho.
var _perf_quadro: Array[float] = []
var _perf_ultimo := 0
## `TIME_PHYSICS_PROCESS` nao e o quadro atual: a Godot guarda nele o **pior**
## quadro de fisica do ultimo segundo real, e atualiza uma vez por segundo.
## Serve de pico, nao de distribuicao -- e e a mesma metrica da tabela da
## FASE 3, entao se compara com ela.
var _perf_fisica: Array[float] = []
var _efeitos: Node = null
var _projeteis: Node = null

var _game: Node2D = null
var _player: Player = null
var _manager: GameManager = null
var _level: LevelComponent = null
var _vida: HealthComponent = null
var _inimigos: Node2D = null
var _orbes: Node2D = null
var _menu: CanvasLayer = null
var _pool: UpgradePool = null
var _armas: WeaponManager = null
var _limites := Rect2()

var _rng := RandomNumberGenerator.new()
var _quadro := 0
var _proxima_amostra := 0.0
var _escolha_pendente := false

var _abates := 0
var _dano_causado := 0.0
var _dano_recebido := 0.0
var _xp_coletado := 0.0
var _vida_minima := 1.0e9
var _boss: Node2D = null
var _boss_vida: HealthComponent = null

var _amostras: Array = []
var _escolhas: Array = []
var _niveis: Array = []
var _boss_linha: Array = []
var _eventos: Array = []
var _fim := {}
var _terminou := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--semente="):
			_semente = int(arg.get_slice("=", 1))
		elif arg.begins_with("--politica="):
			_politica = arg.get_slice("=", 1)
		elif arg.begins_with("--saida="):
			_saida = arg.get_slice("=", 1)
		elif arg == "--parado":
			_parado = true
		elif arg == "--invulneravel":
			_invulneravel = true
		elif arg == "--perf":
			_perf = true
		elif arg.begins_with("--no="):
			_ajustes_de_no.append(arg.trim_prefix("--no="))
		elif arg.begins_with("--armas_iniciais="):
			_armas_iniciais = arg.trim_prefix("--armas_iniciais=").split(",", false)
		elif arg.begins_with("--ajuste="):
			_ajustes.append(arg.trim_prefix("--ajuste="))

	# Uma semente para tudo: o spawn usa o gerador global, o pool tem o dele.
	seed(_semente)
	_rng.seed = _semente

	for ajuste in _ajustes:
		_aplicar_ajuste(ajuste)

	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	if not _armas_iniciais.is_empty():
		var lista: Array[WeaponData] = []
		for id in _armas_iniciais:
			var arma := load("res://resources/weapons/%s.tres" % id) as WeaponData
			if arma == null:
				push_error("sonda: arma inicial desconhecida: %s" % id)
				quit(2)
				return
			lista.append(arma)
		(_game.get_node("Player/WeaponManager") as WeaponManager).starting_weapons = lista
		print("sonda: armas iniciais %s" % str(_armas_iniciais))
	root.add_child(_game)

	_player = _game.get_node("Player")
	_manager = _game.get_node("GameManager")
	_level = _game.get_node("Player/Level")
	_vida = _game.get_node("Player/Health")
	_inimigos = _game.get_node("EnemyContainer")
	_orbes = _game.get_node("PickupContainer")
	_menu = _game.get_node("LevelUpMenu")
	_pool = _game.get_node("UpgradePool")
	_armas = _game.get_node("Player/WeaponManager")
	_efeitos = _game.get_node_or_null("EffectContainer")
	_projeteis = _game.get_node_or_null("ProjectileContainer")
	if _perf:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_limites = (_game.get_node("World/TestWorld") as TestWorld).get_bounds()
	_pool.set_seed(_semente)
	for ajuste in _ajustes_de_no:
		_aplicar_ajuste_de_no(ajuste)

	if _invulneravel:
		var achou := false
		for filho in _player.get_children():
			if filho is HurtboxComponent:
				(filho as HurtboxComponent).set_vulnerable(false)
				achou = true
		if not achou:
			push_error("sonda: --invulneravel sem HurtboxComponent no Player")
			quit(2)

	_inimigos.child_entered_tree.connect(_on_inimigo_entrou)
	_inimigos.child_exiting_tree.connect(_on_inimigo_saiu)
	_vida.damaged.connect(_on_dano_recebido)
	_level.leveled_up.connect(_on_nivel)
	(_game.get_node("Player/PickupArea") as PickupArea).collected.connect(_on_xp)
	(_game.get_node("WaveManager") as WaveManager).boss_spawned.connect(_on_boss)
	_menu.opened.connect(_on_menu_aberto)
	_manager.ended.connect(_on_fim)

	print("sonda: semente %d, politica %s" % [_semente, _politica])


func _physics_process(_delta: float) -> bool:
	if _terminou:
		return true
	_quadro += 1

	# O menu pausa a arvore, mas o SceneTree continua rodando este metodo: e
	# daqui que o bot escolhe, como um jogador clicando com o jogo parado.
	if _escolha_pendente and _menu.visible:
		_escolha_pendente = false
		_escolher()

	if _perf and _manager.estado == GameManager.Estado.JOGANDO:
		var agora := Time.get_ticks_usec()
		if _perf_ultimo > 0:
			_perf_quadro.append((agora - _perf_ultimo) / 1000.0)
		_perf_ultimo = agora
		_perf_fisica.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	elif _perf:
		# Menu de level up aberto: o intervalo ate o proximo quadro jogado seria
		# o tempo parado, nao custo.
		_perf_ultimo = 0

	var t := _manager.get_elapsed()
	if _manager.estado == GameManager.Estado.JOGANDO:
		if _quadro % 2 == 0 and not _parado:
			_dirigir()
		_vida_minima = minf(_vida_minima, _vida_atual())

	if t >= _proxima_amostra:
		_amostrar(t)
		_proxima_amostra += AMOSTRA_A_CADA

	if t >= TEMPO_MAXIMO and not _terminou:
		_fim = {"desfecho": "tempo_esgotado", "tempo": snappedf(t, 0.1), "nivel": _level.level}
		_encerrar()
	return _terminou


# ------------------------------------------------------------------ direcao --


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
		var forca := pow(1.0 - d / RAIO_DE_PERIGO, 2.0) * peso
		fuga += (p - inimigo.global_position).normalized() * forca

	var direcao := Vector2.ZERO
	if fuga.length() > 0.01:
		# Fugir em linha reta leva a um canto. Uma componente de lado faz o bot
		# circular a horda -- o que um jogador de survivor faz por instinto.
		direcao = fuga.normalized() + fuga.orthogonal().normalized() * 0.55

	# Orbe mais perto, com peso que cai quando o aperto sobe.
	var alvo := _orbe_mais_perto(p)
	if alvo != Vector2.INF:
		var vontade := 0.9 / (1.0 + fuga.length() * 1.5)
		direcao += (alvo - p).normalized() * vontade

	# Paredes empurram para dentro.
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
		# Nada por perto nem orbe: anda devagar para o centro, que e onde a
		# horda chega de todos os lados em vez de encurralar.
		direcao = (_limites.get_center() - p) * 0.002

	_apertar(direcao.limit_length(1.0))


func _apertar(v: Vector2) -> void:
	_eixo(&"move_right", &"move_left", v.x)
	_eixo(&"move_down", &"move_up", v.y)


func _eixo(positivo: StringName, negativo: StringName, valor: float) -> void:
	if valor > 0.05:
		Input.action_release(negativo)
		Input.action_press(positivo, clampf(valor, 0.0, 1.0))
	elif valor < -0.05:
		Input.action_release(positivo)
		Input.action_press(negativo, clampf(-valor, 0.0, 1.0))
	else:
		Input.action_release(positivo)
		Input.action_release(negativo)


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


func _on_menu_aberto() -> void:
	_escolha_pendente = true


func _escolher() -> void:
	var oferta: Array = _menu.get(&"_oferta")
	if oferta == null or oferta.is_empty():
		return
	var escolhido: UpgradeData = null
	if _politica == "aleatoria":
		escolhido = oferta[_rng.randi_range(0, oferta.size() - 1)]
	else:
		escolhido = _melhor(oferta)

	var ids: Array = []
	for u in oferta:
		ids.append(String((u as UpgradeData).id))
	_escolhas.append([snappedf(_manager.get_elapsed(), 0.1), _level.level,
		String(escolhido.id), ids])
	_menu.call_deferred(&"_on_escolha", escolhido.id)


func _melhor(oferta: Array) -> UpgradeData:
	var aperto := _vida_atual() / maxf(1.0, _vida.max_health) < 0.5
	var melhor: UpgradeData = oferta[0]
	var melhor_nota := -1.0e9
	for u in oferta:
		var upgrade := u as UpgradeData
		var nota := 0.0
		if upgrade.kind == UpgradeData.Kind.ARMA:
			var nova := not _armas.has_weapon(upgrade.weapon.id)
			if nova:
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


# ----------------------------------------------------------------- contagem --


func _vida_atual() -> float:
	return float(_vida.get(&"current_health"))


func _on_dano_recebido(q: float) -> void:
	_dano_recebido += q


func _on_nivel(n: int) -> void:
	_niveis.append([snappedf(_manager.get_elapsed(), 0.1), n])


func _on_xp(v: float) -> void:
	_xp_coletado += v


func _on_dano_causado(q: float) -> void:
	_dano_causado += q


func _on_inimigo_entrou(no: Node) -> void:
	var vida := no.get_node_or_null("Health") as HealthComponent
	if vida != null:
		vida.damaged.connect(_on_dano_causado)
	# `apply_data()` roda antes de o no entrar na arvore, entao aqui os
	# valores do tipo ja estao no inimigo.
	var tipo := String(_tipo(no))
	if tipo != "" and not _vistos.has(tipo):
		_vistos[tipo] = {
			"move_speed": no.get(&"move_speed"),
			"max_health": vida.max_health if vida != null else null,
			"contact_damage": (no.get_node_or_null("Hitbox") as HitboxComponent).damage
				if no.get_node_or_null("Hitbox") != null else null,
		}
	# O tipo e lido na hora do golpe, e nao aqui: quando o no entra na arvore
	# o spawn pode ainda nao ter entregue os dados dele.
	var golpe := no.get_node_or_null("Hitbox") as HitboxComponent
	if golpe != null:
		golpe.hit_landed.connect(_on_golpe_recebido.bind(no))


func _on_golpe_recebido(_hurtbox: Node, dano: float, inimigo: Node) -> void:
	var tipo := String(_tipo(inimigo)) if is_instance_valid(inimigo) else "?"
	_dano_por_tipo[tipo] = float(_dano_por_tipo.get(tipo, 0.0)) + dano


func _aplicar_ajuste_de_no(texto: String) -> void:
	# "Player/Level.xp_growth=1.2"
	var lados := texto.split("=", false, 1)
	var ponto := lados[0].rfind(".")
	var no := _game.get_node_or_null(lados[0].substr(0, ponto))
	var campo := lados[0].substr(ponto + 1)
	if no == null or not campo in no:
		push_error("sonda: ajuste de no invalido: %s" % texto)
		quit(2)
		return
	var antes = no.get(campo)
	no.set(campo, float(lados[1]))
	print("sonda: no %s: %s -> %s" % [lados[0], str(antes), str(no.get(campo))])


func _aplicar_ajuste(texto: String) -> void:
	# "enemies/cao_demoniaco.move_speed=150"
	var lados := texto.split("=", false, 1)
	var alvo := lados[0]
	var ponto := alvo.rfind(".")
	var caminho := "res://resources/%s.tres" % alvo.substr(0, ponto)
	var campo := alvo.substr(ponto + 1)
	var recurso := load(caminho)
	if recurso == null or not campo in recurso:
		push_error("sonda: ajuste invalido: %s" % texto)
		quit(2)
		return
	var antes = recurso.get(campo)
	recurso.set(campo, float(lados[1]))
	_segurados.append(recurso)
	print("sonda: ajuste %s: %s -> %s" % [alvo, str(antes), str(recurso.get(campo))])


func _on_inimigo_saiu(_no: Node) -> void:
	# O spawn nunca recicla inimigo distante: sair da arvore e morrer.
	if not _terminou:
		_abates += 1


func _on_boss(boss: Node2D) -> void:
	_boss = boss
	_boss_vida = boss.get_node_or_null("Health") as HealthComponent
	_eventos.append(["boss_nasceu", snappedf(_manager.get_elapsed(), 0.1)])


func _amostrar(t: float) -> void:
	var armas := {}
	for id in [&"orbe_do_cajado", &"cajado_raio", &"vinha_espinhosa", &"corvo_espiritual",
			&"anel_de_esporos", &"vagalumes_guardioes"]:
		var n := _armas.get_weapon_level(id)
		if n > 0:
			armas[String(id)] = n
	_amostras.append({
		"t": snappedf(t, 0.1),
		"nivel": _level.level,
		"vida": snappedf(_vida_atual(), 0.1),
		"vida_max": snappedf(_vida.max_health, 0.1),
		"populacao": _inimigos.get_child_count(),
		"abates": _abates,
		"dano_causado": roundf(_dano_causado),
		"dano_recebido": roundf(_dano_recebido),
		"xp": roundf(_xp_coletado),
		"orbes_no_chao": _orbes.get_child_count(),
		"x": roundf(_player.global_position.x),
		"y": roundf(_player.global_position.y),
		"armas": armas,
	})
	if _perf and not _perf_quadro.is_empty():
		_amostras[-1]["perf"] = _resumo_perf()
		_perf_quadro.clear()
		_perf_fisica.clear()
	if _boss_vida != null and is_instance_valid(_boss):
		_boss_linha.append([snappedf(t, 0.1), roundf(float(_boss_vida.get(&"current_health")))])


## Distribuicao do custo de quadro na janela, o pico de fisica e o que havia
## em cena.
func _resumo_perf() -> Dictionary:
	var q := _perf_quadro.duplicate()
	q.sort()
	var soma := 0.0
	for v in q:
		soma += v
	var pico := 0.0
	for v in _perf_fisica:
		pico = maxf(pico, v)
	return {
		"quadro_media": snappedf(soma / q.size(), 0.01),
		"quadro_p95": snappedf(q[int((q.size() - 1) * 0.95)], 0.01),
		"quadro_p99": snappedf(q[int((q.size() - 1) * 0.99)], 0.01),
		"quadro_max": snappedf(q[-1], 0.01),
		"fisica_pico": snappedf(pico, 0.01),
		"efeitos": _efeitos.get_child_count() if _efeitos != null else -1,
		"projeteis": _projeteis.get_child_count() if _projeteis != null else -1,
		"nos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"fisica_ativos": int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
		"pares": int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)),
		"desenhos": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"memoria_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
	}


func _on_fim(vitoria: bool, tempo: float, nivel: int) -> void:
	_fim = {"desfecho": "vitoria" if vitoria else "derrota",
		"tempo": snappedf(tempo, 0.1), "nivel": nivel}
	_encerrar.call_deferred()


func _encerrar() -> void:
	if _terminou:
		return
	_amostrar(_manager.get_elapsed())
	_terminou = true
	var relatorio := {
		"semente": _semente,
		"politica": _politica,
		"parado": _parado,
		"ajustes": _ajustes,
		"invulneravel": _invulneravel,
		"ajustes_de_no": _ajustes_de_no,
		"armas_iniciais": _armas_iniciais,
		"dano_por_tipo": _dano_por_tipo,
		"vistos": _vistos,
		"fim": _fim,
		"vida_minima": snappedf(_vida_minima, 0.1),
		"abates": _abates,
		"amostras": _amostras,
		"niveis": _niveis,
		"escolhas": _escolhas,
		"boss": _boss_linha,
		"eventos": _eventos,
	}
	var f := FileAccess.open(_saida, FileAccess.WRITE)
	f.store_string(JSON.stringify(relatorio, "  "))
	f.close()
	print("sonda: %s aos %.0f s, nivel %d, %d abates -> %s"
		% [_fim.get("desfecho"), float(_fim.get("tempo", 0.0)), int(_fim.get("nivel", 0)),
		_abates, _saida])
	paused = false
	quit(0)
