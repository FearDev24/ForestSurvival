# Registro de Decisões

## DEC-001 — Engine

**Decisão:** Godot 4.7.2 stable.

**Motivo:** versão estável atual no início formal do projeto.

Não usar builds `dev` no branch principal.

---

## DEC-002 — Linguagem

**Decisão:** GDScript.

Não migrar para C# sem razão técnica comprovada e autorização.

---

## DEC-003 — Gênero

**Decisão:** survivor-like original inspirado na estrutura do gênero.

Não criar clone de conteúdo de Vampire Survivors.

---

## DEC-004 — Protagonista

**Decisão:** druida guardião da floresta contra invasões demoníacas.

---

## DEC-005 — Plataforma

**Decisão:** desenvolver primeiro no PC, tendo Android/Google Play como plataforma prioritária de publicação.

---

## DEC-006 — Backend

**Decisão:** nenhum backend no MVP.

Arquitetura offline-first.

---

## DEC-007 — Custos

**Decisão:** evitar serviços externos pagos e custos recorrentes.

---

## DEC-008 — Movimento de inimigos

**Decisão:** começar com perseguição direta simples.

Não utilizar NavigationAgent2D individual para hordas comuns sem necessidade comprovada.

---

## DEC-009 — Armas

**Decisão:** Player não deve conter a implementação de armas específicas.

Usar `WeaponManager` + comportamento de cada arma.

---

## DEC-010 — Conteúdo orientado a dados

**Decisão:** usar Resources para conteúdo repetitivo/configurável quando isso reduzir duplicação.

---

## DEC-011 — Performance

**Decisão:** decisões devem considerar centenas de unidades e hardware mobile.

Otimização deve ser guiada por profiling, não por suposições.

---

## DEC-012 — Handoff entre IAs

**Decisão:** `docs/HANDOFF.md` é o ponto oficial de retomada.

Claude, ChatGPT e outros assistentes devem atualizá-lo ao terminar blocos de trabalho.

---

## DEC-013 — Desenvolvimento independente de arte final

**Decisão:** sprites, animações, efeitos e demais assets finais serão adicionados progressivamente durante o desenvolvimento. A ausência de arte final não bloqueia nenhuma fase de programação.

**Motivo:** a produção de arte tem ritmo próprio e não pode travar a validação de gameplay. Gameplay e camada visual são trilhas paralelas.

Regras derivadas:

1. Placeholders são permitidos durante prototipagem.
2. Placeholder não é asset final.
3. IA não deve inventar nem redesenhar arte final sem solicitação explícita.
4. Gameplay e camada visual devem permanecer desacoplados.
5. Sprites ficam sob uma camada/nó visual substituível (`Visual`) quando apropriado.
6. Movimento, HP, IA, combate, XP e armas não dependem da textura provisória.
7. `CollisionShape` / `Hurtbox` / `Hitbox` são configurados separadamente da arte sempre que possível.
8. Sprites e animações podem chegar gradualmente.
9. A falta de `idle`/`walk` de alguma direção deve permitir fallback temporário, sem erro em runtime.
10. Um asset só é oficial após aprovação do responsável pelo projeto.
11. A entrada de um asset aprovado não pode exigir reescrita de sistemas de gameplay.

Estados oficiais: `PLACEHOLDER` → `CANDIDATE` → `APPROVED` → `INTEGRATED`.

Fluxo detalhado em `docs/ASSET_WORKFLOW.md`.

---

## DEC-014 — Numeração final das physics layers 2D

**Decisão:** as camadas de física 2D ficam fixadas assim, nomeadas em `project.godot`:

| # | Nome |
|---|---|
| 1 | PlayerBody |
| 2 | EnemyBody |
| 3 | PlayerHurtbox |
| 4 | EnemyHurtbox |
| 5 | PlayerAttack |
| 6 | EnemyAttack |
| 7 | Pickup |

