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
- **FASE 4 — Primeira arma:**
  - `scripts/weapons/weapon_data.gd` — `WeaponData`, `Resource` com os números e a cena do ataque; arma nova é um `.tres`, não código (DEC-010);
  - `scripts/weapons/weapon.gd` — uma arma em funcionamento: cooldown, mira e criação do ataque, sem conhecer arma específica;
  - `scripts/weapons/weapon_manager.gd` — slots, acrescentar, melhorar e consultar nível; arma repetida **melhora** em vez de duplicar;
  - `resources/weapons/cajado_raio.tres` e `vinha_espinhosa.tres` — as duas primeiras armas, com progressão de dano e cooldown por nível;
  - `WeaponManager` no Player, ligado ao mundo por `game.gd`;
  - `AbilityEffect.set_damage()`: o nível da arma chega ao golpe sem a cena saber que existe arma;
  - o dano nas cenas de ataque virou `1.0`, marcador — quem manda no número é o `WeaponData`;
  - `tests/test_phase4.gd`, que absorveu o antigo `test_raio.gd`;
  - **andaime removido:** nós `RaioTeste` e `VinhaTeste`, `scripts/effects/lightning_caster.gd` e `tests/test_raio.gd`.
- **Mapa em tiles, bordas e objetos de cenário (arte nova, estado CANDIDATE):**
  - `assets/environment/tileset-{terra,agua}.png` — 16 peças de 64 px cada, conjuntos de **cantos** completos, recortados das folhas originais (que vinham com células de tamanhos diferentes e uma moldura clara por dentro);
  - `assets/environment/forest_tileset.tres` — `TileSet` com terrenos declarados (Terra, Mata, Água, modo cantos), então o pincel do editor autotila;
  - `Ground` (`TileMapLayer`) em `test_world.tscn`, com preenchimento procedural provisório por ruído amostrado **nos cantos** das células;
  - 8 peças de vegetação fechando as quatro bordas do mapa, com sobreposição e tom escurecido para conviver com o chão;
  - `get_camera_bounds()` separado de `get_bounds()`: a câmera enquadra a borda, o spawn não;
  - 8 objetos de cenário com escala variável, agrupamento, reserva de espaço e colisão de pegada nos sólidos;
  - ordem de desenho reorganizada: `y_sort` até os props, `z_index` negativo só no chão;
  - `DEC-020 — Mapa: tileset de cantos, borda fora da área jogável, props sólidos`.
- **Vinha — segunda habilidade (andaime até a FASE 4):**
  - `assets/effects/vinha.png` — 8 quadros de 240 x 88, extraídos de folha em grade irregular e ancorados no botão da rosa;
  - `scenes/effects/vine_lash.tscn`, com hitbox sobre o eixo do golpe;
  - `scripts/effects/ability_effect.gd` (`AbilityEffect`) substitui `lightning_strike.gd`: mesmo comportamento, sem nome de habilidade específica;
  - `LightningCaster` ganha `spawn_on_target` e `aim_at_target`, e passa a servir as duas habilidades;
  - `DEC-021 — Um único efeito de habilidade, com dois modos de disparo`;
  - correção: os testes desligam as habilidades **por tipo**, não por nome — a vinha nova travou `test_phase2` em silêncio.
- **Morte do druida refeita a partir de vídeo:**
  - `assets/characters/morte-druida-south.png` — 36 quadros de 96 x 160, gerados de um vídeo de 10 s em chroma verde;
  - quadro maior que o da caminhada para caber o cajado, com os pés na linha 136;
  - `death_scale` volta para 1.0: a folha nasce na escala certa, e a meia-altura passa a sair do próprio quadro;
  - a folha anterior e o vídeo ficam em `assets/_raw/`.
- **Morte do druida, game over e raio (arte nova, estado CANDIDATE):**
  - `assets/characters/morte-druid-morte-south.png` — 27 frames de morte, animação `death_south` sem loop no `SpriteFrames` do druida;
  - `assets/ui/gameover.png` e `assets/effects/raio.png`, limpos da franja de chroma e movidos para as pastas da estrutura de `02_ARCHITECTURE`;
  - `player_visual.gd` toca a morte uma vez e avisa quando acaba; `player.gd` repassa como `death_finished`, sem saber o que foi apresentado;
  - `game.gd` mostra a imagem de game over no lugar onde o druida caiu, e desliga spawn e raio;
  - `scenes/effects/lightning_strike.tscn` + `scripts/effects/lightning_strike.gd` — raio com dano só a partir do frame de impacto, que some sozinho ao fim da animação;
  - `scripts/effects/lightning_caster.gd` — disparo automático **provisório**, fora do Player (DEC-009), até o `WeaponManager` da FASE 4;
  - `HitboxComponent` ganha **golpe único** (`hit_interval = 0`): cada alvo leva dano uma vez só. É o modo que projéteis e explosões vão usar;
  - botão `REINICIAR` na `CanvasLayer`, que aparece com o game over e recarrega a partida;
  - correção de escala da morte: a arte veio com 63 px de altura contra 87 da caminhada e com os pés 16 px acima da base do quadro; `player_visual.gd` compensa com `death_scale`, sem reamostrar a arte;
  - game over reduzido de 0,45 para 0,28 de escala;
  - `tests/test_raio.gd`, e checagens de morte, game over e botão de reiniciar em `tests/test_phase2.gd`.
