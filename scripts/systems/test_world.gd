class_name TestWorld
extends Node2D
## Área de protótipo — PLACEHOLDER (`docs/ASSET_WORKFLOW.md`, DEC-013).
##
## Não é o mapa do jogo. Serve apenas para perceber o movimento do Player e o
## acompanhamento da câmera durante a FASE 1. Não usa TileSet, não usa assets
## e não define a direção de arte da floresta.
##
## O mapa definitivo do survivor-like poderá ser muito maior, rolar
## infinitamente ou funcionar de outra forma; nada aqui é arquitetura final.
##
## `world_size` é a única fonte de verdade das dimensões: o chão desenhado, as
## paredes de colisão e os limites da câmera derivam todos deste valor.

## Camada de física da geometria estática do mundo. Ver DEC-016.
const WORLD_STATIC_LAYER := 8

const _GROUND_COLOR := Color(0.129, 0.196, 0.153)
const _GRID_COLOR := Color(0.196, 0.290, 0.227)
const _BORDER_COLOR := Color(0.349, 0.451, 0.302)

## Dimensões da área jogável, centrada na origem deste nó.
@export var world_size: Vector2 = Vector2(3072.0, 3072.0)

## Espaçamento do grid de referência visual.
@export var grid_step: float = 256.0

## Espessura das paredes de colisão da borda.
@export var wall_thickness: float = 64.0

## Peças de vegetação que fecham o mapa. As verticais empilham nas laterais, as
## horizontais correm no topo e na base. Quatro variações de cada, alternadas
## para a borda não virar carimbo.
const _ARTE_LATERAL: Array[String] = [
	"res://assets/environment/parede-vert-0.png",
	"res://assets/environment/parede-vert-1.png",
	"res://assets/environment/parede-vert-2.png",
	"res://assets/environment/parede-vert-3.png",
]
const _ARTE_TOPO: Array[String] = [
	"res://assets/environment/parede-horiz-0.png",
	"res://assets/environment/parede-horiz-1.png",
	"res://assets/environment/parede-horiz-2.png",
	"res://assets/environment/parede-horiz-3.png",
]

## Escurece a vegetação da borda para ela conviver com o chão.
##
## A arte da parede veio bem mais clara que os tiles: média (63, 61, 7) contra
## (27, 32, 20) da mata fechada do chão. Sem isto ela brilha e parece colada por
## cima do mapa, em vez de fazer parte dele.
##
## É `modulate` no nó, não alteração do arquivo: reversível, e o dia em que a
## arte for reexportada mais escura basta voltar para branco.
@export var border_tint: Color = Color(0.48, 0.51, 0.57)

## Catálogo de objetos de cenário.
##
## `solido` decide se o objeto vira obstáculo. `raio` e `altura_base` descrevem
## a **pegada** dele no chão, não o desenho: uma pedra alta ocupa pouco chão, um
## tronco deitado ocupa muito e é raso. Quem colide é a pegada.
##
## `min_escala`/`max_escala` dão variação de tamanho por instância. Mato e
## cogumelo variam bastante, pedra e toco menos — pedra pequena demais deixa de
## parecer pedra.
const _PROPS: Array[Dictionary] = [
	{"arte": "prop-toco.png",         "solido": true,  "raio": 26.0, "altura_base": 18.0, "min": 0.85, "max": 1.15},
	{"arte": "prop-tronco-caido.png", "solido": true,  "raio": 46.0, "altura_base": 14.0, "min": 0.85, "max": 1.20},
	{"arte": "prop-pedra-runica.png", "solido": true,  "raio": 24.0, "altura_base": 14.0, "min": 0.90, "max": 1.10},
	{"arte": "prop-rocha-musgo.png",  "solido": true,  "raio": 30.0, "altura_base": 18.0, "min": 0.80, "max": 1.25},
	{"arte": "prop-espinheiro.png",   "solido": true,  "raio": 34.0, "altura_base": 16.0, "min": 0.75, "max": 1.20},
	{"arte": "prop-samambaia.png",    "solido": false, "raio": 0.0,  "altura_base": 0.0,  "min": 0.65, "max": 1.15},
	{"arte": "prop-capim.png",        "solido": false, "raio": 0.0,  "altura_base": 0.0,  "min": 0.60, "max": 1.20},
	{"arte": "prop-cogumelos.png",    "solido": false, "raio": 0.0,  "altura_base": 0.0,  "min": 0.55, "max": 1.15},
]

