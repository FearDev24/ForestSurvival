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
