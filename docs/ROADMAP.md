# ROADMAP

Legenda:

- [ ] não iniciado
- [~] em andamento
- [x] concluído
- [!] bloqueado

# FASE 0 — Fundação

- [x] Criar projeto Godot 4.7.2
- [x] Configurar Git
- [x] Configurar `.gitignore`
- [x] Criar estrutura de pastas
- [x] Configurar resolução
- [x] Configurar Input Map
- [x] Definir layers/masks
- [x] Criar cena `game.tscn`

Critério de saída:
projeto abre e roda sem erro. **Atingido.**

Observações:
- as *layers* 2D estão nomeadas em `project.godot` (DEC-014); as *masks* de cada entidade serão aplicadas quando Player e Enemy existirem (FASE 1/2);
- validação automatizada: `tests/test_foundation.gd`.

# FASE 1 — Movimento e mundo

- [x] Player
- [x] movimento WASD/setas
- [x] câmera
- [x] sprite placeholder
- [x] mapa placeholder
- [x] limites/teste de mundo

Critério:
player se move corretamente. **Atingido.**

Observações:
- o "sprite placeholder" e o "mapa placeholder" são geometria nativa da Godot, não arte (DEC-013);
- limites de mundo são paredes `StaticBody2D` na layer 8 (DEC-016), de protótipo — não são a arquitetura final do mapa;
- o Y-sort ficou pendente nesta fase e foi habilitado junto com a FASE 2 (ver HANDOFF);
- validação automatizada: `tests/test_phase1.gd`.

# FASE 2 — Primeiro inimigo

- [x] cena base Enemy
- [x] perseguição simples
- [x] colisão
- [x] HP
- [x] dano
- [x] morte

Critério:
player e inimigo podem interagir e inimigo pode morrer. **Atingido.**

Observações:
- perseguição direta simples, sem pathfinding (DEC-008); referência ao Player resolvida uma única vez;
- componentes reutilizáveis em `scripts/components/`: `HealthComponent`, `HitboxComponent`, `HurtboxComponent`;
- fluxo de dano e masks registrados em `DEC-017`;
- as sprites do diabrete entraram direto no nó `Visual`, em estado CANDIDATE — não foi preciso placeholder (DEC-013);
- validação automatizada: `tests/test_phase2.gd`.

# FASE 3 — Spawn e horda

- [ ] SpawnManager
- [ ] spawn fora da câmera
- [ ] limite inicial
- [ ] aumento de densidade
- [ ] teste com 100+ inimigos

# FASE 4 — Primeira arma

- [ ] WeaponManager
- [ ] Cajado da Floresta
- [ ] targeting
- [ ] projétil
- [ ] dano
- [ ] cooldown

# FASE 5 — XP e Level Up

- [ ] drop
- [ ] pickup
- [ ] XP
- [ ] curva
- [ ] menu de level up
- [ ] 3 escolhas
- [ ] XP excedente/múltiplos levels

# FASE 6 — Sistema de upgrades

- [ ] WeaponData
- [ ] UpgradeData
- [ ] levels
- [ ] passivas
- [ ] validação das opções

# FASE 7 — Três famílias de arma

- [ ] Cajado — projétil
- [ ] Espinhos — AoE
- [ ] Corvo — orbital

# FASE 8 — Waves

- [ ] WaveData
- [ ] cronômetro
- [ ] 3 tipos de inimigo
- [ ] progressão
- [ ] elite
- [ ] boss

# FASE 9 — Loop completo

- [ ] HP HUD
- [ ] XP HUD
- [ ] timer
- [ ] level
- [ ] pause
- [ ] game over
- [ ] restart
- [ ] victory

Critério:
vertical slice completo.

# FASE 10 — Performance

- [ ] profiler
- [ ] stress 100 inimigos
- [ ] stress 250 inimigos
- [ ] stress 500 inimigos
- [ ] identificar gargalos
- [ ] pooling onde necessário
- [ ] reduzir custo de física
- [ ] reduzir alocações

# FASE 11 — Arte

- [ ] player final
- [ ] animações
- [ ] inimigos
- [ ] mapa
- [ ] efeitos
- [ ] ícones
- [ ] UI

# FASE 12 — Mobile

- [ ] joystick virtual
- [ ] UI responsiva
- [ ] safe areas
- [ ] Android export
- [ ] performance device
- [ ] consumo de memória
- [ ] testes de resolução

# FASE 13 — Meta-progressão

Somente depois do vertical slice:
- [ ] save local
- [ ] moeda
- [ ] desbloqueios
- [ ] seleção de personagem
- [ ] upgrades permanentes

# FASE 14 — Conteúdo

- [ ] mais armas
- [ ] mais passivas
- [ ] mais inimigos
- [ ] bosses
- [ ] mapas
- [ ] personagens

# FASE 15 — Publicação

- [ ] nome final
- [ ] ícone
- [ ] screenshots
- [ ] página Google Play
- [ ] política de privacidade quando aplicável
- [ ] build release
- [ ] testes internos
- [ ] closed testing
- [ ] release
