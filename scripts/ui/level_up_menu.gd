extends CanvasLayer
## Tela de escolha ao subir de nível (`docs/03_SYSTEMS.md` §13).
##
## Pausa, oferece opções **válidas**, aplica uma só e volta ao jogo.
##
## Não decide o que pode ser oferecido nem o que uma escolha faz: isso é do
## `UpgradePool`, que trabalha sobre `UpgradeData` em `.tres`. Esta tela recebe
## uma lista pronta e devolve o id escolhido.
##
## A separação existe porque as duas coisas mudam por motivos diferentes: a
## regra do que é oferecível muda quando entra conteúdo, o desenho da tela muda
## quando entra arte.
##
## Níveis acumulam: subir três de uma vez abre a tela três vezes, uma escolha
## por vez. Sem isso, dois níveis no mesmo instante dariam uma escolha só e o
## jogador perderia o que ganhou.

## Emitido quando a tela realmente abre — ela pode decidir não abrir, quando
## não há nada aplicável a oferecer.
##
## Quem pausa a partida é o `GameManager`, não esta tela: ela avisa que abriu e
## que fechou, e ele decide o que isso significa. Dois lugares mexendo em
## `get_tree().paused` foi o que a FASE 9 veio desfazer.
signal opened

## Emitido quando uma escolha é aplicada.
signal choice_made(id: StringName)

## Emitido quando a fila esvazia e o jogo volta a andar.
signal closed

## Quantas opções mostrar, no máximo.
const MAX_OPCOES := 3

## Tamanho da **placa** de cada opção, em pixels de viewport.
##
## A proporção é a da placa desenhada — 1970x330, ou 5,97:1. Deixar o container
## esticar a placa até a largura toda deformaria as pedras das pontas, então o
## tamanho é fixo e o container encolhe em volta.
const TAMANHO_PLACA := Vector2(620.0, 104.0)

## Espaço entre a moldura do ícone e a placa.
const FOLGA_ICONE := 16

## Lado da moldura do ícone.
##
## Ela fica **ao lado** da placa, não em cima. Duas razões: moldura desenhada
## sobre placa desenhada dava impressão de adesivo colado, e o acender da placa
## passava por baixo dela — as duas coisas denunciavam a montagem.
##
## Solta da placa, ela também deixa de precisar caber na banda de madeira, e
## pode ser maior do que era.
const LADO_ICONE := 104.0

## Placa de fundo de cada opção, nos dois estados. Vêm da cena porque são arte,
## e arte não se escolhe em código (DEC-013).
@export var textura_opcao: Texture2D
@export var textura_opcao_destaque: Texture2D

var _pool: UpgradePool = null
var _pendentes := 0
## As opções da tela aberta, para o botão saber o que aplicar.
var _oferta: Array[UpgradeData] = []

@onready var _opcoes: VBoxContainer = $Caixa/Opcoes
@onready var _titulo: Label = $Caixa/Titulo
@onready var _titulo_arte: TextureRect = $Caixa/TituloArte


## Ligada pela raiz da partida.
func configure(pool: UpgradePool, level: LevelComponent) -> void:
	_pool = pool
	if level != null and not level.leveled_up.is_connected(_on_leveled_up):
		level.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(_level: int) -> void:
	_pendentes += 1
	if visible:
		return

	# Adiado de propósito. O nível costuma subir **dentro** da detecção de área
	# que coletou o fragmento, e pausar a árvore ali faz a Godot recusar: pausar
	# desliga o monitoramento das áreas, e mexer nisso durante a consulta de
	# física é proibido ("Can't change this state while flushing queries").
	_abrir.call_deferred()


func _abrir() -> void:
	_oferta = _pool.sortear(MAX_OPCOES) if _pool != null else [] as Array[UpgradeData]
	if _oferta.is_empty():
		# Nada aplicável: não faz sentido pausar o jogo para não oferecer nada.
		# Acontece quando todas as armas estão no nível máximo — até a FASE 6
		# trazer passivas, é um beco sem saída legítimo.
		_pendentes = 0
		return

	for antigo in _opcoes.get_children():
		antigo.queue_free()

	for upgrade in _oferta:
		_opcoes.add_child(_montar_linha(upgrade))

	# Enquanto não houver arte da palavra, o rótulo escrito assume. Quando
	# houver, ela toma o lugar e o rótulo some — nenhuma das duas depende da
	# outra existir (DEC-013).
	var com_arte := _titulo_arte != null and _titulo_arte.texture != null
	_titulo_arte.visible = com_arte
	_titulo.visible = not com_arte
	_titulo.text = "SUBIU DE NIVEL" if _pendentes <= 1 else "SUBIU DE NIVEL  (x%d)" % _pendentes
	visible = true
	opened.emit()

	# **Sem** foco inicial: a tela abre com nada aceso.
	#
	# Dar foco ao primeiro botão ao abrir fazia ele parecer escolhido antes de o
	# jogador tocar em nada. Quem entra pelo teclado ganha o foco na primeira
	# tecla de navegação — ver `_unhandled_input`.
	var viewport := get_viewport()
	if viewport != null and viewport.gui_get_focus_owner() != null:
		viewport.gui_release_focus()


## Uma linha da tela: moldura do ícone à esquerda, placa clicável à direita.
##
## A moldura fica **fora** do botão. Dentro, ela parecia colada por cima, e o
## acender da placa passava por baixo dela.
##
## Só a placa recebe clique e foco. A moldura é ilustração e não responde ao
## mouse — passar por cima dela não deve acender a placa.
func _montar_linha(upgrade: UpgradeData) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", FOLGA_ICONE)
	linha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	linha.add_child(_coluna_icone(upgrade))
	linha.add_child(_placa(upgrade))
	return linha


