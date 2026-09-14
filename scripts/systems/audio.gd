class_name Audio
extends Node
## Som do jogo, num lugar só.
##
## Quem toca não conhece arquivo: pede `Audio.tocar(&"coleta_orbe")` e pronto.
##
## **Classe com métodos estáticos, e não autoload.** Autoload seria o caminho
## natural, mas o identificador global dele não existe para o compilador quando
## a Godot roda com `--script`, que é como as dezoito suítes deste projeto
## rodam: `Audio.tocar()` dentro de `weapon.gd` não compilaria, e o jogo inteiro
## cairia junto. `class_name` resolve em qualquer modo.
##
## O nó nasce na primeira chamada e mora na raiz da árvore, fora das cenas:
## sobrevive à troca de cena entre menu e partida.
## Os WAV saem de `tools/preparar_sons.py`, e trocar um som é trocar o arquivo,
## sem tocar em lógica — a mesma regra da arte (DEC-013).
##
## Três coisas que este nó resolve e que espalhar `AudioStreamPlayer` por aí
## não resolveria:
##
## **Fila.** Um `AudioStreamPlayer` só toca um som por vez; numa horda morrendo
## junto, o segundo cortaria o primeiro. Aqui há uma roda de tocadores.
##
## **Represa.** Quarenta criaturas morrem no mesmo frame e quarenta cópias do
## mesmo som somam amplitude — satura, e ainda gasta CPU do celular. O mesmo som
## não recomeça antes de `_INTERVALO_MINIMO`.
##
## **Pausa.** Os tocadores rodam em `PROCESS_MODE_ALWAYS` porque a tela de level
## up **pausa a árvore**, e o som do botão tem de sair mesmo assim. Os sons de
## partida não escapam por aí: quem os pede está pausado junto com o resto.

const PASTA := "res://assets/audio/"
const PASTA_MUSICA := "res://assets/audio/musica/"

## Segundos de desvanecimento ao trocar de faixa ou ao parar.
const _FUSAO := 1.2

## Quantos sons podem soar ao mesmo tempo.
##
## Doze cobre o pior caso visto na sonda — uma leva de criaturas morrendo junto
## com um level up — sem virar um coro de vozes idênticas.
const _TOCADORES := 12

## Menor intervalo entre duas partidas do **mesmo** som, em segundos.
const _INTERVALO_MINIMO := 0.045

static var _instancia: Audio

var _tocadores: Array[AudioStreamPlayer] = []
var _proximo := 0
var _fluxos := {}
var _ultima_vez := {}
var _musica: AudioStreamPlayer = null
var _faixa_atual: StringName = &""

## Pedidos feitos antes de haver onde tocar. Ver `_garantir`.
var _na_fila: Array = []


## Toca um som pelo nome do arquivo, sem extensão.
##
## Nome desconhecido não toca nada e avisa — som faltando não derruba partida.
static func tocar(nome: StringName, volume_db := 0.0) -> void:
	if nome == &"":
		return
	var eu := _garantir()
	if eu != null:
		eu._tocar(nome, volume_db)


## Põe uma faixa a tocar em volta, no barramento `Musica`.
##
## Chamar com a faixa que já está tocando não faz nada — senão a trilha
## recomeçaria a cada troca de cena. Nome vazio para o silêncio.
static func musica(nome: StringName) -> void:
	var eu := _garantir()
	if eu != null:
		eu._musica_tocar(nome)


## Volume de um barramento, de 0 a 1. É o gancho para as opções de som.
static func volume(barramento: StringName, fracao: float) -> void:
	var indice := AudioServer.get_bus_index(barramento)
	if indice < 0:
		return
	fracao = clampf(fracao, 0.0, 1.0)
	AudioServer.set_bus_mute(indice, is_zero_approx(fracao))
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(0.0001, fracao)))


