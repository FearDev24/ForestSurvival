# HANDOFF

Última atualização: 2026-09-08

# Projeto

Forest Survival

# Stack

- Godot 4.7.2 stable (DEC-001)
- GDScript
- 2D top-down
- survivor-like
- Android como plataforma prioritária futura

# Commit base encontrado

`3df8d99 feat: cria fundacao inicial do projeto Godot`

Árvore limpa e sincronizada com `origin/main` no início da sessão.

# Estado inicial encontrado

FASE 0 concluída e íntegra. `tests/test_foundation.gd` foi executado antes de qualquer alteração e passou.

Nada da FASE 1 existia: sem `player.tscn`, sem `player.gd`, sem mundo de teste. `scenes/player/` e `scripts/player/` continham apenas `.gitkeep`.

# Estado atual

## Fases concluídas

**FASE 0 a FASE 9.** O vertical slice fechou: dá para jogar, subir de nível, pausar, perder e vencer.

Mais o **HUD da partida** — vida, XP, nível e cronômetro —, adiantado da FASE 9 por um motivo: a FASE 6 é toda sobre balanceamento, e sem ver esses quatro números na tela não há como julgar se uma passiva compensa.

Ao rodar o jogo existe uma área de protótipo com grid e um Player controlável em oito direções, com câmera acompanhando e paredes de borda.

Depois da FASE 1, o sprite do druida (estado CANDIDATE) foi integrado no lugar do placeholder geométrico e a câmera foi ajustada para top-down.

Em 2026-08-29 entrou o **diabrete**, primeiro inimigo, com sprites nas quatro direções (estado CANDIDATE). Junto com ele entraram a cena `enemy.tscn` e a perseguição direta simples, porque sem locomoção não dava para avaliar a arte em movimento.

**FASE 2 — Primeiro inimigo. Concluída.** O diabrete persegue, causa dano por contato, recebe dano e morre uma única vez; o Player tem vida e morre. Componentes de vida, hitbox e hurtbox existem em `scripts/components/` e são reutilizáveis pelas armas da FASE 4.

**O laço do gênero fechou.** Matar rende XP, XP rende escolha, escolha muda a
partida — e o druida ainda pode perder. Falta o sistema de upgrades completo
(FASE 6), mais armas (FASE 7), waves (FASE 8) e HUD (FASE 9).

O mapa deixou de ser um retângulo liso: tem chão em tiles, vegetação fechando
as bordas e objetos de cenário com colisão. A morte do druida foi refeita a
partir de um vídeo e entrou na escala certa. E entrou uma segunda habilidade, a
**vinha**, que estreou o disparo direcional.

O druida **morre em cena**: animação de morte, imagem de game over no
lugar onde ele caiu, e uma primeira habilidade — o **raio** — caindo sozinha
sobre o inimigo mais próximo. O raio é andaime até a FASE 4.

Desde 2026-08-30 os inimigos aparecem sozinhos: o `SpawnManager` cria diabretes fora da tela, em ritmo que aumenta com o tempo e com teto de população. Os quatro diabretes fixos saíram de `game.tscn`.

Não existe arma, XP nem HUD — correto para esta fase. A vida do Player só é visível por script: a barra de HP é da FASE 9. Sem arma, a partida ainda não é vencível: a horda cresce até matar o druida.

## Assets

Inventário (`docs/ASSET_WORKFLOW.md`):

| Asset | Estado | Frames | Sheet |
|---|---|---|---|
| `druida-sul-walk-south.png` | **CANDIDATE** | 13 | 832 x 96 |
| `druida-north-walk-north.png` | **CANDIDATE** | 12 | 768 x 96 |
| `druida-west-walk-west.png` | **CANDIDATE** | 17 | 1088 x 96 |
| `druida-east-walk-east.png` | **CANDIDATE** | 15 | 960 x 96 |
| `diabrete-south-walk-south.png` | **CANDIDATE** | 18 | 1152 x 96 |
| `diabrete-north-walk-north.png` | **CANDIDATE** | 13 | 832 x 96 |
| `diabrete-west-walk-west.png` | **CANDIDATE** | 11 | 704 x 96 |
| `diabrete-east-walk-east.png` | **CANDIDATE** | 15 | 960 x 96 |
| `morte-druid-morte-south.png` | **CANDIDATE** | 27 | 1728 x 96 |
| `ui/gameover.png` | **CANDIDATE** | — | 1448 x 1086 |
| `effects/raio.png` | **CANDIDATE** | 8 | 2048 x 264 |
| `characters/morte-druida-south.png` | **CANDIDATE** | 36 | 3456 x 160 |
| `effects/vinha.png` | **CANDIDATE** | 8 | 1920 x 88 |
| `environment/tileset-terra.png` | **CANDIDATE** | 16 | 256 x 256 |
| `environment/tileset-agua.png` | **CANDIDATE** | 16 | 256 x 256 |
| `environment/parede-vert-0..3.png` | **CANDIDATE** | — | ~88 x 192 cada |
| `environment/parede-horiz-0..3.png` | **CANDIDATE** | — | ~123 x 182 cada |
| `environment/prop-*.png` (8 objetos) | **CANDIDATE** | — | 79 a 132 px |
| mundo de teste (chão + grid) | **PLACEHOLDER** | — | geometria nativa, sem arquivo |

Todos em `assets/characters/`, quadro de 64 x 96, pivot bottom-center, layout horizontal de linha única, com `.json` de metadados ao lado. Reunidos em `assets/characters/druida_sprite_frames.tres` (4 animações, 57 frames).

`assets/characters/frames/` guarda os frames avulsos como **fonte**. Tem um `.gdignore` para a Godot não importar os 71 PNGs individualmente; o jogo carrega só os sheets.

Nenhuma arte foi criada, baixada, redesenhada ou inventada por IA.

### Verificação feita nos sheets

- **As direções conferem com os nomes.** Conferido visualmente frame a frame: east olha para a direita, west para a esquerda, north é de costas (sem rosto), south é de frente. Isto foi checado porque o asset anterior estava rotulado errado.
- **Baseline constante** em y=96 nos cinco sheets — pivot bottom-center correto.
- **Alinhamento bom:** deriva horizontal do centro entre frames de 1,5 px (south, east) a 2,5 px (north, west). O asset anterior tinha 18 px.
- **Ciclo fecha de forma aceitável:** a diferença entre o primeiro e o último frame (15,6 a 21,1) está na mesma faixa da diferença entre frames vizinhos (13,0 a 14,9), ou seja, a emenda do loop não salta mais que uma transição normal.

### Ressalva que permanece

**Não existe animação de `idle` para nenhuma direção.** Houve um `idle_south`, mas a arte estava errada e foi removida a pedido. Parado, o druida congela no primeiro frame da caminhada da direção atual: preserva a direção certa e não inventa pose. É o fallback da regra 9 do `ASSET_WORKFLOW`, não um erro.

O druida é o **único** personagem que terá `idle` (DEC-019); nos inimigos, congelar no frame 0 da caminhada é o comportamento definitivo.

Os arquivos removidos continuam recuperáveis no commit `a56fe21`, se um dia forem úteis como referência.

## Diabrete (primeiro inimigo)

Os quatro sheets estão em `assets/characters/inimigos/`, mesmo formato do druida:
quadro de 64 x 96, pivot bottom-center, linha única horizontal, com `.json` ao
lado. Reunidos em `assets/characters/inimigos/diabrete_sprite_frames.tres`
(4 animações, 57 frames, 12 fps).

### Verificação feita nos sheets

- **As direções conferem com os nomes.** Conferido visualmente: east olha para a
  direita, west para a esquerda, north é de costas, south é de frente.
- **Baseline praticamente constante:** y = 95 em north e south, 94–95 em east e
  west (1 px de variação). Pivot bottom-center correto.
- **Deriva horizontal do centro entre frames:** 1,6 px (north) a 3,7 px (east) —
  faixa parecida com a do druida (1,5–2,5 px).
- **Nenhum pixel solto:** cada frame tem uma única ilha de pixels opacos; não há
  fragmentos flutuando.
- **Larguras seguras:** o maior sheet tem 1152 px, bem abaixo do limite de 4096
  que causou o BUG-001.
- **Os `.json` têm metadados inconsistentes.** O campo `sheet` aponta para nomes
  que não existem (`diabrete-east-idle-east.png`, `diabrete-north-idle-south.png`,
  `diabrete-south-andar-south.png`) e os `id` dos frames dizem `idle_` ou `andar_`
  em vez de `walk_`. Sobra do gerador; não afeta o jogo, porque o `.tres` é feito
  a partir das dimensões reais do PNG, não do `.json`.

### Limpeza de resíduo de chroma key

Os arquivos entregues tinham um contorno de pixels verdes semitransparentes em
volta da silhueta (sobra do fundo verde do gerador), mais alguns pontos de spill
dentro do corpo — visíveis, por exemplo, perto da cauda no frame 11 do sheet sul.

Foram removidos: franja verde semitransparente zerada e despill no que ficou.
O procedimento exato está em `docs/ASSET_WORKFLOW.md`, seção "Limpeza de resíduo
de chroma key". Resultado: **zero** pixels com componente verde dominante nos
quatro sheets, silhueta preservada, nenhuma ilha de pixels criada ou perdida.

Pixels de franja removidos por sheet: 4758 (east), 6064 (north), 8955 (south),
3692 (west).

Os PNGs originais estão preservados em `assets/characters/inimigos/_raw/`, com
`.gdignore` para a Godot não importar cópias — mesmo padrão de
`assets/characters/frames/`. Nada foi apagado.

Nenhuma arte foi criada, redesenhada ou inventada. A limpeza é técnica.

### Sem `idle`, de propósito

**O diabrete não terá `idle`** — nem ele, nem nenhum outro inimigo (DEC-019).
Parado, congela no frame 0 da caminhada da direção que encara, pelo passo 2 da
cadeia de fallback. Isto **não** é pendência de arte: é o alvo.

`idle` continua previsto só para o druida, que ainda não tem.

A cadeia de fallback de `enemy_visual.gd` segue tentando `idle_<direção>` antes
de `walk_<direção>`. Não custa nada e deixa a porta aberta caso um inimigo
específico — um boss, por exemplo — um dia ganhe pose parada.

# Implementação do Enemy

## Caminhos

| O quê | Caminho |
|---|---|
| Cena | `res://scenes/enemies/enemy.tscn` |
| Script | `res://scripts/enemies/enemy.gd` (`class_name Enemy`) |
| Camada visual | `res://scripts/enemies/enemy_visual.gd` |

## Estrutura de `enemy.tscn`

```text
Enemy (CharacterBody2D)   grupo "enemy", layer 2, mask 130
├── Visual (Node2D)        scale 0.5   <- enemy_visual.gd
│   └── Sprite (AnimatedSprite2D)      <- diabrete_sprite_frames.tres
├── CollisionShape2D (CircleShape2D, raio 14)   <- só separa inimigo de inimigo
├── Health (HealthComponent)           <- 30 de vida
├── Hitbox (Area2D)                    <- layer 6 EnemyAttack, mask 3; 10 de dano a cada 1 s
│   └── CollisionShape2D (CircleShape2D, raio 12, y = -14)
└── Hurtbox (Area2D)                   <- layer 4 EnemyHurtbox, mask 0
    └── CollisionShape2D (CircleShape2D, raio 12, y = -14)
```

## Escala

O diabrete é uma criatura pequena: deve medir cerca de **metade da altura do
druida**. A arte, porém, veio no mesmo quadro de 64 x 96 do druida — silhueta de
~92 px de altura (mediana), contra ~86 px do druida. Ou seja, no arquivo ele
chega ligeiramente **maior** que o jogador.

Correção provisória: `Visual.scale = 0.5` na cena, o que dá ~46 px contra os
~86 px do druida (53%). A escala fica no nó visual; `enemy.gd` não sabe dela.

**Isto custa definição.** Com `camera_zoom` 1.0 em 1920 x 1080 a escala total já
é 1,5x; multiplicada por 0.5 dá 0,75x, ou seja, a arte passa a ser reduzida
abaixo da resolução nativa — o mesmo problema descrito na seção da câmera.
**O certo é reexportar as sprites do diabrete em 32 x 48** e devolver a escala
para 1. Está em `docs/TODO.md`.

A `CollisionShape2D` ficou em raio **14**, igual à do Player, embora o diabrete
seja bem menor. Ela não mede o bicho: mede o espaço que ele reserva na horda.
Ver "Espaçamento da horda", mais abaixo, e DEC-018.

## Comportamento

Perseguição direta simples (DEC-008): `global_position.direction_to(alvo)` vezes
`move_speed`, sem `NavigationAgent2D` e sem pathfinding.

`@export var move_speed: float = 110.0` — mais lento que os 200 px/s do Player,
para que dê para fugir. Provisório até a FASE 6.

A referência ao Player é resolvida **uma única vez** no `_ready()`, por
`get_first_node_in_group("player")`. Nenhuma busca global por frame
(`docs/02_ARCHITECTURE.md`, DEC-011). `is_instance_valid()` cobre o alvo sumir da
árvore: o inimigo apenas para, sem erro.

O contrato com a camada visual é idêntico ao do Player — sinais `facing_changed`
e `movement_state_changed`, ligados na própria cena, com a mesma cadeia de
fallback de animação. `enemy.gd` não lê textura, sprite nem nome de animação.

`Enemy.Facing` é declarado no próprio `enemy.gd` em vez de reaproveitar
`Player.Facing`: o inimigo não deve depender do jogador para existir.

## Physics layer / mask, por enquanto

Tabela completa em **DEC-017** e **DEC-018**. Resumo:

| Nó | layer | mask |
|---|---|---|
| `Enemy` | 2 — EnemyBody | 2 (EnemyBody) + 128 (WorldStatic) = 130 |
| `Enemy/Hitbox` | 32 — EnemyAttack | 4 (PlayerHurtbox) |
| `Enemy/Hurtbox` | 8 — EnemyHurtbox | 0 |

**O corpo do inimigo só existe para os outros inimigos** (DEC-018): separa a
horda e é barrado pelo cenário. O Player atravessa por dentro e leva dano por
contato — dano, não empurrão. Fugir passando pelo meio da horda é jogada
legítima; ser bloqueado por dezenas de corpos não seria.

### Espaçamento da horda

O raio do corpo é **14 px**, o mesmo do Player, apesar de o diabrete ser menor.
Ele não representa o tamanho do bicho: representa **o espaço que um inimigo
reserva na horda**. Foi escolhido a partir da largura visível da sprite (24 a
30 px em escala 0.5), para que dois diabretes vizinhos encostem sem virar uma
mancha só. Medido com oito inimigos cercando o Player: **26,3 px** entre os mais
próximos.

Sobra um caso degenerado conhecido: dois inimigos criados **exatamente** no
mesmo ponto não se separam — a física não tem normal de contato para resolver, e
o par sai arremessado junto. Com qualquer distância inicial, mesmo de poucos
pixels, a separação funciona. É um requisito para o `SpawnManager` da FASE 3:
nunca criar dois inimigos na mesma coordenada.

# Implementação do Player

## Caminhos

| O quê | Caminho |
|---|---|
| Cena | `res://scenes/player/player.tscn` |
| Script | `res://scripts/player/player.gd` (`class_name Player`) |
| Camada visual | `res://scripts/player/player_visual.gd` |

## Estrutura de `player.tscn`

```text
Player (CharacterBody2D)   grupo "player", layer 1, mask 128
├── Visual (Node2D)                    <- player_visual.gd
│   └── Sprite (AnimatedSprite2D)      <- druida_sprite_frames.tres
├── CollisionShape2D (CircleShape2D, raio 14)
├── Health (HealthComponent)           <- 100 de vida
├── Hurtbox (Area2D)                   <- layer 3 PlayerHurtbox, mask 0
│   └── CollisionShape2D (CircleShape2D, raio 16, y = -24)
└── Camera2D                           <- offset y = -40
```

O `Sprite` tem `position.y = -48`, o que coloca os pés na origem do `Player`.
A `CollisionShape2D` fica centrada na origem, ou seja, na pegada do personagem
— o padrão para top-down. Ela **não** foi dimensionada a partir da arte.

`Hurtbox`, `PickupArea` e `WeaponManager` **não** foram criados: não são necessários para movimento e pertencem às fases de combate, XP e armas.

## Velocidade

`@export var move_speed: float = 200.0` — px/s, dentro da faixa 180–220 do GDD. Valor provisório; o sistema de Stats só entra na FASE 6.

## Movimento

```gdscript
var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
velocity = direction * move_speed
move_and_slide()
```

- só Input Actions; nenhuma tecla lida diretamente, nenhum `Input.is_key_pressed()`;
- `Input.get_vector` já limita o comprimento a 1, então a diagonal **não** é mais rápida;
- `velocity` **não** é multiplicado por `delta`: em `CharacterBody2D` é px/s e `move_and_slide()` aplica o passo de física;
- roda em `_physics_process`.

## Facing

`enum Facing { SOUTH, NORTH, WEST, EAST }`, determinado pelo eixo de maior magnitude. Empate (diagonal exata) resolve para o eixo **vertical** — regra fixa para a direção não oscilar na diagonal. Parado mantém a última direção válida.

Foi implementado agora por ser barato e por ser exatamente a costura que as sprites direcionais vão usar depois. Não há `AnimationTree`, nem state machine de animação, nem animação fictícia.

## Contrato com a camada visual (DEC-013)

