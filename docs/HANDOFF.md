# HANDOFF

Última atualização: 2026-08-28

# Projeto

Forest Survival

# Stack

- Godot 4.7.2 stable (DEC-001)
- GDScript
- 2D top-down
- survivor-like
- Android como plataforma prioritária futura

# Commit base encontrado

`3df8d99 feat: cria fundacao inicial do projeto Godot`

Árvore limpa e sincronizada com `origin/main` no início da sessão.

# Estado inicial encontrado

FASE 0 concluída e íntegra. `tests/test_foundation.gd` foi executado antes de qualquer alteração e passou.

Nada da FASE 1 existia: sem `player.tscn`, sem `player.gd`, sem mundo de teste. `scenes/player/` e `scripts/player/` continham apenas `.gitkeep`.

# Estado atual

## Fase concluída

**FASE 1 — Movimento e mundo. Concluída.**

Ao rodar o jogo existe uma área de protótipo com grid e um Player controlável em oito direções, com câmera acompanhando e paredes de borda.

Depois da FASE 1, o sprite do druida (estado CANDIDATE) foi integrado no lugar do placeholder geométrico e a câmera foi ajustada para top-down. Isso **não** avança o ROADMAP: a FASE 2 continua não iniciada.

Não existe combate, inimigo, arma, XP nem HUD — correto para esta fase.

## Assets

Inventário (`docs/ASSET_WORKFLOW.md`):

| Asset | Estado | Frames | Sheet |
|---|---|---|---|
| `druida-sul-walk-south.png` | **CANDIDATE** | 13 | 832 x 96 |
| `druida-north-walk-north.png` | **CANDIDATE** | 12 | 768 x 96 |
| `druida-west-walk-west.png` | **CANDIDATE** | 17 | 1088 x 96 |
| `druida-east-walk-east.png` | **CANDIDATE** | 15 | 960 x 96 |
| mundo de teste (chão + grid) | **PLACEHOLDER** | — | geometria nativa, sem arquivo |

Todos em `assets/characters/`, quadro de 64 x 96, pivot bottom-center, layout horizontal de linha única, com `.json` de metadados ao lado. Reunidos em `assets/characters/druida_sprite_frames.tres` (4 animações, 57 frames).

`assets/characters/frames/` guarda os frames avulsos como **fonte**. Tem um `.gdignore` para a Godot não importar os 71 PNGs individualmente; o jogo carrega só os sheets.

Nenhuma arte foi criada, baixada, redesenhada ou inventada por IA.

### Verificação feita nos sheets

- **As direções conferem com os nomes.** Conferido visualmente frame a frame: east olha para a direita, west para a esquerda, north é de costas (sem rosto), south é de frente. Isto foi checado porque o asset anterior estava rotulado errado.
- **Baseline constante** em y=96 nos cinco sheets — pivot bottom-center correto.
- **Alinhamento bom:** deriva horizontal do centro entre frames de 1,5 px (south, east) a 2,5 px (north, west). O asset anterior tinha 18 px.
- **Ciclo fecha de forma aceitável:** a diferença entre o primeiro e o último frame (15,6 a 21,1) está na mesma faixa da diferença entre frames vizinhos (13,0 a 14,9), ou seja, a emenda do loop não salta mais que uma transição normal.

### Ressalva que permanece

**Não existe animação de `idle` para nenhuma direção.** Houve um `idle_south`, mas a arte estava errada e foi removida a pedido. Parado, o druida congela no primeiro frame da caminhada da direção atual: preserva a direção certa e não inventa pose. É o fallback da regra 9 do `ASSET_WORKFLOW`, não um erro.

Os arquivos removidos continuam recuperáveis no commit `a56fe21`, se um dia forem úteis como referência.

# Implementação do Player

## Caminhos

| O quê | Caminho |
|---|---|
| Cena | `res://scenes/player/player.tscn` |
| Script | `res://scripts/player/player.gd` (`class_name Player`) |
| Camada visual | `res://scripts/player/player_visual.gd` |