## Chance de nascer um objeto em cada célula candidata, de 0 a 100.
@export_range(0, 100) var prop_chance: int = 22

## Chance de o objeto sorteado virar um **agrupamento** de dois a quatro, em vez
## de peça solitária. É o que forma moita e amontoado de pedra, que dão ao mapa
## obstáculos de verdade em vez de enfeite espalhado.
@export_range(0, 100) var prop_grupo_chance: int = 35

## De quantas em quantas células o sorteio acontece. Duas células (128 px) evita
## objeto colado em objeto sem precisar testar distância entre eles.
const _PROP_PASSO := 2

## Raio livre em volta do centro do mapa, onde o druida começa a partida.
const _PROP_RAIO_LIVRE := 320.0

## Camada da geometria estática do mundo (DEC-016), a mesma das paredes.
const _WORLD_STATIC_BIT := 1 << (WORLD_STATIC_LAYER - 1)

## Quanto uma peça da borda invade a anterior, em pixels.
##
## As peças não têm todas o mesmo tamanho (123, 123, 123 e 120 de largura; 192,
## 191, 190 e 192 de altura) e foram recortadas no conteúdo, então a folhagem
## não encosta na borda do arquivo. Encostando peça na peça sobra um fio de
## chão entre elas. A sobreposição fecha isso e ainda embaralha a emenda.
@export var border_overlap: float = 12.0

## Quanto a vegetação avança para **fora** da área jogável, em pixels.
##
## A parede física continua exatamente na borda de `world_size`: o jogador para
## onde a mata começa, e o que ele vê além disso é cenário. Estes números vêm do
## tamanho real das peças — 88 px de largura nas laterais, 184 de altura no topo.
const _BORDA_LATERAL := 88.0
const _BORDA_TOPO := 184.0

## Lado do tile do chão, em pixels. Precisa bater com o `tile_size` do
## `forest_tileset.tres`.
const TILE := 64

## As 16 peças do atlas de terra são um **conjunto de cantos**: cada tile é uma
## das 16 combinações de mata/terra nos quatro cantos da célula. Medi canto a
## canto para descobrir isso — as 16 combinações existem, uma vez cada.
##
## Índice = máscara de 4 bits, na ordem noroeste, nordeste, sudeste, sudoeste
## (1 = mata). O valor é a posição da peça no atlas 4x4.
##
## É isto que faz a mata sair como mancha contínua. Escolher tile por densidade,
## ignorando os cantos, produz um labirinto de cercas — foi o que aconteceu na
## primeira tentativa.
const _CANTOS_PARA_TILE: Array[int] = [6, 10, 7, 9, 2, 4, 11, 15, 5, 1, 14, 8, 3, 13, 0, 12]

## Fonte 0 do TileSet — o atlas `tileset-terra.png`.
const _FONTE_TERRA := 0

## Quantas células de mata fechada formam a moldura do mapa.
const _BORDA_DE_MATA := 2

## Espelhamentos possíveis de uma peça, como a Godot os codifica no
## `alternative_tile`. Só valem para as peças **uniformes** — a de terra limpa e
## a de mata fechada: espelhar uma peça de transição trocaria os cantos dela de
## lado e quebraria a emenda.
const _ESPELHOS: Array[int] = [
	0,
	TileSetAtlasSource.TRANSFORM_FLIP_H,
	TileSetAtlasSource.TRANSFORM_FLIP_V,
	TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
]

@onready var _ground: TileMapLayer = $Ground