`player.gd` **nunca** lê textura, sprite, tamanho de imagem ou animação. Ele emite dois sinais, ambos conectados na própria `player.tscn`:

| Sinal | Método no `Visual` | Significado |
|---|---|---|
| `facing_changed(facing)` | `set_facing()` | direção encarada mudou |
| `movement_state_changed(is_moving)` | `set_moving()` | começou ou parou de andar |

Ou seja: a lógica informa **intenção**, a camada visual decide a **representação**. `player.gd` não sabe quantos frames existem, nem que animações existem, nem qual direção tem arte.

O sheet do druida foi integrado exatamente por essa costura, sem alterar uma linha de `player.gd`.

`player_visual.gd` monta o nome da animação a partir do estado e da direção (`walk_north`, `idle_south`, ...) e degrada em ordem quando a animação pedida não existe:

1. `<estado>_<direção>`
2. `walk_<direção>` — mantém a direção certa, congelada no frame 0
3. `<estado>_south`
4. `walk_south`

Nenhum passo gera erro. Acrescentar `idle_north` ao `.tres` faz o passo 1 passar a valer sozinho, sem tocar em código.

Não há espelhamento horizontal para leste/oeste: existem sheets próprios para as duas direções, com o cajado na mão correta.

O nó `Visual` e a `CollisionShape2D` têm `editor_description` explicando isso dentro do editor.

## Physics layer / mask

| Nó | layer | mask |
|---|---|---|
| `Player` | 1 — PlayerBody | 128 — WorldStatic (DEC-016) |
| `Player/Hurtbox` | 4 — PlayerHurtbox | 0 |
| paredes do `TestWorld` | 128 — WorldStatic | 0 |

Mask mínima de propósito. O Player **não** colide com o corpo do inimigo: ele
atravessa a horda e leva dano por contato, não empurrão (DEC-018).

## Câmera

`Camera2D` filha do Player, sem smoothing e sem shake. Os limites (`limit_left/top/right/bottom`) são aplicados em runtime por `Player.apply_camera_limits(bounds)`.

Ajustes de enquadramento top-down feitos com a arte real:

- `@export var camera_zoom: float = 1.0` no Player, aplicado no `_ready()`.
- `Camera2D.position.y = -40`, para enquadrar o corpo em vez dos pés.

O zoom começou em 2.0 e foi reduzido para 1.0 depois de ver o jogo em tela cheia: o druida ocupava 26,7% da altura, sobrando pouco espaço de jogo. Medições em 1920 x 1080:

| zoom | mundo visível | altura do druida |
|---|---|---|
| 2.0 | 640 x 360 | 26,7% da tela |
| 1.5 | 853 x 480 | 20,0% da tela |
| **1.0** | **1280 x 720** | **13,3% da tela** |

Abaixo de 1.0 a arte passa a ser reduzida abaixo da resolução nativa e a pixel art perde definição. Se for preciso mais campo de visão, o caminho é gerar sprites menores, não diminuir mais o zoom.

Nota sobre nitidez: com `stretch/mode = canvas_items`, a escala total é `camera_zoom x (altura_da_janela / 720)`. Em 1920 x 1080 isso dá 1,5x em zoom 1.0 — escala não inteira, então alguns pixels da arte saem com o dobro da largura de outros. É sutil e o custo foi aceito em troca da área de jogo.

`stretch/scale_mode = integer` foi testado e **descartado**: em 1920 x 1080 ele reduz o render para 1280 x 720 e letterboxa a janela, em vez de mostrar mais mundo.

### Y-sort: resolvido

Sprites altos em top-down precisam ordenar por Y, para que quem está mais abaixo
desenhe na frente. Ficou pendente durante a FASE 1 e foi resolvido junto com a
FASE 2, quando passou a haver mais de uma entidade em cena.

São três propriedades em `game.tscn`, nenhuma linha de código:

| Nó | Propriedade | Por quê |
|---|---|---|
| `Game` | `y_sort_enabled = true` | ordena os filhos pela coordenada Y |
| `EnemyContainer` | `y_sort_enabled = true` | faz os inimigos entrarem na **mesma** ordenação do Player, em vez de serem desenhados como um bloco |
| `World` | `z_index = -1` | tira o cenário da ordenação e o põe numa camada abaixo |

O `z_index` é o que evita o problema previsto na FASE 1: o chão tem origem em
y=0, então participar da ordenação faria o Player sumir atrás dele ao andar para
cima. Z-index tem precedência sobre o Y-sort, então o cenário desenha antes de
tudo, sempre. É a "camada própria abaixo das entidades" que estava planejada,
sem precisar reorganizar a árvore da cena.

Funciona porque a **origem de `Player` e `Enemy` fica nos pés**: a ordenação usa
a posição do nó, e o que interessa em top-down é quem está mais à frente no
chão, não quem tem a cabeça mais alta.

Verificado com render: um diabrete acima do druida desaparece atrás dele, um
diabrete abaixo desenha na frente, e o chão continua embaixo mesmo com o Player
em y = -600. `tests/test_phase2.gd` guarda as três propriedades — mas só a
configuração: `--headless` não desenha, e a Godot não expõe consulta de ordem de
desenho.

# Combate (FASE 2)

## Componentes

Ficam em `scripts/components/`, sem conhecer Player, Enemy, arte ou física:

| Componente | Arquivo | Papel |
|---|---|---|
| `HealthComponent` | `health_component.gd` | vida, dano, cura, sinal de morte |
| `HitboxComponent` | `hitbox_component.gd` | **causa** dano |
| `HurtboxComponent` | `hurtbox_component.gd` | **recebe** dano |

Fluxo, conforme `docs/03_SYSTEMS.md` §4:

```text
Hitbox  ->  Hurtbox  ->  HealthComponent  ->  died
```

## Quem procura quem

Registrado em **DEC-017**: a hitbox detecta, a hurtbox só espera ser detectada
(`monitoring = false`, `collision_mask = 0`). Com centenas de inimigos, o custo
tem de ficar no atacante, que é sempre em menor número.

Duas consequências práticas:

- **nenhum `Timer` por entidade** — o intervalo entre golpes é delta acumulado;
- **`_physics_process` da hitbox fica desligado** enquanto não há nada
  sobreposto. Um diabrete atravessando o mapa não custa nada; só quem está
  encostando processa.

## Morte uma única vez

O guarda fica no `HealthComponent`, não em cada entidade: depois que a vida
chega a zero, `damage()` e `heal()` não têm mais efeito e `died` não é
reemitido. Dois golpes letais no mesmo frame matam uma vez só — o que evita XP
dobrado e `queue_free()` duplo quando as armas existirem.

`Enemy._on_health_died()` desliga a física, tira a hurtbox do radar, emite
`died` (gancho pronto para XP e efeito de morte) e chama `queue_free()`.

`Player._on_health_died()` **não** remove o nó: para de andar, sai do radar das
hitboxes e emite `died`. Game over, tela de resultado e restart são da FASE 9.

## Inicialização da vida

`HealthComponent` preenche `current_health` de forma preguiçosa, na primeira
vez que é usado ou quando entra na árvore — não só em `_ready()`. Motivo: um
componente criado por `new()` e usado antes de entrar na cena (como em teste)
ficaria com 0 de vida. O comportamento em cena não muda.

## Números provisórios

| O quê | Valor |
|---|---|
| vida do Player | 100 |
| vida do diabrete | 30 |
| dano por contato do diabrete | 10 |
| intervalo entre golpes | 1,0 s |

Todos provisórios até o sistema de Stats, na FASE 6. Na prática: quatro
diabretes encostados matam o druida parado em cerca de 2 s.

# Morte, game over e raio

Arte nova, em estado **CANDIDATE**. Os três arquivos tinham a mesma franja verde
de chroma key das sprites anteriores, e foram limpos. Como os três têm verde
**legítimo** (manto do druida, folhas do game over), aplicou-se só a remoção da
franja, sem despill — ver `docs/ASSET_WORKFLOW.md`.

Os originais estão em `assets/_raw/`, com `.gdignore`. O `gameover.png` e o
`raiopronto.png` saíram da raiz de `assets/` para `assets/ui/` e
`assets/effects/`, seguindo a estrutura de `docs/02_ARCHITECTURE.md`; o raio foi
renomeado para `raio.png`.

## Morte do druida

27 frames, entram no `SpriteFrames` do druida como `death_south`, com
**`loop = false`** — a animação acontece e acaba.

A costura respeita o contrato de DEC-013 ponta a ponta:

```text
Health.died -> Player.died -> Visual.play_death()
                                   |
                          (animação toca uma vez)
                                   |
        Visual.death_animation_finished -> Player.death_finished -> Game
```

`player.gd` **não** sabe que existe animação de morte, quantos frames ela tem ou
quanto dura. Ele avisa que morreu e é avisado de que a apresentação acabou. Se
um dia a morte virar um shader, uma partícula ou nada, nada muda na lógica.

### Refeita a partir de vídeo

A primeira arte de morte foi substituída: a atual saiu de um vídeo de 10 s em
chroma verde, virou **36 quadros de 96 x 160** e toca em 2,4 s a 15 fps.

O quadro é maior que o da caminhada (64 x 96) porque o cajado sobe bem acima da
cabeça e, no fim, cai deitado no chão — em 64 x 96 ele sairia cortado. Os pés
ficam na linha **136**, com 24 px sobrando embaixo para o cajado caído.

`death_scale` voltou para **1.0**: a folha foi gerada já com o corpo em 70 px,
igual ao da caminhada. O `_apply_death_transform` passou a tirar a meia-altura do
próprio quadro em vez de assumir 48, senão a morte pularia para cima ao começar.

O processo completo está em `docs/ASSET_WORKFLOW.md`, seção "De vídeo para
sprite sheet". A folha anterior e o vídeo estão em `assets/_raw/`.

### Escala: o erro que a caixa esconde



Medida contra a caminhada, no mesmo quadro de 64 x 96:

| | caminhada | morte |
|---|---|---|
| altura da silhueta | 87 px | **63 px** |
| linha dos pés | 95 (a base do quadro) | **79** |

Ou seja: ao morrer, o druida encolhia para 72% do tamanho e ainda flutuava 16 px
acima do chão.

Isso valeu para a **arte anterior**, e a lição continua valendo para a próxima
que chegar: **calibrar escala pela caixa do sprite engana**. O bbox da caminhada
inclui o cajado subindo acima da cabeça, e usá-lo dava fator 1,38 quando o certo
era 1,56. Três medidas independentes concordavam no valor certo — altura do corpo
(70 contra 45), largura máxima (52 contra 35) e raiz da área opaca (3515 contra
1433); só a caixa discordava.

A correção mora na camada visual (`death_scale`, `death_feet_row`), nunca na
arte: reamostrar pixel art estraga o desenho de forma permanente, e uma
transformação em runtime é reversível.

Só existe arte de morte virada para o **sul**. Morrer virado para outro lado cai
nela pela mesma cadeia de fallback das outras animações — pose certa na direção
errada é melhor que pose nenhuma. Sem nenhuma arte de morte, o sinal de fim é
emitido na hora e a partida segue.

## Game over

`Sprite2D` em `game.tscn`, invisível até a hora, com `z_index = 100` para ficar
acima de tudo e fora da ordenação por Y.

Escala **0,28**: a arte tem 1448 x 1086 e em tamanho original ocuparia mais que a
tela inteira. Assim ela fica com 405 x 304 unidades de mundo, cerca de um terço
da largura visível — grande o bastante para ser o assunto da tela, pequena o
bastante para ainda dar para ver onde o druida caiu.

Aparece **em coordenada de mundo**, centrada onde o druida caiu (com 48 px de
sobe para ficar sobre o corpo, não sobre os pés), não numa `CanvasLayer`: a
ideia é marcar o ponto da morte, e a câmera já está parada ali junto com o corpo.

Ao aparecer, `game.gd` desliga o `SpawnManager` e o raio — "interromper spawn" e
"interromper gameplay" do `docs/03_SYSTEMS.md` §16.

## Reiniciar

Botão `REINICIAR` na `CanvasLayer`, invisível até a morte, que aparece junto com
a imagem e já nasce com o foco — dá para acionar no teclado, sem mouse.

Fica em coordenada de **tela**, não de mundo: um botão no mundo sairia de vista
se a câmera se mexesse, e o alvo de clique dependeria do zoom.

`get_tree().reload_current_scene()` recria `game.tscn` inteira: druida com vida
cheia, nenhum inimigo, spawn zerado. Serve enquanto não há nada a preservar
entre partidas — meta-progressão é FASE 13.

**Isto ainda não é a tela de game over.** Falta tempo de partida, level
alcançado e voltar ao menu, que são da FASE 9, com o `GameManager` e o estado
`GAME_OVER`. O que existe hoje é a imagem aparecendo na hora certa, no lugar
certo, e um caminho de volta para o jogo.

## Raio

| O quê | Caminho |
|---|---|
| Efeito | `res://scenes/effects/lightning_strike.tscn` |
| Script do efeito | `res://scripts/effects/lightning_strike.gd` |
| Disparo (provisório) | `res://scripts/effects/lightning_caster.gd`, nó `RaioTeste` |

8 frames de 256 x 264, sem loop. A **origem do nó é o ponto de impacto**, no
chão: a sprite é deslocada 132 px para cima para que a explosão da base caia na
origem. Assim, mandar o raio para a posição de um inimigo faz ele cair em cima
do inimigo, sem conta nenhuma do lado de quem dispara.

A hitbox só liga no **frame 4**, quando o raio encosta no chão. Antes disso é
nuvem se formando, e dar dano ali pareceria injusto. Terminada a animação, o nó
se libera: efeito não pode virar nó eterno.

### Golpe único no `HitboxComponent`

O raio estreou um modo novo: **`hit_interval = 0` significa um golpe por alvo**.
Cada hurtbox leva dano uma vez só, por mais que continue dentro da área.

É o modo que projétil, explosão e área vão usar na FASE 4 — e era a dúvida
registrada aqui como pendência da fase. Ficou resolvida: o componente atende os
dois casos, sem duplicar código e sem `if` espalhado por quem usa.

### O disparo é andaime

`RaioTeste` fica em `game.tscn`, **fora do Player**. Ele escolhe o inimigo mais
próximo dentro de 640 px e joga um raio em cima, a cada 1,5 s.

Colocar isso dentro do Player seria exatamente o acoplamento que a DEC-009
proíbe, e sair dele depois custaria mais do que escrever certo agora. Quando o
`WeaponManager` existir, este nó some e a arma vira dado em `Resource`
(DEC-010).

A varredura de inimigos acontece **só no instante do disparo** — 40 varreduras
por minuto, não 3600. Guardar o alvo entre disparos não serviria: o mais próximo
muda o tempo todo, e ele pode ter morrido.

Números provisórios: 30 de dano (mata um diabrete de uma vez), raio de 40 px de
área, 1,5 s de intervalo, 640 px de alcance.

# Mapa (arte, não fase do ROADMAP)

O `TestWorld` continua sendo **protótipo** — não é o mapa definitivo e não avança
o ROADMAP. O que mudou é que ele deixou de ser um retângulo liso desenhado em
código. Detalhes da arquitetura em **DEC-020**.

## Chão

| O quê | Onde |
|---|---|
| TileSet | `assets/environment/forest_tileset.tres` |
| Atlas | `tileset-terra.png` e `tileset-agua.png`, 4x4 de 64 px |
| Camada | `Ground`, `TileMapLayer` dentro de `test_world.tscn` |

As duas folhas que chegaram são **conjuntos de cantos completos**: as 16
combinações de terreno nos quatro cantos da célula, uma peça para cada, sem
faltar nem repetir. Isso foi descoberto medindo canto a canto, não presumido —
e é o que permite transição sem emenda.

O `TileSet` declara os terrenos (0 Terra, 1 Mata, 2 Água, modo cantos), então
**o pincel de terreno do editor autotila sozinho**. O preenchimento automático
só roda se o `Ground` estiver vazio: a primeira célula pintada à mão desliga ele.

Mapa de 48 x 48 células, com moldura de mata fechada de 2 células nas bordas.
As peças uniformes — terra limpa e mata fechada, que cobrem a maior área — são
espelhadas por célula, senão o padrãozinho de pedras aparece em xadrez.

**O que este conjunto não faz:** não há transição direta de terra para água. Cada
folha cobre um par de terrenos (terra↔mata numa, mata↔água na outra). Pintar água
encostando em terra não acha peça; ponha uma faixa de mata entre as duas.

## Bordas

Oito peças de vegetação — 4 verticais de ~88 x 192 e 4 horizontais de ~123 x 182 —
distribuídas em ~100 `Sprite2D` ao longo das quatro bordas, alternando variações
e espelhando metade delas.

São sprites, não tiles: os tamanhos não cabem na grade de 64 e recortá-las
quebraria a continuação das trepadeiras.

Duas coisas que custaram medição:

- **cada peça avança pela própria largura**, menos 12 px de sobreposição. As
  peças têm tamanhos diferentes (123, 123, 123 e 120; 192, 191, 190 e 192), e
  avançar por um valor fixo abria fresta que ia acumulando ao longo da borda;
- **tom escurecido** por `modulate` (0.48, 0.51, 0.57). A arte veio bem mais
  clara que o chão — média (63, 61, 7) contra (27, 32, 20) da mata fechada — e
  sem isso brilhava como se estivesse colada por cima do mapa.