## Estrutura de `player.tscn`

```text
Player (CharacterBody2D)   grupo "player", layer 1, mask 128
├── Visual (Node2D)                    <- player_visual.gd
│   └── Sprite (AnimatedSprite2D)      <- druida_sprite_frames.tres
├── CollisionShape2D (CircleShape2D, raio 14)
└── Camera2D                           <- zoom 2, offset y = -40
```

O `Sprite` tem `position.y = -48`, o que coloca os pés na origem do `Player`.
A `CollisionShape2D` fica centrada na origem, ou seja, na pegada do personagem
— o padrão para top-down. Ela **não** foi dimensionada a partir da arte.

`Hurtbox`, `PickupArea` e `WeaponManager` **não** foram criados: não são necessários para movimento e pertencem às fases de combate, XP e armas.

## Velocidade

`@export var move_speed: float = 200.0` — px/s, dentro da faixa 180–220 do GDD. Valor provisório; o sistema de Stats só entra na FASE 6.

## Movimento

```gdscript
var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
velocity = direction * move_speed
move_and_slide()
```

- só Input Actions; nenhuma tecla lida diretamente, nenhum `Input.is_key_pressed()`;
- `Input.get_vector` já limita o comprimento a 1, então a diagonal **não** é mais rápida;
- `velocity` **não** é multiplicado por `delta`: em `CharacterBody2D` é px/s e `move_and_slide()` aplica o passo de física;
- roda em `_physics_process`.

## Facing

`enum Facing { SOUTH, NORTH, WEST, EAST }`, determinado pelo eixo de maior magnitude. Empate (diagonal exata) resolve para o eixo **vertical** — regra fixa para a direção não oscilar na diagonal. Parado mantém a última direção válida.

Foi implementado agora por ser barato e por ser exatamente a costura que as sprites direcionais vão usar depois. Não há `AnimationTree`, nem state machine de animação, nem animação fictícia.

## Contrato com a camada visual (DEC-013)

`player.gd` **nunca** lê textura, sprite, tamanho de imagem ou animação. Ele emite dois sinais, ambos conectados na própria `player.tscn`:

| Sinal | Método no `Visual` | Significado |
|---|---|---|
| `facing_changed(facing)` | `set_facing()` | direção encarada mudou |
| `movement_state_changed(is_moving)` | `set_moving()` | começou ou parou de andar |

Ou seja: a lógica informa **intenção**, a camada visual decide a **representação**. `player.gd` não sabe quantos frames existem, nem que animações existem, nem qual direção tem arte.

O sheet do druida foi integrado exatamente por essa costura, sem alterar uma linha de `player.gd`.

`player_visual.gd` monta o nome da animação a partir do estado e da direção (`walk_north`, `idle_south`, ...) e degrada em ordem quando a animação pedida não existe:

1. `<estado>_<direção>`
2. `walk_<direção>` — mantém a direção certa, congelada no frame 0
3. `<estado>_south`
4. `walk_south`

Nenhum passo gera erro. Acrescentar `idle_north` ao `.tres` faz o passo 1 passar a valer sozinho, sem tocar em código.

Não há espelhamento horizontal para leste/oeste: existem sheets próprios para as duas direções, com o cajado na mão correta.

O nó `Visual` e a `CollisionShape2D` têm `editor_description` explicando isso dentro do editor.

## Physics layer / mask

| Nó | layer | mask |
|---|---|---|
| `Player` | 1 — PlayerBody | 128 — WorldStatic (DEC-016) |
| paredes do `TestWorld` | 128 — WorldStatic | 0 |

Mask mínima de propósito. Nada foi marcado preventivamente.

## Câmera

`Camera2D` filha do Player, sem smoothing e sem shake. Os limites (`limit_left/top/right/bottom`) são aplicados em runtime por `Player.apply_camera_limits(bounds)`.

Ajustes de enquadramento top-down feitos com a arte real:

- `@export var camera_zoom: float = 2.0` no Player, aplicado no `_ready()`. Comparei 1.0, 1.5 e 2.0 em execução: a 1.0 o druida ocupa 13% da altura da tela e perde detalhe; a 2.0 fica legível, o que importa pela prioridade Android (`docs/ANDROID.md`). **Usar zoom inteiro** — 1.5 deforma pixel art, produzindo pixels de tamanhos diferentes.
- `Camera2D.position.y = -40`, para enquadrar o corpo em vez dos pés.

Ambos são **provisórios** e devem ser revistos na FASE 3: com hordas na tela, campo de visão passa a competir com legibilidade, e o zoom 2 reduz a área visível para 640x360 unidades de mundo.

### Pendente para top-down: Y-sort

Sprites altos em top-down precisam ordenar por Y, para que quem está mais abaixo desenhe na frente. **Não foi habilitado agora**, de propósito: com `y_sort_enabled` na raiz, o chão do `TestWorld` (origem em y=0) passaria a ordenar contra o Player, e o Player desapareceria atrás do chão ao andar para cima. Fazer direito exige separar o chão em uma camada própria, abaixo das entidades. Fica para quando existirem inimigos (FASE 2/3).

# Mundo de teste

| O quê | Caminho |
|---|---|
| Cena | `res://scenes/game/test_world.tscn` |
| Script | `res://scripts/systems/test_world.gd` (`class_name TestWorld`) |

`@export var world_size := Vector2(3072, 3072)` é a **única fonte de verdade** das dimensões. Dela derivam, sem duplicação:

1. o chão e o grid, desenhados em `_draw()` (grid a cada 256 px, só para tornar o deslocamento perceptível);
2. as quatro paredes `StaticBody2D`, construídas em código em `_ready()`;
3. os limites da câmera.

Os limites usam **paredes físicas** (Opção A), não clamp de posição: assim o mapa não precisa vazar para dentro de `player.gd`, e trocar o mapa não mexe no Player.

**Isto é protótipo.** Não é TileSet, não é floresta, não é a arquitetura final do mapa. O mapa do survivor-like poderá ser muito maior, rolar infinitamente ou funcionar de outra forma.

# Composição da partida

`res://scripts/systems/game.gd`, na raiz de `game.tscn`, faz uma coisa só:

```gdscript
_player.apply_camera_limits(_test_world.get_bounds())
```

Não é manager e não guarda estado. Existe para que o Player não conheça o mapa e o mapa não alcance dentro do Player. GameManager, SpawnManager e WaveManager entram nas fases previstas no ROADMAP.

## Estrutura de `game.tscn`

```text
Game (Node2D)                <- scripts/systems/game.gd
├── World (Node2D)
│   └── TestWorld            <- instância de test_world.tscn
├── Player                   <- instância de player.tscn, em (0, 0)
├── EnemyContainer (Node2D)
├── ProjectileContainer (Node2D)
├── PickupContainer (Node2D)
├── EffectContainer (Node2D)
└── CanvasLayer
```

# Arquivos criados

- `scenes/player/player.tscn`
- `scenes/game/test_world.tscn`
- `assets/characters/druida_sprite_frames.tres` (4 animações, 57 frames)
- `assets/characters/frames/.gitkeep` substituído por `.gdignore` + `README.md`
- `scripts/player/player.gd` (+ `.uid`)
- `scripts/player/player_visual.gd` (+ `.uid`)
- `scripts/systems/test_world.gd` (+ `.uid`)
- `scripts/systems/game.gd` (+ `.uid`)
- `tests/test_phase1.gd` (+ `.uid`)
- `tests/test_foundation.gd.uid` (gerado pela Godot, versionado agora)

# Arquivos modificados

- `scenes/game/game.tscn` (script de composição, instâncias de TestWorld e Player)
- `docs/ROADMAP.md` (FASE 1 marcada)
- `docs/DECISIONS.md` (DEC-016)
- `docs/HANDOFF.md`
- `docs/CHANGELOG.md`
- `docs/TODO.md`