**Motivo:** `docs/02_ARCHITECTURE.md` exigia registrar a numeração definitiva após a implementação. A ordem planejada foi mantida sem alteração.

Renumerar uma camada existente quebra cenas já configuradas. Camadas novas devem ser acrescentadas a partir da 8, nunca inseridas no meio.

As *masks* de cada entidade não fazem parte desta decisão: são definidas por nó quando Player, Enemy, projéteis e pickups forem criados.

---

## DEC-015 — Renderer e modo de stretch

**Decisão:**

- `renderer/rendering_method = "mobile"` (Forward Mobile) também no desenvolvimento em PC;
- viewport base `1280 × 720`, landscape;
- `stretch/mode = "canvas_items"` e `stretch/aspect = "expand"`;
- `textures/canvas_textures/default_texture_filter = 0` (Nearest).

**Motivo:**

- Android é a plataforma prioritária de publicação (DEC-005). Desenvolver no mesmo renderer da plataforma alvo evita descobrir incompatibilidades de shader e de features só no fim;
- `canvas_items` + `expand` mantém a escala da UI e mostra mais mundo em telas mais largas, em vez de distorcer ou adicionar barras — necessário pela variedade de proporções de tela em Android;
- filtro Nearest preserva a leitura de pixel art (`docs/05_ART_DIRECTION.md`).

Mudar para Forward+ ou Compatibility exige nova decisão registrada.

---

## DEC-016 — Layer 8: WorldStatic

**Decisão:** a geometria estática do mundo (paredes, obstáculos, bloqueios de cenário) usa a **layer 8 — WorldStatic**.

**Motivo:** as sete camadas de DEC-014 cobrem apenas entidades (corpos, hurtboxes, ataques, pickups). Nenhuma delas descreve cenário. A FASE 1 precisou de paredes de borda, e DEC-014 determina que camadas novas sejam acrescentadas a partir da 8, nunca inseridas no meio.

Configuração resultante nesta fase:

| Nó | `collision_layer` | `collision_mask` |
|---|---|---|
| `Player` | 1 (PlayerBody) | 128 (WorldStatic) |
| paredes do `TestWorld` | 128 (WorldStatic) | 0 |

A mask do Player é deliberadamente mínima: só o necessário para ser barrado pelo cenário. Inimigos, hurtboxes e pickups entram nas masks quando esses sistemas existirem — não antes.

A camada é conceitual e não depende do mapa de protótipo: o mapa definitivo, quando existir, usa a mesma layer 8.

---

## DEC-017 — Fluxo de dano: a hitbox procura, a hurtbox espera

**Decisão:** no fluxo `Hitbox -> Hurtbox -> HealthComponent -> morte`
(`docs/03_SYSTEMS.md` §4), quem detecta é sempre a **hitbox**:

- `HitboxComponent`: `monitoring = true`, `monitorable = false`;
- `HurtboxComponent`: `monitoring = false`, `monitorable = true`, `collision_mask = 0`.

A hurtbox nunca procura ninguém e não roda lógica por frame. Ela só expõe
`take_damage()`, que é o único ponto de entrada de dano de uma entidade.

**Motivo:** com centenas de inimigos em tela (DEC-011), o custo tem de ficar do
lado de quem ataca, que é sempre em menor número. Se cada inimigo ficasse
varrendo o mundo à procura de ataques, o custo cresceria com a horda.

Decisões derivadas, no mesmo espírito:

1. **Intervalo entre golpes por delta acumulado, não por `Timer`.** Um nó
   `Timer` por hitbox seria centenas de nós de processamento
   (`docs/02_ARCHITECTURE.md`, "Evitar"). O `hit_interval` é contado em
   `_physics_process`.
2. **`_physics_process` desligado quando não há sobreposição.** Um inimigo
   perseguindo do outro lado do mapa não paga nada; só quem está encostando
   processa.
