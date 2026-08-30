# TODO

# Concluído

FASE 0 — Fundação.
FASE 1 — Movimento e mundo.
FASE 2 — Primeiro inimigo.

Detalhes em `docs/HANDOFF.md`.

# Agora — FASE 3 (spawn e horda)

- [ ] criar `SpawnManager` em `scripts/systems/`
- [ ] **nunca criar dois inimigos na mesma coordenada** — sobreposição exata não se resolve sozinha (ver "Espaçamento da horda" no HANDOFF)
- [ ] spawn fora da câmera, sem nascer visivelmente sobre o Player
- [ ] limite inicial de população
- [ ] aumento gradual de densidade
- [ ] teste com 100+ inimigos, registrando FPS, frametime, nodes e memória
- [ ] criar `tests/test_phase3.gd`

# Pendências de arte (não bloqueiam programação — DEC-013)

- [x] gerar as direções que faltam: north, west, east
- [ ] gerar `idle` para as quatro direções do **druida** (o `idle_south` que existia estava errado e foi removido). Só o druida tem `idle` — DEC-019
- [x] regerar com os frames alinhados (deriva caiu de ~18 px para 1,5–2,5 px)
- [x] reexportar em sheets menores (ver BUG-001, corrigido)
- [ ] revisar a velocidade das caminhadas: 15 fps, valor inicial, não testado com o jogo em ritmo real
- [ ] aprovar ou recusar o conjunto do druida: hoje está CANDIDATE, não APPROVED
- [ ] aprovar ou recusar o conjunto do diabrete: hoje está CANDIDATE, não APPROVED
- [ ] revisar a velocidade da caminhada do diabrete: 12 fps, valor inicial
- [ ] **reexportar o diabrete em 32 x 48** e devolver `Visual.scale` para 1 (hoje está em 0.5, o que reduz pixel art abaixo da resolução nativa)

# Pendências técnicas

- [ ] confirmar o projeto em Godot **4.7.2** stable (a validação rodou em 4.7.1; ver "Limitações e pendências" no HANDOFF)
- [ ] confirmar manualmente o movimento com teclado físico no editor (o input automatizado usa `Input.action_press`)
- [ ] revalidar `camera_zoom` (hoje 1.0) na FASE 3, com hordas na tela, e em tela de celular
- [x] habilitar Y-sort ao criar inimigos, separando o chão em uma camada abaixo das entidades

# Depois

Seguir `ROADMAP.md`.

# Regra

Não acumular aqui ideias soltas de conteúdo.

Ideias de conteúdo devem ir para `04_CONTENT_PLAN.md`.

TODO deve conter trabalho executável.
