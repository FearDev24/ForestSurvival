extends SceneTree
## Verificação do acerto das habilidades: a colisão casa com o desenho, e o
## inimigo recua quando o golpe pega.
##
## Uso:
##   godot --headless --path . --script res://tests/test_acerto.gd
##
## O jogador dizia que as habilidades "saem e parecem não bater". Medido, eram
## três coisas: a vinha para a esquerda com a colisão 48 px abaixo do desenho
## (o sprite espelhava, a colisão não), o raio com um círculo de 80 px num
## impacto de 160 a 190, e a vinha sem colisão nos primeiros 50 px da raiz.
##
## As medidas de desenho saem **das próprias texturas**, quadro a quadro, e não
## de números anotados aqui: se a arte mudar, este teste diz que a colisão
## ficou para trás.

const EFEITOS := "res://scenes/effects/"
const LONGE := Vector2(-4000.0, -4000.0)
const GAME_SCENE := "res://scenes/game/game.tscn"

var _failures: Array[String] = []
var _stage := 0
var _frames := 2
var _efeitos := {}

var _game: Node = null
var _atingido: Node2D = null
var _morto: Node2D = null
var _boss: Node2D = null
var _pos := {}


func _initialize() -> void:
	for nome in ["lightning_strike", "vine_lash", "spirit_crow", "guardian_fireflies", "spore_ring"]:
		var efeito := (load(EFEITOS + nome + ".tscn") as PackedScene).instantiate() as Node2D
		efeito.position = LONGE
		root.add_child(efeito)
		_efeitos[nome] = efeito
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false
	match _stage:
		0:
			_check_raio()
			_check_vinha()
			_check_corvo()
			_check_vagalumes()
			_check_esporos()
			for efeito in _efeitos.values():
				efeito.queue_free()
			_montar_recuo()
			_stage = 1
			_frames = 15
		1:
			_check_recuo()
			_check_profundidade()
			_montar_pedra()
			# A pedra só vale para a física no passo seguinte: sem esperar, a
			# checagem de chão livre não a veria, e este teste passaria à toa.
			_stage = 2
			_frames = 4
		2:
			_check_chao_livre()
			_report()
			quit(0 if _failures.is_empty() else 1)
			return true
	return false


# --------------------------------------------------------------- geometria --


## Retângulo, no espaço do efeito, onde o quadro tem tinta.
func _desenho(efeito: Node2D, quadro: int) -> Rect2:
	var sprite := efeito.get_node("Sprite") as AnimatedSprite2D
	var textura := sprite.sprite_frames.get_frame_texture(sprite.animation, quadro)
	var img := textura.get_image()
	var w := img.get_width()
	var h := img.get_height()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.16:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2()
	if sprite.flip_v:
		var t := y0
		y0 = h - 1 - y1
		y1 = h - 1 - t
	if sprite.flip_h:
		var t := x0
		x0 = w - 1 - x1
		x1 = w - 1 - t
	var canto := sprite.position + sprite.offset - Vector2(w, h) * 0.5
	var local := Rect2(canto + Vector2(x0, y0), Vector2(x1 - x0, y1 - y0))
	# Do espaço do sprite para o do efeito, com a rotação da mira.
	return _transformar(Transform2D(efeito.rotation, Vector2.ZERO), local)


## Parte do quadro com tinta abaixo de uma altura (onde o raio encosta no chão).
func _desenho_perto_do_chao(efeito: Node2D, quadro: int, altura: float) -> Rect2:
	var sprite := efeito.get_node("Sprite") as AnimatedSprite2D
	var img := sprite.sprite_frames.get_frame_texture(sprite.animation, quadro).get_image()
	var w := img.get_width()
	var h := img.get_height()
	var canto := sprite.position + sprite.offset - Vector2(w, h) * 0.5
	var x0 := INF
	var x1 := -INF
	var y1 := -INF
	for y in h:
		var yl := canto.y + y
		if yl < altura:
			continue
		for x in w:
			if img.get_pixel(x, y).a > 0.16:
				x0 = minf(x0, canto.x + x)
				x1 = maxf(x1, canto.x + x)
				y1 = maxf(y1, yl)
	if x1 < x0:
		return Rect2()
	return Rect2(Vector2(x0, altura), Vector2(x1 - x0, y1 - altura))