O contorno verde que o protótipo desenhava em volta do mundo só aparece agora
**quando não há tiles**, junto com o chão liso. Com o mapa em tiles ele virava um
risco atravessando a mata.

## Objetos de cenário

Oito peças em `assets/environment/prop-*.png`, espalhadas em ~63 instâncias.

| Sólidos (colisão) | Atravessáveis |
|---|---|
| toco, tronco caído, pedra rúnica, rocha, espinheiro | samambaia, capim, cogumelos |

Escala variável **por tipo**: mato de 0,55 a 1,20, pedra e toco de 0,80 a 1,25 —
pedra pequena demais deixa de parecer pedra. Metade nasce espelhada, menos a
pedra rúnica, cuja runa ficaria ao contrário.

35% dos sorteios viram agrupamento de 2 a 4 peças, que é o que cria obstáculo em
vez de enfeite espalhado.

**Reserva de espaço:** cada peça registra posição e raio, e nada nasce dentro do
espaço de ninguém — duas árvores não crescem no mesmo lugar. Medido no mapa
gerado: zero pares sólido-com-sólido invadindo espaço.

## Ordem de desenho

Reorganizada para os props funcionarem:

| Nó | Configuração | Por quê |
|---|---|---|
| `Game`, `World`, `TestWorld`, `Props`, `Borda` | `y_sort_enabled` | o druida passa **atrás** do toco, e o toco cobre quem está atrás dele |
| `Ground` (`TileMapLayer`) | `z_index = -1` | tira o chão da ordenação: ele tem origem em y=0 e engoliria quem andasse para cima |

Antes o `World` inteiro tinha `z_index = -1`, o que jogava tudo dele para baixo
das entidades. A borda precisou de ordenação própria pelo mesmo motivo: sem ela,
ordenaria pela posição do nó pai, em (0,0), e engoliria o Player perto da parede
de cima.

# Estado da partida (FASE 9)

| O quê | Caminho |
|---|---|
| Estado | `res://scripts/systems/game_manager.gd`, nó `GameManager` |
| Pausa | `res://scenes/ui/pause_menu.tscn` |
| Resultado | `res://scenes/ui/result_screen.tscn` |
| Botão compartilhado | `res://scripts/ui/placa_ui.gd` |

## O problema que a fase resolveu

O estado da partida morava em **quatro lugares que precisavam concordar
sozinhos**: `_running` na raiz, e um `enabled` no `SpawnManager`, no
`WaveManager` e no `WeaponManager`. Nada garantia que concordassem, e cada tela
nova teria de lembrar de mexer nos quatro.

Agora há um estado só. Ligar e desligar sistema virou **consequência da
transição**, não responsabilidade de quem a provocou.

```text
JOGANDO ──┬─ opened ──→ ESCOLHENDO ── closed ──→ JOGANDO
          ├─ pause  ──→ PAUSADO    ── pause  ──→ JOGANDO
          ├─ morte  ──→ DERROTA
          └─ boss   ──→ VITORIA
```

## Duas coisas deixaram de existir

A tela de escolha **não pausa mais sozinha**: emite `opened` e `closed`, e o
manager decide o que isso significa. Dois lugares mexendo em
`get_tree().paused` foi o que esta fase veio desfazer.

A imagem de game over solta no mundo e o botão avulso na `CanvasLayer` saíram. A
tela de resultado mostra tempo e nível, como a §16 pede, e serve também à
vitória (§17) — o que muda entre os dois desfechos é o título e a cor. Duas
cenas quase iguais divergiriam na primeira mexida.

## A palavra de fim: duas peças, uma escala

As duas frases — `titulo_floresta_caiu.png` e `titulo_floresta_resistiu.png` —
vieram da mesma sessão de geração, com o mesmo canvas e o mesmo corpo de letra.
Por isso os recortes saíram com a **mesma largura**, 1152 px, e alturas
diferentes: 559 na derrota, 531 na vitória, porque as partículas de cinza
esticam a peça de baixo.

Daí a construção do `TituloArte`: um slot de 385x187 com aspecto preservado.
Como as duas têm a mesma largura, as duas ficam limitadas pela largura e caem
na mesma escala, 0,3342. Encaixar por **altura** — o reflexo — daria escalas
diferentes e a letra mudaria de tamanho entre um desfecho e outro.

A caixa da tela **não é centrada no painel**, porque o interior do painel não
é: medido em `assets/ui/painel_escolha.png`, a borda de cima ocupa 0,227 da
altura e a de baixo 0,119. Centrada, a palavra encavalava a pedra — foi o que
a primeira captura mostrou.

## A vitória é uma conexão, não um sistema

O `WaveManager` já entregava o nó do boss em `boss_spawned`, e o
`HealthComponent` dele já emitia `died` desde a FASE 2. O manager só liga um no
outro.

## Por que `configure()` não liga nada

Ele conecta os sinais e destrava a árvore, mas **não força os sistemas a
ligados**. Quem já estava desligado de propósito — a suíte da FASE 3 mede a
rampa do spawn com as waves fora — deve continuar desligado. A primeira versão
forçava, e a FASE 3 quebrou na hora.

## O que `tests/test_phase9.gd` cobre

Estrutura: os três nós existem, as telas nascem escondidas, as quatro camadas
não se atropelam, e tudo que age com a árvore parada tem `process_mode` ALWAYS
— sem isso os botões não recebem clique e a partida trava de vez.

Comportamento: pausar para **a árvore, o spawn, as waves e o relógio**; retomar
religa os quatro; e o boss morrendo dá vitória, com o fim anunciado **uma única
vez** e o tempo aparecendo na tela.

O teste não checa "a tela apareceu". Checa que o estado manda nos sistemas —
uma tela que aparecesse com o spawn ainda correndo passaria num teste de
visibilidade e falha neste.

## Verificação de que a FASE 9 não passa vazia

Cinco erros injetados, os cinco pegos: pausa sem desligar o spawn, relógio
andando na pausa, vitória anunciada duas vezes, tela de pausa sem
`process_mode` ALWAYS, e o level up voltando a pausar por conta própria.

## Três suítes antigas tiveram de mudar

As três acusaram mudança real, não ruído:

1. **FASE 0** cobrava um nó `CanvasLayer` em `game.tscn` — o que existia só para
   segurar o botão de reiniciar. Passou a cobrar `PauseMenu` e `ResultScreen`;
2. **FASE 2** cobrava o `Sprite2D` de game over e o botão avulso. Passou a
   cobrar que a morte leve a **alguma** tela e que o estado vá para `DERROTA`.
   E o último caso dela — o inimigo sem alvo — precisou despausar antes, porque
   a derrota agora para a árvore inteira e o inimigo parado não decide nada;
3. **FASE 5** conferia a despausa no mesmo quadro em que a tela fecha. O manager
   mexe no estado da árvore **adiado**, pelo mesmo motivo do orbe de XP, então o
   teste ganhou um estágio só para observar isso um quadro depois.

# Tela de level up com arte

| O quê | Caminho |
|---|---|
| Ícones | `tools/preparar_icones_ui.py` → `assets/ui/icones/` |
| Painel e placas | `tools/preparar_painel_ui.py` → `assets/ui/` |
| Tela | `res://scenes/ui/level_up_menu.tscn` |

## A moldura comum é o que faz os nove lerem como conjunto

Sem ela, um escudo de casca marrom e um corvo etéreo não parecem do mesmo jogo.
Gema marca arma, folha marca passiva.

As duas molduras chegaram com **alfa de verdade em vez de fundo magenta**, e com
a janela interna em `813x781` na posição `(221,224)` — **idêntica nas duas, ao
pixel**. Isso permitiu compor os dois conjuntos com a mesma conta, sem registro
manual.

## Assunto que não é ícone

O cajado e a vinha vieram em proporção 1:2,6 e, encaixados inteiros num
quadrado, viravam um fio de 28 px. Para eles há recorte declarado em `RECORTES`,
que fica com a parte que identifica a habilidade: a coroa do cajado, o botão da
rosa. A rosa virou o **único vermelho do conjunto**, o que ajuda a achá-la de
relance.

## O layout saiu de medição, não de palpite

O miolo escuro do painel foi medido na própria arte: `1223x627` dentro de
`1374x821`. Em tela, com o painel a 1000x598, isso dá **890x456** de área útil.
Daí saem os 62 px de título — a gema do topo desce para dentro do miolo, e o
rótulo escreve na base do espaço para passar por baixo dela — e as linhas de
`704x118`, que é a proporção exata da placa desenhada.

Deixar o container esticar a linha até a largura toda deformaria as pedras das
pontas. Por isso o tamanho é fixo e o container encolhe em volta.

## O botão continua sendo um botão

Foco pelo teclado, `pressed`, estados. O conteúdo entra como filho, e os filhos
usam `MOUSE_FILTER_IGNORE` para o clique chegar ao botão em vez de parar no
rótulo. `hover`, `focus` e `pressed` usam a mesma placa acesa: quem navega no
teclado precisa ver onde está tanto quanto quem usa o mouse.

E a coluna do ícone existe **mesmo sem ícone**. Sem ela, uma opção ainda sem
arte empurraria o texto para a esquerda e a fileira perderia o alinhamento.

# Waves (FASE 8)

| O quê | Caminho |
|---|---|
| Tipo de inimigo | `res://scripts/enemies/enemy_data.gd`, `resources/enemies/*.tres` |
| Fase da partida | `res://scripts/systems/wave_data.gd`, `resources/waves/*.tres` |
| Tabela em funcionamento | `res://scripts/systems/wave_manager.gd`, nó em `game.tscn` |

## A divisão de trabalho

| Quem | Decide |
|---|---|
| `WaveManager` | **quem** nasce e **quando** |
| `SpawnManager` | **onde** nasce e **se cabe** |

É a divisão que a `docs/03_SYSTEMS.md` §6 e §7 já descreviam. A escolha do ponto
continua no `SpawnManager` porque é lá que se conhece a câmera e as paredes; o
teto de população vem da wave, mas quem conta os vivos é o `SpawnManager`, com
`get_child_count()` — O(1) (DEC-011).

## A rampa antiga não foi apagada

O `SpawnManager` mantém a rampa linear como **modo sem waves**, e ela se cala
enquanto a tabela manda (`driven_by_waves`). Serve para uma cena de teste, e é o
que a suíte da FASE 3 mede — aquela suíte é sobre o spawn, não sobre a tabela.

Desligar o `WaveManager` **devolve** a rampa em vez de calar os dois. Sem isso,
um wave desligado deixaria a partida sem inimigo nenhum, que é pior que qualquer
um dos dois mandando sozinho.

## Os tipos se distinguem por número enquanto não há arte

Cinco `EnemyData`: imp, cão, bruto, elite e o boss Guardião Profanado. Como só
existe a arte do diabrete, eles diferem em vida, dano, velocidade, XP, escala do
`Visual`, raio de corpo e **tinta**.

Isso é PLACEHOLDER declarado (DEC-013): quando a arte de cada um chegar, `scene`
deixa de ser nula e `tint` volta a branco, sem tocar em código. A escala é só da
arte; colisão se ajusta por `body_radius`, porque colisão é dado de gameplay e
não consequência do sprite (`docs/ASSET_WORKFLOW.md`, regra 7).

## A armadilha do sub-recurso compartilhado

`Enemy.apply_data()` **duplica a forma de colisão antes de mexer no raio**.

As `CircleShape2D` moram como sub-recurso de `enemy.tscn`, e sub-recurso é
compartilhado entre todas as instâncias da cena. Engordar o boss sem duplicar
engordaria **todo diabrete em tela**, silenciosamente. O teste da fase confere
os dois lados: o raio do boss foi aplicado, e o raio do imp continua pequeno.

## O elite larga mais sem que ninguém saiba o que é um elite

`PickupSpawner` lê `xp_value` do próprio inimigo, com o `@export` do nó como
valor de reserva para quem não declara. O elite larga 12 vezes o do imp porque
o `.tres` dele diz isso — não porque exista um `if elite` em lugar nenhum.

## O que `tests/test_phase8.gd` cobre

Tipos: cada `.tres` é válido, os ids não repetem, **as vidas não repetem** — três
arquivos com os mesmos números não seriam três inimigos —, e o elite e o boss
justificam o nome (elite acima de 3× o comum em vida e XP, boss acima de 3× o
elite).

Tabela: a primeira wave começa em 0 s, duas waves não começam no mesmo instante,
o teto de população cresce ao longo da partida, nenhuma wave passa dos 200
medidos, e exatamente uma wave tem boss.

Progressão isolada: `configure()` ordena a tabela mesmo recebendo-a ao contrário,
assume o ritmo do `SpawnManager`, e um salto de 300 s cai na wave certa — o
percurso da tabela existe porque somar um perderia uma wave num salto grande.

Em partida: a primeira wave só produz imp, e a vida e o XP do tipo chegam ao
inimigo; um salto para 430 s traz o boss **uma vez**, com a vida e o raio dele,
sem engordar os imps.

## Verificação de que a FASE 8 não passa vazia

Cinco erros injetados. **Um passou**, pelo mesmo motivo já visto na FASE 6: não
era bug. O boss só nasce na virada de wave, então a guarda de `_bosses_criados`
protege uma reentrada que o fluxo normal nunca provoca — o teste não tinha como
distinguir. Passou a **forçar a reentrada**, e agora remover a guarda falha.

Os outros quatro foram pegos de primeira: progressão somando um em vez de
percorrer a tabela, forma de colisão redimensionada sem duplicar, tipo não
chegando ao inimigo, e elite com vida de inimigo comum.

# Famílias de arma (FASE 7)

| Família | Script | Armas |
|---|---|---|
| golpe | `res://scripts/effects/ability_effect.gd` | Cajado Tempestade, Vinha Espinhosa |
| projétil | `res://scripts/effects/projectile_effect.gd` | Corvo Espiritual |
| zona | `res://scripts/effects/zone_effect.gd` | Anel de Esporos |
| orbital | `res://scripts/effects/orbit_effect.gd` | Vagalumes Guardiões |

## O que separa uma família da outra

**Como o ataque termina.** É a única diferença que não cabe num campo:

- o golpe morre quando a animação acaba;
- o projétil morre ao atravessar N inimigos **ou** ao esgotar o tempo de voo;
- a zona morre quando a duração acaba, e enquanto vive bate repetido;
- o orbital morre pela duração também, mas acompanha o druida enquanto existe.

Empilhar as quatro regras num script só faria cada uma carregar a condição das
outras três. Por isso são scripts diferentes — e por isso a arma continua sendo
só um `.tres`: quem escolhe a família é o `effect_scene`, que já era um campo.

## Campos opcionais, e por quê

`WeaponData` ganhou `projectile_speed`, `projectile_pierce` e `effect_duration`.
Nos três, **zero quer dizer "usa o valor da cena"**, e não zero.

Sem isso, acrescentar velocidade de voo obrigaria o raio e a vinha — que não
voam — a preencher um número que não lhes diz respeito, e cada família nova
somaria campos mortos a todas as armas já escritas.

## O orbital é temporário de propósito

Ele nasce no cooldown da arma, gira por alguns segundos e some — não fica para
sempre. Não é limitação: é o que permite a família caber no mesmo modelo das
outras três (arma dispara, efeito vive, efeito morre) em vez de exigir um
segundo modelo só para ela.

Ele acompanha o druida por coordenada de mundo, não sendo filho dele. Ser filho
resolveria o acompanhamento de graça, mas colocaria um ataque dentro do Player
— e o Player não conhece arma nem efeito (`docs/02_ARCHITECTURE.md`).

## O pareamento do roadmap ficou para trás

`docs/ROADMAP.md` listava *Cajado — projétil, Espinhos — AoE, Corvo — orbital*.
Essa lista é anterior à FASE 4, e a FASE 4 decidiu outra coisa: o cajado virou
raio que cai sobre o alvo, a vinha virou golpe que brota do chão (DEC-021,
DEC-022). Os dois ficaram na mesma família.

Respeitar o pareamento antigo significaria refazer duas armas já aprovadas em
jogo. Em vez disso entraram armas novas para as famílias que faltavam, e a
orbital — única da lista sem representante — foi construída. São quatro
famílias onde o roadmap pedia três.

## Três stats ganharam leitor

`PROJECTILE_SPEED`, `DURATION` e `AMOUNT` estavam declarados desde a FASE 6 sem
ninguém perguntar por eles. Agora a arma pergunta: velocidade de voo, duração da
zona e do orbital, e quantos alvos um disparo atende.

## O que `tests/test_phase7.gd` cobre

Estrutura: cada arma aponta o script de família certo, existem quatro famílias
distintas, e toda hitbox de cena traz o dano-marcador 1.0 — se sair 1 de dano em
jogo, alguém esqueceu de chamar `set_damage()`.

A zona é a única com `hit_interval` maior que zero; golpe e projétil batem uma
vez por alvo. No projétil isso é o que faz a perfuração contar direito — sem
isso o mesmo inimigo gastaria todas as perfurações sozinho.

Isolado: o projétil anda 30 px em 0,3 s a 100 px/s e some ao esgotar o voo; o
orbital nasce sobre quem acompanha, espalha três orbes no raio certo, vai junto
quando o druida anda, gira, e some na duração.

Em partida: o corvo cria projétil, ele se desloca, e a cena esvazia sozinha.

## Verificação de que a FASE 7 não passa vazia

