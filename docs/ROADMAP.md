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

- [x] SpawnManager
- [x] spawn fora da câmera
- [x] limite inicial
- [x] aumento de densidade
- [x] teste com 100+ inimigos

Critério:
inimigos aparecem sozinhos, em ritmo crescente, sem quebrar a partida. **Atingido.**

Observações:
- `SpawnManager` recebe alvo, container e limites do mundo de `game.gd`; não procura nada sozinho;
- o raio de spawn sai do viewport e do zoom da câmera, não de constante, por causa da variedade de telas Android (DEC-015);
- rampa linear de 5 minutos: intervalo de 1,2 s a 0,2 s, população de 40 a 200;
- teto de 200 medido, não chutado: ver "Carga" no HANDOFF;
- validação automatizada: `tests/test_phase3.gd`.

# FASE 4 — Primeira arma

- [x] WeaponManager
- [x] Cajado da Floresta — entrou como **Cajado Tempestade**, o raio
- [x] targeting
- [x] projétil — os ataques são efeitos de vida curta, não projéteis com trajetória
- [x] dano
- [x] cooldown

Critério:
o druida ataca sozinho e mata inimigos. **Atingido.**

Observações:
- duas armas, não uma: o raio e a **Vinha Espinhosa**, porque a arte das duas já existia e ambas cabiam no mesmo `WeaponData` (DEC-021);
- arma é dado, não código: `resources/weapons/*.tres` (DEC-010). Arma nova é um `.tres`;
- o `WeaponManager` mora no Player, mas não conhece arma alguma (DEC-009);
- a mira varre a lista de inimigos **só no instante do disparo**, nunca por frame;
- o andaime da fase anterior — `RaioTeste`, `VinhaTeste`, `lightning_caster.gd` e `tests/test_raio.gd` — foi apagado;
- validação automatizada: `tests/test_phase4.gd`.

Falta para o loop completo: XP e level up (FASE 5) decidem **quando** uma arma sobe de nível. O `WeaponManager` já expõe `upgrade_weapon()` e `has_upgradable_weapon()` para isso.

# FASE 5 — XP e Level Up

- [x] drop
- [x] pickup
- [x] XP
- [x] curva
- [x] menu de level up
- [x] 3 escolhas
- [x] XP excedente/múltiplos levels

Critério:
matar rende XP, XP rende escolha, escolha muda a partida. **Atingido.**

Observações:
- o `PickupSpawner` escuta o `SpawnManager` e liga o `died` de cada inimigo uma vez: custo de uma conexão por inimigo, sem varrer nada;
- quem procura o fragmento é a `PickupArea` do Player, não cada fragmento — o Player é um só e os orbes são muitos (mesmo princípio da DEC-017);
- XP excedente nunca se perde, e vários níveis de uma vez abrem uma escolha por nível — o ponto marcado como IMPORTANTE no `docs/03_SYSTEMS.md` §12;
- a tela só abre com opção **aplicável**: arma no nível máximo não é oferecida (§13);
- o visual do orbe é PLACEHOLDER desenhado em código (DEC-013);
- validação automatizada: `tests/test_phase5.gd`.

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

- [x] HP HUD
- [x] XP HUD
- [x] timer
- [x] level
- [ ] pause
- [ ] game over
- [ ] restart
- [ ] victory

Critério:
vertical slice completo. **Parcial.**

O painel foi adiantado, fora da ordem do roadmap, porque a FASE 6 é toda sobre
balanceamento: sem ver vida, XP e tempo na tela não há como julgar se uma
passiva compensa. O resto da fase — pausa, tela de game over de verdade e
condição de vitória — continua pendente e depende do `GameManager`
(`docs/03_SYSTEMS.md` §16).

Observações:
- as barras são `TextureProgressBar` com moldura e preenchimento separados: clipar a imagem cheia inteira cortaria a gema da ponta junto (DEC-023);
- o cronômetro é da partida, não do HUD: quem conta é `scripts/systems/game.gd`, em passo de física, e por isso ele congela sozinho quando a tela de level up pausa o jogo;
- validação automatizada: `tests/test_hud.gd`.

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