## Retângulo, no espaço do efeito, que a colisão ocupa.
func _colisao(efeito: Node2D) -> Rect2:
	var hitbox := efeito.get_node("Hitbox") as Node2D
	var forma := hitbox.get_node("CollisionShape2D") as CollisionShape2D
	var t := Transform2D(efeito.rotation, Vector2.ZERO) * hitbox.transform * forma.transform
	return _transformar(t, forma.shape.get_rect())


func _transformar(t: Transform2D, r: Rect2) -> Rect2:
	var pontos := [r.position, r.position + Vector2(r.size.x, 0.0),
		r.position + Vector2(0.0, r.size.y), r.end]
	var saida := Rect2(t * pontos[0], Vector2.ZERO)
	for p in pontos:
		saida = saida.expand(t * p)
	return saida


func _faixa(efeito: AbilityEffect, quadros: int) -> Array[int]:
	var faixa: Array[int] = []
	var ultimo := efeito.impact_last_frame if efeito.impact_last_frame >= 0 else quadros - 1
	for q in range(efeito.impact_frame, ultimo + 1):
		faixa.append(q)
	return faixa


# ------------------------------------------------------------------ efeitos --


## O raio: a colisão cobre a largura do impacto no chão, e só pega nos quadros
## em que o desenho encosta.
func _check_raio() -> void:
	var efeito := _efeitos["lightning_strike"] as AbilityEffect
	var sprite := efeito.get_node("Sprite") as AnimatedSprite2D
	var total := sprite.sprite_frames.get_frame_count(sprite.animation)
	var larguras: Array[float] = []
	for q in total:
		var chao := _desenho_perto_do_chao(efeito, q, -12.0)
		var encosta := chao.size.x > 20.0
		var pega := q >= efeito.impact_frame and (efeito.impact_last_frame < 0 or q <= efeito.impact_last_frame)
		if encosta != pega:
			_fail("Raio, quadro %d: o desenho %s o chão e a colisão %s" % [
				q, "encosta" if encosta else "não encosta", "pega" if pega else "não pega"])
		if encosta:
			larguras.append(maxf(absf(chao.position.x), absf(chao.end.x)))
	if larguras.is_empty():
		_fail("Raio: nenhum quadro encosta no chão")
		return
	var media := 0.0
	var maior := 0.0
	for l in larguras:
		media += l
		maior = maxf(maior, l)
	media /= larguras.size()
	var colisao := _colisao(efeito)
	var metade := maxf(absf(colisao.position.x), absf(colisao.end.x))
	if metade < media * 0.85 or metade > maior * 1.1:
		_fail("Raio: a colisão vai a %.0f px do centro, o impacto no chão vai a %.0f em média (até %.0f)" % [
			metade, media, maior])


## A vinha, para a direita **e** para a esquerda: a colisão fica sobre o
## desenho, da raiz à ponta.
func _check_vinha() -> void:
	var efeito := _efeitos["vine_lash"] as AbilityEffect
	for lado in [Vector2.RIGHT, Vector2.LEFT]:
		efeito.aim(lado)
		var nome := "direita" if lado == Vector2.RIGHT else "esquerda"
		var colisao := _colisao(efeito)
		var sprite := efeito.get_node("Sprite") as AnimatedSprite2D
		var alcance := Rect2()
		for q in _faixa(efeito, sprite.sprite_frames.get_frame_count(sprite.animation)):
			var d := _desenho(efeito, q)
			alcance = d if alcance.size == Vector2.ZERO else alcance.merge(d)
		var dy := absf(colisao.get_center().y - alcance.get_center().y)
		if dy > 10.0:
			_fail("Vinha para a %s: a colisão está %.0f px fora do desenho na vertical" % [nome, dy])
		# A vinha brota do chão: o pé do desenho e o da colisão ficam na altura
		# da raiz, nos dois sentidos. Girar 180° para virar pendurava os dois
		# juntos ~70 px abaixo do ponto de onde ela nasce — coincidiam entre si,
		# e mesmo assim a vinha flutuava.
		if alcance.end.y > 10.0 or colisao.end.y > 10.0:
			_fail("Vinha para a %s: não está apoiada no chão — o desenho vai até %.0f px e a colisão até %.0f px abaixo da raiz" % [
				nome, alcance.end.y, colisao.end.y])
		var sobra := minf(colisao.end.x, alcance.end.x) - maxf(colisao.position.x, alcance.position.x)
		if sobra < alcance.size.x * 0.85:
			_fail("Vinha para a %s: a colisão cobre %.0f dos %.0f px do chicote" % [nome, maxf(0.0, sobra), alcance.size.x])


