extends CanvasLayer
## Tela de pausa (`docs/ROADMAP.md`, FASE 9).
##
## Não decide nada: escuta o `GameManager` e se mostra. Os botões devolvem a
## intenção para ele — continuar, reiniciar, voltar ao menu —, e é ele que sabe o que cada
## uma significa.
##
## `process_mode` ALWAYS na cena: a tela precisa responder enquanto a árvore
## está parada, que é justamente quando ela aparece.

## Tamanho de cada botão. A proporção é a da placa desenhada, 5,97:1; esticá-la
## até a largura do container deformaria as pedras das pontas.
const TAMANHO_BOTAO := Vector2(400.0, 67.0)

@export var textura_placa: Texture2D
@export var textura_placa_destaque: Texture2D

var _manager: GameManager = null

@onready var _opcoes: VBoxContainer = $Caixa/Opcoes


## Ligada pela raiz da partida.
func configure(manager: GameManager) -> void:
	_manager = manager
	if manager != null and not manager.state_changed.is_connected(_on_state_changed):
		manager.state_changed.connect(_on_state_changed)
	_montar()
	visible = false


func _montar() -> void:
	for antigo in _opcoes.get_children():
		antigo.queue_free()
	for texto in ["CONTINUAR", "REINICIAR", "MENU"]:
		var botao := PlacaUI.criar(texto, TAMANHO_BOTAO, textura_placa, textura_placa_destaque)
		botao.pressed.connect(_on_escolha.bind(texto))
		_opcoes.add_child(botao)


func botoes() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in _opcoes.get_children():
		var botao := filho as Button
		if botao != null:
			lista.append(botao)
	return lista


func _on_state_changed(estado: GameManager.Estado) -> void:
	var abrir := estado == GameManager.Estado.PAUSADO
	if abrir and not visible:
		# Nada nasce aceso: o foco só entra quando o jogador usa o teclado.
		var viewport := get_viewport()
		if viewport != null and viewport.gui_get_focus_owner() != null:
			viewport.gui_release_focus()
	visible = abrir


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if PlacaUI.focar_no_teclado(event, botoes(), get_viewport()):
		get_viewport().set_input_as_handled()


func _on_escolha(texto: String) -> void:
	if _manager == null:
		return
	match texto:
		"CONTINUAR":
			_manager.retomar()
		"REINICIAR":
			_manager.reiniciar()
		"MENU":
			_manager.voltar_ao_menu()