func _ready() -> void:
	_build_walls()
	_fill_ground()
	_build_border_art()
	_scatter_props()


## Retângulo jogável em coordenadas locais deste nó.
func get_bounds() -> Rect2:
	return Rect2(-world_size * 0.5, world_size)


## Até onde a câmera pode enxergar: a área jogável mais a faixa de vegetação que
## fecha o mapa.
##
## Existe separado de `get_bounds()` de propósito. Quem cria inimigos usa o
## retângulo jogável, senão nasceria gente dentro da parede; quem enquadra usa
## este, senão a borda de mata ficaria cortada fora da tela e o mapa pareceria
## acabar no nada.
func get_camera_bounds() -> Rect2:
	return get_bounds().grow_individual(_BORDA_LATERAL, _BORDA_TOPO, _BORDA_LATERAL, _BORDA_TOPO)


## Preenche o chão com um mapa provisório, e **só** se ele estiver vazio.
##
## Um mapa pintado à mão no editor sempre vence: a primeira célula desenhada
## desliga este preenchimento. Isto aqui existe para o jogo não rodar sobre um
## retângulo liso enquanto o mapa de verdade não é desenhado — é placeholder no
## sentido da DEC-013, não geração procedural de conteúdo.
func _fill_ground() -> void:
	if _ground == null or _ground.tile_set == null:
		return
	if not _ground.get_used_cells().is_empty():
		return

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	# Uma clareira ocupa cerca de meia tela. Frequência maior vira mato picado.
	noise.frequency = 0.045
	noise.seed = 20260830

	# Preenche até o limite da câmera, não só a área jogável: sem isso apareceria
	# a cor de fundo por trás da vegetação da borda.
	var bounds := get_camera_bounds()
	var de := Vector2i(floori(bounds.position.x / TILE), floori(bounds.position.y / TILE))
	var ate := Vector2i(ceili(bounds.end.x / TILE), ceili(bounds.end.y / TILE))

	# O ruído é amostrado nos **cantos** das células, não no centro: é o canto
	# que os tiles casam, então dois vizinhos sempre concordam sobre o canto que
	# compartilham e a transição nunca quebra.
	var e_mata := func(cx: int, cy: int) -> bool:
		if cx < de.x + _BORDA_DE_MATA or cx > ate.x - _BORDA_DE_MATA 				or cy < de.y + _BORDA_DE_MATA or cy > ate.y - _BORDA_DE_MATA:
			return true # mata fechada na moldura, encostando nas paredes
		return noise.get_noise_2d(float(cx), float(cy)) > 0.02

	for cy in range(de.y, ate.y):
		for cx in range(de.x, ate.x):
			var mascara := 0
			if e_mata.call(cx, cy):
				mascara |= 8      # noroeste
			if e_mata.call(cx + 1, cy):
				mascara |= 4      # nordeste
			if e_mata.call(cx + 1, cy + 1):
				mascara |= 2      # sudeste
			if e_mata.call(cx, cy + 1):
				mascara |= 1      # sudoeste
			var tile: int = _CANTOS_PARA_TILE[mascara]

			# O atlas tem uma única peça de terra limpa e uma de mata fechada, e
			# são justamente as que cobrem a maior área. Repetidas sem mais nada,
			# o padrãozinho de pedras aparece em xadrez. Espelhar quebra isso de
			# graça, sem arte nova e sem custo em runtime.
			var espelho := 0
			if mascara == 0 or mascara == 15:
				espelho = _ESPELHOS[_ruido_estavel(cx, cy) % _ESPELHOS.size()]

			_ground.set_cell(Vector2i(cx, cy), _FONTE_TERRA, Vector2i(tile % 4, tile / 4), espelho)