Oito erros injetados, **os oito pegos de primeira**: projétil parado, projétil
sem prazo de validade, zona que não some, zona com golpe único, corvo apontando
para a cena do raio, orbital que não acompanha, orbes empilhados no centro e
`set_damage()` alcançando só o primeiro orbe.

Duas armadilhas velhas reapareceram durante o desenvolvimento, e valem registro
porque foram erros **do teste**, não do código:

1. **`_ready` não dispara** em nó acrescentado de dentro de
   `SceneTree._initialize()` — quarta aparição. O `OrbitEffect` posicionava os
   orbes no `_ready`, e o teste via os três empilhados na origem. Virou
   inicialização preguiçosa, como no `HealthComponent`, na `PickupArea` e no
   `Hud`;
2. **medir no mesmo quadro em que se anota** não mede nada. A primeira versão
   anotava a posição do projétil e comparava na linha seguinte: a distância era
   zero por construção, e o teste não tinha como falhar nem como passar por
   mérito. Passou a comparar seis quadros depois.

# Catálogo de upgrades (FASE 6)

| O quê | Caminho |
|---|---|
| Opção | `res://scripts/upgrades/upgrade_data.gd` |
| Catálogo | `res://scripts/systems/upgrade_pool.gd`, nó `UpgradePool` em `game.tscn` |
| Conteúdo | `res://resources/upgrades/*.tres` |
| Tela | `res://scripts/ui/level_up_menu.gd` |

## Quem decide o quê

```text
LevelComponent.leveled_up
        |
   LevelUpMenu pede a lista       ->  UpgradePool.sortear()
        |                                    |
   desenha os botões              aplicáveis, sem repetir na tela
        |
   devolve o id escolhido         ->  UpgradePool.apply()
                                             |
                              StatComponent  ou  WeaponManager
```

A tela não sabe o que é uma passiva. O catálogo não sabe desenhar. A separação
existe porque os dois mudam por motivos diferentes: a regra do que é oferecível
muda quando entra conteúdo, o desenho muda quando entra arte.

## Uma passiva é um stat mais um número

`UpgradeData` tem `stat`, `flat`, `mult` e `max_stacks`. Nada além disso — e é
proposital: se alguma passiva precisar de campo próprio, virou caso especial, e
era exatamente isso que o `StatComponent` existia para evitar.

Armas convivem na mesma lista, com `kind = ARMA` e um `WeaponData` apontado.
Escolher uma arma que já está equipada sobe o nível dela, porque
`WeaponManager.add_weapon()` já fazia isso desde a FASE 4.

## O que "opção impossível" quer dizer (§13)

| Caso | Regra |
|---|---|
| passiva no teto | `stacks < max_stacks` |
| arma equipada | `level < max_level` |
| arma nova | há slot livre |

E o sorteio tira sem reposição: a mesma opção não aparece duas vezes na mesma
tela — isso gastaria uma das três escolhas sem dar alternativa.

O sorteio é uniforme. Raridade e peso são conteúdo, não estrutura, e entram como
campo do `UpgradeData` quando houver opções suficientes para isso importar.

## Onde cada passiva bate

| Passiva | Stat | Quem lê |
|---|---|---|
| Casca de Carvalho | `MAX_HEALTH` | `Player._aplicar_stats()` |
| Passos do Cervo | `MOVE_SPEED` | `Player._aplicar_stats()` |
| Essência Viva | `PICKUP_RADIUS` | `Player._aplicar_stats()` |
| Semente Ancestral | `AREA` | `Weapon.area_efetiva()` |
| Ciclo Lunar | `COOLDOWN` | `Weapon.cooldown_efetivo()` |
| Coração Verde | `REGEN` | `HealthComponent._process()` |

A arma lê **a cada disparo**, não guarda. É o que faz uma passiva escolhida no
meio da partida valer no tiro seguinte, sem ninguém precisar avisar a arma de
nada.

Área vira **escala do nó do efeito**. A hitbox é filha dele, então cresce junto
com o desenho e a cena do golpe não precisa saber que existe passiva. Escala
uniforme e positiva de propósito: negativa inverteria a colisão, e a Godot
reclama de forma com escala negativa.

`REGEN` não está entre os nove stats da §14 — entrou porque o Coração Verde
precisa dela. Foi acrescentada **no fim do enum**: os `.tres` guardam o stat
como número, e inserir no meio remapearia silenciosamente as passivas já
escritas.

O tique de regeneração fica desligado enquanto `regeneration` for zero, o que
importa porque todo inimigo tem um `HealthComponent` e nenhum regenera — sem
isso seriam duzentos `_process` inúteis numa horda cheia. E cura em passos de
**1 de vida**, guardando a sobra: curar 0,008 por quadro emitiria
`health_changed` sessenta vezes por segundo para um ganho invisível.

## Um teste da FASE 5 teve de mudar

`tests/test_phase5.gd` afirmava que, **com todas as armas no teto**, a tela não
abre. Isso era verdade quando armas eram a única opção que existia. Com passivas
no catálogo deixou de ser, e o teste passou a falhar — corretamente.

A regra sob teste continua a mesma, mas a condição virou a de verdade: esgotar o
**catálogo inteiro**. É a fase seguinte corrigindo uma premissa da anterior, e o
teste antigo cumpriu o papel dele ao acusar a mudança.

# Stats (FASE 6, primeiro item)

| O quê | Caminho |
|---|---|
| Componente | `res://scripts/components/stat_component.gd`, nó `Stats` no Player |
| Quem aplica | `res://scripts/player/player.gd`, `_aplicar_stats()` |

## A conta

```text
efetivo = (base + plano) * (1 + percentual)
```

O plano soma antes, o percentual multiplica depois. É a ordem que faz "+20 de
vida" e "+10% de vida" se comportarem como o jogador espera com as duas
equipadas. Percentuais **somam entre si**: +10% e +10% dão +20%, não +21% — é a
regra do gênero e a única que o jogador consegue prever de cabeça olhando a tela
de escolha.

Um stat multiplicador — dano, cooldown, área — é só um stat cuja base é 1.0.
Não precisou de tratamento próprio.

## O componente não guarda as bases

A velocidade base continua em `Player.move_speed`, a vida base em
`HealthComponent.max_health`, o alcance no raio da forma da `PickupArea`. Cada
um desses valores já estava documentado e ajustado onde vive; copiá-los para o
`StatComponent` criaria duas fontes de verdade, e "qual das duas vale?" não tem
resposta boa.

Quem guarda base é o **Player**, e só as que ele precisa reescrever: aplicar um
stat **escreve por cima** do valor do componente, então se
`HealthComponent.max_health` virasse a base da conta seguinte, cada recálculo
somaria em composto. Duas passivas de +50 dariam +150.

## Piso no fator percentual

`_FATOR_MINIMO := 0.05`. Sem ele, redução de cooldown somando -100% zeraria o
intervalo entre ataques e a arma dispararia todo frame; -120% deixaria o
cooldown negativo. O piso troca um bug de travar o jogo por um teto de poder.

## Vida máxima ganha também cura

Decisão de conteúdo, não de arquitetura, e mora no aplicador do Player: sem ela
a passiva de vida só levantaria o teto e o jogador não sentiria nada no momento
em que escolheu — o efeito apareceria minutos depois.

## O que `tests/test_phase6.gd` cobre

A conta isolada, sem cena: base pura, plano, ordem entre plano e percentual,
percentuais somando entre si, bônus zerado não sendo bônus, um stat não sujando
o outro, e o piso segurando uma redução de -300%.

O sinal: `stat_changed` sai uma vez por mudança real, com o stat certo.

No Player montado: sem passiva nada muda de valor; com passiva, velocidade, vida
máxima e raio de coleta obedecem; ganhar vida máxima cura o mesmo tanto; e dois
bônus de +50 dão base+100, não base+150.

A velocidade é lida por `Player.get_move_speed()`, não recalculada dentro do
teste — refazer a conta ali provaria só que o `StatComponent` sabe multiplicar,
não que o Player chegou a perguntar.

## Verificação de que a FASE 6 não passa vazia

Seis erros injetados e revertidos, **todos pegos de primeira**: percentual
multiplicando antes do plano somar, percentuais compondo em vez de somando,
piso removido, base relida a cada recálculo, Player sem escutar `stat_changed`,
e ganho de vida máxima sem curar.

# HUD da partida (FASE 9, adiantado)

| O quê | Caminho |
|---|---|
| Painel | `res://scenes/ui/hud.tscn`, nó `Hud` em `game.tscn` |
| Lógica | `res://scripts/ui/hud.gd` |
| Arte | `assets/ui/barra_{vida,xp}_{fundo,preenchimento}.png` |
| Preparo da arte | `tools/preparar_barras_hud.py`, a partir de `assets/_raw/` |
| Cronômetro | `_elapsed` em `res://scripts/systems/game.gd` |

## Quem sabe o quê

O HUD é apresentação e nada mais. Não lê estado a cada frame, não guarda regra e
não conhece Player, armas nem spawn: recebe `HealthComponent` e `LevelComponent`
em `configure()` e depois só reage aos sinais que os dois já emitiam desde a
FASE 0 e a FASE 5. Nenhum componente precisou mudar para o painel existir.

O cronômetro é a exceção, e de propósito: tempo decorrido é estado **de
partida**, não de HUD. Quem conta é `game.gd`, que empurra o valor por
`set_time()`. O efeito prático é que o relógio congela sozinho quando a tela de
level up pausa o jogo, sem o HUD saber o que é pausa — e quando o `GameManager`
da FASE 9 chegar, o tempo vai junto com ele e o painel continua igual.

A contagem é em `_physics_process`, não em `_process`: o passo de física é fixo,
então o relógio não depende de quantos quadros a máquina desenha e um teste sabe
exatamente quanto tempo passou depois de N passos.

## Por que a moldura e o líquido são dois arquivos

A arte chegou em dois estados por barra: vazia e cheia. Clipar a imagem cheia
inteira pela metade cortaria a **gema da ponta direita** junto com o líquido.
Então o script separa os dois: `texture_under` é a moldura completa,
`texture_progress` é só o líquido que vive dentro do vão. A moldura fica firme e
só o conteúdo recua.

## O que o preparo da arte resolveu

Os dois pares vieram em canvas diferentes e construídos de formas diferentes:

- **tamanho:** 1752x897 contra 1717x916 no XP, 1983x793 contra 2172x724 no HP. O `TextureProgressBar` desenha as duas texturas no mesmo retângulo, então tamanhos diferentes deslocariam o líquido para fora do vão;
- **o vão:** no XP ele é um buraco transparente; no HP já vem pintado de escuro. Por isso a detecção não pode ser "onde é transparente" — é pela **cor do líquido**;
- **o encaixe:** no HP a borda superior da moldura serve de referência e o erro deu 0,00 px. No XP não serve, porque o musgo da borda difere entre as duas peças e alinhar por ela deixava o verde 6 px acima do vão; ali o alinhamento é pelo próprio vão, com erro de 0,50 px. O script escolhe o critério conforme a moldura tenha ou não vão vazado;
- **franja de chroma:** 250 px ao todo, removidos com um teste estrito (verde claro, saturado, sem vermelho nem azul) para não comer o musgo, que é mais escuro e amarelado.

O tamanho de tela está baked na textura por necessidade, não por gosto — o
porquê está em **DEC-023**.

# XP e level up (FASE 5)

| O quê | Caminho |
|---|---|
| Nível e curva | `res://scripts/components/level_component.gd`, nó `Level` no Player |
| Fragmento | `res://scenes/pickups/xp_orb.tscn` |
| Coleta | `res://scripts/player/pickup_area.gd`, nó `PickupArea` no Player |
| Drop | `res://scripts/systems/pickup_spawner.gd`, nó em `game.tscn` |
| Escolha | `res://scenes/ui/level_up_menu.tscn` |

## O caminho do XP

```text
Enemy.died -> PickupSpawner -> XpOrb no chão
                                   |
                        PickupArea do Player coleta
                                   |
                   LevelComponent.add_xp -> leveled_up
                                   |
                            LevelUpMenu pausa e oferece
```

Ninguém varre nada. O `PickupSpawner` liga o `died` de cada inimigo **uma vez**,
quando ele nasce; e quem procura o fragmento é a área do Player, que é uma só,
não cada orbe — mesmo princípio da DEC-017.

## XP excedente e níveis acumulados

É o ponto que o `docs/03_SYSTEMS.md` §12 marca como IMPORTANTE, e está resolvido
em dois lugares:

- **no `LevelComponent`:** um ganho grande sobe quantos níveis couberem e guarda
  o resto. Ganhar 65 quando faltam 20 e depois 40 sobe dois níveis e deixa 5;
- **no menu:** cada nível vira uma escolha na fila. Subir três de uma vez abre a
  tela três vezes, uma escolha por vez. Sem isso, dois níveis no mesmo instante
  dariam uma escolha só e o jogador perderia o que ganhou.

Há um teto de 50 níveis por ganho, contra curva mal configurada: `xp_growth`
zerado faria o laço rodar para sempre no primeiro fragmento coletado.

## A tela só abre se tiver o que oferecer

A §13 pede "evitar opções impossíveis". Arma no nível máximo não entra na lista,
e se **nenhuma** opção sobra a tela não abre — pausar o jogo para não oferecer
nada seria pior que não pausar. Com todas as armas no teto isso é um beco sem
saída legítimo, até a FASE 6 trazer passivas.

## Um erro de física que apareceu só em execução

`Can't change this state while flushing queries`, cinco vezes por partida. O
orbe é uma `Area2D`, e ele era acrescentado à cena **dentro** da detecção de
colisão que matou o inimigo — registrar a forma de uma área durante a consulta
de física é proibido.

Resolvido com `add_child.call_deferred()`. A posição já está definida antes,
então um frame de atraso não muda nada visível.

Vale como padrão do projeto: **tudo que nasce a partir de um sinal de física
entra na cena adiado.** Já valia para `monitorable`/`monitoring` desde a FASE 3;
agora vale para o nó inteiro.

# Armas (FASE 4)

## Estrutura

| O quê | Caminho |
|---|---|
| Dados | `res://scripts/weapons/weapon_data.gd` (`WeaponData`, um `Resource`) |
| Arma em funcionamento | `res://scripts/weapons/weapon.gd` (`Weapon`) |
| Gerenciador | `res://scripts/weapons/weapon_manager.gd` (`WeaponManager`) |
| Armas existentes | `res://resources/weapons/*.tres` |
| Nó | `WeaponManager`, filho do `Player` |

O `WeaponManager` mora dentro do Player, como manda `docs/02_ARCHITECTURE.md`,
mas **não conhece arma nenhuma** (DEC-009). Quem liga tudo ao mundo é a raiz da
partida: o Player não conhece o container de inimigos nem o de efeitos, e não
deve conhecer.

Acrescentar uma arma ao jogo é criar um `.tres` (DEC-010). Nenhuma linha de
código muda.

## As duas primeiras

| | Cajado Tempestade | Vinha Espinhosa |
|---|---|---|
| dano (nível 1) | 30 | 20 |
| cooldown | 1,5 s | 1,1 s |
| alcance | 640 px | 260 px |
| posição | cai **em cima** do inimigo | **brota do chão**, num anel de 150 px em volta do druida |
| direção | não tem | **horizontal**, para o lado do alvo |
| por nível | +10 de dano, cooldown x0,88 | +6 de dano, cooldown x0,9 |
| teto | nível 5 | nível 5 |

Posição e direção são campos de `WeaponData` — `spawn_mode`, `spawn_radius` e
`aim_mode` —, não regras no código do ataque. O porquê da vinha brotar do chão e
de a mira ser só horizontal está em **DEC-022**.

São o raio e a vinha que já existiam como andaime, agora com dados e nível. O
`RaioTeste`, o `VinhaTeste`, o `lightning_caster.gd` e o `tests/test_raio.gd`
foram **apagados**.

## Decisões que ficaram no código

**Arma repetida melhora, não duplica.** Pedir de novo a mesma arma sobe o nível.
É assim que a tela de level up da FASE 5 vai funcionar, e duplicar armaria duas
cópias atirando em paralelo sem ninguém ter pedido.

**Sem alvo, o cooldown não é gasto.** Guardar o disparo para quando houver
inimigo é mais justo do que desperdiçá-lo no vazio.

**A mira varre a lista só no instante do disparo.** Com o cooldown atual são
poucas dezenas de varreduras por minuto, contra milhares se fosse por frame
(DEC-011). Guardar o alvo entre disparos não serviria: o mais próximo muda o
tempo todo, e ele pode ter morrido.

**O dano mora no `WeaponData`, não na cena do ataque.** As cenas ficaram com
`damage = 1.0` como marcador: se sair 1 de dano em jogo, alguém esqueceu de
configurar. Deixar o número certo na cena esconderia esse esquecimento, porque
coincidiria com o dano do nível 1 — foi assim que o teste começou passando por
motivo errado.

**`enabled` é estado do manager, não de cada arma.** Desligado antes de
`configure()`, continua valendo para as armas criadas depois. Sem isso, quem
desliga cedo demais não desliga nada: foi exatamente o que quebrou dois testes
quando as armas entraram, porque `Game._ready()` só roda no primeiro frame.

## Gancho para a FASE 5

`upgrade_weapon()` e `has_upgradable_weapon()` já existem. O segundo é o que
impede a tela de level up de oferecer melhoria impossível
(`docs/03_SYSTEMS.md` §13).

# Vinha (segunda habilidade, andaime)

