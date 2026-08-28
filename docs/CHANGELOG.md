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

### Fixed

Nada.
