extends SceneTree
## Verificação do som.
##
## Uso:
##   godot --headless --path . --script res://tests/test_audio.gd
##
## O `AudioServer` responde sem placa de som, então dá para cobrar som em teste
## headless — não o que se ouve, mas o que dispara.
##
## O que se prova aqui:
## - os doze arquivos existem, carregam e têm duração;
## - todo som citado em `WeaponData` e `EnemyData` existe de verdade (um nome
##   errado numa `.tres` é mudo em silêncio: ninguém descobre jogando);
## - a represa do mesmo som segura repetição no mesmo instante;
## - e, o que importa de fato, que **os eventos do jogo tocam**: coletar orbe,
##   subir de nível, tomar dano, disparar arma e matar criatura.
##
## Este último grupo é o que um teste de arquivo não pega: os doze WAV podem
## estar perfeitos e o jogo continuar mudo por falta de uma conexão.

const GAME_SCENE := "res://scenes/game/game.tscn"
const PASTA := "res://assets/audio/"

const ESPERADOS := [
	&"arma_raio", &"arma_vinha", &"arma_corvo", &"arma_orbe", &"arma_esporos",
	&"criatura_morre", &"coleta_orbe", &"nivel", &"escolha", &"dano_druida",
	&"guardiao_rugido", &"guardiao_queda",
]

var _failures: Array[String] = []
var _game: Node = null
var _audio: Node = null
var _frames := 3


func _initialize() -> void:
	_game = (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames -= 1
	if _frames > 0:
		return false

	# Nem o autoload está "dentro da árvore" durante `_initialize`, e tocar de lá
	# é erro de motor. Daqui em diante vale.
	# O nó nasce na primeira chamada; pedir um som garante que ele exista.
	Audio.tocar(&"coleta_orbe")
	_audio = root.get_node_or_null("Audio")
	if _audio == null:
		_fail("O nó Audio não apareceu na raiz: nada no jogo consegue tocar som")
		_report()
		quit(1)
		return true

	(_game.get_node("SpawnManager") as SpawnManager).enabled = false
	(_game.get_node("WaveManager") as WaveManager).enabled = false

	_check_arquivos()
	_check_barramentos()
	_check_nomes_nas_resources()
	_check_represa()
	_check_eventos()

	_report()
	quit(0 if _failures.is_empty() else 1)
	return true


## Os doze existem, carregam e têm duração.
func _check_arquivos() -> void:
	for nome in ESPERADOS:
		var caminho := PASTA + String(nome) + ".wav"
		if not ResourceLoader.exists(caminho):
			_fail("Som ausente: %s" % caminho)
			continue
		var fluxo := load(caminho) as AudioStream
		if fluxo == null:
			_fail("%s não carregou como AudioStream" % nome)
		elif fluxo.get_length() <= 0.0:
			_fail("%s tem duração zero" % nome)


func _check_barramentos() -> void:
	for barramento in [&"SFX", &"Musica"]:
		if AudioServer.get_bus_index(barramento) < 0:
			_fail("Barramento %s não existe: o volume não teria onde ser regulado" % barramento)


## Nome de som errado numa `.tres` é mudo em silêncio.
func _check_nomes_nas_resources() -> void:
	for arquivo in DirAccess.get_files_at("res://resources/weapons"):
		if not arquivo.ends_with(".tres"):
			continue
		var arma := load("res://resources/weapons/" + arquivo) as WeaponData
		if arma != null:
			_conferir_nome(arma.som, "a arma %s" % arma.id)

	for arquivo in DirAccess.get_files_at("res://resources/enemies"):
		if not arquivo.ends_with(".tres"):
			continue
		var bicho := load("res://resources/enemies/" + arquivo) as EnemyData
		if bicho == null:
			continue
		_conferir_nome(bicho.som_morte, "a morte de %s" % bicho.id)
		_conferir_nome(bicho.som_nascimento, "o nascimento de %s" % bicho.id)


func _conferir_nome(nome: StringName, quem: String) -> void:
	if nome == &"":
		return
	if not ResourceLoader.exists(PASTA + String(nome) + ".wav"):
		_fail("%s pede o som '%s', que não existe" % [quem, nome])


## O mesmo som não recomeça no mesmo instante: quarenta criaturas morrendo
## juntas somariam amplitude e saturariam.
func _check_represa() -> void:
	_calar()
	Audio.tocar(&"criatura_morre")
	var depois_de_um := _tocando()
	Audio.tocar(&"criatura_morre")
	Audio.tocar(&"criatura_morre")
	var depois_de_tres := _tocando()
	if depois_de_um != 1:
		_fail("Um som pedido deveria ocupar um tocador; ocupou %d" % depois_de_um)
	if depois_de_tres != depois_de_um:
		_fail("O mesmo som entrou %d vezes no mesmo instante: a represa não segurou"
			% depois_de_tres)

	# Sons diferentes continuam podendo soar juntos.
	Audio.tocar(&"nivel")
	if _tocando() <= depois_de_tres:
		_fail("Dois sons diferentes deveriam soar juntos, e o segundo não entrou")


## O que nenhum teste de arquivo pega: as conexões.
func _check_eventos() -> void:
	var eventos := [
		["coletar um orbe", func() -> void:
			(_game.get_node("Player/PickupArea") as PickupArea).collected.emit(1.0)],
		["subir de nível", func() -> void:
			(_game.get_node("Player/Level") as LevelComponent).add_xp(9999.0)],
		["o druida tomar dano", func() -> void:
			(_game.get_node("Player/Health") as HealthComponent).damage(5.0)],
		["uma criatura morrer", func() -> void: _matar_criatura()],
		["a arma disparar", func() -> void: _disparar()],
	]
	for evento in eventos:
		_calar()
		(evento[1] as Callable).call()
		if _tocando() == 0:
			_fail("%s não tocou som nenhum" % evento[0])


func _matar_criatura() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	var bicho := spawn.spawn_data(load("res://resources/enemies/imp_corrompido.tres") as EnemyData)
	if bicho == null:
		_fail("Não consegui fazer nascer uma criatura para matar")
		return
	(bicho.get_node("Health") as HealthComponent).damage(99999.0)


func _disparar() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	var druida := _game.get_node("Player") as Node2D
	var alvo := spawn.spawn_data(load("res://resources/enemies/imp_corrompido.tres") as EnemyData)
	if alvo != null:
		alvo.global_position = druida.global_position + Vector2(80.0, 0.0)
	var armas := _game.get_node("Player/WeaponManager") as WeaponManager
	for filho in armas.get_children():
		var arma := filho as Weapon
		if arma != null and arma.data != null and arma.data.som != &"":
			arma._physics_process(99.0)
			return
	_fail("Nenhuma arma com som para disparar")


func _calar() -> void:
	for filho in _audio.get_children():
		var tocador := filho as AudioStreamPlayer
		if tocador != null:
			tocador.stop()
	# A represa é por som e por instante: sem limpar, o teste seguinte mediria
	# o silêncio do anterior.
	_audio.set("_ultima_vez", {})


func _tocando() -> int:
	var total := 0
	for filho in _audio.get_children():
		var tocador := filho as AudioStreamPlayer
		if tocador != null and tocador.playing:
			total += 1
	return total


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ÁUDIO OK — doze sons no lugar, nomes conferidos, represa segurando e os cinco eventos tocando.")
		return
	printerr("ÁUDIO FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