## Espalha objetos decorativos pelas clareiras.
##
## Só entra em **célula de terra limpa** — as quatro pontas em terra, máscara 0
## de canto. Dentro da mata o objeto sumiria no meio das copas, e em célula de
## transição ele ficaria metade dentro do mato.
##
## Nada disso tem colisão: são decoração. Se um dia toco e pedra precisarem
## barrar o caminho, o lugar é aqui, não no `Player`.
func _scatter_props() -> void:
	if _ground == null:
		return

	var raiz := Node2D.new()
	raiz.name = "Props"
	# Ordena por Y junto com o Player e os inimigos: dá para passar atrás do
	# toco, e o toco cobre quem está atrás dele.
	raiz.y_sort_enabled = true
	add_child(raiz)

	var bounds := get_bounds()
	var de := Vector2i(ceili(bounds.position.x / TILE), ceili(bounds.position.y / TILE))
	var ate := Vector2i(floori(bounds.end.x / TILE), floori(bounds.end.y / TILE))
	var centro := bounds.get_center()
	var limpo: int = _CANTOS_PARA_TILE[0]

	# Ocupação de cada peça já colocada: posição e raio. Uma árvore não nasce em
	# cima da outra, então nada pode ser plantado dentro do espaço de ninguém.
	var ocupado: Array[Vector3] = []

	for cy in range(de.y + _BORDA_DE_MATA, ate.y - _BORDA_DE_MATA, _PROP_PASSO):
		for cx in range(de.x + _BORDA_DE_MATA, ate.x - _BORDA_DE_MATA, _PROP_PASSO):
			if _ruido_estavel(cx * 7, cy * 13) % 100 >= prop_chance:
				continue

			# Terra limpa: a peça do chão desta célula é a de máscara 0. Dentro
			# da mata o objeto sumiria entre as copas; em célula de transição
			# ficaria metade no mato.
			if _ground.get_cell_atlas_coords(Vector2i(cx, cy)) != Vector2i(limpo % 4, limpo / 4):
				continue

			var base := Vector2(cx * TILE + TILE * 0.5, cy * TILE + TILE * 0.5)
			if base.distance_to(centro) < _PROP_RAIO_LIVRE:
				continue

			var quantos := 1
			if _ruido_estavel(cx + 17, cy + 29) % 100 < prop_grupo_chance:
				quantos = 2 + _ruido_estavel(cx * 11, cy * 3) % 3

			for k in quantos:
				var semente := _ruido_estavel(cx * 31 + k * 7, cy * 17 + k * 13)
				# Em grupo as peças se afastam do ponto central; sozinha, fica
				# quase no meio da célula. O raio de espalhamento é maior que o
				# das peças, senão elas nasceriam sempre uma dentro da outra.
				var angulo := TAU * float(semente % 360) / 360.0
				var alcance := 0.0 if quantos == 1 else 48.0 + float(semente % 55)
				var at := base + Vector2(alcance, 0.0).rotated(angulo) 						+ Vector2(float(semente % 23) - 11.0, float((semente / 5) % 19) - 9.0)
				_add_prop(raiz, at, semente, ocupado)


