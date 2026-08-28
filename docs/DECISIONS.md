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
