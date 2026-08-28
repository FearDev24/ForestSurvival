# 02 — Arquitetura Técnica

# Objetivos

- modularidade;
- fácil manutenção por IA/humano;
- performance;
- dados separados de comportamento;
- facilidade para criar novas armas e inimigos;
- independência entre gameplay e arte final (DEC-013).

# Estrutura planejada

```text
res://
├── autoload/
│   ├── game_manager.gd
│   └── save_manager.gd              # somente quando necessário
├── assets/
│   ├── characters/
│   ├── enemies/
│   ├── environment/
│   ├── ui/
│   ├── weapons/
│   └── effects/
├── audio/
├── resources/
│   ├── enemies/
│   ├── weapons/
│   ├── upgrades/
│   └── waves/
├── scenes/
│   ├── game/
│   ├── player/
│   ├── enemies/
│   ├── weapons/
│   ├── projectiles/
│   ├── pickups/
│   ├── ui/
│   └── effects/
├── scripts/
│   ├── components/
│   ├── player/
│   ├── enemies/
│   ├── weapons/
│   ├── systems/
│   └── ui/
└── tests/
```

# Cena principal

Estrutura desejada aproximada:

```text
Game
├── World
├── Player
├── EnemyContainer
├── ProjectileContainer
├── PickupContainer
├── EffectContainer
├── SpawnManager
├── WaveManager
└── CanvasLayer
    └── HUD
```

# Player

```text
Player (CharacterBody2D)
├── Visual
├── CollisionShape2D
├── Hurtbox
├── PickupArea
├── WeaponManager
└── Camera2D
```

# Enemy

```text
Enemy (CharacterBody2D)
├── Visual
├── CollisionShape2D
├── Hitbox
└── Hurtbox
```

# Camada visual e assets

Ver `docs/ASSET_WORKFLOW.md` e `DEC-013`.

O nó `Visual` de `Player` e `Enemy` é o **único ponto de troca de arte** da entidade.

Regras:

- `Visual` pode conter um placeholder (`ColorRect`, `Polygon2D`, sprite temporário) ou a arte final; o restante da cena não muda entre os dois casos;
- `CollisionShape2D`, `Hurtbox` e `Hitbox` são irmãos de `Visual`, nunca filhos dele, e são dimensionados por critério de gameplay;
- scripts de movimento, HP, IA, combate, XP e armas não leem `texture`, `sprite_frames`, tamanho de sprite ou frame atual;
- a lógica comunica **intenção** à camada visual (direção, estado "andando"/"parado", "levou dano"); a escolha de animação pertence à camada visual;
- animação ausente resulta em fallback silencioso (espelhar direção oposta, reutilizar sul, ou manter `idle`), nunca em erro em runtime;
- substituir um asset aprovado não deve exigir alteração em nenhum script de gameplay. Se exigir, o acoplamento é um defeito a corrigir.

# Componentes

Quando possível separar:
- HealthComponent
- HurtboxComponent
- HitboxComponent
- MovementComponent
- DropComponent

Não criar abstração antes de existir necessidade real.

# WeaponManager

Responsável por:
- armazenar armas equipadas;
- adicionar arma;
- melhorar arma;
- consultar nível;
- limitar slots.

Não deve implementar comportamento específico de cada arma.

# Recursos

Usar `Resource` para dados que terão múltiplas variantes.

Exemplo conceitual:

```gdscript
class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export var base_damage: float
@export var cooldown: float
@export var projectile_speed: float
@export var amount: int
```

# Comunicação

Preferir:
- signals;
- referências diretas quando relação é simples e estável;
- managers apenas para responsabilidades globais.

Evitar:
- `get_tree().get_nodes_in_group()` repetidamente em centenas de entidades por frame;
- autoload para tudo;
- dependência circular.

# Performance

Para hordas:

## Permitido inicialmente

Inimigo:
- guarda referência ao player;
- calcula direção simples;
- `move_and_slide()` ou movimento controlado adequado.

## Evitar

- pathfinding complexo individual;
- raycasts constantes sem necessidade;
- busca de alvo global todo frame por todo projétil;
- criação/destruição excessiva em massa;
- timers-node individuais em centenas de entidades quando uma alternativa central for melhor.

# Object Pooling

Não implementar no primeiro minuto do projeto.

Implementar quando profiling indicar custo relevante ou antes do teste final mobile para:
- projéteis muito frequentes;
- inimigos;
- pickups;
- efeitos.

# Física

Configurar layers/masks de forma documentada.

Planejamento:

1. PlayerBody
2. EnemyBody
3. PlayerHurtbox
4. EnemyHurtbox
5. PlayerAttack
6. EnemyAttack
7. Pickup

A numeração final deve ser registrada após implementação.

# Dados vs código

Código = comportamento.

Resources = valores e conteúdo.

Objetivo:
criar novo inimigo alterando principalmente dados/scene, sem duplicar lógica.
