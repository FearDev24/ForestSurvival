extends SceneTree
## Verificação da FASE 7 — Três famílias de arma.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase7.gd
##
## O critério da fase é que as três famílias sejam **sensivelmente diferentes**,
## e o que separa uma da outra é como o ataque termina:
##
## | Família | O que a define |
## |---|---|
## | golpe (`AbilityEffect`) | acontece num ponto e some com a animação |
## | projétil (`ProjectileEffect`) | viaja, e some ao atravessar N inimigos ou esgotar o voo |
## | zona (`ZoneEffect`) | fica no chão e bate repetido enquanto dura |
## | orbital (`OrbitEffect`) | gira em volta do druida e vai junto com ele |
##
## Este teste checa exatamente isso, e checa que acrescentar uma família não
## quebrou as armas antigas — o `WeaponData` ganhou campos, e uma arma que não
## os preenche precisa continuar funcionando igual.
##
## Não julga arte (DEC-013): a zona é um círculo desenhado em código.

const ARMAS := "res://resources/weapons/"

var _failures: Array[String] = []

var _game: Node = null
var _weapons: WeaponManager = null
var _efeitos: Node = null
var _inimigos: Node = null

var _stage := 0
var _frames_left := 0
var _corvo: Node2D = null
var _zona: Node2D = null
var _pos_inicial := Vector2.ZERO


func _initialize() -> void:
	_check_familias()
	_check_campos_opcionais()
	_check_projetil_isolado()
	_check_zona_isolada()
	_check_orbital_isolado()

	if not _build_running_scene():
		_report()
		quit(1)


func _physics_process(_delta: float) -> bool:
	match _stage:
		0:
			_frames_left -= 1
			if _frames_left <= 0:
				_achar_corvo()
		1:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_corvo_andou()
				_start_zona()
		2:
			_frames_left -= 1
			if _frames_left <= 0:
				_check_zona_fica()
				_finish()
				return true
	return false


# ---------------------------------------------------------------- famílias --


## Três famílias quer dizer três comportamentos, não três `.tres` com números
## diferentes. Cada uma tem de ter um script próprio de fim de vida.
func _check_familias() -> void:
	var esperado := {
		"cajado_raio": "AbilityEffect",
		"vinha_espinhosa": "AbilityEffect",
		"corvo_espiritual": "ProjectileEffect",
		"anel_de_esporos": "ZoneEffect",
		"vagalumes_guardioes": "OrbitEffect",
	}

	var familias := {}
	for chave in esperado:
		var id: String = chave
		var caminho := ARMAS + id + ".tres"
		if not ResourceLoader.exists(caminho):
			_fail("Arma não encontrada: %s" % caminho)
			continue
		var data := load(caminho) as WeaponData
		if data == null or not data.is_valid():
			_fail("%s não é um WeaponData válido" % id)
			continue
		if data.effect_scene == null:
			_fail("%s sem cena de ataque" % id)
			continue

		var efeito := data.effect_scene.instantiate()
		var script := efeito.get_script() as Script
		var nome := "<sem script>"
		if script != null:
			nome = String(script.get_global_name())
		var alvo_familia: String = esperado[id]
		if nome != alvo_familia:
			_fail("%s deveria usar %s, usa %s" % [id, alvo_familia, nome])
		familias[nome] = true

		# Procura por tipo, não por nome: o orbital tem três hitboxes chamadas
		# Orbe0..2, e exigir o nome "Hitbox" acusaria uma família legítima.
		var hitboxes: Array[HitboxComponent] = []
		for filho in efeito.get_children():
			var hb := filho as HitboxComponent
			if hb != null:
				hitboxes.append(hb)
		if hitboxes.is_empty():
			_fail("%s sem nenhuma hitbox" % id)
		for hb in hitboxes:
			# O 1.0 é marcador: se sair 1 de dano em jogo, alguém esqueceu de
			# chamar set_damage(). Um valor "certo" na cena esconderia isso.
			if not is_equal_approx(hb.damage, 1.0):
				_fail("%s: dano da cena deveria ser o marcador 1.0, é %.1f" % [id, hb.damage])
		efeito.free()

	if familias.size() < 4:
		_fail("Esperava quatro famílias distintas, achei %d: %s" % [familias.size(), str(familias.keys())])