| O quê | Caminho |
|---|---|
| Efeito | `res://scenes/effects/vine_lash.tscn` |
| Script comum | `res://scripts/effects/ability_effect.gd` (`AbilityEffect`) |
| Disparo | `resources/weapons/vinha_espinhosa.tres`, pelo `WeaponManager` |

Uma rosa brota no chão e uma vinha espinhosa chicoteia na direção do inimigo mais
próximo. 8 quadros de 240 x 88, 20 de dano, alcance 260 px, a cada 1,1 s.

`lightning_strike.gd` virou **`ability_effect.gd`**: era comportamento genérico
com nome de uma habilidade só, e com duas o nome já mentia — registrado em
**DEC-021**. Na FASE 4 o disparo saiu do andaime e virou `Weapon`.

## A arte exigiu três correções

A folha veio em **grade irregular** (larguras e espaçamentos diferentes, porque a
vinha cresce a cada frame), e cada uma das três tentativas ensinou algo:

1. **Dois botões de rosa por quadro.** A janela de recorte alcançava a rosa do
   quadro vizinho. Cada quadro passou a ser **isolado antes do recorte**.
2. **A rosa andava entre os quadros.** A âncora estava na borda esquerda da
   terra, que muda conforme o montinho cresce. Passou a ser o **botão da rosa**,
   detectado por cor.
3. **O efeito nascia longe do druida.** `AnimatedSprite2D` é **centrada por
   padrão**, e eu calculei o deslocamento como se a origem fosse o canto. O
   offset tem de sair do centro do quadro até a âncora.

Conferido depois: um botão por quadro nos oito, e dano de exatamente 20 nas seis
direções testadas com o inimigo a 130 px.

# Spawn e horda (FASE 3)

## Caminhos

| O quê | Caminho |
|---|---|
| Script | `res://scripts/systems/spawn_manager.gd` (`class_name SpawnManager`) |
| Nó | `SpawnManager`, filho de `Game` em `game.tscn` |

## Como é ligado

`game.gd` entrega ao manager o alvo, o container e os limites do mundo:

```gdscript
_spawn_manager.configure(_player, _enemy_container, bounds)
```

O manager **não** procura o Player por grupo, não procura o container por
caminho e não conhece o mapa. Mesmo padrão já usado para os limites da câmera:
quem conhece a composição é a raiz da partida.

## Onde o inimigo nasce

Sorteia um ângulo em volta do Player e coloca o inimigo à distância de
`get_spawn_distance()`, que é **meia diagonal da tela visível mais a margem** —
não uma constante.

Sai do viewport e do zoom da câmera ativa de propósito: com
`stretch/aspect = expand` (DEC-015), uma tela mais larga mostra mais mundo, e um
raio fixo faria o inimigo nascer visível em parte dos aparelhos Android.

O ponto é limitado ao mapa com folga de 64 px das paredes. Se a limitação puxar
o ponto para dentro do campo de visão — Player encurralado num canto —, o
manager tenta outros ângulos (8 por padrão) e fica com o mais distante. Cada
inimigo recebe um ponto próprio, então nunca nascem na mesma coordenada, que é
o caso degenerado descrito em "Espaçamento da horda".

## Ritmo

Rampa linear de `ramp_seconds` (5 minutos):

| | início | fim |
|---|---|---|
| intervalo entre spawns | 1,2 s | 0,2 s |
| teto de população | 40 | 200 |

Tudo exportado, tudo provisório: a tabela de waves de verdade é do
`WaveManager`, na FASE 8. O `enabled` existe para o game over da FASE 9
interromper o spawn — e é o que os testes usam para medir sem interferência.

## Custo por frame

Uma soma de delta e uma comparação. Sem `Timer`, sem busca por grupo, e a
população lida em `get_child_count()` do container, que é O(1).

# Carga: quantos diabretes cabem

Medido em execução real **com renderização**, 1280 x 720, vsync desligado, numa
RTX 2060 SUPER. Cada patamar foi criado e deixado convergir sobre o Player
parado por 5,5 s antes de medir — ou seja, com a horda **empilhada**, que é o
pior caso.

| inimigos | FPS | process | física | draw calls | nodes | memória |
|---|---|---|---|---|---|---|
| 50 | 1845 | 3,19 ms | 1,42 ms | 25 | 476 | 41,1 MB |
| 100 | 1664 | 2,96 ms | 3,58 ms | 51 | 926 | 43,0 MB |
| 200 | 1021 | 2,25 ms | **8,20 ms** | 94 | 1826 | 46,7 MB |
| 250 | 454 | 2,42 ms | 14,03 ms | 123 | 2276 | 48,7 MB |
| 300 | 66 | 2,29 ms | **19,05 ms** | 151 | 2726 | 50,5 MB |

Leitura:

1. **O gargalo é a física, não o desenho nem o script.** `process` fica em ~2 ms
   em todos os patamares; a física vai de 1,42 ms a 19 ms.
2. **O crescimento é pior que linear.** Dobrar de 100 para 200 mais que dobra o
   custo. A causa é a colisão corpo-a-corpo entre inimigos (DEC-018): empilhados
   em volta do Player, cada um resolve contato com vários vizinhos.
3. **O limite prático é ~250.** Um frame a 60 FPS tem 16,6 ms no total; com 300
   inimigos só a física já custa 19 ms e a partida entra em espiral (a Godot
   passa a rodar vários passos de física por frame, e o FPS despenca para 66).
4. **O teto de 200 do `SpawnManager` foi escolhido a partir desta medição**, não
   chutado: gasta metade do orçamento de física e deixa a outra metade para
   armas, projéteis e HUD, que ainda não existem.

Isto é PC. Android é bem mais fraco e terá de ser medido de novo na FASE 12; o
`final_population_cap` é exportado justamente para virar um número por
plataforma. Otimizar (pooling, física mais barata, separação sem corpo rígido) é
FASE 10 — e agora existe um número contra o qual comparar.

# Mundo de teste

| O quê | Caminho |
|---|---|
| Cena | `res://scenes/game/test_world.tscn` |
| Script | `res://scripts/systems/test_world.gd` (`class_name TestWorld`) |

`@export var world_size := Vector2(3072, 3072)` é a **única fonte de verdade** das dimensões. Dela derivam, sem duplicação:

1. o chão e o grid, desenhados em `_draw()` (grid a cada 256 px, só para tornar o deslocamento perceptível);
2. as quatro paredes `StaticBody2D`, construídas em código em `_ready()`;
3. os limites da câmera.

Os limites usam **paredes físicas** (Opção A), não clamp de posição: assim o mapa não precisa vazar para dentro de `player.gd`, e trocar o mapa não mexe no Player.

**Isto é protótipo.** Não é TileSet, não é floresta, não é a arquitetura final do mapa. O mapa do survivor-like poderá ser muito maior, rolar infinitamente ou funcionar de outra forma.

# Composição da partida

`res://scripts/systems/game.gd`, na raiz de `game.tscn`, faz uma coisa só:

```gdscript
_player.apply_camera_limits(_test_world.get_bounds())
```

Não é manager e não guarda estado. Existe para que o Player não conheça o mapa e o mapa não alcance dentro do Player. GameManager, SpawnManager e WaveManager entram nas fases previstas no ROADMAP.

## Estrutura de `game.tscn`

```text
Game (Node2D)                <- scripts/systems/game.gd
├── World (Node2D)
│   └── TestWorld            <- instância de test_world.tscn
├── Player                   <- instância de player.tscn, em (0, 0)
├── EnemyContainer (Node2D)
├── ProjectileContainer (Node2D)
├── PickupContainer (Node2D)
├── EffectContainer (Node2D)
└── CanvasLayer
```

# Arquivos criados

- `scenes/player/player.tscn`
- `scenes/game/test_world.tscn`
- `assets/characters/druida_sprite_frames.tres` (4 animações, 57 frames)
- `assets/characters/frames/.gitkeep` substituído por `.gdignore` + `README.md`
- `scripts/player/player.gd` (+ `.uid`)
- `scripts/player/player_visual.gd` (+ `.uid`)
- `scripts/systems/test_world.gd` (+ `.uid`)
- `scripts/systems/game.gd` (+ `.uid`)
- `tests/test_phase1.gd` (+ `.uid`)
- `tests/test_foundation.gd.uid` (gerado pela Godot, versionado agora)

Na entrada do diabrete (2026-08-29):

- `assets/characters/inimigos/diabrete-*.png` + `.json` (sheets limpos) e `_raw/` com os originais
- `assets/characters/inimigos/diabrete_sprite_frames.tres`
- `scenes/enemies/enemy.tscn`
- `scripts/enemies/enemy.gd` e `scripts/enemies/enemy_visual.gd`

`.gitkeep` removidos de `scenes/enemies/` e `scripts/enemies/`.

Na FASE 2:

- `scripts/components/health_component.gd`, `hitbox_component.gd`, `hurtbox_component.gd` (+ `.uid`)
- `tests/test_phase2.gd` (+ `.uid`)

Na FASE 3:

- `scripts/systems/spawn_manager.gd` (+ `.uid`)
- `tests/test_phase3.gd` (+ `.uid`)

No mapa e nas habilidades (2026-09-01):

- `assets/environment/` — tilesets, TileSet com terrenos, 8 peças de borda, 8 props
- `assets/characters/morte-druida-south.png` + `.json`
- `assets/effects/vinha.png` + `vinha_sprite_frames.tres`
- `scenes/effects/vine_lash.tscn`
- `scripts/effects/ability_effect.gd` (substitui `lightning_strike.gd`)
- `assets/_raw/` — folhas originais, vídeo da morte e artes antes da limpeza

Na FASE 4:

- `scripts/weapons/weapon_data.gd`, `weapon.gd`, `weapon_manager.gd` (+ `.uid`)
- `resources/weapons/cajado_raio.tres` e `vinha_espinhosa.tres`
- `tests/test_phase4.gd` (+ `.uid`)

Apagados na FASE 4: `scripts/effects/lightning_caster.gd` e `tests/test_raio.gd`.

# Arquivos modificados

- `scenes/game/game.tscn` (script de composição, instâncias de TestWorld e Player)
- `docs/ROADMAP.md` (FASE 1 marcada)
- `docs/DECISIONS.md` (DEC-016)
- `docs/HANDOFF.md`
- `docs/CHANGELOG.md`
- `docs/TODO.md`

`.gitkeep` removidos de `scenes/player/`, `scripts/player/` e `scripts/systems/`, que agora têm conteúdo real.

Na integração do sprite (depois da FASE 1) mudaram: `scenes/player/player.tscn`, `scripts/player/player.gd` (sinal `movement_state_changed`, export `camera_zoom`) e `scripts/player/player_visual.gd` (reescrito para o sheet). O `.png` e o `.json` do asset entraram versionados.

# Testes executados

Godot usado na validação: **4.7.1 stable** (`4.7.1.stable.official.a13da4feb`).

| # | Comando | Resultado |
|---|---|---|
| 1 | `--headless --script res://tests/test_foundation.gd` (antes de alterar nada) | `FASE 0 OK`, exit 0 |
| 2 | `--headless --import` | exit 0, `Player` e `TestWorld` registrados como classes globais |
| 3 | `--headless --script res://tests/test_foundation.gd` (depois) | `FASE 0 OK`, exit 0 |
| 4 | `--headless --script res://tests/test_phase1.gd` | `FASE 1 OK`, exit 0 |
| 5 | `--quit-after 180 --resolution 1280x720` (com render) | Vulkan / Forward Mobile, exit 0, sem erro |
| 6 | Captura de tela em execução real (script temporário, não versionado) | ver abaixo |
| 7 | Suíte completa reexecutada após integrar o sprite | `FASE 0 OK` e `FASE 1 OK`, exit 0 nos dois |
| 8 | Captura em execução com o sprite, zoom 1.0 / 1.5 / 2.0 e caminhada | arte renderiza, anima e a câmera acompanha |
| 9 | Após trocar pelos sheets por direção: suíte completa + captura das animações em execução | `FASE 0 OK` e `FASE 1 OK`; todas as animações resolvem e tocam corretamente |
| 10 | Após remover o `idle_south`: andar e parar nas quatro direções | `.tres` expõe só `walk_east/north/south/west`; parado em cada direção resolve para `walk_<direção>` no frame 0, sem erro nem warning |
| 11 | `--headless --import` após limpar os sheets do diabrete e criar o `.tres` | exit 0, sem erro nem warning |
| 12 | `test_foundation.gd` e `test_phase1.gd` com o inimigo em cena | `FASE 0 OK` e `FASE 1 OK`, exit 0 nos dois |
| 13 | Execução real com render, quatro diabretes em `game.tscn` (script temporário, não versionado) | ver abaixo |
| 14 | `--headless --script res://tests/test_phase2.gd` | `FASE 2 OK`, exit 0 |
| 15 | Suíte completa depois da FASE 2 | `FASE 0 OK`, `FASE 1 OK` e `FASE 2 OK`, exit 0 nos três |
| 16 | Quatro erros injetados de propósito, para provar que a FASE 2 não passa vazia | ver abaixo |
| 17 | Partida real com render, quatro diabretes contra o Player parado | ver abaixo |
| 18 | Oito diabretes cercando o Player parado, com render | menor distância entre eles 26,3 px; nenhuma sprite empilhada |
| 19 | Y-sort com render: um diabrete acima e outro abaixo do druida, Player em y = -600 | o de baixo desenha na frente, o de cima some atrás, e o chão continua embaixo |
| 20 | Dois erros injetados nas propriedades de ordenação | `z_index` do World em 0 e `EnemyContainer` sem `y_sort_enabled`; os dois foram pegos |
| 21 | `--headless --script res://tests/test_phase3.gd` | `FASE 3 OK`, exit 0 |
| 22 | Suíte completa depois da FASE 3 | `FASE 0/1/2/3 OK`, exit 0 nas quatro |
| 23 | Carga com renderização, 50 a 300 inimigos empilhados | ver "Carga: quantos diabretes cabem" |
| 24 | `--headless --script res://tests/test_raio.gd` | `RAIO OK`, exit 0 |
| 25 | Dois erros injetados no raio | `hit_interval` deixando de ser 0, e hitbox ligada desde o frame 0; os dois foram pegos |
| 26 | Execução com render: morte, game over e raio | ver abaixo |
| 27 | Mapa em tiles, com render | 2.304 células preenchidas, mata em manchas contínuas, sem emenda |
| 28 | Props: contagem de sobreposição no mapa gerado | 63 peças, **zero** pares sólido-com-sólido invadindo espaço |
| 29 | Player empurrado contra um prop sólido | barrado a 32 px do centro dele |
| 30 | Vinha nas seis direções, inimigo a 130 px | 20 de dano em todas — um golpe por alvo |
| 31 | Um botão de rosa por quadro, nos 8 quadros da vinha | conferido por contagem de manchas |
| 32 | Suíte completa depois do mapa e das habilidades | `FASE 0/1/2/3 OK` e `RAIO OK` |
| 33 | `--headless --script res://tests/test_phase4.gd` | `FASE 4 OK`, exit 0 |
| 34 | Três erros injetados nas armas | cooldown ignorado, dano do nível não chegando ao ataque, e arma repetida duplicando; os três foram pegos |
| 35 | Partida real com as duas armas e 10 inimigos | 10 mortos em 6,7 s, zero efeitos deixados na cena |
| 36 | Suíte completa depois da FASE 4 | `FASE 0/1/2/3/4 OK` |
| 37 | `--headless --script res://tests/test_phase5.gd` | `FASE 5 OK`, exit 0 |
| 38 | Três erros injetados na FASE 5 | XP excedente descartado, opção impossível oferecida e fila de níveis ignorada; os três foram pegos |
| 39 | Partida real: 12 inimigos, coleta e level up | subiu ao nível 2, tela abriu com duas opções válidas, jogo pausado |
| 40 | Vinha depois do DEC-022, com render | rotação 0°, nascendo a 145 px do druida |
| 41 | Suíte completa depois da FASE 5 | `FASE 0/1/2/3/4/5 OK` |
| 42 | `--headless --script res://tests/test_hud.gd` | `HUD OK`, exit 0 |
| 43 | Quatro erros injetados no HUD | dois passaram na primeira tentativa; o teste foi reforçado e os quatro passaram a ser pegos |
| 44 | Render de verdade a 1280x720, vida em 62% e XP em 63% | as quatro peças na tela, moldura inteira e líquido no vão |
| 45 | Suíte completa depois do HUD | sete suítes, exit 0 em todas |
| 46 | `--headless --script res://tests/test_phase6.gd` | `FASE 6 (parcial) OK`, exit 0 |
| 47 | Seis erros injetados no `StatComponent` e no aplicador do Player | os seis foram pegos de primeira |
| 48 | Suíte completa depois do `StatComponent` | oito suítes, exit 0 em todas |
| 49 | `--headless --script res://tests/test_phase6.gd` com catálogo | `FASE 6 (parcial) OK`, exit 0 |
| 50 | Quatro erros injetados no catálogo | teto ignorado, arma sem slot, sorteio repetindo e passiva sem efeito; os quatro foram pegos |
| 51 | Partida real, level up com render | tela pausou e ofereceu duas passivas e uma arma, com descrição |
| 52 | Suíte completa depois do catálogo | oito suítes, exit 0 em todas |
| 53 | Quatro erros injetados na arma e na regeneração | dois passaram na primeira tentativa; o teste foi reforçado e os quatro passaram a ser pegos |
| 54 | Partida real com as seis passivas | tela ofereceu Essência Viva, Coração Verde e Passos do Cervo |
| 55 | Suíte completa ao fim da FASE 6 | `FASE 0/1/2/3/4/5/6 OK` mais o HUD |
| 56 | `--headless --script res://tests/test_phase7.gd` | `FASE 7 OK`, exit 0 |
| 57 | Oito erros injetados nas famílias | os oito foram pegos de primeira |
| 58 | Partida real com as quatro famílias, com render | raio, corvo, zona e vagalumes na tela juntos; cinco de sete inimigos mortos em 5 s |
| 59 | Suíte completa ao fim da FASE 7 | nove suítes, exit 0 em todas |
| 60 | `--headless --script res://tests/test_phase8.gd` | `FASE 8 OK`, exit 0 |
| 61 | Cinco erros injetados nas waves | um passou por não ser bug; o teste passou a forçar a reentrada e os cinco passaram a ser pegos |
| 62 | Partida saltada para 430 s, com render | wave 5 valendo, 9 imps, 10 cães, 9 brutos, 2 elites e 1 boss em cena |
| 63 | Os cinco tipos lado a lado, com render | tamanhos e tintas distintos, do cão ao boss |
| 64 | Suíte completa ao fim da FASE 8 | dez suítes, exit 0 em todas |
| 65 | `--headless --script res://tests/test_phase9.gd` | `FASE 9 OK`, exit 0 |
| 66 | Cinco erros injetados no estado da partida | os cinco foram pegos |
| 67 | Pausa e vitória com render | painel, título e botões nas duas; tempo e nível na de resultado |
| 68 | Suíte completa ao fim da FASE 9 | onze suítes, exit 0 em todas |