- **FASE 3 — Spawn e horda:**
  - `scripts/systems/spawn_manager.gd` — ponto de spawn fora da câmera, teto de população e rampa de densidade, sem `Timer` e sem busca por grupo;
  - `SpawnManager` em `game.tscn`, ligado ao Player, ao `EnemyContainer` e aos limites do mundo por `game.gd`;
  - os quatro diabretes fixos saíram de `game.tscn`: quem cria inimigos agora é o manager;
  - `tests/test_phase3.gd` — estrutura, spawn fora da tela, teto de população, rampa de densidade e carga com 50/100/250/500 inimigos;
  - correção: `monitorable`/`monitoring` passam a ser desligados com `set_deferred` na morte. Sem isso, morrer dentro do `area_entered` da hitbox que matou gerava "Function blocked during in/out signal" — apareceu no teste de carga, com 300 inimigos.
- **FASE 2 — Primeiro inimigo:**
  - `scripts/components/health_component.gd` — `max_health`, `current_health`, `damage()`, `heal()`, sinais `health_changed`, `damaged` e `died`, com morte emitida uma única vez;
  - `scripts/components/hitbox_component.gd` — dano por contato com `hit_interval`, sem `Timer` por entidade e com `_physics_process` desligado quando não há alvo sobreposto;
  - `scripts/components/hurtbox_component.gd` — único ponto de entrada de dano de uma entidade;
  - `Health` e `Hurtbox` no Player (100 de vida), `Health`, `Hitbox` e `Hurtbox` no Enemy (30 de vida, 10 de dano por contato a cada 1 s);
  - morte do inimigo (sai da partida) e morte do Player (para de andar e sai do radar; game over é da FASE 9);
  - colisão de corpos conforme `DEC-018`: inimigo separa-se de inimigo (mask 130, raio 14) e o Player atravessa a horda levando dano por contato;
  - `tests/test_phase2.gd` — estrutura, componentes, layers/masks, perseguição, dano por contato com intervalo, morte única e ausência de erro após a morte do Player;
  - Y-sort habilitado: `y_sort_enabled` na raiz de `game.tscn` e no `EnemyContainer`, com `z_index = -1` no `World` para manter o cenário abaixo das entidades — pendência aberta desde a FASE 1;
  - `DEC-017 — Fluxo de dano: a hitbox procura, a hurtbox espera`;
  - `DEC-018 — Inimigo colide com inimigo, nunca com o Player`.
- **Diabrete — sprites do primeiro inimigo (estado CANDIDATE):**
  - `assets/characters/inimigos/diabrete-{south,north,west,east}-walk-*.png` + `.json`, limpos do resíduo de chroma key e versionados;
  - `assets/characters/inimigos/_raw/` com os PNGs originais como fonte, ignorados pela Godot (`.gdignore`);
  - `assets/characters/inimigos/diabrete_sprite_frames.tres` — 4 animações, 57 frames, 12 fps;
  - `scenes/enemies/enemy.tscn` — `Enemy (CharacterBody2D)` no grupo `enemy`, com `Visual` e `CollisionShape2D` (círculo, raio 12);
  - `scripts/enemies/enemy.gd` — perseguição direta simples (DEC-008), referência ao Player resolvida uma única vez, enum `Facing`, sinais `facing_changed` e `movement_state_changed`;
  - `scripts/enemies/enemy_visual.gd` — camada visual com a mesma cadeia de fallback do Player;
  - quatro diabretes instanciados em `game.tscn` sob `EnemyContainer`, para teste manual;
  - `Visual.scale = 0.5` no inimigo e `CollisionShape2D` com raio 8: o diabrete é uma criatura pequena, de cerca de metade da altura do druida;
  - seção "Limpeza de resíduo de chroma key" em `docs/ASSET_WORKFLOW.md`.
- **Integração do sprite do druida (estado CANDIDATE, não avança o ROADMAP):**
  - `assets/characters/druidwalkesquerda-walk-west.png` + `.json` versionados e importados;
  - `Sprite2D` com 120 frames sob o nó `Visual`, no lugar do placeholder geométrico;
  - sinal `movement_state_changed` no Player, para a camada visual alternar entre parado e caminhando;
  - `camera_zoom` exportado (2.0) e câmera deslocada para enquadrar o corpo, ajuste top-down;
  - `BUG-001` em `docs/BUGS.md`: largura de 7680 px do sheet contra o limite de textura de GPUs Android antigas.
- **Sprites por direção (estado CANDIDATE, não avança o ROADMAP):**
  - cinco sheets em `assets/characters/`: `idle_south` (14 frames), `walk_south` (13), `walk_north` (12), `walk_west` (17), `walk_east` (15), todos 64 x 96 e pivot bottom-center;
  - `assets/characters/druida_sprite_frames.tres` reunindo as 5 animações (71 frames), caminhadas a 15 fps e idle a 8 fps;
  - `Visual/Sprite` passou de `Sprite2D` para `AnimatedSprite2D`;
  - `player_visual.gd` escolhe a animação por estado + direção, com degradação em quatro níveis quando a animação pedida não existe;
  - `assets/characters/frames/` com os frames avulsos como fonte, marcada com `.gdignore` para a Godot não importá-los;
  - removido o sheet antigo `druidwalkesquerda-walk-west` (7680 px), o que **corrige BUG-001**.
- **Remoção do `idle_south`** (arte incorreta, a pedido): sheet, `.json`, `.import` e os 14 frames avulsos removidos; `druida_sprite_frames.tres` regerado com 4 animações e 57 frames; animação padrão da cena passou para `walk_south`. Nenhuma mudança de lógica foi necessária — a degradação já prevista em `player_visual.gd` cobriu a ausência de idle.
- **Câmera afastada:** `camera_zoom` de 2.0 para 1.0. Em 1920 x 1080 a área visível passa de 640 x 360 para 1280 x 720 unidades de mundo, e o druida de 26,7% para 13,3% da altura da tela.

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