## A zona é a única que bate repetido — é isso que a torna uma família e não
## mais um golpe.
func _check_zona_isolada() -> void:
	var cena := load("res://scenes/effects/spore_ring.tscn") as PackedScene
	if cena == null:
		_fail("Cena da zona não encontrada")
		return
	var zona := cena.instantiate()
	var hitbox := zona.get_node_or_null("Hitbox") as HitboxComponent
	if hitbox == null:
		_fail("A zona não tem Hitbox")
	elif hitbox.hit_interval <= 0.0:
		_fail("A zona deveria bater repetido: hit_interval %.2f" % hitbox.hit_interval)

	# E as outras duas batem uma vez por alvo.
	var outras: Array[String] = ["res://scenes/effects/lightning_strike.tscn",
		"res://scenes/effects/spirit_crow.tscn"]
	for caminho in outras:
		var outro := (load(caminho) as PackedScene).instantiate()
		var hb := outro.get_node_or_null("Hitbox") as HitboxComponent
		if hb != null and not is_zero_approx(hb.hit_interval):
			_fail("%s deveria bater uma vez por alvo, tem hit_interval %.2f" % [caminho, hb.hit_interval])
		outro.free()

	zona.free()


## Campos de família são opcionais: zero quer dizer "usa o da cena".
##
## Sem isso, acrescentar `projectile_speed` obrigaria o raio e a vinha — que não
## voam — a preencher um número que não lhes diz respeito.
func _check_campos_opcionais() -> void:
	var raio := load(ARMAS + "cajado_raio.tres") as WeaponData
	if raio == null:
		return
	if raio.projectile_speed != 0.0 or raio.projectile_pierce != 0 or raio.effect_duration != 0.0:
		_fail("O raio não deveria preencher campo de família alheia")

	var corvo := load(ARMAS + "corvo_espiritual.tres") as WeaponData
	if corvo != null and corvo.projectile_speed <= 0.0:
		_fail("O corvo precisa de velocidade de voo: %.1f" % corvo.projectile_speed)

	var esporos := load(ARMAS + "anel_de_esporos.tres") as WeaponData
	if esporos != null and esporos.effect_duration <= 0.0:
		_fail("A zona precisa de duração: %.1f" % esporos.effect_duration)


## O projétil some sozinho quando o tempo acaba, mesmo sem acertar ninguém.
## Sem isso ele viajaria para sempre, custando física até o fim da partida.
func _check_projetil_isolado() -> void:
	var cena := load("res://scenes/effects/spirit_crow.tscn") as PackedScene
	if cena == null:
		_fail("Cena do corvo não encontrada")
		return

	var p := cena.instantiate() as Node2D
	root.add_child(p)
	p.set_lifetime(0.5)
	p.set_speed(100.0)
	p.aim(Vector2.RIGHT)

	for _i in range(6):
		p._physics_process(0.05)
	if not is_instance_valid(p) or p.is_queued_for_deletion():
		_fail("O projétil sumiu antes do tempo")
	elif not is_equal_approx(p.global_position.x, 30.0):
		_fail("0,3 s a 100 px/s deveria andar 30 px, andou %.1f" % p.global_position.x)

	for _i in range(6):
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			p._physics_process(0.05)
	if is_instance_valid(p) and not p.is_queued_for_deletion():
		_fail("O projétil não sumiu depois de esgotar o tempo de voo")
		p.free()


## O orbital é o único que **acompanha**: os outros três ficam onde nasceram.
##
## Testado sem cena de partida, movendo o alvo à mão — é a diferença que define
## a família, e ela não depende de arma nem de inimigo.
func _check_orbital_isolado() -> void:
	var cena := load("res://scenes/effects/guardian_fireflies.tscn") as PackedScene
	if cena == null:
		_fail("Cena dos vagalumes não encontrada")
		return

	var druida := Node2D.new()
	root.add_child(druida)
	druida.global_position = Vector2(100.0, 100.0)

	var orb := cena.instantiate() as Node2D
	orb.set_duration(1.0)
	orb.set_damage(42.0)
	root.add_child(orb)
	orb.set_follow(druida)

	if not is_equal_approx(orb.global_position.x, 100.0):
		_fail("O orbital deveria nascer sobre quem acompanha: %.1f" % orb.global_position.x)

	# Os três orbes precisam estar espalhados, não empilhados no centro.
	var distancias: Array[float] = []
	for filho in orb.get_children():
		var area := filho as Area2D
		if area != null:
			distancias.append(area.position.length())
			if not is_equal_approx((area as HitboxComponent).damage, 42.0):
				_fail("set_damage() não alcançou todos os orbes: %.1f" % (area as HitboxComponent).damage)
	if distancias.size() != 3:
		_fail("Esperava três orbes, achei %d" % distancias.size())
	for d in distancias:
		if absf(d - orb.radius) > 1.0:
			_fail("Orbe fora do raio: %.1f, esperado %.1f" % [d, orb.radius])

	# O druida anda; os orbes vão junto.
	var angulo_antes: Vector2 = (orb.get_child(0) as Area2D).position
	druida.global_position = Vector2(400.0, 100.0)
	orb._physics_process(0.1)
	if not is_equal_approx(orb.global_position.x, 400.0):
		_fail("O orbital não acompanhou o druida: %.1f" % orb.global_position.x)
	if (orb.get_child(0) as Area2D).position.distance_to(angulo_antes) < 1.0:
		_fail("Os orbes não giraram")

	# E some quando a duração acaba.
	for _i in range(12):
		if is_instance_valid(orb) and not orb.is_queued_for_deletion():
			orb._physics_process(0.1)
	if is_instance_valid(orb) and not orb.is_queued_for_deletion():
		_fail("O orbital não sumiu depois da duração")
		orb.free()
	druida.free()


