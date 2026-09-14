class_name EnemyData
extends Resource
## Dados de um tipo de inimigo (`docs/02_ARCHITECTURE.md`, "Recursos"; DEC-010).
##
## Aqui não há comportamento: só os números e, se houver, a cena. Criar um tipo
## novo é criar um `.tres` — mesmo princípio do `WeaponData`.
##
## Enquanto só existe a arte do diabrete, os tipos se distinguem por número,
## tamanho e cor. Isso é PLACEHOLDER declarado (DEC-013): quando a arte de cada
## um chegar, `scene` deixa de ser nula e `tint` volta a branco, sem tocar em
## código.

## Identificador estável. Nunca o nome de exibição, que muda com tradução.
@export var id: StringName = &""

@export var display_name: String = ""

## Cena própria deste tipo. **Nula usa a cena padrão do `SpawnManager`** — é o
## que permite três tipos existirem antes de haver três artes.
@export var scene: PackedScene

@export_group("Combate")
@export var max_health: float = 30.0

## Dano por contato, aplicado pela hitbox do inimigo.
@export var contact_damage: float = 10.0

@export var move_speed: float = 110.0

## Quanto de XP o fragmento dele vale. É por aqui que o elite larga mais.
@export var xp_value: float = 1.0

@export_group("Apresentação")
## Animações deste tipo. **Nulo mantém as da cena** — é o que permite um tipo
## novo existir antes de ter arte, distinguido só por número, tamanho e tinta.
@export var sprite_frames: SpriteFrames

## Multiplica a escala do nó `Visual`. Só a arte: colisão é dado de gameplay e
## se ajusta por `body_radius` (`docs/ASSET_WORKFLOW.md`, regra 7).
@export var visual_scale: float = 1.0

## Raio do corpo e da hurtbox. **Zero mantém o da cena.**
@export var body_radius: float = 0.0

## Tinta aplicada ao inimigo inteiro. Branco não altera nada.
@export var tint: Color = Color.WHITE

## Morte encenada: o corpo fica na partida até a queda terminar, e só então
## sai. **Só o Guardião** (DEC-024) — as criaturas comuns somem no quadro em
## que morrem, e isso é o final delas, não falta de arte.
@export var staged_death: bool = false

## Quanto o golpe de uma habilidade empurra este tipo, de 0 a 1. Pesado recua
## menos; o Guardião não recua — um boss empurrado a cada golpe deixa de
## parecer um boss.
@export var knockback_scale: float = 1.0

## Atravessa pedra, totem e as outras criaturas.
##
## O Guardião tem 220 px de corpo e a floresta é cheia de obstáculo do tamanho
## dele: empurrando pedra e horda ao mesmo tempo, ele encalhava e o jogador
## ficava esperando o chefe chegar. A alternativa séria seria navegação com
## desvio, o que é um sistema inteiro para um inimigo só.
##
## Tira o corpo das duas pontas: ele deixa de ser barrado e deixa de barrar.
## Dano de contato e vulnerabilidade não passam por aqui — Hitbox e Hurtbox são
## áreas próprias, em camadas próprias, e continuam valendo.
@export var passa_por_tudo: bool = false

@export_group("Aura")

## Cor da luz que acompanha a criatura. Alfa zero desliga.
##
## Serve para o chefe se anunciar no meio da horda: ele não é só o maior, é o
## único que ilumina o chão em volta.
@export var aura_color: Color = Color(0, 0, 0, 0)

## Raio da luz, em pixels de mundo. Zero desliga.
@export var aura_radius: float = 0.0

## Quanto a luz pulsa, em segundos de ida e volta. Zero deixa fixa.
@export var aura_pulso: float = 0.0


## Um tipo sem id ou sem vida não deveria existir; vale conferir na carga,
## porque `.tres` é editado à mão com frequência.
func is_valid() -> bool:
	return id != &"" and max_health > 0.0