## Cria um objeto de cenário com os pés em `at`, se houver espaço livre.
##
## A raiz de cada objeto fica **no chão**, e a sprite é deslocada para cima. É
## isso que faz a ordenação por Y acertar: quem ordena é o pé, não o topo do
## desenho.
func _add_prop(pai: Node2D, at: Vector2, semente: int, ocupado: Array[Vector3]) -> void:
	var modelo: Dictionary = _PROPS[semente % _PROPS.size()]
	var arte: Texture2D = load("res://assets/environment/%s" % modelo["arte"])
	if arte == null:
		return

	var minimo: float = modelo["min"]
	var maximo: float = modelo["max"]
	var escala: float = minimo + (maximo - minimo) * float((semente / 7) % 100) / 99.0

	# Espaço que a peça reserva no chão. Sai da largura do desenho, não da
	# colisão: o que não pode encavalar é a **imagem**, e mato ralo pode
	# encostar sem ficar estranho.
	var raio := arte.get_width() * escala * 0.42
	var solido: bool = modelo["solido"]
	if not solido:
		raio *= 0.55

	for outro in ocupado:
		# O raio vem guardado com sinal — negativo marca mato —, então o
		# tamanho é o valor absoluto. Somar o sinal encolheria a distância
		# exigida entre um tronco e um mato, que foi o que deixou quatro pares
		# encavalados na primeira versão.
		var minimo_livre: float = raio + absf(outro.z)
		# Duas peças de mato podem se tocar; qualquer coisa envolvendo tronco,
		# pedra ou espinheiro precisa do espaço inteiro.
		if not solido and outro.z < 0.0:
			minimo_livre *= 0.6
		if at.distance_to(Vector2(outro.x, outro.y)) < minimo_livre:
			return

	# O sinal do raio guardado marca se a peça é sólida, sem precisar de segundo
	# vetor: negativo = mato, positivo = obstáculo.
	ocupado.append(Vector3(at.x, at.y, raio if solido else -raio))

	var no := Node2D.new()
	no.position = at
	pai.add_child(no)

	var sprite := Sprite2D.new()
	sprite.texture = arte
	sprite.centered = false
	sprite.scale = Vector2(escala, escala)
	sprite.position = Vector2(-arte.get_width() * escala * 0.5, -arte.get_height() * escala)
	# Espelhar dobra a variedade de graça. Não vale para a pedra rúnica: a runa
	# gravada ficaria ao contrário.
	sprite.flip_h = (semente / 3) % 2 == 0 and modelo["arte"] != "prop-pedra-runica.png"
	no.add_child(sprite)

	if not solido:
		return

	# A colisão é uma cápsula deitada na base do desenho: representa a pegada no
	# chão, não a silhueta. Um toco alto não deve barrar quem passa atrás dele.
	var forma := CapsuleShape2D.new()
	forma.radius = float(modelo["altura_base"]) * escala * 0.5
	forma.height = maxf(forma.radius * 2.0 + 1.0, float(modelo["raio"]) * escala)

	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	colisao.rotation = PI * 0.5  # cápsula deitada
	colisao.position = Vector2(0.0, -forma.radius)

	var corpo := StaticBody2D.new()
	corpo.collision_layer = _WORLD_STATIC_BIT
	corpo.collision_mask = 0
	corpo.add_child(colisao)
	no.add_child(corpo)


## Fecha o mapa com vegetação, na faixa entre a parede física e o limite da
## câmera.
##
## São `Sprite2D` soltos, não tiles: as peças têm 88 x 192 e 123 x 184, tamanhos
## que não cabem na grade de 64 do chão. Forçá-las no TileSet significaria
## recortá-las, e o desenho perderia a continuação das trepadeiras.
func _build_border_art() -> void:
	var bounds := get_bounds()
	var laterais: Array[Texture2D] = []
	for caminho in _ARTE_LATERAL:
		laterais.append(load(caminho))
	var topos: Array[Texture2D] = []
	for caminho in _ARTE_TOPO:
		topos.append(load(caminho))
	if laterais.is_empty() or topos.is_empty():
		return

	var raiz := Node2D.new()
	raiz.name = "Borda"
	# Cada peça ordena pelo próprio Y. Sem isto a borda inteira ordenaria pela
	# posição do nó pai, em (0,0), e engoliria o Player perto da parede de cima.
	raiz.y_sort_enabled = true
	add_child(raiz)

	# Laterais: empilham de cima para baixo, cobrindo também a altura da faixa
	# do topo e da base, para não sobrar canto vazio.
	#
	# O avanço usa a altura da **peça colocada**, menos a sobreposição. Avançar
	# por um valor fixo abriria fresta toda vez que caísse uma peça mais baixa.
	var y := bounds.position.y - _BORDA_TOPO
	var indice := 0
	while y < bounds.end.y + _BORDA_TOPO:
		var arte: Texture2D = laterais[indice % laterais.size()]
		_add_border_piece(raiz, arte, Vector2(bounds.position.x - arte.get_width(), y), false)
		var espelhada: Texture2D = laterais[(indice + 2) % laterais.size()]
		_add_border_piece(raiz, espelhada, Vector2(bounds.end.x, y), true)
		y += maxf(1.0, float(arte.get_height()) - border_overlap)
		indice += 1

	# Topo e base: correm da esquerda para a direita, mesma regra de avanço.
	var x := bounds.position.x - _BORDA_LATERAL
	indice = 0
	while x < bounds.end.x + _BORDA_LATERAL:
		var arte: Texture2D = topos[indice % topos.size()]
		# Espelhar metade das peças dobra a variação sem arte nova.
		_add_border_piece(raiz, arte, Vector2(x, bounds.position.y - arte.get_height()), indice % 2 == 0)
		var debaixo: Texture2D = topos[(indice + 1) % topos.size()]
		_add_border_piece(raiz, debaixo, Vector2(x, bounds.end.y), indice % 2 == 1, true)
		x += maxf(1.0, float(arte.get_width()) - border_overlap)
		indice += 1