## O que `tests/test_phase1.gd` cobre

Estrutura: `player.tscn` existe, raiz é `CharacterBody2D`, script anexado, grupo `player`, `Visual` presente, `CollisionShape2D` com shape, `Camera2D` presente, `collision_layer`/`collision_mask` corretos, `move_speed` válido, `game.tscn` instancia Player e área de teste maior que a viewport, Input Actions presentes.

Comportamento, em execução real: deslocamento medido a **60 Hz** e a **30 Hz**, limites da câmera aplicados, e Player empurrado contra a parede.

## Resultado das medições

```
60 Hz: 100.0 px em 0.50s
30 Hz: 100.0 px em 0.50s
```

Exatamente `200 px/s x 0,5 s` nas duas taxas — velocidade independente do FPS, medida, não presumida.

## Verificação de que os testes não são vacuosos

Dois erros foram injetados de propósito e revertidos em seguida:

1. `velocity = direction * move_speed * delta` → o teste falhou com 1,7 px a 60 Hz contra 3,3 px a 30 Hz;
2. `collision_mask = 0` no Player → o teste falhou com "Player atravessou a parede: x=1842.7, borda em 1536.0".

Ambos foram desfeitos e a suíte voltou a passar.

## Verificação visual

Executado com renderização, capturando o viewport. Confirmado: Player visível no centro com o grid ao redor, câmera acompanhando o movimento, câmera travando na borda do mundo, e Player parando em `x = 1521.995` — exatamente `1536 - 14` (borda menos o raio da colisão). `facing` terminou em `EAST`, e os limites da câmera em `[-1536, -1536, 1536, 1536]`.

## Teste em execução do diabrete

Quatro diabretes instanciados em (±320, ±240), Player na origem. Medido em
execução, com render, a 1280 x 720:

```
Diabrete1 dist 392.7 -> 224.0  anim=walk_east frame=4 tocando=true
Diabrete2 dist 392.7 -> 224.0  anim=walk_west frame=8 tocando=true
Diabrete3 dist 392.7 -> 224.0  anim=walk_east frame=4 tocando=true
Diabrete4 dist 392.7 -> 224.0  anim=walk_west frame=8 tocando=true
```

Os quatro convergem para o Player, a animação resolve pela direção certa e está
tocando. Com o Player andando para leste por 2 s, os da direita continuam a
alcançá-lo (87,9 px) e os da esquerda ficam para trás (323,0 px) — coerente com
110 px/s contra 200 px/s. A captura do viewport confirma a leitura da arte sobre
o chão escuro, sem halo verde. Nenhum erro no console.

**As direções vertical (north/south) não foram exercitadas nesta captura**, pois
os quatro inimigos estavam em posições de eixo horizontal dominante. A cadeia de
fallback é a mesma já validada no Player.

**Não foi feito teste com teclado humano.** O input foi simulado via `Input.action_press`, que percorre o mesmo caminho de Input Actions que o teclado. Vale confirmar manualmente no editor.

## O que `tests/test_phase2.gd` cobre

Ordem de desenho: `y_sort_enabled` na raiz de `game.tscn` e no `EnemyContainer`,
e `z_index` negativo no `World`.

Estrutura: cena do Enemy (raiz, script, grupo, `Visual`, `CollisionShape2D`,
`Health`, `Hitbox`, `Hurtbox`), layers e masks das cinco caixas conforme
DEC-014/DEC-017/DEC-018, hurtboxes ligadas ao `HealthComponent`, caixas de
combate como irmãs de `Visual` e não filhas, e a ausência de colisão de corpo
entre Player e inimigo nas duas direções.

`HealthComponent` isolado: vida cheia ao entrar na árvore, `damage`, `heal`,
teto de `max_health`, dano negativo ignorado, cura não ressuscita e — o ponto do
critério de aceite — **dois golpes letais no mesmo frame emitem `died` uma vez**.

Comportamento, em execução real: perseguição (distância encurta pelo menos 60 px
em 1 s), dano por contato **respeitando o intervalo** (1,2 s encostado = exatos
dois golpes, não sessenta), **travessia** (o Player anda por dentro do inimigo
sem ser barrado, e leva dano ao fazê-lo), **separação** (dois inimigos quase
colados terminam a pelo menos 20 px um do outro), morte do inimigo uma única vez
com o nó saindo da árvore, Player morto parando e saindo do radar, e inimigo sem
alvo parando em vez de estourar.

## Verificação de que a FASE 2 não passa vazia

Quatro erros foram injetados de propósito e revertidos em seguida:

1. remoção do guarda `_is_dead` em `HealthComponent.damage()` → "emitiu 'died' 2
   vez(es), esperado 1";
2. `_cooldown = 0.0` no lugar de `_cooldown = hit_interval` na hitbox → "dano por
   contato em 1.2 s foi de 100.0 (10.0 golpes), esperado 2 golpes";
3. `collision_mask` do Player para 130, voltando a colidir com o inimigo →
   "Player não pode colidir com o corpo do inimigo" e "atravessar o inimigo não
   causou dano ao Player";
4. `collision_mask` do inimigo para 129, tirando a colisão entre inimigos →
   "collision_mask do Enemy esperado 130, encontrado 129" e "inimigos ficaram
   empilhados: 0.0 px de distância, mínimo 20.0".

Os quatro foram desfeitos e a suíte voltou a passar.

## Partida real, quatro diabretes contra o Player parado

```
vida inicial do jogador: 100
  frame  201  vida do jogador: 80
  frame  212  vida do jogador: 60
  frame  261  vida do jogador: 40
  frame  272  vida do jogador: 20
  frame  321  vida do jogador: 0
inimigos vivos: 4
jogador morto: true
```

Os diabretes levam ~3,3 s para cruzar o mapa, e a partir daí tiram 20 por golpe
(dois deles encostam no mesmo frame). O Player morre no frame 321 e a partida
continua rodando sem erro: os quatro inimigos seguem na árvore e nada estoura.

## O que `tests/test_phase3.gd` cobre

Estrutura: `SpawnManager` presente em `game.tscn` com `enemy_scene` definida,
intervalos e tetos coerentes (a partida tem de ficar **mais** densa, não menos),
e `EnemyContainer` começando vazio — um inimigo fixo na cena voltaria a
atrapalhar o manager.

Comportamento, em execução real: inimigos são criados; **nenhum nasce dentro do
campo de visão** (o mais próximo fica exatamente no raio mínimo, 1001 px na
resolução do teste); o teto de população segura a horda no valor configurado; e
a rampa deixa a partida mais densa de forma gradual, não em degrau.

Carga: 50, 100, 250 e 500 inimigos, conferindo que o número existe de verdade,
que a maioria continua se movendo (a simulação não parou) e que o motor
**acompanha o tempo real**. Este último ponto é o que dá para medir sem
renderização: a Godot dorme o resto de cada frame enquanto dá conta, então o
tempo de relógio por frame fica colado em 16,6 ms; passar disso é sinal de que
não deu. Quanta folga existe é outra pergunta, e essa exigiu render (tabela
acima).

## Um bug encontrado pelo teste de carga

Com 300 inimigos apareceu `Function blocked during in/out signal`. Causa: a
morte quase sempre chega **de dentro** do `area_entered` da hitbox que matou, e
a Godot proíbe mexer em `monitorable`/`monitoring` durante o processamento do
sinal. Com poucos inimigos a coincidência é rara; com 300, acontece.

Corrigido em `HurtboxComponent.set_vulnerable()` e em `Enemy._on_health_died()`,
que agora usam `set_deferred`. Nenhuma mudança de comportamento: o golpe
seguinte só viria no frame seguinte de qualquer forma.

## Morte, game over e raio em execução

Com render, 8 diabretes em volta do druida:

```
raios lancados: 2 | inimigos vivos: 0 | mortos: 8
efeitos na cena: 0
game over visivel no meio da animacao: false
game over visivel depois: true | posicao (0.0, -48.0) | player morreu em (0.0, 0.0)
efeitos deixados na cena: 0
```

Dois raios limparam os oito diabretes — a área de 40 px pega vários quando eles
estão empilhados em volta do jogador. Nenhum efeito ficou na cena. A imagem de
game over **não** aparece durante a animação de morte, aparece depois, e no
lugar exato onde o druida caiu.

Capturas frame a frame confirmam o raio caindo sobre a linha dos inimigos, com o
impacto no chão, e o druida se desfazendo em partículas azuis até sobrar só o
cajado.

## Um teste que sumiu em silêncio

Ao entrar a vinha, `test_phase2` **parou de reportar** — nem OK, nem falha. A
habilidade nova matava o inimigo que o teste estava medindo, e ele ficava
esperando para sempre.

Causa: os testes desligavam a habilidade **pelo nome** (`RaioTeste`), e a vinha
passou batido. Agora desligam **por tipo**, varrendo os filhos da cena. A
próxima habilidade que entrar não quebra os testes em silêncio.

Vale como aviso geral: teste que depende de nome de nó quebra quando alguém
acrescenta um irmão.

## O que `tests/test_phase4.gd` cobre

Dados: cada `.tres` é válido, ids não se repetem, e a progressão **progride** —
dano sobe e cooldown cai do nível 1 para o 2, sem chegar a zero no nível máximo.
Um `.tres` é editado à mão com frequência, e um valor zerado passa despercebido.

Cenas de ataque: aceitam `set_damage()`, têm `aim()` quando a arma mira, e a
hitbox está nas layers certas em golpe único.

`WeaponManager` isolado, sem física no meio: arma nova entra no nível 1, arma
repetida **melhora** em vez de duplicar, o limite de slots recusa a terceira sem
trocar ninguém, o nível para no teto, e arma inexistente reporta nível 0.

Em execução: a arma dispara sozinha **dentro do cooldown** (2 disparos em 4 s,
com tolerância de um, porque o dobro seria cooldown ignorado), o dano por golpe
bate com o nível, e o `EffectContainer` não acumula nós.

## Verificação de que a FASE 4 não passa vazia

Três erros injetados e revertidos:

1. cooldown ignorado no `Weapon` → "240 disparos em 4.0 s, esperado ~2";
2. `set_damage()` não chamado → "2.0 de dano tirado em 2 disparos de 30.0";
3. arma repetida deixando de melhorar → "deveria subir para o nível 2, está no 1".

## O que `tests/test_phase5.gd` cobre

Curva isolada, sem cena: ganho pequeno não sobe nível, fechar o nível exato deixa
sobra zero, e **65 de XP sobe dois níveis guardando 5** — o ponto da §12. Uma
curva degenerada (`xp_growth` zerado) não pode travar o jogo.

Estrutura: o orbe é `Area2D` na layer Pickup com mask 0, responde a `collect()`,
e o Player tem `Level` e `PickupArea` com raio válido.

Em execução: inimigo morto larga **um** orbe **onde morreu**, sem coletar
sozinho; encostar coleta e soma XP; dois níveis de uma vez pausam o jogo, abrem
opções com ação ligada, aplicam **uma** escolha por nível e só fecham quando a
fila esvazia; e com todas as armas no teto a tela **não abre**.

## Verificação de que a FASE 5 não passa vazia

Três erros injetados e revertidos. O segundo é o interessante: na primeira
tentativa ele **passou**, porque o teste nunca chegava a ter arma no nível
máximo — a regra existia no código, mas nada a protegia. Foi preciso acrescentar
o caso; hoje o teste enche as armas até o teto de propósito.

1. XP excedente descartado → "65 de XP deveria subir dois níveis, subiu 1";
2. opção impossível oferecida → "a tela abriu com todas as armas no teto";
3. fila de níveis ignorada → "a tela fechou com nível ainda na fila".

## O que `tests/test_hud.gd` cobre

Arte: as duas peças de cada barra têm o mesmo tamanho, cabem na viewport,
esvaziam da direita para a esquerda e usam filtro Linear.

Relógio: `00:00`, `00:09`, `01:05`, `09:59` e — passando de uma hora —
`1:02:05`.

`configure()`: com componentes soltos em estado que não é o inicial de ninguém —
vida em 25%, XP em 40% do nível 2 —, as barras e o rótulo precisam refletir isso
no instante em que o painel é ligado.

Em execução: dano e XP movem as barras na proporção certa, o rótulo de nível
acompanha, e o relógio **congela** enquanto a tela de level up mantém o jogo
pausado.

## Verificação de que a FASE 6 não passa vazia

Oito erros injetados ao todo, em duas rodadas.

Na primeira, sobre o `StatComponent` e o catálogo, os seis foram pegos de
primeira: percentual multiplicando antes do plano, percentuais compondo em vez
de somando, piso removido, base relida a cada recálculo, Player sem escutar
`stat_changed`, e ganho de vida máxima sem curar. Mais quatro no catálogo: teto
de repetição ignorado, arma oferecida sem slot, sorteio repetindo na mesma tela
e passiva sem efeito.

Na segunda, sobre a arma e a regeneração, **dois dos quatro passaram**:

1. **"a vida processa sempre" passava** porque o teste lia `is_processing()`
   logo depois de `add_child()`, e `_ready` não dispara em nó acrescentado de
   dentro de `SceneTree._initialize()` — a mesma armadilha do `Hud`, de novo.
   O teste passou a atribuir `regeneration` explicitamente, e ganhou o caso
   inverso: zerar desliga o processamento de volta;
2. **"morto continua regenerando" passava** por um motivo diferente e mais
   interessante: não era bug. Quem impede o morto de voltar é o `heal()`, e a
   guarda no tique é só defensiva. O teste afirmava o que outra guarda já
   garantia. Passou a testar o efeito — morto que recebe cura continua morto —,
   que é o que o jogo precisa, e injetar a remoção da guarda no `heal()` agora
   falha.

A segunda vale como padrão: **um teste que não distingue duas implementações
não está testando aquela linha.**

## Verificação de que o teste do HUD não passa vazio

Quatro erros injetados e revertidos. **Dois passaram na primeira tentativa**, e
os dois motivos valem registro:

1. **`configure()` esvaziado ainda passava.** O teste conferia os valores
   iniciais na cena de verdade, e `hud.tscn` trazia `value = 100` na barra de
   vida — o padrão da cena satisfazia a checagem sozinho. Corrigido em dois
   lugares: a barra nasce vazia na cena, e existe agora um teste de `configure()`
   com componentes soltos em estado arbitrário, que não tem como ser satisfeito
   por padrão nenhum;
2. **cronômetro correndo durante a pausa ainda passava.** A janela de pausa do
   teste era de 30 passos, meio segundo: um relógio que continuasse correndo
   ainda mostraria o mesmo número inteiro de segundos. A janela passou para 75
   passos, mais de um segundo, que é o mínimo para a diferença aparecer.

Os outros dois foram pegos de primeira: rótulo de nível parado e preenchimento
com tamanho diferente da moldura.

A lição é a mesma das fases anteriores, num formato novo: **um teste que
verifica o estado inicial não pode aceitar como resposta o valor que a cena já
traz de fábrica.**

## Uma armadilha já conhecida, num nó novo

`@onready` não resolve em nó acrescentado à árvore de dentro de
`SceneTree._initialize()` — `_ready()` não dispara ali. É a mesma razão da
inicialização preguiçosa do `HealthComponent` e do `get_node_or_null` na
`PickupArea`. O `Hud` resolve os filhos na primeira vez que é usado, pelo mesmo
motivo. No jogo real `_ready()` roda normalmente; quem tropeça é o teste, e ele
tropeçou.

# Limitações e pendências