# ------------------------------------------------------------ comportamento --


func _build_running_scene() -> bool:
	if not ResourceLoader.exists("res://scenes/game/game.tscn"):
		_fail("game.tscn não encontrada")
		return false

	_game = (load("res://scenes/game/game.tscn") as PackedScene).instantiate()
	root.add_child(_game)

	_weapons = _game.get_node_or_null("Player/WeaponManager") as WeaponManager
	_efeitos = _game.get_node_or_null("EffectContainer")
	_inimigos = _game.get_node_or_null("EnemyContainer")
	var spawn := _game.get_node_or_null("SpawnManager") as SpawnManager
	if spawn != null:
		spawn.enabled = false

	if _weapons == null or _efeitos == null or _inimigos == null:
		_fail("game.tscn sem WeaponManager, EffectContainer ou EnemyContainer")
		return false

	# Só o corvo, para o EffectContainer não encher de raio e vinha.
	_weapons.set_weapons_enabled(false)
	var corvo := load(ARMAS + "corvo_espiritual.tres") as WeaponData
	if corvo == null or not _weapons.add_weapon(corvo):
		_fail("Não consegui equipar o corvo")
		return false

	var alvo := (load("res://scenes/enemies/enemy.tscn") as PackedScene).instantiate() as CharacterBody2D
	_inimigos.add_child(alvo)
	alvo.global_position = Vector2(300.0, 0.0)
	alvo.set_physics_process(false)

	_weapons.set_weapons_enabled(true)
	_frames_left = 85
	_stage = 0
	return true


## O disparo só acontece depois do cooldown da arma — 1,3 s, ou 78 passos de
## física. Esperar dez quadros não provaria nada.
func _achar_corvo() -> void:
	for filho in _efeitos.get_children():
		if filho is ProjectileEffect:
			_corvo = filho as Node2D
			break
	if _corvo == null:
		_fail("O corvo não criou nenhum projétil em 85 quadros")
		_frames_left = 1
		_stage = 1
		return
	_pos_inicial = _corvo.global_position
	_frames_left = 6
	_stage = 1


## Medido alguns quadros **depois** de anotar a posição. Na primeira versão a
## anotação e a comparação aconteciam no mesmo quadro, e a distância era zero
## por construção — o teste não teria como falhar nem como passar por mérito.
func _check_corvo_andou() -> void:
	if _corvo == null or not is_instance_valid(_corvo):
		return
	var andou := _corvo.global_position.distance_to(_pos_inicial)
	if andou < 1.0:
		_fail("O projétil ficou parado: um ataque que viaja precisa viajar")


func _start_zona() -> void:
	# Desliga as armas: daqui em diante o teste quer ver a cena **esvaziar**, e
	# um corvo novo a cada 1,3 s nunca deixaria.
	_weapons.set_weapons_enabled(false)

	var zona := (load("res://scenes/effects/spore_ring.tscn") as PackedScene).instantiate() as Node2D
	zona.set_duration(0.4)
	_efeitos.add_child(zona)
	_zona = zona
	# 115 quadros: mais que a duração da zona (0,4 s) e mais que o voo de um
	# corvo já no ar (1,8 s). Menos que isso, sobra efeito por estar vivo, não
	# por vazamento, e o teste acusaria o inocente.
	_frames_left = 115
	_stage = 2


## A zona precisa **durar**. Se sumisse no mesmo quadro, seria um golpe.
func _check_zona_fica() -> void:
	if is_instance_valid(_zona) and not _zona.is_queued_for_deletion():
		_fail("A zona não sumiu depois da duração dela")
	var restantes := 0
	for filho in _efeitos.get_children():
		if not filho.is_queued_for_deletion():
			restantes += 1
	if restantes > 0:
		_fail("Sobraram %d efeitos na cena: ataque que não se limpa vira vazamento" % restantes)


# ------------------------------------------------------------------ relato --


func _finish() -> void:
	if _game != null:
		_game.queue_free()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 7 OK — golpe, projétil, zona e orbital: quatro famílias distintas.")
		return
	printerr("FASE 7 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
