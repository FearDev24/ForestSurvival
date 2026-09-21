extends SceneTree
## Capturas de tela para a ficha da Google Play.
##
## Uso (com janela, não headless — headless não desenha):
##   godot --path . --resolution 1920x1080 --script res://tools/capturar_loja_play.gd --fixed-fps 60
##
## Gera seis quadros em `user://play/`: menu, partida cheia, chefe, escolha de
## magia, loja e vitória. A partida é a de verdade — spawn, waves e armas —, com
## o druida invulnerável só para a cena não acabar antes da foto.
##
## Usa um save próprio: capturar não pode mexer no progresso de quem joga.

const GAME := "res://scenes/game/game.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const LOJA := "res://scenes/ui/loja.tscn"
const ARMAS := ["cajado_raio", "vinha_espinhosa", "corvo_espiritual", "anel_de_esporos", "vagalumes_guardioes"]

var _passo := 0
var _espera := 40
var _jogo: Node = null


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://play"))
	SaveJogo.usar_caminho("user://play/save_captura.json")
	SaveJogo.apagar()
	change_scene_to_file(MENU)


func _foto(nome: String) -> void:
	root.get_texture().get_image().save_png("user://play/%s.png" % nome)
	print("capturado: %s" % nome)


func _process(_d: float) -> bool:
	_espera -= 1
	if _espera > 0:
		return false
	match _passo:
		0:
			_foto("1_menu")
			change_scene_to_file(GAME)
			_passo = 1
			_espera = 30
		1:
			_jogo = current_scene
			_preparar_partida(300.0)
			_passo = 2
			_espera = 600
		2:
			_foto("2_partida")
			_trazer_chefe()
			_passo = 30
			_espera = 90
		30:
			_foto("3_chefe_a")
			_passo = 31
			_espera = 45
		31:
			_foto("3_chefe_b")
			_passo = 3
			_espera = 45
		3:
			_foto("3_chefe_c")
			(_jogo.get_node("Player/Level") as LevelComponent).add_xp(99999.0)
			_passo = 4
			_espera = 20
		4:
			_foto("4_escolha")
			SaveJogo.dados()["moedas"] = 420
			Permanentes.comprar(&"vida")
			Permanentes.comprar(&"velocidade")
			change_scene_to_file(LOJA)
			_passo = 5
			_espera = 30
		5:
			_foto("5_loja")
			change_scene_to_file(GAME)
			_passo = 6
			_espera = 40
		6:
			_jogo = current_scene
			(_jogo.get_node("SpawnManager") as SpawnManager).enabled = false
			(_jogo.get_node("WaveManager") as WaveManager).enabled = false
			var m := _jogo.get_node("GameManager") as GameManager
			m.set("_abates", 1043)
			m.emit_signal("ended", true, 489.0, 21)
			_passo = 7
			_espera = 25
		7:
			_foto("6_vitoria")
			SaveJogo.apagar()
			quit(0)
			return true
	return false


## Partida de verdade adiantada no relógio, com as seis magias e sem morte.
func _preparar_partida(segundos: float) -> void:
	var armas := _jogo.get_node("Player/WeaponManager") as WeaponManager
	for id in ARMAS:
		armas.add_weapon(load("res://resources/weapons/%s.tres" % id) as WeaponData)
	for filho in _jogo.get_node("Player").get_children():
		if filho is HurtboxComponent:
			(filho as HurtboxComponent).set_vulnerable(false)
	(_jogo.get_node("GameManager") as GameManager).set("_elapsed", segundos)
	(_jogo.get_node("WaveManager") as WaveManager).set("_elapsed", segundos)
	# Nivel coerente com o relogio: aos 5 minutos a sonda chega por volta do 14.
	# Mexe no numero direto, e nao por XP, para nao abrir a tela de escolha.
	var nivel := _jogo.get_node("Player/Level") as LevelComponent
	nivel.level = 14
	# So o rotulo do HUD: emitir `leveled_up` abriria a tela de escolha.
	_jogo.get_node("Hud").call("_on_leveled_up", 14)


## O Guardião entra perto do druida, com a horda em volta.
func _trazer_chefe() -> void:
	var spawn := _jogo.get_node("SpawnManager") as SpawnManager
	var chefe := spawn.spawn_data(load("res://resources/enemies/guardiao_profanado.tres") as EnemyData)
	if chefe != null:
		var druida := _jogo.get_node("Player") as Node2D
		chefe.global_position = druida.global_position + Vector2(330.0, -40.0)
	# O raio cai no inimigo mais proximo e cobria o chefe inteiro na foto. As
	# outras magias continuam: a cena precisa parecer combate.
	var armas := _jogo.get_node("Player/WeaponManager")
	for filho in armas.get_children():
		var arma := filho as Weapon
		if arma != null and arma.data != null and arma.data.id == &"cajado_raio":
			arma.set_physics_process(false)