## O corvo: a colisão tem o tamanho do corpo, não do quadro.
func _check_corvo() -> void:
	var efeito := _efeitos["spirit_crow"] as Node2D
	var sprite := efeito.get_node("Sprite") as AnimatedSprite2D
	var larguras: Array[float] = []
	var alturas: Array[float] = []
	for q in sprite.sprite_frames.get_frame_count(sprite.animation):
		var d := _desenho(efeito, q)
		larguras.append(d.size.x)
		alturas.append(d.size.y)
	larguras.sort()
	alturas.sort()
	var corpo := Vector2(larguras[larguras.size() / 2], alturas[alturas.size() / 2])
	var colisao := _colisao(efeito).size
	for eixo in [["largura", colisao.x, corpo.x], ["altura", colisao.y, corpo.y]]:
		var razao: float = eixo[1] / maxf(1.0, eixo[2])
		if razao < 0.8 or razao > 1.25:
			_fail("Corvo: a colisão tem %.0f px de %s, o corpo tem %.0f" % [eixo[1], eixo[0], eixo[2]])


## Os vagalumes: a colisão é o orbe desenhado e um pouco do brilho.
func _check_vagalumes() -> void:
	var efeito := _efeitos["guardian_fireflies"] as Node2D
	var desenhado: float = efeito.get("orb_radius")
	for filho in efeito.get_children():
		var forma := filho.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if forma == null:
			continue
		var raio := (forma.shape as CircleShape2D).radius
		if raio < desenhado or raio > desenhado * 1.5:
			_fail("Vagalume: colisão de raio %.0f para um orbe desenhado com %.0f" % [raio, desenhado])
			return


## Os esporos: a colisão é o círculo desenhado.
func _check_esporos() -> void:
	var efeito := _efeitos["spore_ring"] as Node2D
	var desenhado: float = efeito.get("visual_radius")
	var forma := efeito.get_node("Hitbox/CollisionShape2D") as CollisionShape2D
	var raio := (forma.shape as CircleShape2D).radius
	if absf(raio - desenhado) > 1.0:
		_fail("Esporos: colisão de raio %.0f para um anel desenhado com %.0f" % [raio, desenhado])


# -------------------------------------------------------------------- recuo --


func _montar_recuo() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	spawn.enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false
	(_game.get_node("Player/WeaponManager") as WeaponManager).set_weapons_enabled(false)
	var imp := load("res://resources/enemies/imp_corrompido.tres") as EnemyData
	var guardiao := load("res://resources/enemies/guardiao_profanado.tres") as EnemyData

	_atingido = _nascer(spawn, imp, Vector2(400.0, 0.0))
	_morto = _nascer(spawn, imp, Vector2(400.0, 300.0))
	_boss = _nascer(spawn, guardiao, Vector2(-400.0, 300.0))

	# Golpe que não mata, vindo da esquerda: recua para a direita.
	_golpear(_atingido, 1.0)
	# Golpe que mata: nada de empurrão.
	_golpear(_morto, 99999.0)
	if is_instance_valid(_morto) and (_morto.get("_recuo") as Vector2) != Vector2.ZERO:
		_fail("Um golpe que mata empurrou o inimigo")
	# O Guardião não recua.
	_golpear(_boss, 1.0)


func _nascer(spawn: SpawnManager, dados: EnemyData, desvio: Vector2) -> Node2D:
	var inimigo := spawn.spawn_data(dados)
	var druida := _game.get_node("Player") as Node2D
	inimigo.global_position = druida.global_position + desvio
	# Sem perseguir: o único movimento que sobra é o recuo.
	inimigo.set("_target", null)
	_pos[inimigo] = inimigo.global_position
	return inimigo


func _golpear(inimigo: Node2D, dano: float) -> void:
	var fonte := Node2D.new()
	root.add_child(fonte)
	fonte.global_position = inimigo.global_position + Vector2(-40.0, 0.0)
	(inimigo.get_node("Hurtbox") as HurtboxComponent).take_damage(dano, fonte)
	fonte.queue_free()


