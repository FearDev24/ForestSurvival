extends SceneTree
## Acrescenta `idle_<direção>` ao `SpriteFrames` do druida, sem tocar no resto.
##
## Uso (depois de `python tools/extrair_idle_druida.py`):
##   godot --headless --path . --script res://tools/ligar_idle_druida.gd
##
## Edita o recurso pela própria Godot em vez de reescrever o `.tres` à mão: as
## caminhadas e a morte vieram de outras ferramentas, e regerar o arquivo inteiro
## arriscaria perder o que já está aprovado. Rodar de novo substitui as quatro
## animações de idle e deixa o resto como estava.

const FRAMES := "res://assets/characters/druida_sprite_frames.tres"
const PASTA := "res://assets/characters/"
## Sem oeste: no jogo, oeste é leste espelhado (`player_visual.gd`).
const DIRECOES := ["south", "north", "east"]


func _initialize() -> void:
	var frames := load(FRAMES) as SpriteFrames
	for direcao in DIRECOES:
		var nome := "druida-idle-%s" % direcao
		var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PASTA + nome + ".json"))
		var folha := load(PASTA + nome + ".png") as Texture2D
		var animacao := StringName("idle_%s" % direcao)
		if frames.has_animation(animacao):
			frames.remove_animation(animacao)
		frames.add_animation(animacao)
		frames.set_animation_loop(animacao, true)
		# A velocidade sai do laço do vídeo: respirar no tempo em que o vídeo
		# respira, e não na cadência da caminhada.
		frames.set_animation_speed(animacao, float(dados["speed"]))
		var largura := int(dados["frameWidth"])
		var altura := int(dados["frameHeight"])
		for k in int(dados["frames"]):
			var recorte := AtlasTexture.new()
			recorte.atlas = folha
			recorte.region = Rect2(k * largura, 0, largura, altura)
			frames.add_frame(animacao, recorte)
		print("%s: %d quadros a %.1f fps" % [animacao, frames.get_frame_count(animacao), dados["speed"]])
	var erro := ResourceSaver.save(frames, FRAMES)
	print("salvo" if erro == OK else "ERRO ao salvar: %d" % erro)
	quit(0 if erro == OK else 1)
