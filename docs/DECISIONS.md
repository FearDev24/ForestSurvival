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