func _check_recuo() -> void:
	if is_instance_valid(_atingido):
		var andou: Vector2 = _atingido.global_position - _pos[_atingido]
		if andou.x < 8.0 or andou.x > 40.0 or absf(andou.y) > 3.0:
			_fail("O golpe da esquerda deveria empurrar o inimigo uns 18 px para a direita; andou %s" % str(andou))
	else:
		_fail("O inimigo atingido sem morrer sumiu")
	if is_instance_valid(_morto):
		_fail("O golpe letal não matou o inimigo")
	if is_instance_valid(_boss):
		var andou: float = (_boss.global_position - _pos[_boss]).length()
		if andou > 1.0:
			_fail("O Guardião recuou %.1f px: ele não deveria se mexer" % andou)


# ------------------------------------------------------ profundidade e chão --


## Quem nasce do chão entra na mesma ordem de profundidade das pedras; quem vem
## do céu ou voa fica por cima de tudo; a zona de esporos fica embaixo delas.
func _check_profundidade() -> void:
	var conteiner := _game.get_node("EffectContainer") as Node2D
	if not conteiner.y_sort_enabled:
		_fail("Os efeitos não entram na ordem de profundidade: a vinha seria desenhada por cima das pedras")
	for regra in [
		["vine_lash", 0, 0, "nasce do chão: mesma profundidade das pedras (z 0)"],
		["spore_ring", -100, -1, "fica no chão: embaixo das pedras (z negativo)"],
		["lightning_strike", 1, 100, "vem do céu: por cima de tudo"],
		["spirit_crow", 1, 100, "voa: por cima de tudo"],
		["guardian_fireflies", 1, 100, "voam: por cima de tudo"],
	]:
		var cena := (load(EFEITOS + regra[0] + ".tscn") as PackedScene).instantiate() as Node2D
		if cena.z_index < regra[1] or cena.z_index > regra[2]:
			_fail("%s está em z_index %d, mas %s" % [regra[0], cena.z_index, regra[3]])
		cena.free()


var _pedra := Rect2()
var _alvo_da_vinha: Node2D = null


func _montar_pedra() -> void:
	var druida := _game.get_node("Player") as Node2D
	var pedra := StaticBody2D.new()
	pedra.collision_layer = 1 << (TestWorld.WORLD_STATIC_LAYER - 1)
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(80.0, 80.0)
	forma.shape = retangulo
	pedra.add_child(forma)
	_game.add_child(pedra)
	pedra.global_position = druida.global_position + Vector2(200.0, -20.0)
	_pedra = Rect2(pedra.global_position - retangulo.size * 0.5, retangulo.size)
	_alvo_da_vinha = Node2D.new()
	_game.add_child(_alvo_da_vinha)
	_alvo_da_vinha.global_position = druida.global_position + Vector2(300.0, 0.0)


## Com uma pedra ao lado do druida, nenhuma vinha nasce atravessando ela — e a
## maioria ainda nasce: uma checagem que recusasse tudo também "passaria".
func _check_chao_livre() -> void:
	# Desde a DEC-025 o druida nasce só com o Orbe do Cajado: a vinha entra à mão.
	var gerente := _game.get_node("Player/WeaponManager") as WeaponManager
	if not gerente.has_weapon(&"vinha_espinhosa"):
		gerente.add_weapon(load("res://resources/weapons/vinha_espinhosa.tres") as WeaponData)
	var vinha: Weapon = null
	for filho in _game.get_node("Player/WeaponManager").get_children():
		var arma := filho as Weapon
		if arma != null and arma.data != null and arma.data.id == &"vinha_espinhosa":
			vinha = arma
	if vinha == null:
		_fail("O druida não tem a Vinha Espinhosa para o teste de chão livre")
		return
	var golpes: Array[Node2D] = []
	var ouvir := func(efeito: Node2D, _alvo: Node2D) -> void: golpes.append(efeito)
	vinha.attacked.connect(ouvir)
	for i in 60:
		vinha._attack(_alvo_da_vinha)
	vinha.attacked.disconnect(ouvir)
	if golpes.size() < 20:
		_fail("Só %d de 60 vinhas nasceram: a checagem de chão livre está recusando demais" % golpes.size())
	var atravessou := 0
	for efeito in golpes:
		var forma := efeito.get_node("Hitbox/CollisionShape2D") as CollisionShape2D
		if _transformar(forma.global_transform, forma.shape.get_rect()).intersects(_pedra):
			atravessou += 1
	if atravessou > 0:
		_fail("%d de %d vinhas nasceram atravessando a pedra" % [atravessou, golpes.size()])


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ACERTO OK — colisões sobre o desenho, recuo só em golpe que não mata, vinha só em chão livre e na profundidade das pedras.")
		return
	printerr("ACERTO FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
