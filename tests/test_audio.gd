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
## - os cinco arquivos existem, carregam e têm duração;
## - todo som citado em `WeaponData` e `EnemyData` existe de verdade (um nome
##   errado numa `.tres` é mudo em silêncio: ninguém descobre jogando);
## - a represa do mesmo som segura repetição no mesmo instante;
## - que **os eventos tocam**: coletar orbe, subir de nível, e o Guardião nascer;
## - e que **o combate é mudo**, por decisão do jogador: disparar arma, matar
##   criatura e tomar dano não tocam nada.
##
## Os dois últimos grupos são o que um teste de arquivo não pega: os WAV podem
## estar perfeitos e o jogo mudo por falta de conexão — ou barulhento por sobra.

const GAME_SCENE := "res://scenes/game/game.tscn"
const PASTA := "res://assets/audio/"

const ESPERADOS := [
	&"coleta_orbe", &"nivel", &"escolha", &"guardiao_rugido", &"guardiao_queda",
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
	_check_musica()
	_check_trilha_do_chefe()

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
	Audio.tocar(&"coleta_orbe")
	var depois_de_um := _tocando()
	Audio.tocar(&"coleta_orbe")
	Audio.tocar(&"coleta_orbe")
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
		["o Guardião nascer", func() -> void: _nascer_guardiao()],
	]
	for evento in eventos:
		_calar()
		(evento[1] as Callable).call()
		if _tocando() == 0:
			_fail("%s não tocou som nenhum" % evento[0])

	# E o contrário, que também é decisão: combate é mudo.
	var mudos := [
		["uma arma disparar", func() -> void: _disparar()],
		["uma criatura morrer", func() -> void: _matar_criatura()],
		["o druida tomar dano", func() -> void:
			(_game.get_node("Player/Health") as HealthComponent).damage(5.0)],
	]
	for evento in mudos:
		_calar()
		(evento[1] as Callable).call()
		if _tocando() != 0:
			_fail("%s tocou som: o combate deveria ser mudo" % evento[0])


func _matar_criatura() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	var bicho := spawn.spawn_data(load("res://resources/enemies/imp_corrompido.tres") as EnemyData)
	if bicho == null:
		_fail("Não consegui fazer nascer uma criatura para matar")
		return
	(bicho.get_node("Health") as HealthComponent).damage(99999.0)


func _nascer_guardiao() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	var chefe := spawn.spawn_data(load("res://resources/enemies/guardiao_profanado.tres") as EnemyData)
	if chefe == null:
		_fail("Não consegui fazer nascer o Guardião")


func _disparar() -> void:
	var spawn := _game.get_node("SpawnManager") as SpawnManager
	var druida := _game.get_node("Player") as Node2D
	var alvo := spawn.spawn_data(load("res://resources/enemies/imp_corrompido.tres") as EnemyData)
	if alvo != null:
		alvo.global_position = druida.global_position + Vector2(80.0, 0.0)
	var armas := _game.get_node("Player/WeaponManager") as WeaponManager
	for filho in armas.get_children():
		var arma := filho as Weapon
		if arma != null and arma.data != null:
			arma._physics_process(99.0)
			return
	_fail("Nenhuma arma para disparar")


## A trilha toca em volta, no barramento próprio, e sobrevive à pausa.
##
## O barramento separado é o que permite baixar a música sem baixar o resto, e o
## laço é o que a faz durar mais que 93 segundos de partida.
func _check_musica() -> void:
	Audio.musica(Audio.TRILHA)
	var tocador := _audio.get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	for filho in _audio.get_children():
		var p := filho as AudioStreamPlayer
		if p != null and p.bus == &"Musica":
			tocador = p
	if tocador == null:
		_fail("A trilha não criou tocador nenhum no barramento Musica")
		return
	if not tocador.playing:
		_fail("A trilha não está tocando")
	if tocador.stream == null:
		_fail("O tocador da trilha está sem faixa")
	elif tocador.stream is AudioStreamOggVorbis and not (tocador.stream as AudioStreamOggVorbis).loop:
		_fail("A trilha não está em laço: ela acabaria no meio da partida")
	if tocador.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail("A trilha para quando a árvore pausa: o silêncio a cada level up seria pior")


func _calar() -> void:
	for filho in _audio.get_children():
		var tocador := filho as AudioStreamPlayer
		# A trilha não entra: ela toca a partida inteira, e calá-la aqui era o
		# que fazia a checagem seguinte achar que ela nunca tinha começado.
		if tocador != null and tocador.bus != &"Musica":
			tocador.stop()
	# A represa é por som e por instante: sem limpar, o teste seguinte mediria
	# o silêncio do anterior.
	_audio.set("_ultima_vez", {})


func _tocando() -> int:
	var total := 0
	for filho in _audio.get_children():
		var tocador := filho as AudioStreamPlayer
		if tocador != null and tocador.playing and tocador.bus != &"Musica":
			total += 1
	return total


## Toda faixa que alguma wave pede existe em disco.
##
## `WaveData.trilha` continua podendo trocar a música numa wave; hoje nenhuma
## pede, porque a trilha escolhida é uma só. Se alguém pedir, o nome tem de
## existir — nome errado seria silêncio sem aviso.
func _check_trilha_do_chefe() -> void:
	var ondas := _game.get_node("WaveManager") as WaveManager
	for wave in ondas.waves:
		if wave.trilha != &"" and not ResourceLoader.exists(
				"res://assets/audio/musica/%s.ogg" % wave.trilha):
			_fail("A wave %s pede a faixa '%s', que não existe" % [wave.id, wave.trilha])


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("ÁUDIO OK — cinco sons no lugar, combate mudo, trilha em laço, Guardião e interface tocando.")
		return
	printerr("ÁUDIO FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
