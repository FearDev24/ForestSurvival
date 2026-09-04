# TODO

# Concluído

FASE 0 — Fundação.
FASE 1 — Movimento e mundo.
FASE 2 — Primeiro inimigo.
FASE 3 — Spawn e horda.
FASE 4 — Primeira arma.
FASE 5 — XP e Level Up.
HUD da partida (FASE 9, adiantado): vida, XP, nível e cronômetro.

Detalhes em `docs/HANDOFF.md`.

# Agora — FASE 6 (sistema de upgrades)

- [ ] `UpgradeData` em `Resource`, no lugar das opções montadas à mão pelo menu
- [ ] passivas da primeira lista do `04_CONTENT_PLAN.md` (vida, velocidade, área, cooldown, alcance de coleta)
- [ ] oferecer arma nova além de melhorar equipada, respeitando os slots
- [ ] validar opções: nada impossível, nada repetido na mesma tela
- [ ] `StatComponent` para as passivas terem onde somar (`03_SYSTEMS.md` §14)
- [ ] criar `tests/test_phase6.gd`

Com o HUD no lugar, dá para julgar cada passiva olhando a tela em vez de ler
número em log — que era o motivo de adiantá-lo.

# Pendências de arte (não bloqueiam programação — DEC-013)

- [x] gerar as direções que faltam: north, west, east
- [ ] gerar `idle` para as quatro direções do **druida** (o `idle_south` que existia estava errado e foi removido). Só o druida tem `idle` — DEC-019
- [x] regerar com os frames alinhados (deriva caiu de ~18 px para 1,5–2,5 px)
- [x] reexportar em sheets menores (ver BUG-001, corrigido)
- [ ] revisar a velocidade das caminhadas: 15 fps, valor inicial, não testado com o jogo em ritmo real
- [ ] aprovar ou recusar o conjunto do druida: hoje está CANDIDATE, não APPROVED
- [ ] aprovar ou recusar o conjunto do diabrete: hoje está CANDIDATE, não APPROVED
- [ ] aprovar ou recusar a morte do druida, o `gameover` e o raio: hoje estão CANDIDATE
- [ ] aprovar ou recusar o mapa (tiles, bordas, props) e a vinha: hoje estão CANDIDATE
- [ ] gerar folha de obstáculos: toco cortado, tronco partido, troncos cruzados, cairn — fundo magenta, base encostando embaixo, 60 a 120 px
- [ ] gerar variações de cogumelo e arbusto (solitário, trio, touceira) para o mapa não repetir peça
- [ ] gerar peças de transição terra↔água, que o tileset atual não cobre
- [x] reexportar a morte do druida na escala da caminhada — resolvido pela versão feita do vídeo, que já nasce com o corpo em 70 px (`death_scale` voltou a 1.0)
- [ ] tela de game over de verdade — tempo, level, reiniciar, voltar ao menu (FASE 9); hoje só a imagem aparece
- [ ] animação de morte do **inimigo**: hoje ele simplesmente some
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