## O nó, criado na primeira vez que alguém pede som.
static func _garantir() -> Audio:
	if is_instance_valid(_instancia):
		return _instancia
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore == null:
		return null
	_instancia = Audio.new()
	_instancia.name = "Audio"
	# A raiz pode estar **ocupada montando filhos** — é o caso quando o primeiro
	# som vem do `_ready` de alguém, que é exatamente quando a partida pede a
	# trilha. Nesse caso a entrada na árvore fica para o fim do quadro, e o que
	# for pedido nesse meio-tempo espera na fila em vez de se perder: sem isso a
	# música da partida simplesmente não tocava.
	if arvore.root.is_node_ready():
		arvore.root.add_child(_instancia)
	else:
		arvore.root.add_child.call_deferred(_instancia)
	return _instancia


func _ready() -> void:
	_montar()
	# Despeja o que foi pedido antes de existir lugar para tocar.
	var fila := _na_fila.duplicate()
	_na_fila.clear()
	for pedido in fila:
		if pedido[0] == &"musica":
			_musica_tocar(pedido[1])
		else:
			_tocar(pedido[1], pedido[2])


## Os tocadores nascem na primeira vez que fazem falta, não em `_ready`.
##
## Num script de teste, o autoload entra na árvore dentro de
## `SceneTree._initialize()` e `_ready` não dispara — a mesma armadilha do
## `HealthComponent`, do `Hud` e do `OrbitEffect`, que resolvem do mesmo jeito.
## Sem isto, a primeira chamada a `tocar()` num teste headless estoura.
func _montar() -> void:
	if not _tocadores.is_empty():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in _TOCADORES:
		var tocador := AudioStreamPlayer.new()
		tocador.bus = &"SFX"
		tocador.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(tocador)
		_tocadores.append(tocador)


func _tocar(nome: StringName, volume_db: float) -> void:
	if not is_inside_tree():
		_na_fila.append([&"som", nome, volume_db])
		return
	_montar()

	var agora := Time.get_ticks_msec() / 1000.0
	var ultima: float = _ultima_vez.get(nome, -999.0)
	if agora - ultima < _INTERVALO_MINIMO:
		return

	var fluxo := _fluxo(nome)
	if fluxo == null:
		return
	_ultima_vez[nome] = agora

	var tocador := _livre()
	tocador.stream = fluxo
	tocador.volume_db = volume_db
	tocador.play()


## O primeiro tocador parado; se todos estiverem ocupados, o mais antigo da roda.
##
## Roubar o mais antigo é melhor que ignorar o pedido: o som que está no fim já
## foi ouvido, e o que chega agora é o que o jogador precisa escutar.
func _livre() -> AudioStreamPlayer:
	for tocador in _tocadores:
		if not tocador.playing:
			return tocador
	var escolhido := _tocadores[_proximo]
	_proximo = (_proximo + 1) % _tocadores.size()
	return escolhido


func _musica_tocar(nome: StringName) -> void:
	if not is_inside_tree():
		_na_fila.append([&"musica", nome, 0.0])
		return
	if nome == _faixa_atual:
		return
	_faixa_atual = nome

	if _musica == null:
		_musica = AudioStreamPlayer.new()
		_musica.bus = &"Musica"
		# A trilha não para na tela de level up nem na de pausa: o silêncio
		# repentino a cada escolha seria pior que a música continuar.
		_musica.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_musica)

	if nome == &"":
		_musica.stop()
		return

	var caminho := PASTA_MUSICA + String(nome) + ".ogg"
	if not ResourceLoader.exists(caminho):
		push_warning("Faixa ausente: %s" % caminho)
		return
	var fluxo := load(caminho) as AudioStream
	if fluxo is AudioStreamOggVorbis:
		# Em volta, e sem pausa entre uma volta e outra.
		(fluxo as AudioStreamOggVorbis).loop = true
	_musica.stream = fluxo
	_musica.volume_db = -60.0
	_musica.play()

	# Entra subindo: começar no volume cheio junto com a partida é um susto.
	var tween := create_tween()
	tween.tween_property(_musica, "volume_db", 0.0, _FUSAO)


func _fluxo(nome: StringName) -> AudioStream:
	if _fluxos.has(nome):
		return _fluxos[nome]
	var caminho := PASTA + String(nome) + ".wav"
	if not ResourceLoader.exists(caminho):
		push_warning("Som ausente: %s" % caminho)
		_fluxos[nome] = null
		return null
	var fluxo := load(caminho) as AudioStream
	_fluxos[nome] = fluxo
	return fluxo
