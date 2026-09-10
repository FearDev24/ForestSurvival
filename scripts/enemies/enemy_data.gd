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


## Um tipo sem id ou sem vida não deveria existir; vale conferir na carga,
## porque `.tres` é editado à mão com frequência.
func is_valid() -> bool:
	return id != &"" and max_health > 0.0
