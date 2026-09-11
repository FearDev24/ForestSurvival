extends SceneTree
## Verificação da FASE 10 — Performance.
##
## Uso:
##   godot --headless --path . --script res://tests/test_phase10.gd
##
## A FASE 10 foi de medição: a sonda com `--perf` numa partida inteira e
## `tools/stress_performance.gd` na horda empilhada (`docs/HANDOFF.md`,
## "FASE 10"). Tempo de quadro **não** é conferido aqui — depende da máquina, e
## medir é trabalho das ferramentas, não da suíte.
##
## O que vira regra é o que a medição mostrou que não pode voltar:
##
## 1. **os fragmentos de XP compartilham uma textura só.** Quando cada um se
##    desenhava com polígono e contorno, 300 no chão custavam 331 chamadas de
##    desenho a mais; com a textura compartilhada, nenhuma;
## 2. **nenhum teto de população passa de 200.** Com a horda empilhada, 300
##    inimigos já custam 18,8 ms de física, acima dos 16,6 do quadro, e 500
##    derrubam o jogo para 4 FPS;
## 3. **as ferramentas de medição continuam compilando** — sem elas, a próxima
##    mudança de desempenho volta a ser palpite.

const TETO_MEDIDO := 200
const GAME_SCENE := "res://scenes/game/game.tscn"
const ORBE_SCRIPT := "res://scripts/pickups/xp_orb.gd"
const WAVES := "res://resources/waves/"
const FERRAMENTAS := [
	"res://tools/sonda_balanceamento.gd",
	"res://tools/stress_performance.gd",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_check_orbes()
	_check_tetos()
	_check_ferramentas()
	_report()
	quit(0 if _failures.is_empty() else 1)


func _check_orbes() -> void:
	var a := XpOrb.textura_compartilhada()
	var b := XpOrb.textura_compartilhada()
	if a == null:
		_fail("O fragmento de XP não tem textura para desenhar")
		return
	if a != b:
		_fail("Cada fragmento pintou a própria textura: a Godot deixa de agrupar, e cada um vira uma chamada de desenho")

	# O `_draw` tem de usar a textura. Uma função compartilhada que ninguém chama
	# não conserta nada, e o desenho não tem como ser observado sem janela: a
	# conferência é no código.
	var fonte := (load(ORBE_SCRIPT) as Script).source_code
	if not fonte.contains("draw_texture("):
		_fail("O fragmento de XP não desenha com a textura compartilhada")
	for caro in ["draw_colored_polygon(", "draw_polyline("]:
		if fonte.contains(caro):
			_fail("O fragmento de XP voltou a usar %s: cada um vira uma chamada de desenho" % caro.trim_suffix("("))


func _check_tetos() -> void:
	var game := (load(GAME_SCENE) as PackedScene).instantiate()
	var spawn := game.get_node_or_null("SpawnManager") as SpawnManager
	if spawn == null:
		_fail("game.tscn sem SpawnManager")
	else:
		for par in [["initial_population_cap", spawn.initial_population_cap],
				["final_population_cap", spawn.final_population_cap]]:
			if int(par[1]) > TETO_MEDIDO:
				_fail("SpawnManager.%s = %d, acima dos %d medidos" % [par[0], par[1], TETO_MEDIDO])
	game.free()

	var achadas := 0
	for arquivo in DirAccess.get_files_at(WAVES):
		if not arquivo.ends_with(".tres"):
			continue
		var wave := load(WAVES + arquivo) as WaveData
		if wave == null:
			continue
		achadas += 1
		if wave.population_cap > TETO_MEDIDO:
			_fail("A wave %s pede %d inimigos, acima dos %d medidos" % [arquivo, wave.population_cap, TETO_MEDIDO])
	if achadas == 0:
		_fail("Nenhuma wave encontrada em %s: o teto não foi conferido" % WAVES)


func _check_ferramentas() -> void:
	for caminho in FERRAMENTAS:
		if not ResourceLoader.exists(caminho):
			_fail("Ferramenta de medição ausente: %s" % caminho)
		elif load(caminho) == null:
			_fail("Ferramenta de medição não compila: %s" % caminho)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("FASE 10 OK — fragmentos numa textura só, teto de 200 respeitado e ferramentas de medição compilando.")
		return
	printerr("FASE 10 FALHOU:")
	for failure in _failures:
		printerr("  - %s" % failure)