- **Só existe um tipo de escolha no level up**: melhorar arma equipada. Passivas e armas novas são a FASE 6.
- **A zona e o orbital são PLACEHOLDER desenhados em código** (DEC-013): círculo de esporos e três luzes com halo. Só o corvo tem arte de verdade.
- **Nenhuma passiva aumenta a quantidade de orbes.** O orbital tem três, definidos na cena; `AMOUNT` hoje só decide quantos alvos um disparo atende.
- **Os tipos de inimigo não têm arte própria.** Todos usam a sprite do diabrete, diferindo em escala e tinta. É PLACEHOLDER declarado, não pendência de código.
- **O boss não tem comportamento próprio**: persegue igual aos outros, só com muito mais vida. Padrão de ataque de boss não está no roadmap do MVP.
- **Nada acontece quando o boss morre.** `WaveManager.boss_spawned` é o gancho, e a condição de vitória é da FASE 9.
- **Duas das onze opções ainda não têm ícone**: Anel de Esporos e Vagalumes Guardiões. A tela reserva a coluna e desenha só o texto (DEC-013).
- **O sorteio é uniforme.** Não há raridade nem peso: toda opção aplicável tem a mesma chance.
- **Com todas as armas no nível máximo, subir de nível não oferece nada** e a tela nem abre. É beco sem saída até haver passivas.
- **O orbe de XP é PLACEHOLDER** desenhado em código, e não tem atração: coleta só por encostar, no raio de 48 px.
- **Nenhuma arma é escolhida pelo jogador.** As duas vêm equipadas desde o começo, por `starting_weapons`. Escolher personagem e armas iniciais é FASE 13.
- **Os ataques não são projéteis.** São efeitos de vida curta no lugar do alvo. O `ProjectileContainer` continua vazio; arma com trajetória entra quando existir uma que precise.
- **Os inimigos raspam nos props sólidos.** Eles colidem com a layer 8 e perseguem em linha reta, sem pathfinding (DEC-008). Com peças pequenas o `move_and_slide` contorna; com a horda cheia isso precisa ser observado (DEC-020).
- **Não há transição de terra para água** no tileset: cada folha cobre um par de terrenos. Pintar água encostando em terra não acha peça.
- **O mapa procedural é placeholder**, não design: existe para o jogo não rodar sobre um retângulo liso. A primeira célula pintada à mão desliga ele.
- **O inimigo não tem animação de morte**: some na hora. A do druida existe; a dele não.
- **Não há menu principal.** A §16 pede "voltar ao menu" e não existe menu para onde voltar: o botão é SAIR. O menu não está na lista da FASE 9 e pede tela e arte próprias.
- **O raio é andaime.** Dispara sozinho, não tem nível, não tem upgrade e não passa por `WeaponManager`. Vira arma de verdade na FASE 4.
- **Inimigo não tem nem terá `idle`** (DEC-019). Parado, congela no frame 0 da caminhada. É o alvo, não pendência.
- **Sprites de mesma linha ainda se misturam.** O Y-sort resolve a profundidade, mas dois inimigos praticamente na mesma coordenada Y têm ordem indefinida entre si, e a sprite de 96 px de altura sobre uma pegada de 28 px faz a horda se sobrepor verticalmente de qualquer jeito. É característica de top-down com personagem alto, não defeito de ordenação.
- **Não há feedback visual de dano**: nem no Player nem no inimigo. A `Hurtbox` já emite `hit`, que é o gancho para piscar ou mostrar número — falta a arte e é assunto da FASE 11.
- **O HUD não tem ícones nem números.** Mostra vida, XP, nível e tempo; não mostra quantas armas há, nem o valor exato de vida. Suficiente para balancear a FASE 6.
- **O tamanho do HUD está baked na textura** (DEC-023): mudá-lo é editar `LARGURA_EM_TELA` em `tools/preparar_barras_hud.py` e rodar de novo, não arrastar o nó no editor.
- **A derrota e a vitória param a árvore inteira.** Os inimigos congelam atrás do painel. É a leitura literal de "interromper gameplay" da §16; se ficar estranho em jogo, é um `const` no `GameManager`.
- **Os `.json` do diabrete têm `sheet` e `id` de frame inconsistentes** (dizem `idle`/`andar`, apontam para nomes inexistentes). Não afeta o jogo; vale corrigir na origem.
- **O druida não tem `idle` em nenhuma direção**, e é o único personagem que deveria ter (DEC-019). Parado, congela no frame 0 da caminhada correspondente.
- **Diagonal mostra a direção vertical.** Andando na diagonal, o empate de magnitude resolve para north/south. É a regra fixa do `facing`; se preferir horizontal na diagonal, é uma linha em `_update_facing`.
- BUG-001 (largura da textura) foi **corrigido** pela troca do asset.
- **Godot 4.7.2 continua não validado.** O ambiente só tem 4.7.1 stable; procurei por 4.7.2 e não existe na máquina. DEC-001 não foi alterada e nada fora de 4.7 foi usado. Quem tiver 4.7.2 deve abrir o projeto uma vez e rodar as duas suítes.
- Movimento não foi testado com teclado físico por uma pessoa (ver acima).
- O mundo de teste é protótipo descartável, não arquitetura de mapa.
- Nenhum bug de código. BUG-001 está corrigido em `docs/BUGS.md`.

# Próxima tarefa

**FASE 12 — Mobile, na branch `fase-12-mobile`.** O que dava para fazer sem
aparelho está feito (abaixo); o que falta é medir **no celular**. A FASE 11
(arte) segue esperando as peças que estão com o responsável — os pacotes de
prompt já entregues estão em "O que também está pendente".


## Arte entregue: o que entrou, e o que ainda falta

A pasta `assets/ultimas solicitacoes` trouxe os ícones das armas, o nome do
jogo, o fundo do menu, o ícone do app e três folhas de animação. Tudo isso está
**integrado e verificado**; faltam os quatro vídeos de criatura (bruto, elite,
Guardião andando e Guardião morrendo), cujos prompts já foram entregues.

As peças chegaram com transparência de verdade, mas com o fundo **cercado de
desenho** ainda em magenta — miolo do anel de esporos, vãos entre as asas do
vagalume, contador das letras. É o mesmo caso já resolvido no painel: recortar
por cor não basta, é preciso cortar por cor **e** conectividade, e o rosa que
sobra da beirada antisserrilhada vira cinza de mesma luminância em vez de
buraco.

### Escala das animações: a arte decide, não o contrário

`tools/preparar_efeitos.py` mede o raio visível de cada quadro e imprime. Foi
essa medida que decidiu a escala de cada sprite e a colisão correspondente:

| efeito   | raio da arte      | colisão antes | decisão                                  |
| -------- | ----------------- | ------------- | ---------------------------------------- |
| orbe     | 24 a 28 px        | 10            | sprite a 55%, colisão passa para 14      |
| esporos  | 84 a 128 px       | 64            | só os dois quadros grandes, a 50%        |
| vagalume | 10 a 16 px        | 11            | serve como está, sem escala              |

O anel merece nota: ele **cresce** ao longo da folha, e a colisão de uma zona é
um círculo fixo. Com os quatro quadros, os dois primeiros acertariam antes de a
nuvem encostar no inimigo. Ficam os dois maiores, e a animação passa a pulsar
em vez de crescer.

Os três orbes dos vagalumes começam em quadros diferentes: piscando juntos
pareceriam um efeito só.

### O desenho em código sai quando a arte entra

`OrbeProjetil`, `ZoneEffect` e `OrbitEffect` desenhavam círculos em `_draw()`.
Agora cada um pergunta se existe um `Sprite` na cena e, havendo, não desenha
nada — a DEC-013 previa exatamente essa troca, e ela não custou uma linha de
lógica. O `ZoneEffect` também deixa de pedir redesenho por quadro nesse caso.

### Os testes passaram a medir a textura

`tests/test_acerto.gd` e `tests/test_progressao.gd` comparavam a colisão com o
raio **exportado do placeholder** — que sobrevive intacto quando a arte entra.
Continuariam passando com a arte em qualquer escala. Agora o raio sai da
própria textura, quadro a quadro, mediana dos quadros e já multiplicado pela
escala do sprite. Verificado com defeito de propósito: esporos a 25% (`colisão
64 para nuvem de 32`), vagalume a 300% (`colisão 11 para orbe de 41`) e orbe a
100% (`colisão 14 para desenho de 27`) — os três acusam.

### Armadilha: PNG novo não existe até ser importado

As três suítes falharam na primeira execução com "There is no animation with
name 'idle'" e raio medido **zero**. A causa não era o `.tres`: os PNG novos não
tinham `.import`, e sem ele a textura não existe para a Godot rodando headless —
o `AtlasTexture` fica vazio e o `SpriteFrames` vem sem animação. `godot
--headless --import` antes de rodar os testes resolve, e vale para qualquer
asset que chegue por script em vez de pelo editor.

## FASE 12 — Mobile: o jogo se joga por toque e exporta para Android

O que entrou:

- **joystick virtual flutuante** (`scripts/ui/joystick_virtual.gd`, nó `Hud/Joystick`):
  nasce onde o polegar encosta na metade esquerda da tela e aperta as mesmas
  ações `move_*` do teclado, com a força da distância do polegar. O druida lê
  `Input.get_vector()` e não sabe que existe joystick (`docs/ANDROID.md`).
  Flutuante porque o canto inferior esquerdo é da barra de vida. Um dedo só: os
  outros ficam livres para os botões;
- **o joystick solta só o que ele mesmo apertou.** A primeira versão soltava as
  quatro ações ao desligar, e isso parava o druida de quem segura uma tecla — a
  suíte da FASE 1 pegou. Ele também solta tudo ao pausar e quando o app perde o
  foco: pausado, ele não recebe o toque de soltar, e o druida voltaria da pausa
  andando sozinho;
- **botão de pausa por toque** (`Hud/Pausa`, canto superior direito): no celular
  não há Esc. O HUD emite `pausa_pedida` e `game.gd` liga ao
  `GameManager.pausar()` — ele segue sendo o único dono da pausa;
- **área segura** (`scripts/ui/area_segura.gd`): converte a área segura da tela
  para unidades de viewport e empurra cada borda do HUD conforme a âncora. **Só
  em aparelho móvel**: no Windows a área segura é a tela menos a barra de
  tarefas, e o HUD pularia com a janela fora de tela cheia;
- os controles de toque só aparecem em tela de toque. **Para testar no PC com o
  mouse**, ligar `input_devices/pointing/emulate_touch_from_mouse` nas
  Configurações do Projeto;
- orientação paisagem pelo sensor, e compressão de textura ETC2/ASTC ligada — a
  exportação para Android recusa sem ela;
- **exportação Android** (`export_presets.cfg`, preset "Android", só arm64-v8a):

      godot --headless --path . --export-debug "Android" build/android/ForestSurvival-debug.apk

  Sai um APK de depuração de ~38 MB, assinado com a keystore de depuração do
  editor, SDK alvo 36. `tools/`, `tests/`, `_raw/` e `docs/` ficam de fora
  (conferido pela lista de arquivos do APK). `build/` não é versionado.

O que ainda não está resolvido:

- **o nome do pacote é provisório**: `com.feardev24.forestsurvival`. Na Google
  Play ele é a identidade do app e não muda depois da primeira publicação —
  decisão do responsável antes do primeiro envio;
- **não há ícone do app**: a exportação avisa e usa o da Godot. É arte a pedir
  (192 x 192 e as duas camadas de 432 x 432 do ícone adaptativo);
- **o `export_filter` é `all_resources`**, então vai para o APK tudo o que a
  Godot importa, usado ou não — `gameover.png`, 1,2 MB, é um dos maiores
  arquivos do pacote;
- **só o aparelho responde**: tempo de quadro, memória, o entalhe de verdade e
  o tamanho dos botões na mão. A física da horda no teto, que a FASE 10 deixou
  para cá, é a primeira coisa a medir.

### Primeira medição no aparelho (2026-09-11)

Xiaomi 2412DPC0AG, Android 16, Mali-G720 MC7, tela de 2712 x 1220 a 120 Hz.
`scripts/systems/monitor_desempenho.gd` — só em build de depuração num
aparelho móvel — escreve uma linha no log a cada 5 s, lida pelo
`adb logcat -s godot`.

- **120 FPS**: o quadro fica em 8,3 ms na média (o vsync de 120 Hz), p95 de 10 a
  13 ms, um pico de 27 ms. Física no máximo 4,7 ms;
- memória de 52 MB, e 125 MB de vídeo;
- **o entalhe caiu à direita** nessa orientação: 77 unidades de viewport de
  margem, e o HUD se afastou dele;
- em paisagem a tela é 2,22:1, e o `expand` mostra 1600 x 720 de mundo;
- **ressalva**: a partida medida foi curta — ~2 minutos e no máximo 15 inimigos.
  A horda cheia perto do Guardião, que é o caso pesado, ainda não foi medida
  no aparelho;
- o joystick ficou bom na mão, na avaliação do responsável.

`tests/test_phase12.gd` confere o joystick nas ações do teclado com a força
certa, o segundo dedo e a metade direita ignorados, o druida parado depois da
pausa, o botão de pausa, a área segura por âncora sem acumular, a orientação e
o preset. Provada com quatro erros injetados — pausa sem soltar, a tela inteira
começando o joystick, área segura ignorando a âncora e o joystick soltando
teclas que não apertou.

## Progressão por fase (DEC-025): nasce com o Orbe, ganha o resto na partida

O druida nascia com o Cajado e a Vinha e tinha 4 das 5 habilidades aos 40 s.
Agora nasce só com o **Orbe do Cajado** e cada arma é oferecida a partir da
sua fase (tabela na DEC-025). Medido com a sonda, 20 partidas cada:

| começo | 2ª / 3ª / 4ª habilidade | nível aos 60 s | mortes nas waves 1-2-3-4 | vitórias |
|---|---|---|---|---|
| Cajado + Vinha (antes) | — / 19 / 39 s | 6 | 0 / 0 / 5 / 58% | 6/20 |
| só o Corvo (teste) | 72 / 89 / 117 s | **1** | 5 / 21 / 27 / 55% | 3/20 |
| **só o Orbe (atual)** | **43 / 94 / 200 s** | **6** | 0 / 0 / 0 / 10% | **17/20** |

A progressão ficou como planejado: começo no mesmo ritmo e as habilidades
espalhadas pelas fases. Os Vagalumes quase nunca entram (1 em 20), mas é a
política do bot — ele para de pegar arma nova com quatro, e aos 270 s já tem.

**Mas o jogo ficou fácil demais: 17 vitórias em 20.** Três calibrações do
Orbe, testadas em memória, não mudaram isso:

| calibração | vitórias | nível aos 60 s |
|---|---|---|
| Orbe cresce menos por nível (+3 de dano, recarga -5%) | 16/20 | 6 |
| o mesmo, e dano inicial 14 | 13/20 | **2** — o começo volta a emperrar |
| o primeiro, e cerco e Guardião mais densos | 17/20 | 6 |

Ou seja, a força do Orbe não é a causa, e os números dele ficam como estão. O
que ficou fácil é a partida inteira: o recuo novo afasta os inimigos (antes da
troca de início ele já tinha levado de ~2 para 6 vitórias em 20), e com uma
arma só no começo as subidas de nível se concentram nas habilidades principais.
O dano recebido passou a vir de elites (31-38%) e brutos (29-34%).

Um controle confirmou que os ajustes em memória chegam às armas: com o Orbe
causando dano 1, o druida não matou ninguém e morreu aos 32 s, no nível 1.

### Dificuldade recalibrada (meta adotada: o bot vence ~1 em 3)

Cinco calibrações, 20 partidas cada, todas com os valores conferidos no jogo
pelo que cada inimigo teve ao nascer:

| calibração | vitórias | wave 3 | cerco | Guardião |
|---|---|---|---|---|
| como estava | 17/20 | 0% | 10% | 0% |
| C1 — elite e bruto mais duros, boss 3000 | 17/20 | 0% | 0% | 15% |
| C2 — waves 3 a 5 mais densas | 18/20 | 0% | 0% | 5% |
| C3 — C1 + C2 | 11/20 | 0% | 5% | 26% |
| C4 — C3 + matilha densa e elites cedo | 13/20 | 0% | 25% | 7% |
| **C5 — C2 + elite 500/30 e boss 3600 (gravado)** | **10/20** | 0% | 25% | 20% |

**O que os números ensinam:** inimigos mais duros **ou** mais numerosos não
mexem no placar — as armas do druida dão conta de cada um isolado. Só as duas
coisas juntas endurecem a partida. E adiantar a pressão (C4) não tira o passeio
das waves 2 e 3: nelas o que mata é acúmulo, não densidade momentânea; o efeito
foi só antecipar as mortes para o cerco.

O gravado é o C5: elite com 500 de vida e 30 de dano, bruto com 170, Guardião
com 3600, e as waves 3, 4 e 5 mais densas com elites mais frequentes. Confirmado
depois de gravado, com 20 partidas sem nenhum ajuste em memória: **8 vitórias em
20**, 40% morrendo no cerco e 17% no Guardião — dentro do ruído do C5 medido. Ele ainda
é mais fácil que a meta (1 em 2, não 1 em 3), e a diferença entre 10, 11 e 13
vitórias está dentro do ruído de 20 partidas: o que separou o C5 foi o formato
da curva. **Apertar mais depende de jogar** — o bot não julga se é divertido.

### Bot de teste no celular: rodou no aparelho

`BotPiloto` + `BotMobile` + o preset "Android Bot": um APK separado que joga
sozinho no aparelho e escreve no log. O teste no PC passa (`tests/test_bot.gd`).
**No Xiaomi a instalação de um app novo pelo USB precisa de um toque de
confirmação na tela do celular** (`INSTALL_FAILED_USER_RESTRICTED`); atualizar
um app já instalado não pede. Por isso o teste rodou com o APK do bot exportado
**com o nome de pacote do jogo normal**, instalado por cima dele — o preset no
repositório continua com pacote próprio, e o jogo normal foi reinstalado no fim.

