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
