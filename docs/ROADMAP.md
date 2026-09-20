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

- [x] WeaponData — feito na FASE 4
- [x] UpgradeData
- [x] levels — feito na FASE 4, com teto por arma
- [x] passivas — as 6 da primeira lista
- [x] validação das opções

Critério:
upgrades são dados, passivas mudam o jogo de verdade, nada impossível é
oferecido. **Atingido.**

Observações:
- uma passiva é um stat mais um número: `stat`, `flat`, `mult` e `max_stacks`, e nada além disso. Campo próprio seria caso especial, que é o que o `StatComponent` existe para evitar;
- armas convivem na mesma lista, com `kind = ARMA`. Escolher uma já equipada sobe o nível dela;
- dano, cooldown e área são lidos **a cada disparo**, não guardados: passiva escolhida no meio da partida vale no tiro seguinte, sem avisar a arma;
- `REGEN` não está na lista da §14 — entrou porque o Coração Verde precisa dela, e foi acrescentado no fim do enum porque os `.tres` guardam o stat como número;
- validação automatizada: `tests/test_phase6.gd`.

Fora da lista original, feito primeiro:

- [x] `StatComponent` (`docs/03_SYSTEMS.md` §14), com velocidade, vida máxima e alcance de coleta migrados

A ordem foi invertida de propósito. Sem um lugar onde os bônus se somem, toda
passiva viraria um caso especial escrito à mão e o `UpgradeData` nasceria tendo
que conhecer cada um deles. Com o `StatComponent` no lugar, uma passiva é um
bônus somado a um stat e mais nada.

# FASE 7 — Três famílias de arma

- [x] golpe — `AbilityEffect` (Cajado Tempestade, Vinha Espinhosa)
- [x] projétil — `ProjectileEffect` (Corvo Espiritual)
- [x] zona — `ZoneEffect` (Anel de Esporos)
- [x] orbital — `OrbitEffect` (Vagalumes Guardiões)

Critério:
famílias sensivelmente diferentes, e arma nova continua sendo `.tres`.
**Atingido** — com quatro famílias, não três.

A lista original pareava arma e família assim: *Cajado — projétil, Espinhos —
AoE, Corvo — orbital*. Foi escrita antes da FASE 4, e a FASE 4 decidiu outra
coisa: o cajado virou raio que cai **sobre** o alvo e a vinha virou golpe que
brota do chão (DEC-021, DEC-022). Os dois acabaram na mesma família. Manter o
pareamento antigo significaria refazer duas armas já aprovadas em jogo; em vez
disso entraram duas armas novas, e a orbital — que era a única família da lista
sem representante — foi construída.

Observações:
- o que separa as famílias é **como o ataque termina**: animação, alvos atravessados, duração no chão, duração acompanhando. É por isso que são scripts diferentes e não campos do mesmo;
- `WeaponData` ganhou `projectile_speed`, `projectile_pierce` e `effect_duration`, todos com **zero = usa o valor da cena** — assim uma família nova não obriga arma antiga a preencher número alheio;
- `DURATION`, `PROJECTILE_SPEED` e `AMOUNT` deixaram de ser stats sem leitor;
- validação automatizada: `tests/test_phase7.gd`.

# FASE 8 — Waves

- [x] WaveData
- [x] cronômetro
- [x] 3 tipos de inimigo
- [x] progressão
- [x] elite
- [x] boss

Critério:
quem nasce e quando é dado, não fórmula; elite e boss existem e são
sensivelmente diferentes; a partida tem um arco legível. **Atingido.**

Observações:
- a divisão é a que a §6 e a §7 já pediam — o `WaveManager` decide **quem e quando**, o `SpawnManager` decide **onde e se cabe**;
- a rampa linear do `SpawnManager` continua existindo como modo sem waves, e se cala enquanto a tabela manda. Desligar o `WaveManager` devolve a rampa, em vez de calar os dois;
- os tipos se distinguem por número, tamanho e cor enquanto só há a arte do diabrete. É PLACEHOLDER declarado (DEC-013): quando cada arte chegar, `scene` deixa de ser nula e `tint` volta a branco, sem tocar em código;
- nenhuma wave passa de 200 inimigos, que é o teto medido: 250 já custam 14,03 ms de física contra 16,6 de orçamento por quadro;
- validação automatizada: `tests/test_phase8.gd`.

# FASE 9 — Loop completo

- [x] HP HUD
- [x] XP HUD
- [x] timer
- [x] level
- [x] pause
- [x] game over
- [x] restart
- [x] victory

Critério:
vertical slice completo. **Atingido.**

O HUD foi adiantado, fora da ordem do roadmap, porque a FASE 6 é toda sobre
balanceamento: sem ver vida, XP e tempo na tela não há como julgar se uma
passiva compensa.