**O que o aparelho respondeu** (Xiaomi 2412DPC0AG, 120 Hz; partida de 7,5 min,
druida invulnerável, vitória no Guardião):

| medida | valor |
|---|---|
| quadro médio | 8,39 ms (o teto dos 120 Hz é 8,33) |
| p95 do quadro | 12,1 ms; pior janela 18,9 |
| pior quadro | 25,2 ms |
| física | pico mediano 5,1 ms, pior 13,2 |
| memória | 58 MB, mais 124 MB de vídeo |
| pico de inimigos | 58 |
| pico de fragmentos de XP no chão | **397** |

Ou seja: folga larga para 60 FPS, mas **os 120 Hz não se sustentam** — um em
cada vinte quadros passa de 12 ms, e a pior janela foi aos 6 minutos, com 58
inimigos e 203 fragmentos na tela. O acúmulo de fragmentos que a FASE 10
apontou aparece aqui com número de aparelho. A horda nunca passou de 58, o que
é a mesma facilidade que a calibração de dificuldade veio corrigir.

Duas lições do caminho:

- **exportar pela Godot derruba o servidor do `adb`**, e com ele qualquer
  `logcat` rodando no PC. Por isso o log do bot é gravado **dentro do
  aparelho** (`logcat -f /data/local/tmp/fs_bot.log`) e baixado depois;
- o log do jogo normal também sai com `adb logcat -d -s godot`, do buffer do
  aparelho, se a captura ao vivo cair.

## Acerto das habilidades: a colisão é o desenho, e o golpe se vê

O responsável testou no celular e disse que as habilidades "saem e parecem não
bater", e que a vinha passava por cima das pedras. Medido nos desenhos:

| habilidade | colisão antes | o desenho | colisão agora |
|---|---|---|---|
| raio | círculo de 80 px | impacto no chão de 160 a 190 px, quadros 4 a 6 | cápsula de 180 x 72 na altura do corpo, só nos quadros 4 a 6 |
| vinha | cápsula de 25 a 175 | chicote de -25 a 175, faixa -46..-2 | cápsula de -25 a 175, faixa -56..-4, quadros 3 a 6 |
| corvo | círculo de 52 px | corpo de ~72 x 55 com o bater das asas | cápsula de 72 x 48 |
| vagalumes | raio 18 | orbe de raio 9, brilho fraco até 17 | raio 11 |
| esporos | raio 64 | anel de 59 a 64 | igual — já estava certo |

**O diagnóstico da vinha precisou de duas correções.** Primeiro pareceu que a
colisão ficava abaixo do desenho ao virar para a esquerda. Não era: virar
girava o efeito 180°, e o giro leva **desenho e colisão juntos** para o outro
lado do eixo — a vinha inteira ficava pendurada ~70 px abaixo do ponto de onde
brota, coincidindo consigo mesma e flutuando. A suíte de acerto pegou as duas
leituras erradas. Agora virar é **espelhar na horizontal**, sem girar
(`AbilityEffect.aim` e `HitboxComponent.set_espelhado`), e a suíte confere que
a vinha fica apoiada no chão nos dois sentidos. O giro continua para mira em
ângulo qualquer, que nenhuma arma usa (DEC-022).

**Recuo.** Golpe de habilidade que não mata empurra o inimigo ~18 px para longe
de quem acertou, em 0,14 s, com intervalo de 0,2 s. Golpe que mata não empurra:
o inimigo some, e o empurrão não se veria. `EnemyData.knockback_scale`: bruto
0,5, elite 0,4, **Guardião 0** — um boss empurrado a cada golpe deixa de
parecer um boss.

**A vinha e os objetos do mapa.** Os efeitos eram desenhados sempre por cima de
tudo (`z_index` 40). Agora o `EffectContainer` ordena por Y e a vinha fica em
z 0: entra na mesma ordem de profundidade de pedras, totens e personagens, e
uma pedra na frente dela a encobre. E ela só brota onde a faixa do golpe não
atravessa objeto sólido (`WeaponData.grounded`): a arma tenta até 8 pontos em
volta do druida e, sem chão livre, não ataca naquele disparo. A faixa conferida
é a própria colisão do efeito, espelhada para a esquerda. Raio, corvo e
vagalumes ficam por cima de tudo — vêm do céu ou voam —, e os esporos ficam no
chão, embaixo dos objetos, como já estavam.

**Em aberto:**

- **o balanceamento mudou**: o recuo afasta os inimigos do druida e a vinha
  deixa de atacar quando não há chão livre. Os números da seção "Balanceamento
  medido" são de antes disto; vale rodar a sonda de novo;
- **o APK no celular é anterior a estas mudanças**: precisa ser exportado e
  instalado de novo para o responsável sentir o acerto e o recuo na mão.

`tests/test_acerto.gd`, provada com sete erros injetados: a vinha voltando a
girar, o raio de volta ao círculo de 40, o raio pegando depois de sair do chão,
o golpe letal empurrando, o Guardião recuando, a vinha sem checagem de chão
livre e os efeitos fora da ordem de profundidade.

## FASE 10 — Performance: medido numa partida de verdade

Duas ferramentas, e nenhuma otimização sem número antes:

- `tools/sonda_balanceamento.gd -- --perf` — a partida real, gravando o custo de
  cada quadro **pelo relógio** e o que havia em cena. Com `--fixed-fps` e sem
  limite de quadros, o intervalo entre dois passos é exatamente o custo do
  quadro. Rodar **uma partida por vez**, e com janela para incluir o desenho;
- `tools/stress_performance.gd` — o método da tabela "Carga" da FASE 3: horda
  empilhada sobre o druida parado, vsync desligado. Armas desligadas, para o
  patamar se sustentar, e `--orbes=N` para medir fragmentos de XP isolados.

**Uma armadilha de medição:** `Performance.TIME_PHYSICS_PROCESS` não é o quadro
atual. A Godot guarda nele o **pior** quadro de física do último segundo real,
e atualiza uma vez por segundo. Serve de pico, não de distribuição. A primeira
versão da sonda o tratou como distribuição, e cada janela de 5 s de jogo tinha
uma leitura só.

### Horda empilhada (RTX 2060 SUPER, 1280 x 720)

| inimigos | FPS | física (pico/s) | pares de colisão | desenhos | nós |
|---|---|---|---|---|---|
| 100 | 1646 | 4,6 ms | 199 | 81 | 1293 |
| 200 (teto) | 694 | 11,4 ms | 422 | 131 | 2193 |
| 300 | 55 | 18,8 ms | 668 | 180 | 3093 |
| 500 | 4 | 39,9 ms | 1192 | 265 | 4893 |

- **500 é inviável, e o teto de 200 continua certo.** O custo cresce mais rápido
  que o número de inimigos, porque a horda empilhada multiplica os pares de
  colisão;
- 200 empilhados custam hoje 11,4 ms, contra os 8,20 da FASE 3, pelo mesmo
  método. **A diferença não foi investigada**: de lá para cá entraram props
  sólidos no mapa, componentes novos no inimigo e a HUD. Só importa se a horda
  voltar a encostar no teto — o que não acontece nas partidas medidas.

### Partida real (teto invulnerável, 3 partidas)

- o quadro inteiro fica entre 0,7 e 2,7 ms em média, p99 abaixo de 4 ms e pior
  quadro de ~7 ms, contra 16,6 ms de orçamento: **neste PC o jogo usa no máximo
  ~25% do quadro**;
- **a horda real não chega ao teto**: com as armas no máximo, o pico ficou entre
  60 e 110 inimigos;
- **os fragmentos de XP se acumulam sem limite**: até 376 no chão aos 7 minutos,
  e nós e memória sobem junto.

### O que foi otimizado: o desenho dos fragmentos

Os fragmentos não custam física — 100 inimigos com 300 fragmentos deram 4,2 ms,
contra 4,6 sem nenhum —, mas **cada um era uma chamada de desenho**: polígono e
contorno desenhados por instância impedem a Godot de agrupar. Agora todos
desenham a mesma textura, pintada uma vez (`XpOrb.textura_compartilhada()`).

| 100 inimigos + 300 fragmentos | desenhos | FPS |
|---|---|---|
| polígono + contorno (antes) | 412 | 879 |
| só o polígono | 244 | 1374 |
| **textura compartilhada** | **79** | **1571** |

Na partida real, a partir dos 6 minutos: de 129 chamadas de desenho em média
(224 no pico) para 46 (57), com os mesmos ~350 fragmentos no chão.

### O que não foi feito, e por quê

- **pooling** — nenhum sinal de soluço: p99 abaixo de 4 ms e pior quadro de ~7 ms
  na partida inteira. Fica para quando um número pedir;
- **reduzir custo de física** — numa partida real a física fica em poucos ms. O
  caso caro é a horda empilhada no teto, e esse precisa ser medido **no
  aparelho**: é da FASE 12 ("performance device");
- **reduzir alocações** — sem sinal na medição.

### Decisão pendente: fragmentos sem limite

O acúmulo não tem teto. Um jogador que foge sem coletar deixa centenas no chão,
e partidas mais longas deixariam milhares. Com a textura compartilhada eles não
custam desenho nem física, mas cada um é um nó e memória. A saída comum no
gênero é **fundir** os fragmentos acima de um limite num fragmento maior, com a
soma do XP: o XP total não muda, mas o jogador vê e coleta de outro jeito. É
decisão de design, e aguarda o responsável.

`tests/test_phase10.gd` guarda o que a medição mostrou que não pode voltar: os
fragmentos numa textura só, nenhum teto de população acima de 200 e as
ferramentas de medição compilando. Provada com três erros injetados — textura
pintada por fragmento, wave pedindo 300 inimigos e o `_draw` de volta ao
polígono.

## Balanceamento medido: o druida não chega ao Guardião

Os números das FASES 6, 7 e 8 saíram de raciocínio, não de partida jogada.
`tools/sonda_balanceamento.gd` passou a jogar a partida real sem janela — um
bot que foge da horda circulando, busca orbes e escolhe upgrades pelo próprio
menu — e `tools/resumir_sonda.py` resume os JSON. ~100 partidas, 2026-09-10.

**A sonda vale como régua:** o druida parado morre aos 51–68 s; o bot, aos
~200 s. A direção faz diferença real. O bot não diz se é divertido — e é um
jogador mediano: um humano bom fica entre ele e o teto invulnerável.

**Cada ajuste é conferido no jogo.** A primeira versão da sonda perdia os
ajustes feitos em recurso: o recurso alterado ficava numa variável local, era
liberado ao fim da função, saía do cache, e a partida recarregava o original do
disco. A sonda imprimia `190.0 -> 150.0` e o cão corria a 190. Isso invalidou
um teste do cão e uma varredura do boss, e uma conclusão errada chegou a ser
escrita aqui. Agora a sonda segura a referência e grava em `vistos` o que cada
tipo realmente teve ao nascer, lido do nó.

### Sobrevivência (partidas mortais)

| condição | n | sobrevive, média | IC95 | viram o boss |
|---|---|---|---|---|
| original (`xp_growth` 1,35, boss 3000) | 10 | 204 s | 153–255 | 0 |
| `xp_growth` 1,20, boss 2000, cão 190 | 12 | 256 s | 233–280 | 0 |
| + cão a 150 | 20 | 280 s | 253–307 | 0 |
| **arquivos atuais** (+ bruto com dano 12 e velocidade 55) | 20 | **345 s** | 307–383 | 3 (2 vitórias) |

- **A curva de XP travava a progressão** justo quando a pressão sobe: nível 8
  aos 2 min e depois um por minuto, com os brutos entrando aos 150 s. Com 1,20:
  nível 10 aos 2 min e 12 aos 3 (z = 2,6 contra a original);
- **o cão a 150 ajuda, e está aplicado.** Juntando todas as partidas com a
  curva 1,20 — 22 com o cão a 190, 30 com ele a 150 —, a diferença é de +64 s
  (244 contra 308 s, z = 3,3). A primeira estimativa, +133 s, foi inflada por
  duas partidas fora da curva (660 e 437 s) numa amostra de dez; sozinha, a
  rodada com o valor já gravado deu +24 s (z = 1,3). O dano recebido passa a
  vir principalmente dos brutos (48%, contra 33% do cão);
- **o jogo passou a ser vencível.** Com o bruto ajustado, 3 de 20 partidas
  chegam ao Guardião e 2 vencem (boss cai em 96 e 137 s). Somando o lote de
  teste da combinação, 10 de 40 chegaram ao boss e 6 venceram. O dano recebido
  fica dividido: cão 42%, bruto 34%, elite 18%.

### O bruto (aplicado: dano 12, velocidade 55)

Com o cão a 150, o bruto passou a causar ~55% do dano recebido. Cada
hipótese contra uma base do mesmo lote, 20 partidas cada; em todas a sonda
conferiu em `vistos` que o bruto nasceu com o valor testado.

| hipótese | sobrevive | contra a base | viram o boss | vitórias |
|---|---|---|---|---|
| base (arquivos atuais) | 320 s | — | 1 | 0 |
| dano 18 → 12 | 367 s | +47 s (z 1,7) | 3 | 1 |
| velocidade 70 → 55 | 352 s | +32 s (z 1,4) | 3 | 3 |
| vida 130 → 90 | 345 s | +25 s (z 1,0) | 3 | 2 |
| **dano 12 + velocidade 55** (outro lote, base 292 s) | **375 s** | **+83 s (z 2,9)** | **7** | **4** |

Sozinha, nenhuma das três passa do ruído; juntas elas dão +55 s (z = 3,4).
A combinação é a primeira condição em que um terço dos druidas chega ao
Guardião, e com o boss a 2000 quem chega costuma vencer (10 de 16 somando
todos os grupos). O dano recebido fica dividido entre cão (36%) e bruto (35%).

A mesma configuração base deu 280, 292 e 320 s em lotes diferentes: só vale
comparar condições rodadas no mesmo lote.

### O Guardião (druida invulnerável, curva 1,20)

| vida | caiu dentro de 240 s | tempo até cair |
|---|---|---|
| 3000 | 15 de 20 | mediana ~105 s |
| **2000** (aplicado) | 5 de 5 | mediana 93 s (48–221) |
| 1500 | 5 de 5 | mediana 73 s, uma queda em 13 s |

Com 3000, um em cada quatro druidas que chegassem vivos não derrubaria o boss
em quatro minutos. Com 1500 ele vira saco de pancada. 2000 cai sempre e ainda
dura uma luta de minuto e meio.

### O que isso não mede

- **a mesma semente não reproduz a partida** (160–207 s em quatro rodadas da
  semente 1). Por isso cada condição tem 10 partidas e se compara média;
- **o bot deixa muitos orbes no chão** (58–163 por partida). Um humano que
  colete mais sobe de nível mais cedo;
- **se é divertido.** Isso só jogando.

## O que também está pendente, fora do roadmap

- **arte do menu principal** — o menu existe (`scenes/ui/main_menu.tscn`, cena principal do projeto) e funciona com texto e cor. Faltam o nome do jogo desenhado (vaga `TituloArte`) e a ilustração de fundo (vaga `FundoArte`); quando chegarem, entram nas vagas sem tocar em código (DEC-013);
- **arte da morte do Guardião** — o fluxo já existe (DEC-024, emenda): o boss cai com uma queda provisória no `Visual` e a vitória espera ela terminar. Quando o vídeo chegar, a arte entra como animação `death` **sem loop** no `SpriteFrames` do Guardião e substitui a provisória sozinha. As criaturas comuns somem ao morrer, e isso é o final, não falta;
- **arte própria do bruto, da elite e do Guardião** — os três ainda são o diabrete recolorido e aumentado (1,45×, 1,7× e 2,8×);
- **arte da zona de esporos e dos vagalumes** — as duas ainda são formas desenhadas em código;
- **ícones do Anel de Esporos, dos Vagalumes e do Orbe do Cajado** — a tela de escolha reserva a coluna e desenha só o texto;
- **arte do Orbe do Cajado** — o disparo é um círculo desenhado em código; hoje sai do centro do corpo do druida, e com a arte dá para mover a saída para a ponta do cajado (`spawn_offset`);

## Critério de aceite da FASE 11

Ver `docs/ROADMAP.md`. As dezessete suítes continuam passando (`test_foundation`,
`test_phase1` a `test_phase10`, `test_phase12`, `test_hud`, `test_menu`,
`test_acerto`, `test_bot` e `test_progressao`).

# Não alterar sem registrar decisão

- Godot 4.7.2 stable
- GDScript
- survivor-like original
- protagonista druida
- offline-first
- sem serviços pagos no MVP
- arquitetura preparada para mobile
- desenvolvimento independente de arte final (DEC-013 / `docs/ASSET_WORKFLOW.md`)
- numeração das physics layers 2D (DEC-014)
- renderer `mobile` e stretch `canvas_items`/`expand` (DEC-015)
- layer 8 WorldStatic (DEC-016)
- movimento por Input Actions, nunca por tecla direta

# Regra permanente de assets

Falta de sprite, animação ou efeito **não é bloqueio**. Use placeholder sob o nó `Visual`, mantenha gameplay desacoplado da arte e siga `docs/ASSET_WORKFLOW.md`.
