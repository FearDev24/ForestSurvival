extends SceneTree
## Verificação da progressão de habilidades por fase (DEC-025).
##
## Uso:
##   godot --headless --path . --script res://tests/test_progressao.gd
##
## O druida nasce só com o Orbe do Cajado e ganha as outras habilidades ao longo
## da partida, cada uma a partir da sua fase. Antes disto ele nascia com o
## Cajado e a Vinha, e a sonda mostrou que tinha quatro das cinco habilidades
## aos 40 s — sem "habilidade de cada fase".
##
## Confere:
## - o druida nasce só com o Orbe;
## - cada arma do catálogo tem a fase da tabela aprovada, e as passivas não
##   têm trava;
## - o sorteio **não oferece** uma arma antes da hora, e passa a oferecer na hora;
## - o Orbe acerta onde é desenhado, sai da altura do cajado e mira direto no
##   inimigo, em qualquer direção.

const GAME_SCENE := "res://scenes/game/game.tscn"
const ORBE_SCENE := "res://scenes/effects/orbe_do_cajado.tscn"

## A tabela aprovada: segundos de partida a partir dos quais cada arma é oferecida.
const TABELA := {
	&"arma_orbe_do_cajado": 0.0,
	&"arma_vinha_espinhosa": 30.0,
	&"arma_cajado_raio": 60.0,
	&"arma_corvo_espiritual": 150.0,
	&"arma_anel_de_esporos": 150.0,
	&"arma_vagalumes_guardioes": 270.0,
}

var _failures: Array[String] = []
var _game: Node = null
var _frames := 3


func _initialize() -> void:
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false
	(_game.get_node("SpawnManager") as SpawnManager).enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false
	_check_inicio()
	_check_tabela()
	_check_liberacao()
	_check_orbe()
	_check_mira()
	_report()
	quit(0 if _failures.is_empty() else 1)
	return true


func _check_inicio() -> void:
	var armas := _game.get_node("Player/WeaponManager") as WeaponManager
	if armas.get_weapon_count() != 1 or not armas.has_weapon(&"orbe_do_cajado"):
		_fail("O druida deveria nascer só com o Orbe do Cajado; nasce com %d arma(s)%s" % [
			armas.get_weapon_count(), "" if armas.has_weapon(&"orbe_do_cajado") else ", sem o Orbe"])


func _check_tabela() -> void:
	var pool := _game.get_node("UpgradePool") as UpgradePool
	var vistos := {}
	for upgrade in pool.catalogo:
		if upgrade.kind == UpgradeData.Kind.ARMA:
			vistos[upgrade.id] = true
			if not TABELA.has(upgrade.id):
				_fail("A arma %s está no catálogo sem fase definida" % upgrade.id)
			elif not is_equal_approx(upgrade.unlock_time, TABELA[upgrade.id]):
				_fail("%s é liberada aos %.0f s; a tabela aprovada diz %.0f s" % [
					upgrade.id, upgrade.unlock_time, TABELA[upgrade.id]])
		elif upgrade.unlock_time > 0.0:
			_fail("A passiva %s tem trava de tempo: passivas valem desde o começo" % upgrade.id)
	for id in TABELA:
		if not vistos.has(id):
			_fail("%s não está no catálogo" % id)


## O sorteio olha o relógio: um segundo antes da fase não oferece, na fase oferece.
func _check_liberacao() -> void:
	var pool := _game.get_node("UpgradePool") as UpgradePool
	var manager := _game.get_node("GameManager") as GameManager
	for t in [0.0, 29.0, 30.0, 59.0, 60.0, 149.0, 150.0, 269.0, 270.0]:
		manager.set("_elapsed", t)
		var ofertaveis := {}
		for upgrade in pool.aplicaveis():
			ofertaveis[upgrade.id] = true
		for id in TABELA:
			if id == &"arma_orbe_do_cajado":
				continue  # já equipado: subir o nível dele vale desde o começo
			var deveria: bool = t >= TABELA[id]
			if ofertaveis.has(id) != deveria:
				_fail("Aos %.0f s, %s %s oferecida" % [t, id, "deveria ser" if deveria else "não deveria ser"])
	manager.set("_elapsed", 0.0)


