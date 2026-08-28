# TODO

# Concluído

FASE 0 — Fundação. Ver `docs/HANDOFF.md`.

- [x] colocar documentação no repositório
- [x] criar projeto Godot
- [x] criar estrutura de pastas
- [x] criar `.gitignore`
- [x] configurar resolução
- [x] configurar Input Map
- [x] nomear physics layers 2D
- [x] criar cena principal e defini-la como Main Scene
- [x] commit da fundação

# Agora — FASE 1 (movimento e mundo)

- [ ] criar `scenes/player/player.tscn` (raiz `Player`, `CharacterBody2D`)
- [ ] criar `scripts/player/player.gd` com movimento por Input Actions
- [ ] normalizar input para que a diagonal não seja mais rápida
- [ ] usar `delta` (velocidade independente do FPS)
- [ ] adicionar `Camera2D` seguindo o jogador
- [ ] adicionar sprite **placeholder** sob o nó `Visual`
- [ ] criar mapa placeholder e limites de mundo
- [ ] instanciar o Player em `game.tscn` sob `World`
- [ ] testar conforme a seção "Movimento" de `TEST_PLAN.md`
- [ ] atualizar HANDOFF, CHANGELOG, TODO e ROADMAP

# Pendências técnicas

- [ ] confirmar o projeto em Godot **4.7.2** stable (a validação da FASE 0 rodou em 4.7.1; ver "Problemas conhecidos" no HANDOFF)
- [ ] definir as *masks* de física por entidade quando Player e Enemy existirem (as *layers* já estão nomeadas — DEC-014)

# Depois

Seguir `ROADMAP.md`.

# Regra

Não acumular aqui ideias soltas de conteúdo.

Ideias de conteúdo devem ir para `04_CONTENT_PLAN.md`.

TODO deve conter trabalho executável.