## A moldura, ou um espaço do mesmo tamanho quando ela ainda não existe.
##
## O espaço existe mesmo vazio: sem ele, uma opção ainda sem arte deslocaria a
## placa para a esquerda e a fileira perderia o alinhamento.
func _coluna_icone(upgrade: UpgradeData) -> Control:
	if upgrade.icon == null:
		var vazio := Control.new()
		vazio.custom_minimum_size = Vector2(LADO_ICONE, LADO_ICONE)
		vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return vazio

	var icone := TextureRect.new()
	icone.texture = upgrade.icon
	icone.custom_minimum_size = Vector2(LADO_ICONE, LADO_ICONE)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icone


## As placas clicáveis da tela aberta, na ordem em que aparecem.
##
## Existe para que teclado e teste não precisem saber como a linha é montada por
## dentro: mexer na estrutura não deve quebrar nada fora daqui.
func botoes() -> Array[Button]:
	var lista: Array[Button] = []
	if _opcoes == null:
		return lista
	for linha in _opcoes.get_children():
		for filho in linha.get_children():
			var botao := filho as Button
			if botao != null:
				lista.append(botao)
	return lista


## A placa: o que é clicável, e o único lugar onde há texto.
func _placa(upgrade: UpgradeData) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = TAMANHO_PLACA
	botao.focus_mode = Control.FOCUS_ALL
	botao.pressed.connect(_on_escolha.bind(upgrade.id))
	_vestir(botao)

	var texto := VBoxContainer.new()
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.alignment = BoxContainer.ALIGNMENT_CENTER
	texto.add_theme_constant_override("separation", 2)
	# As peças de pedra das pontas ocupam cerca de 12% da largura cada, medido
	# na arte da placa. O texto começa depois da da esquerda.
	texto.offset_left = TAMANHO_PLACA.x * 0.14
	texto.offset_right = -TAMANHO_PLACA.x * 0.11
	botao.add_child(texto)

	texto.add_child(_rotulo_nome(upgrade))
	var efeito := upgrade.description if not upgrade.description.is_empty() else upgrade.resumo()
	if not efeito.is_empty():
		texto.add_child(_rotulo_efeito(efeito))

	return botao


## Troca o visual padrão do botão pela placa desenhada.
##
## A placa acesa é o **único** destaque: hover, pressed e foco usam ela. Não há
## contorno nem moldura por cima — a arte já diz o que está selecionado, e um
## retângulo desenhado em código sobre uma moldura desenhada à mão briga com ela.
##
## O estilo de foco é desenhado **por cima** do estado, e é por isso que ele
## recebe a mesma placa: sobrepor a acesa sobre a normal mostra a acesa, sem
## nada mais aparecer.
func _vestir(botao: Button) -> void:
	if textura_opcao == null:
		return

	var acesos: Array[String] = ["hover", "pressed", "focus"]
	var estados: Array[String] = ["normal", "hover", "pressed", "focus", "disabled"]
	for estado in estados:
		var caixa := StyleBoxTexture.new()
		var aceso: bool = estado in acesos and textura_opcao_destaque != null
		caixa.texture = textura_opcao_destaque if aceso else textura_opcao
		botao.add_theme_stylebox_override(estado, caixa)


func _rotulo_nome(upgrade: UpgradeData) -> Label:
	var nome := Label.new()
	nome.text = _titulo_da_opcao(upgrade)
	nome.add_theme_font_size_override("font_size", 25)
	nome.add_theme_color_override("font_color", Color(0.93, 0.98, 0.88))
	nome.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	nome.add_theme_constant_override("outline_size", 6)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return nome


func _rotulo_efeito(texto: String) -> Label:
	var linha := Label.new()
	linha.text = texto
	linha.add_theme_font_size_override("font_size", 17)
	linha.add_theme_color_override("font_color", Color(0.72, 0.82, 0.66))
	linha.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	linha.add_theme_constant_override("outline_size", 5)
	linha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return linha


## O teclado entra na tela sem o mouse, mas só quando é usado.
##
## Enquanto ninguém navega, nada fica aceso. A primeira seta ou confirmação põe
## o foco na primeira opção, e daí em diante a navegação da própria Godot toma
## conta. A tecla que traz o foco é consumida de propósito: ela serve para
## entrar na lista, não para escolher às cegas.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or _opcoes == null or _opcoes.get_child_count() == 0:
		return
	var viewport := get_viewport()
	if viewport == null or viewport.gui_get_focus_owner() != null:
		return

	var lista := botoes()
	if lista.is_empty():
		return

	for acao in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept"]:
		if event.is_action_pressed(acao):
			lista[0].grab_focus()
			viewport.set_input_as_handled()
			return


## Nome, e quantas vezes a opção já foi levada.
##
## O contador só aparece a partir da segunda vez: "Casca de Carvalho II" diz ao
## jogador que ele está empilhando, e some quando não há o que dizer.
func _titulo_da_opcao(upgrade: UpgradeData) -> String:
	var repetida := _pool.stacks(upgrade.id) if _pool != null else 0
	if repetida <= 0:
		return upgrade.display_name
	# O contador só aparece a partir da segunda vez: "Casca de Carvalho II" diz
	# ao jogador que ele está empilhando, e some quando não há o que dizer.
	return "%s  %s" % [upgrade.display_name, "I".repeat(mini(repetida + 1, 5))]


func _on_escolha(id: StringName) -> void:
	if _pool != null:
		_pool.apply(id)
	choice_made.emit(id)

	_pendentes = maxi(0, _pendentes - 1)
	if _pendentes > 0:
		# Ainda há nível na fila: uma escolha por vez, sem fechar no meio.
		_abrir()
		return

	visible = false
	closed.emit()