`.gitkeep` removidos de `scenes/player/`, `scripts/player/` e `scripts/systems/`, que agora têm conteúdo real.

Na integração do sprite (depois da FASE 1) mudaram: `scenes/player/player.tscn`, `scripts/player/player.gd` (sinal `movement_state_changed`, export `camera_zoom`) e `scripts/player/player_visual.gd` (reescrito para o sheet). O `.png` e o `.json` do asset entraram versionados.

# Testes executados

Godot usado na validação: **4.7.1 stable** (`4.7.1.stable.official.a13da4feb`).

| # | Comando | Resultado |
|---|---|---|
| 1 | `--headless --script res://tests/test_foundation.gd` (antes de alterar nada) | `FASE 0 OK`, exit 0 |
| 2 | `--headless --import` | exit 0, `Player` e `TestWorld` registrados como classes globais |
| 3 | `--headless --script res://tests/test_foundation.gd` (depois) | `FASE 0 OK`, exit 0 |
| 4 | `--headless --script res://tests/test_phase1.gd` | `FASE 1 OK`, exit 0 |
| 5 | `--quit-after 180 --resolution 1280x720` (com render) | Vulkan / Forward Mobile, exit 0, sem erro |
| 6 | Captura de tela em execução real (script temporário, não versionado) | ver abaixo |
| 7 | Suíte completa reexecutada após integrar o sprite | `FASE 0 OK` e `FASE 1 OK`, exit 0 nos dois |
| 8 | Captura em execução com o sprite, zoom 1.0 / 1.5 / 2.0 e caminhada | arte renderiza, anima e a câmera acompanha |
| 9 | Após trocar pelos sheets por direção: suíte completa + captura das animações em execução | `FASE 0 OK` e `FASE 1 OK`; todas as animações resolvem e tocam corretamente |
| 10 | Após remover o `idle_south`: andar e parar nas quatro direções | `.tres` expõe só `walk_east/north/south/west`; parado em cada direção resolve para `walk_<direção>` no frame 0, sem erro nem warning |

## O que `tests/test_phase1.gd` cobre

Estrutura: `player.tscn` existe, raiz é `CharacterBody2D`, script anexado, grupo `player`, `Visual` presente, `CollisionShape2D` com shape, `Camera2D` presente, `collision_layer`/`collision_mask` corretos, `move_speed` válido, `game.tscn` instancia Player e área de teste maior que a viewport, Input Actions presentes.

Comportamento, em execução real: deslocamento medido a **60 Hz** e a **30 Hz**, limites da câmera aplicados, e Player empurrado contra a parede.

## Resultado das medições

```
60 Hz: 100.0 px em 0.50s
30 Hz: 100.0 px em 0.50s
```

Exatamente `200 px/s x 0,5 s` nas duas taxas — velocidade independente do FPS, medida, não presumida.

## Verificação de que os testes não são vacuosos

Dois erros foram injetados de propósito e revertidos em seguida:

1. `velocity = direction * move_speed * delta` → o teste falhou com 1,7 px a 60 Hz contra 3,3 px a 30 Hz;
2. `collision_mask = 0` no Player → o teste falhou com "Player atravessou a parede: x=1842.7, borda em 1536.0".

Ambos foram desfeitos e a suíte voltou a passar.

## Verificação visual

Executado com renderização, capturando o viewport. Confirmado: Player visível no centro com o grid ao redor, câmera acompanhando o movimento, câmera travando na borda do mundo, e Player parando em `x = 1521.995` — exatamente `1536 - 14` (borda menos o raio da colisão). `facing` terminou em `EAST`, e os limites da câmera em `[-1536, -1536, 1536, 1536]`.

**Não foi feito teste com teclado humano.** O input foi simulado via `Input.action_press`, que percorre o mesmo caminho de Input Actions que o teclado. Vale confirmar manualmente no editor.

# Limitações e pendências