Observações:
- o estado da partida virou **um só**, no `GameManager`. Antes morava em quatro lugares que precisavam concordar sozinhos: `_running` na raiz e um `enabled` no spawn, no wave e nas armas;
- ligar e desligar sistema passou a ser **consequência da transição**, não responsabilidade de quem a provocou. Cada tela nova deixou de ter que lembrar dos quatro;
- a tela de escolha não pausa mais sozinha: avisa que abriu e fechou, e quem pausa é o manager. Dois lugares mexendo em `get_tree().paused` foi o que esta fase veio desfazer;
- a vitória é uma conexão, não um sistema: o wave entrega o nó do boss e o `HealthComponent` dele já emitia `died` desde a FASE 2;
- a mesma tela serve à vitória e à derrota — o que muda é o título e a cor. Duas cenas quase iguais divergiriam na primeira mexida;
- validação automatizada: `tests/test_phase9.gd`.

O **menu principal** ficou de fora desta fase e entrou depois: a §16 pede "voltar
ao menu", e desde então o jogo abre em `scenes/ui/main_menu.tscn` e o botão MENU da
pausa e do resultado volta para ele (validação em `tests/test_menu.gd`). Faltam só
o nome do jogo desenhado e a ilustração de fundo, que funcionam como vagas vazias.

Observações:
- as barras são `TextureProgressBar` com moldura e preenchimento separados: clipar a imagem cheia inteira cortaria a gema da ponta junto (DEC-023);
- o cronômetro é da partida, não do HUD: quem conta é `scripts/systems/game.gd`, em passo de física, e por isso ele congela sozinho quando a tela de level up pausa o jogo;
- validação automatizada: `tests/test_hud.gd`.

# FASE 10 — Performance

- [x] profiler — `tools/sonda_balanceamento.gd -- --perf`: custo de quadro numa partida real
- [x] stress 100 inimigos
- [x] stress 250 inimigos — medido em 200 e 300, os dois lados do teto
- [x] stress 500 inimigos — 4 FPS: inviável, e o teto de 200 fica
- [x] identificar gargalos — física da horda empilhada; desenho dos fragmentos de XP
- [x] pooling onde necessário — avaliado: nenhum lugar precisou (p99 abaixo de 4 ms)
- [ ] reduzir custo de física — adiado para a medição no aparelho (FASE 12)
- [ ] reduzir alocações — sem sinal na medição
- [x] fragmentos de XP numa textura só — 331 chamadas de desenho a menos com 300 no chão

Detalhes, tabelas e o que ficou de fora em `docs/HANDOFF.md`, "FASE 10".

# FASE 11 — Arte

- [x] player final — druida em quatro direções, mais a morte
- [x] animações — caminhada das cinco criaturas e a queda do Guardião, todas tiradas de vídeo por `tools/extrair_inimigo_video.py`
- [x] inimigos — diabrete, cão, bruto, elite e Guardião com arte própria; nenhum é mais o diabrete recolorido
- [x] mapa — tileset da floresta, com pedra, totem, toco e vegetação
- [x] efeitos — as seis habilidades desenhadas; nenhuma é mais forma em código
- [x] ícones — doze, um por arma e por passiva
- [x] UI — barras, painéis, placas, títulos das três telas, nome do jogo, fundo do menu e ícone do app
- [x] `idle` do druida — as quatro direções, tiradas de vídeo por `tools/extrair_idle_druida.py`

Fechada com a arte entregue e integrada, incluindo o `idle` do druida.

# FASE 12 — Mobile

- [x] joystick virtual — flutuante, na metade esquerda, pelas mesmas ações `move_*` do teclado
- [x] UI responsiva — `canvas_items` + `expand` (DEC-015), controles de toque só em tela de toque
- [x] safe areas — `AreaSegura`, só em aparelho móvel
- [x] Android export — `export_presets.cfg`, APK de depuração arm64 gerado
- [x] performance device — medido no Xiaomi 2412DPC0AG com o bot jogando: quadro médio 8,4 ms, p95 12,1, pior 25,2; física no pico 13,2. Folga para 60 FPS, mas os 120 Hz da tela não se sustentam
- [x] consumo de memória — 58 MB de RAM e 124 MB de vídeo numa partida de 7,5 minutos
- [x] pausa por toque — não estava na lista: no celular não há Esc

Detalhes e o que ainda falta decidir em `docs/HANDOFF.md`, "FASE 12".
- [ ] testes de resolução

# FASE 13 — Meta-progressão

Somente depois do vertical slice:
- [x] save local — JSON versionado em `user://`, com defaults seguros (DEC-026)
- [x] moeda — abates, tempo e vitória, somados no save e mostrados no resultado
- [ ] desbloqueios
- [ ] seleção de personagem
- [x] upgrades permanentes — vida, dano e velocidade, cinco níveis cada, na tela MELHORIAS

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