func _add_border_piece(pai: Node2D, arte: Texture2D, at: Vector2, flip_h: bool, flip_v := false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = arte
	sprite.centered = false
	sprite.position = at
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	sprite.modulate = border_tint
	pai.add_child(sprite)


## Número pseudoaleatório estável para uma célula.
##
## Não usa `randi()` de propósito: o mapa tem de sair igual em toda execução,
## senão duas partidas mostram chãos diferentes e um bug visual vira impossível
## de reproduzir.
func _ruido_estavel(cx: int, cy: int) -> int:
	var h := (cx * 73856093) ^ (cy * 19349663)
	return absi(h) % 1000


func _draw() -> void:
	var bounds := get_bounds()

	# Sem tiles, o chão liso e o grid seguram o protótipo. Com tiles, sairiam
	# por cima da arte.
	if _ground == null or _ground.get_used_cells().is_empty():
		draw_rect(bounds, _GROUND_COLOR, true)

		# O grid existe só para tornar o deslocamento perceptível sem arte.
		var x := bounds.position.x
		while x <= bounds.end.x:
			draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), _GRID_COLOR, 2.0)
			x += grid_step

		var y := bounds.position.y
		while y <= bounds.end.y:
			draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), _GRID_COLOR, 2.0)
			y += grid_step

		# O contorno só existe junto com o chão liso, para marcar onde o mundo
		# acaba. Com tiles e vegetação de borda ele vira um risco verde
		# atravessando a mata.
		draw_rect(bounds, _BORDER_COLOR, false, 6.0)


## Cria as quatro paredes de borda a partir de `world_size`.
##
## Construídas em código de propósito: assim as dimensões não ficam duplicadas
## entre a cena, o desenho do chão e os limites da câmera.
func _build_walls() -> void:
	var bounds := get_bounds()
	var center := bounds.get_center()
	var half := wall_thickness * 0.5
	var horizontal := Vector2(world_size.x + wall_thickness * 2.0, wall_thickness)
	var vertical := Vector2(wall_thickness, world_size.y + wall_thickness * 2.0)

	_add_wall("WallTop", Vector2(center.x, bounds.position.y - half), horizontal)
	_add_wall("WallBottom", Vector2(center.x, bounds.end.y + half), horizontal)
	_add_wall("WallLeft", Vector2(bounds.position.x - half, center.y), vertical)
	_add_wall("WallRight", Vector2(bounds.end.x + half, center.y), vertical)


func _add_wall(wall_name: String, at: Vector2, size: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size

	var collision := CollisionShape2D.new()
	collision.shape = rectangle

	var body := StaticBody2D.new()
	body.name = wall_name
	body.position = at
	body.collision_layer = 1 << (WORLD_STATIC_LAYER - 1)
	# Parede não precisa detectar nada; quem detecta é o corpo que se move.
	body.collision_mask = 0
	body.add_child(collision)

	add_child(body)