- **Não há `idle` em nenhuma direção.** Parado, congela no frame 0 da caminhada correspondente. Fallback previsto, não erro.
- **Diagonal mostra a direção vertical.** Andando na diagonal, o empate de magnitude resolve para north/south. É a regra fixa do `facing`; se preferir horizontal na diagonal, é uma linha em `_update_facing`.
- BUG-001 (largura da textura) foi **corrigido** pela troca do asset.
- **Godot 4.7.2 continua não validado.** O ambiente só tem 4.7.1 stable; procurei por 4.7.2 e não existe na máquina. DEC-001 não foi alterada e nada fora de 4.7 foi usado. Quem tiver 4.7.2 deve abrir o projeto uma vez e rodar as duas suítes.
- Movimento não foi testado com teclado físico por uma pessoa (ver acima).
- O mundo de teste é protótipo descartável, não arquitetura de mapa.
- Nenhum bug de código. BUG-001 está corrigido em `docs/BUGS.md`.

# Próxima tarefa

**FASE 2 — Primeiro inimigo.** Não iniciada.

Itens, na ordem do `docs/ROADMAP.md`:

1. criar `scenes/enemies/enemy.tscn` com raiz `Enemy (CharacterBody2D)` e a estrutura de `docs/02_ARCHITECTURE.md`: `Visual`, `CollisionShape2D`, `Hitbox`, `Hurtbox`;
2. criar `scripts/enemies/enemy.gd` com perseguição direta simples ao Player — **sem** `NavigationAgent2D` e sem pathfinding (DEC-008);
3. colisão: `Enemy` na layer 2 (EnemyBody); definir as masks de Player e Enemy conforme DEC-014/DEC-016 — o Player passa a precisar da layer 2 na mask;
4. criar `HealthComponent` em `scripts/components/` com `max_health`, `current_health`, `damage()`, `heal()` e sinal de morte (`docs/03_SYSTEMS.md` §3);
5. dano por contato via `Hitbox` -> `Hurtbox` -> `HealthComponent` (`docs/03_SYSTEMS.md` §4);
6. morte do inimigo, garantindo que ocorra uma única vez;
7. placeholder visual do inimigo sob o nó `Visual`, conforme `docs/ASSET_WORKFLOW.md` — não criar arte;
8. instanciar um inimigo em `game.tscn` sob `EnemyContainer` para teste manual;
9. testar conforme a seção "Enemy" do `docs/TEST_PLAN.md`, inclusive "não deixa erro após player morrer";
10. criar `tests/test_phase2.gd`; manter `test_foundation.gd` e `test_phase1.gd` passando;
11. atualizar HANDOFF, CHANGELOG, TODO e ROADMAP.

Para achar o Player, o inimigo deve usar o grupo `player` **uma vez**, guardando a referência — nunca `get_nodes_in_group()` dentro de `_physics_process` (`docs/02_ARCHITECTURE.md`, pensando em centenas de inimigos).

## Critério de aceite da FASE 2

- inimigo encontra e persegue o Player;
- inimigo recebe dano e morre uma única vez;
- Player e inimigo colidem de forma coerente;
- nenhum erro no debugger depois da morte do Player;
- nenhum inimigo faz busca global por frame;
- placeholder continua desacoplado da lógica.

# Não alterar sem registrar decisão

- Godot 4.7.2 stable
- GDScript
- survivor-like original
- protagonista druida
- offline-first
- sem serviços pagos no MVP
- arquitetura preparada para mobile
- desenvolvimento independente de arte final (DEC-013 / `docs/ASSET_WORKFLOW.md`)
- numeração das physics layers 2D (DEC-014)
- renderer `mobile` e stretch `canvas_items`/`expand` (DEC-015)
- layer 8 WorldStatic (DEC-016)
- movimento por Input Actions, nunca por tecla direta

# Regra permanente de assets

Falta de sprite, animação ou efeito **não é bloqueio**. Use placeholder sob o nó `Visual`, mantenha gameplay desacoplado da arte e siga `docs/ASSET_WORKFLOW.md`.