3. **A morte acontece uma única vez.** O guarda fica no `HealthComponent`, não
   em cada entidade: dois golpes letais no mesmo frame emitem `died` uma vez só.
   É isso que impede XP dobrado e `queue_free()` duplo.

**Masks resultantes na FASE 2:**

| Nó | `collision_layer` | `collision_mask` |
|---|---|---|
| `Player` | 1 — PlayerBody | 2 (EnemyBody) + 128 (WorldStatic) = 130 |
| `Player/Hurtbox` | 4 — PlayerHurtbox | 0 |
| `Enemy` | 2 — EnemyBody | 1 (PlayerBody) + 128 (WorldStatic) = 129 |
| `Enemy/Hitbox` | 32 — EnemyAttack | 4 (PlayerHurtbox) |
| `Enemy/Hurtbox` | 8 — EnemyHurtbox | 0 |

As armas do jogador, na FASE 4, entram como layer 16 (PlayerAttack) com mask 8
(EnemyHurtbox) — o espelho exato disto, sem inventar camada nova.

---

## DEC-018 — Inimigo colide com inimigo, nunca com o Player

**Decisão:** o corpo do inimigo (`CollisionShape2D` de `Enemy`) serve para
separar inimigos entre si e para ser barrado pelo cenário. Ele **não** colide
com o corpo do Player.

| Nó | `collision_layer` | `collision_mask` |
|---|---|---|
| `Player` | 1 — PlayerBody | 128 (WorldStatic) |
| `Enemy` | 2 — EnemyBody | 2 (EnemyBody) + 128 (WorldStatic) = 130 |

Consequências:

1. **Inimigos não se empilham.** Sem isso, uma horda inteira ocupa o mesmo
   ponto e vira uma sprite só — ilegível.
2. **O Player atravessa a horda.** Ele pode escapar passando por dentro dos
   inimigos, e leva dano por contato ao fazer isso — dano, não empurrão.
3. **Ninguém empurra o Player.** Em um survivor-like, dezenas de corpos
   empurrando o jogador tiram o controle dele das mãos do jogador.

**Motivo:** fuga é a mecânica central do gênero. Se a horda barrasse o
movimento, cercar o jogador seria morte certa por bloqueio, não por dano — e o
jogador perderia sem poder reagir.

O dano continua vindo por `Hitbox` -> `Hurtbox` (DEC-017), que é `Area2D` e não
depende de colisão de corpo nenhuma.

**Raio do corpo do inimigo:** 14 px, o mesmo do Player, apesar de o diabrete ser
menor. O raio aqui não representa "o tamanho do bicho": ele define **o espaço
que um inimigo reserva na horda**, e foi escolhido a partir da largura visível
da sprite (24 a 30 px em escala 0.5) para que duas sprites vizinhas encostem sem
se sobrepor. Reexportar a arte em 32 x 48 não muda este número, porque o tamanho
na tela é o mesmo.