## O Orbe acerta onde é desenhado: a colisão cobre o núcleo e um pouco do
## brilho. Com a arte no lugar, o núcleo medido sai da própria textura, já na
## escala do sprite — se a folha mudar, este teste diz que a colisão ficou para
## trás. Sem arte, vale o raio do placeholder desenhado em código.
func _check_orbe() -> void:
	var cena := (load(ORBE_SCENE) as PackedScene).instantiate() as Node2D
	var sprite := cena.get_node_or_null("Sprite") as AnimatedSprite2D
	var desenho: float = _raio_da_arte(sprite) if sprite != null else cena.get("raio_desenho")
	var forma := cena.get_node("Hitbox/CollisionShape2D") as CollisionShape2D
	var raio := (forma.shape as CircleShape2D).radius
	if raio < desenho * 0.85 or raio > desenho * 1.3:
		_fail("Orbe: colisão de raio %.0f para um desenho de %.0f" % [raio, desenho])
	if cena.z_index <= 0:
		_fail("Orbe em z_index %d: ele voa na altura do cajado, por cima do chão" % cena.z_index)
	cena.free()


## Raio visível da arte, quadro a quadro, já na escala do sprite: fica a
## mediana, porque o orbe pulsa entre 24 e 28 px de raio.
func _raio_da_arte(sprite: AnimatedSprite2D) -> float:
	var raios: Array[float] = []
	for q in sprite.sprite_frames.get_frame_count(sprite.animation):
		var img := sprite.sprite_frames.get_frame_texture(sprite.animation, q).get_image()
		var w := img.get_width()
		var h := img.get_height()
		var cx := (w - 1) * 0.5
		var cy := (h - 1) * 0.5
		var raio := 0.0
		for y in h:
			for x in w:
				if img.get_pixel(x, y).a > 0.16:
					raio = maxf(raio, maxf(absf(x - cx), absf(y - cy)))
		raios.append(raio * absf(sprite.scale.x))
	raios.sort()
	return raios[raios.size() / 2]


## Sai da altura do cajado e vai reto no inimigo, na diagonal inclusive — é o
## que um orbe redondo pode fazer e as habilidades desenhadas de lado não.
func _check_mira() -> void:
	var orbe: Weapon = null
	for filho in _game.get_node("Player/WeaponManager").get_children():
		var arma := filho as Weapon
		if arma != null and arma.data != null and arma.data.id == &"orbe_do_cajado":
			orbe = arma
	if orbe == null:
		_fail("Sem a arma do Orbe no druida para conferir a mira")
		return
	var druida := _game.get_node("Player") as Node2D
	var alvo := Node2D.new()
	_game.add_child(alvo)
	alvo.global_position = druida.global_position + Vector2(150.0, 150.0)
	var disparos: Array[Node2D] = []
	var ouvir := func(efeito: Node2D, _a: Node2D) -> void: disparos.append(efeito)
	orbe.attacked.connect(ouvir)
	orbe._attack(alvo)
	orbe.attacked.disconnect(ouvir)
	if disparos.is_empty():
		_fail("O Orbe não disparou")
		return
	var efeito := disparos[0]
	var saida := efeito.global_position - druida.global_position
	if saida.y > -10.0:
		_fail("O Orbe sai a %.0f px dos pés do druida: deveria sair da altura do cajado" % -saida.y)
	var esperado := (alvo.global_position + orbe.data.spawn_offset - efeito.global_position).angle()
	if absf(angle_difference(efeito.rotation, esperado)) > 0.05:
		_fail("O Orbe mirou a %.0f°, o inimigo estava a %.0f°" % [rad_to_deg(efeito.rotation), rad_to_deg(esperado)])


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("PROGRESSÃO OK — nasce só com o Orbe, cada arma na sua fase, e o Orbe acerta onde é desenhado.")
		return
	printerr("PROGRESSÃO FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
