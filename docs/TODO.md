# TODO

# Concluído

FASE 0 — Fundação.
FASE 1 — Movimento e mundo.

Detalhes em `docs/HANDOFF.md`.

# Agora — FASE 2 (primeiro inimigo)

- [ ] criar `scenes/enemies/enemy.tscn` (raiz `Enemy`, `CharacterBody2D`)
- [ ] criar `scripts/enemies/enemy.gd` com perseguição direta simples (sem pathfinding — DEC-008)
- [ ] guardar a referência ao Player uma única vez, nunca buscar por frame
- [ ] criar `HealthComponent` em `scripts/components/`
- [ ] fluxo de dano `Hitbox` -> `Hurtbox` -> `HealthComponent`
- [ ] morte do inimigo, garantindo que ocorra uma única vez
- [ ] definir layers/masks de Player e Enemy (layer 2 EnemyBody)
- [ ] placeholder visual do inimigo sob o nó `Visual`
- [ ] instanciar um inimigo em `game.tscn` sob `EnemyContainer`
- [ ] criar `tests/test_phase2.gd`
- [ ] testar conforme a seção "Enemy" do `TEST_PLAN.md`
- [ ] atualizar HANDOFF, CHANGELOG, TODO e ROADMAP

# Pendências técnicas

- [ ] confirmar o projeto em Godot **4.7.2** stable (a validação rodou em 4.7.1; ver "Limitações e pendências" no HANDOFF)
- [ ] confirmar manualmente o movimento com teclado físico no editor (o input automatizado usa `Input.action_press`)

# Depois

Seguir `ROADMAP.md`.

# Regra

Não acumular aqui ideias soltas de conteúdo.

Ideias de conteúdo devem ir para `04_CONTENT_PLAN.md`.

TODO deve conter trabalho executável.