Isto não contradiz a regra 7 do `ASSET_WORKFLOW` ("colisão é dado de gameplay,
não consequência do sprite"): o critério continua sendo de jogo — leitura da
horda —, e não "o desenho tem tantos pixels".

---

## DEC-019 — `idle` só para o druida

**Decisão:** apenas o druida terá animação de `idle`. Inimigos e demais
personagens recebem somente `walk` nas quatro direções.

Parados, eles congelam no **primeiro frame do `walk` da direção que encaram** —
que é exatamente o que a camada visual já faz hoje, pelo passo 2 da cadeia de
fallback (`docs/ASSET_WORKFLOW.md`, regra 9).

**Motivo:** decisão do responsável pelo projeto. Em um survivor-like, o inimigo
está praticamente sempre em movimento: ele nasce fora da tela e caminha até o
jogador. `idle` de inimigo seria arte produzida para um estado que quase não
aparece.

Consequências:

1. **A falta de `idle` em inimigo deixa de ser pendência.** Não deve mais
   aparecer em `docs/TODO.md`, nem como ressalva no HANDOFF.
2. **A cadeia de fallback continua como está.** `enemy_visual.gd` segue tentando
   `idle_<direção>` antes de `walk_<direção>`: não custa nada, não gera erro, e
   mantém a porta aberta caso um inimigo específico (um boss, por exemplo) um dia
   ganhe pose parada.
3. **Nenhum script de gameplay muda.** A lógica informa "estou parado"; o que a
   camada visual faz com isso é problema dela (DEC-013).

---

## DEC-020 — Mapa: tileset de cantos, borda fora da área jogável, props sólidos

**Decisão:** o mapa é montado a partir de três coisas separadas, com papéis que
não se misturam.

### 1. Chão: tileset de **cantos**

As folhas de tiles são conjuntos completos de 16 peças, uma para cada combinação
de terreno nos quatro cantos da célula. O `TileSet` declara isso como terrain set
em modo `MATCH_CORNERS`, com três terrenos: 0 Terra, 1 Mata, 2 Água.

O preenchimento automático amostra ruído **nos cantos** das células, nunca no
centro: é o canto que as peças casam, então dois vizinhos sempre concordam sobre
o canto que dividem e a transição nunca quebra.

Escolher peça por densidade, ignorando os cantos, produz um labirinto de cercas.
Isso foi testado e descartado — não é questão de gosto.

### 2. Borda: vegetação **fora** da área jogável

`get_bounds()` é a área jogável: paredes físicas e spawn de inimigos usam ela.
`get_camera_bounds()` é ela mais a faixa de vegetação que fecha o mapa, e é o que
a câmera enquadra.

Separar os dois é obrigatório. Com um retângulo só, ou o inimigo nasce dentro da
parede, ou a mata da borda fica cortada fora da tela.

### 3. Props: obstáculo é **pegada**, não silhueta

Objetos sólidos (toco, tronco, pedra, rocha, espinheiro) têm colisão na layer 8
WorldStatic, a mesma das paredes (DEC-016). A forma é uma cápsula na **base** do
desenho: um toco alto não pode barrar quem passa atrás dele.

Mato baixo — samambaia, capim, cogumelo — não tem colisão. Barrar o caminho com
vegetação rasteira irrita mais do que ajuda.

Cada peça reserva espaço no chão e nada nasce dentro do espaço de ninguém: duas
árvores não crescem no mesmo lugar. Mato pode encostar em mato; qualquer coisa
envolvendo tronco ou pedra exige o espaço inteiro.

**Consequência que precisa de atenção:** os inimigos também colidem com a
layer 8, e a perseguição deles é direta, sem pathfinding (DEC-008). Eles raspam e
podem prender nos obstáculos. Se isso virar problema com a horda cheia, a saída é
os props só barrarem o Player — mas aí deixam de ser obstáculo de verdade.

---

## DEC-021 — Um único efeito de habilidade, com dois modos de disparo

**Decisão:** raio e vinha — e o que vier — usam o **mesmo** script de efeito
(`AbilityEffect`) e o **mesmo** disparador, configurado por export.

O efeito faz três coisas: toca a animação uma vez, liga a hitbox no frame em que
o golpe encosta, e se libera no fim. O disparador escolhe alvo e posição.

Dois exports cobrem a diferença entre as habilidades existentes:

| | raio | vinha |
|---|---|---|
| `spawn_on_target` | `true` — cai em cima do inimigo | `false` — nasce no druida |
| `aim_at_target` | `false` — não tem direção | `true` — gira para o alvo |

**Motivo:** o primeiro script chamava-se `lightning_strike.gd` e descrevia um
comportamento genérico com nome de uma habilidade só. Duas habilidades depois, o
nome mentia. Um segundo script de disparo seria duplicação de andaime.

**Sobre girar o efeito:** a arte é desenhada apontando para a direita. Girar o nó
resolve direção e hitbox de uma vez. Passando de 90°, o desenho ficaria de cabeça
para baixo, e aí o espelho vertical entra **na sprite**, não no nó — espelhar o
nó inverteria a colisão junto e a Godot reclama de escala negativa em forma de
colisão.

**A hitbox de habilidade direcional fica sobre o eixo do golpe.** Deslocá-la para
acompanhar a arte faz o ataque errar quando o efeito gira: o deslocamento vertical
vira deslocamento lateral. Isso custou um bug medido — dano zero para cima e para
a esquerda.

Tudo isto é andaime até a FASE 4. Quando o `WeaponManager` existir (DEC-009), o
efeito vira o "ataque" de uma arma e os disparadores somem.

---

## DEC-022 — Habilidade aponta só na horizontal, e a vinha brota do chão

**Decisão:** habilidade com direção aponta para a **esquerda ou para a direita**,
nunca na diagonal nem na vertical. O alvo decide apenas o lado.

**Motivo:** a arte é desenhada de lado. Girada num ângulo qualquer, ela denuncia
que é um desenho girado — a rosa fica tombada, a sombra aponta para o lugar
errado, a leitura de "coisa apoiada no chão" se perde. Restringir ao horizontal
custa precisão de mira e devolve coerência visual, que é a troca certa num jogo
onde o combate é automático e o jogador não mira.

**Decisão:** a vinha **não sai do corpo do druida**. Ela brota da terra num
ponto sorteado dentro de um anel em volta dele.

**Motivo:** o druida é um invocador, não um lutador corpo a corpo. Vinha saindo
do corpo dele lê como golpe físico; brotando do chão em volta, lê como magia de
natureza — que é a identidade do personagem (DEC-004).

Os dois viraram campos de `WeaponData`, não regras no código do ataque:

| Campo | Valores |
|---|---|
| `spawn_mode` | `NO_ALVO`, `NO_DRUIDA`, `EM_VOLTA` |
| `spawn_radius` | raio do anel, usado por `EM_VOLTA` |
| `aim_mode` | `NENHUMA`, `PARA_O_ALVO`, `HORIZONTAL` |

`PARA_O_ALVO` continua existindo, mas nenhuma arma usa. Fica para o dia em que
houver arte desenhada para girar — um projétil radial, por exemplo.

---

## DEC-023 — Arte do HUD sai pronta no tamanho de tela, e com filtro Linear

**Decisão:** as texturas das barras de vida e de XP são geradas por
`tools/preparar_barras_hud.py` **já na largura em que aparecem na tela**
(1040 px a de XP, 620 px a de vida), e os nós `TextureProgressBar` usam
`texture_filter = LINEAR`, não o Nearest padrão do projeto.

**Motivo, o tamanho:** `TextureProgressBar` usa o tamanho da textura como
**tamanho mínimo do controle**. Uma textura maior que o tamanho desejado não tem
como ser encolhida pelo `size` — o controle simplesmente cresce até caber nela.
A arte bruta tem cerca de 1700 a 2000 px de largura, ou seja, não caberia. Ou se
reduz antes, ou se recorre a `scale` no nó, que quebra o alinhamento por âncoras.
Reduzir antes, com Lanczos, ainda dá o melhor resultado dos dois.

**Motivo, o filtro:** essa arte não é pixel art. É ilustração com gradiente,
musgo e pedra. Reduzida ou ampliada com Nearest, serrilha. É uma exceção
consciente à DEC-015, **limitada ao HUD**: as sprites do jogo continuam Nearest.

**Consequência:** mudar o tamanho do HUD é mudar `LARGURA_EM_TELA` no script e
rodar de novo, não arrastar o nó no editor. Está escrito no cabeçalho do script e
na descrição dos nós.

**Consequência:** a arte bruta fica em `assets/_raw/`, fora do que a Godot
importa, e é a única cópia com a resolução original. O que está em `assets/ui/` é
derivado e pode ser regerado.
