# HANDOFF

Última atualização: 2026-08-30 (segunda leva)

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

**FASE 0 — Fundação, FASE 1 — Movimento e mundo, FASE 2 — Primeiro inimigo e FASE 3 — Spawn e horda.**

Ao rodar o jogo existe uma área de protótipo com grid e um Player controlável em oito direções, com câmera acompanhando e paredes de borda.

Depois da FASE 1, o sprite do druida (estado CANDIDATE) foi integrado no lugar do placeholder geométrico e a câmera foi ajustada para top-down.

Em 2026-08-29 entrou o **diabrete**, primeiro inimigo, com sprites nas quatro direções (estado CANDIDATE). Junto com ele entraram a cena `enemy.tscn` e a perseguição direta simples, porque sem locomoção não dava para avaliar a arte em movimento.

**FASE 2 — Primeiro inimigo. Concluída.** O diabrete persegue, causa dano por contato, recebe dano e morre uma única vez; o Player tem vida e morre. Componentes de vida, hitbox e hurtbox existem em `scripts/components/` e são reutilizáveis pelas armas da FASE 4.

O druida agora **morre em cena**: animação de morte, imagem de game over no
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

### A arte de morte veio fora de escala

Medida contra a caminhada, no mesmo quadro de 64 x 96:

| | caminhada | morte |
|---|---|---|
| altura da silhueta | 87 px | **63 px** |
| linha dos pés | 95 (a base do quadro) | **79** |

Ou seja: ao morrer, o druida encolhia para 72% do tamanho e ainda flutuava 16 px
acima do chão.

Corrigido na **camada visual**, não na arte: `player_visual.gd` aplica
`death_scale = 1.38` e recoloca a sprite para que os pés continuem na origem do
nó. Reamostrar pixel art para 1,38x estragaria o desenho de forma permanente;
uma transformação em runtime é reversível.

Os dois valores são `@export`. Se a morte for reexportada na mesma escala e
alinhamento das outras animações, voltam a `1.0` e `95.5` e nenhuma outra linha
muda. Está em `docs/TODO.md`.

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

# Limitações e pendências

- **O inimigo não tem animação de morte**: some na hora. A do druida existe; a dele não.
- **A imagem de game over não é tela de game over**: tem o botão de reiniciar, mas não tem tempo de partida, level alcançado nem voltar ao menu. É da FASE 9.
- **O raio é andaime.** Dispara sozinho, não tem nível, não tem upgrade e não passa por `WeaponManager`. Vira arma de verdade na FASE 4.
- **Inimigo não tem nem terá `idle`** (DEC-019). Parado, congela no frame 0 da caminhada. É o alvo, não pendência.
- **Sprites de mesma linha ainda se misturam.** O Y-sort resolve a profundidade, mas dois inimigos praticamente na mesma coordenada Y têm ordem indefinida entre si, e a sprite de 96 px de altura sobre uma pegada de 28 px faz a horda se sobrepor verticalmente de qualquer jeito. É característica de top-down com personagem alto, não defeito de ordenação.
- **Não há feedback visual de dano**: nem no Player nem no inimigo. A `Hurtbox` já emite `hit`, que é o gancho para piscar ou mostrar número — falta a arte e é assunto da FASE 11.
- **A vida não aparece na tela.** A barra de HP é da FASE 9; hoje só dá para ver a vida por script.
- **Nada acontece quando o Player morre.** Ele para e sai do radar, e o jogo continua rodando. Game over, tela de resultado e restart são da FASE 9.
- **Os `.json` do diabrete têm `sheet` e `id` de frame inconsistentes** (dizem `idle`/`andar`, apontam para nomes inexistentes). Não afeta o jogo; vale corrigir na origem.
- **O druida não tem `idle` em nenhuma direção**, e é o único personagem que deveria ter (DEC-019). Parado, congela no frame 0 da caminhada correspondente.
- **Diagonal mostra a direção vertical.** Andando na diagonal, o empate de magnitude resolve para north/south. É a regra fixa do `facing`; se preferir horizontal na diagonal, é uma linha em `_update_facing`.
- BUG-001 (largura da textura) foi **corrigido** pela troca do asset.
- **Godot 4.7.2 continua não validado.** O ambiente só tem 4.7.1 stable; procurei por 4.7.2 e não existe na máquina. DEC-001 não foi alterada e nada fora de 4.7 foi usado. Quem tiver 4.7.2 deve abrir o projeto uma vez e rodar as duas suítes.
- Movimento não foi testado com teclado físico por uma pessoa (ver acima).
- O mundo de teste é protótipo descartável, não arquitetura de mapa.
- Nenhum bug de código. BUG-001 está corrigido em `docs/BUGS.md`.

# Próxima tarefa

**FASE 4 — Primeira arma.** Não iniciada.

Hoje a partida não é vencível: o druida não tem como matar nada. É o buraco mais
óbvio do vertical slice.

Itens, na ordem do `docs/ROADMAP.md`:

1. criar `WeaponManager` no Player, sem comportamento de arma específica dentro dele (DEC-009);
2. Cajado da Floresta como primeira arma, com os dados em `Resource` (DEC-010);
3. targeting do inimigo mais próximo — **sem** busca global por frame por projétil (`docs/02_ARCHITECTURE.md`);
4. projétil sob `ProjectileContainer`, reaproveitando o `HitboxComponent` que já existe;
5. dano e cooldown;
6. criar `tests/test_phase4.gd`; manter as três suítes anteriores passando;
7. atualizar HANDOFF, CHANGELOG, TODO e ROADMAP.

As layers do ataque do jogador já estão decididas e são o espelho exato do que o
inimigo faz hoje (DEC-017): **layer 5 PlayerAttack (16), mask 8 EnemyHurtbox**.
Nenhuma camada nova precisa ser inventada.

O modo de **golpe único** do `HitboxComponent` já existe: `hit_interval = 0` faz
cada alvo levar dano uma vez só. Foi o raio que estreou, e é o que projétil,
explosão e área precisam. Não é preciso inventar nada novo para o dano.

Boa parte do caminho da arma também já está andada pelo raio: efeito que nasce,
acerta e some; alvo escolhido no instante do disparo; layers corretas. O que
falta é a **arquitetura**: `WeaponManager`, dados em `Resource`, nível e
cooldown por arma. Ao terminar, apagar o `RaioTeste`, o
`scripts/effects/lightning_caster.gd` e o `tests/test_raio.gd`.

## Critério de aceite da FASE 4

- a arma dispara sozinha, em cooldown;
- o projétil viaja com velocidade independente do FPS;
- o inimigo atingido perde vida e morre;
- nenhum projétil fica eterno na cena;
- nenhum projétil faz busca global de alvo por frame.

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
