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

# Pendências de arte (não bloqueiam programação — DEC-013)

- [x] gerar as direções que faltam: north, west, east
- [ ] gerar `idle` para as quatro direções (o `idle_south` que existia estava errado e foi removido)
- [x] regerar com os frames alinhados (deriva caiu de ~18 px para 1,5–2,5 px)
- [x] reexportar em sheets menores (ver BUG-001, corrigido)
- [ ] revisar a velocidade das caminhadas: 15 fps, valor inicial, não testado com o jogo em ritmo real
- [ ] aprovar ou recusar o conjunto: hoje está CANDIDATE, não APPROVED

# Pendências técnicas

- [ ] confirmar o projeto em Godot **4.7.2** stable (a validação rodou em 4.7.1; ver "Limitações e pendências" no HANDOFF)
- [ ] confirmar manualmente o movimento com teclado físico no editor (o input automatizado usa `Input.action_press`)
- [ ] revalidar `camera_zoom` (hoje 1.0) na FASE 3, com hordas na tela, e em tela de celular
- [ ] habilitar Y-sort ao criar inimigos, separando o chão em uma camada abaixo das entidades

# Depois

Seguir `ROADMAP.md`.

# Regra

Não acumular aqui ideias soltas de conteúdo.

Ideias de conteúdo devem ir para `04_CONTENT_PLAN.md`.

TODO deve conter trabalho executável.
