# Changelog

Todas as mudanças relevantes devem ser registradas aqui.

Formato inspirado em Keep a Changelog, sem obrigação rígida.

## Unreleased

### Added

- documentação inicial do projeto;
- protocolo multi-IA;
- GDD inicial;
- arquitetura inicial;
- roadmap;
- plano de testes;
- direção de arte;
- planejamento Android;
- `docs/ASSET_WORKFLOW.md` com a política de assets progressivos e os estados `PLACEHOLDER` / `CANDIDATE` / `APPROVED` / `INTEGRATED`;
- `DEC-013 — Desenvolvimento independente de arte final` em `docs/DECISIONS.md`;
- **FASE 0 — Fundação:**
  - `project.godot` (Godot 4.7, renderer `mobile`, viewport 1280x720 landscape, stretch `canvas_items`/`expand`, filtro Nearest);
  - Input Map com `move_up`, `move_down`, `move_left`, `move_right` e `pause`, por `physical_keycode` (WASD + setas + Escape);
  - nomes das 7 physics layers 2D;
  - estrutura de pastas de `docs/02_ARCHITECTURE.md`;
  - `scenes/game/game.tscn` (`Game`, `World`, `EnemyContainer`, `ProjectileContainer`, `PickupContainer`, `EffectContainer`, `CanvasLayer`), definida como Main Scene;
  - `tests/test_foundation.gd`, validação headless da FASE 0;
  - `DEC-014 — Numeração final das physics layers 2D`;
  - `DEC-015 — Renderer e modo de stretch`.
- **FASE 1 — Movimento e mundo:**
  - `scenes/player/player.tscn` — `Player (CharacterBody2D)` no grupo `player`, com `Visual`, `CollisionShape2D` (círculo, raio 14) e `Camera2D`;
  - `scripts/player/player.gd` — movimento em 8 direções por Input Actions, diagonal normalizada, `move_speed` exportado (200 px/s), enum `Facing` e sinal `facing_changed`;
  - `scripts/player/player_visual.gd` — camada visual substituível, com placeholder geométrico;
  - `scenes/game/test_world.tscn` + `scripts/systems/test_world.gd` — área de protótipo 3072x3072 com chão, grid e paredes derivados de `world_size`;
  - `scripts/systems/game.gd` — composição da partida: liga os limites do mundo à câmera do Player;
  - `tests/test_phase1.gd` — validação headless de estrutura, diagonal, independência de FPS, limites de câmera e paredes;
  - `DEC-016 — Layer 8: WorldStatic`.
- **Integração do sprite do druida (estado CANDIDATE, não avança o ROADMAP):**
  - `assets/characters/druidwalkesquerda-walk-west.png` + `.json` versionados e importados;
  - `Sprite2D` com 120 frames sob o nó `Visual`, no lugar do placeholder geométrico;
  - sinal `movement_state_changed` no Player, para a camada visual alternar entre parado e caminhando;
  - `camera_zoom` exportado (2.0) e câmera deslocada para enquadrar o corpo, ajuste top-down;
  - `BUG-001` em `docs/BUGS.md`: largura de 7680 px do sheet contra o limite de textura de GPUs Android antigas.
- **Sprites por direção (estado CANDIDATE, não avança o ROADMAP):**
  - cinco sheets em `assets/characters/`: `idle_south` (14 frames), `walk_south` (13), `walk_north` (12), `walk_west` (17), `walk_east` (15), todos 64 x 96 e pivot bottom-center;
  - `assets/characters/druida_sprite_frames.tres` reunindo as 5 animações (71 frames), caminhadas a 15 fps e idle a 8 fps;
  - `Visual/Sprite` passou de `Sprite2D` para `AnimatedSprite2D`;
  - `player_visual.gd` escolhe a animação por estado + direção, com degradação em quatro níveis quando a animação pedida não existe;
  - `assets/characters/frames/` com os frames avulsos como fonte, marcada com `.gdignore` para a Godot não importá-los;
  - removido o sheet antigo `druidwalkesquerda-walk-west` (7680 px), o que **corrige BUG-001**.
- **Remoção do `idle_south`** (arte incorreta, a pedido): sheet, `.json`, `.import` e os 14 frames avulsos removidos; `druida_sprite_frames.tres` regerado com 4 animações e 57 frames; animação padrão da cena passou para `walk_south`. Nenhuma mudança de lógica foi necessária — a degradação já prevista em `player_visual.gd` cobriu a ausência de idle.

### Changed

- `README.md`: nova seção "Política de assets" e `ASSET_WORKFLOW.md` na lista de documentação;
- `AGENTS.md`: regras de placeholder, desacoplamento arte/gameplay e leitura obrigatória do fluxo de assets;
- `docs/02_ARCHITECTURE.md`: seção "Camada visual e assets" definindo o nó `Visual` como único ponto de troca de arte;
- `docs/05_ART_DIRECTION.md`: entrega progressiva de arte, fallback de direções e animações;
- `docs/HANDOFF.md`: estado atual, regra permanente de assets e última tarefa concluída;
- `PROMPT_CLAUDE_INICIAL.md` e `PROMPT_CHATGPT_RETOMADA.md`: leitura e regras de assets;
- `docs/ROADMAP.md`: FASE 0 marcada como concluída;
- `docs/HANDOFF.md`: estado pós-FASE 0, configurações, testes e próxima tarefa exata da FASE 1;
- `docs/TODO.md`: fundação concluída, próximas tarefas passam a ser as da FASE 1.
- `scenes/game/game.tscn`: script de composição, instância da área de teste sob `World` e instância do Player;
- `docs/ROADMAP.md`: FASE 1 marcada como concluída;
- `docs/HANDOFF.md`: estado pós-FASE 1, implementação do Player, testes e próxima tarefa exata da FASE 2;
- `docs/TODO.md`: FASE 1 concluída, próximas tarefas passam a ser as da FASE 2.

### Fixed

Nada.
