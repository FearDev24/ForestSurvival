class_name Hud
extends CanvasLayer
## Painel da partida: vida, experiência, nível e tempo
## (`docs/ROADMAP.md`, FASE 9).
##
## É apresentação e nada mais. Não lê estado de ninguém a cada frame, não guarda
## regra de jogo e não conhece Player, WeaponManager nem SpawnManager: recebe os
## dois componentes em `configure()` e depois só reage aos sinais que eles já
## emitiam desde a FASE 0 e a FASE 5.
##
## O cronômetro é a exceção, e de propósito: tempo decorrido é estado de
## partida, não de HUD. Quem conta é `scripts/systems/game.gd`, que empurra o
## valor por `set_time()`. Assim o relógio para sozinho quando a partida pausa,
## sem o HUD precisar saber o que é pausa.

## Formato do relógio quando a partida passa de uma hora. Antes disso, `MM:SS`.
const _UMA_HORA := 3600.0

var _health: HealthComponent = null
var _level: LevelComponent = null

## Os filhos são resolvidos na primeira vez que o painel é usado, não em
## `@onready`. Motivo: `_ready()` não dispara em nó acrescentado à árvore de
## dentro de `SceneTree._initialize()`, que é como os testes montam a cena —
## mesma razão da inicialização preguiçosa do `HealthComponent`.
var _barra_vida: TextureProgressBar = null
var _barra_xp: TextureProgressBar = null
var _rotulo_nivel: Label = null
var _rotulo_tempo: Label = null
var _resolvido := false


func _ready() -> void:
	_resolver()


func _resolver() -> void:
	if _resolvido:
		return
	_resolvido = true
	_barra_vida = get_node_or_null("BarraVida") as TextureProgressBar
	_barra_xp = get_node_or_null("BarraXp") as TextureProgressBar
	_rotulo_nivel = get_node_or_null("Nivel") as Label
	_rotulo_tempo = get_node_or_null("Tempo") as Label


## Liga o painel aos componentes da partida.
##
## Chamado por `game.gd`. Os valores iniciais são lidos uma vez aqui porque os
## componentes já emitiram os sinais deles antes deste `configure()` acontecer —
## conectar sem essa leitura deixaria as barras vazias até o primeiro dano e o
## primeiro fragmento.
func configure(health: HealthComponent, level: LevelComponent) -> void:
	_resolver()
	_health = health
	_level = level

	health.health_changed.connect(_on_health_changed)
	level.xp_changed.connect(_on_xp_changed)
	level.leveled_up.connect(_on_leveled_up)

	_barra_vida.value = health.get_ratio() * 100.0
	_barra_xp.value = level.get_ratio() * 100.0
	_on_leveled_up(level.level)
	set_time(0.0)


## Atualiza o relógio. Recebe segundos decorridos de partida.
func set_time(seconds: float) -> void:
	_resolver()
	var total := int(maxf(0.0, seconds))
	if seconds >= _UMA_HORA:
		_rotulo_tempo.text = "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
	else:
		_rotulo_tempo.text = "%02d:%02d" % [total / 60, total % 60]


func _on_health_changed(current: float, maximum: float) -> void:
	_barra_vida.value = 100.0 * current / maxf(1.0, maximum)


func _on_xp_changed(current: float, needed: float) -> void:
	_barra_xp.value = 100.0 * current / maxf(1.0, needed)


func _on_leveled_up(level: int) -> void:
	_rotulo_nivel.text = "NIVEL %d" % level
