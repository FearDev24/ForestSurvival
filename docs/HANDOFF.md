# HANDOFF

Última atualização: 2026-08-28

# Projeto

Forest Survival

# Stack

- Godot 4.7.2 stable (DEC-001)
- GDScript
- 2D top-down
- survivor-like
- Android como plataforma prioritária futura

# Estado atual

## Fase concluída

**FASE 0 — Fundação. Concluída.**

O projeto Godot existe, abre, roda e não apresenta erros estruturais.

## Documentação

Estrutura de documentação definida e atualizada.

Política de assets progressivos registrada (`DEC-013`) e detalhada em `docs/ASSET_WORKFLOW.md`.

## Código

- `project.godot` criado e válido;
- estrutura de pastas da arquitetura criada (pastas ainda vazias usam `.gitkeep`);
- `res://scenes/game/game.tscn` criada e definida como Main Scene;
- nenhum script de gameplay existe ainda — isso é esperado nesta fase;
- nenhum autoload registrado ainda (`autoload/` está vazia de propósito).

## Assets

Nenhum asset existe em nenhum estado (`PLACEHOLDER` / `CANDIDATE` / `APPROVED` / `INTEGRATED`).

# Última tarefa concluída

FASE 0 — Fundação.

## Arquivos criados

- `project.godot`
- `scenes/game/game.tscn`
- `tests/test_foundation.gd`
- `.gitkeep` nas pastas novas da estrutura

## Arquivos modificados

- `docs/ROADMAP.md` (FASE 0 marcada como concluída)
- `docs/DECISIONS.md` (DEC-014, DEC-015)
- `docs/HANDOFF.md`
- `docs/CHANGELOG.md`
- `docs/TODO.md`

## Configurações realizadas

### Janela

- viewport base `1280 × 720`, landscape;
- `stretch/mode = canvas_items`;
- `stretch/aspect = expand`;
- `handheld/orientation = 0` (landscape).

### Renderer

- `mobile` (Forward Mobile), filtro de textura Nearest, clear color verde-escuro. Ver DEC-015.

### Input Map

Todas as ações usam `physical_keycode` (funciona em layouts não-QWERTY):

| Ação | Teclas |
|---|---|
| `move_up` | W, ↑ |
| `move_down` | S, ↓ |
| `move_left` | A, ← |
| `move_right` | D, → |
| `pause` | Escape |

O gameplay **deve** consultar essas ações. Nunca ler teclas diretamente — isso permitirá plugar joystick virtual no Android sem reescrever o Player (`docs/ANDROID.md`).

### Physics layers 2D

Nomeadas em `project.godot` conforme DEC-014: 1 PlayerBody, 2 EnemyBody, 3 PlayerHurtbox, 4 EnemyHurtbox, 5 PlayerAttack, 6 EnemyAttack, 7 Pickup.

As *masks* por entidade ainda não existem — serão definidas ao criar Player e Enemy.

### Cena principal

```text
Game (Node2D)
├── World (Node2D)
├── EnemyContainer (Node2D)
├── ProjectileContainer (Node2D)
├── PickupContainer (Node2D)
├── EffectContainer (Node2D)
└── CanvasLayer (CanvasLayer)
```

Sem script e sem managers, de propósito.

# Testes executados

1. `godot --headless --path . --import` → concluiu sem erro (exit 0).
2. `godot --headless --path . --script res://tests/test_foundation.gd` → `FASE 0 OK — fundação validada.` (exit 0).
3. `godot --path . --quit-after 180 --resolution 1280x720` → main scene carregou com Vulkan / Forward Mobile, sem erro (exit 0).

## Resultado

Todos passaram. Debugger sem erros estruturais.

## Como repetir a validação

```
godot --headless --path . --script res://tests/test_foundation.gd
```

O script confere Main Scene, resolução, stretch, as 5 ações de input, as 7 physics layers e os nós de `game.tscn`. Sai com código 1 se algo regredir.

# Problemas conhecidos

- **Versão do Godot no ambiente de desenvolvimento local:** a máquina usada tinha apenas **Godot 4.7.1 stable** instalado, não 4.7.2. O `project.godot` declara `config/features = PackedStringArray("4.7", "Mobile")`, que é compatível com toda a linha 4.7, e a validação acima foi executada em 4.7.1. **A fundação ainda não foi verificada em 4.7.2.** DEC-001 permanece válida e não foi alterada. Quem tiver 4.7.2 instalado deve abrir o projeto uma vez e confirmar que não há avisos de migração.
- Nenhum bug de gameplay registrado (não há gameplay ainda).

# Próxima tarefa

**FASE 1 — Movimento e mundo.** Não iniciada.

Itens, na ordem do `docs/ROADMAP.md`:

1. criar `scenes/player/player.tscn` com raiz `Player (CharacterBody2D)` e a estrutura de `docs/02_ARCHITECTURE.md`: `Visual`, `CollisionShape2D`, `Hurtbox`, `PickupArea`, `WeaponManager`, `Camera2D` — criando apenas o que a fase exigir;
2. criar `scripts/player/player.gd` com movimento em 8 direções usando **somente** as ações `move_up` / `move_down` / `move_left` / `move_right`;
3. normalizar o vetor de input para que a diagonal não seja mais rápida;
4. usar `delta` para que a velocidade não dependa do FPS;
5. `Camera2D` seguindo o jogador;
6. sprite **placeholder** sob o nó `Visual`, conforme `docs/ASSET_WORKFLOW.md` — não criar arte final;
7. mapa placeholder e limites de mundo para teste;
8. instanciar o Player em `game.tscn` sob `World`;
9. testar conforme a seção "Movimento" de `docs/TEST_PLAN.md`;
10. atualizar HANDOFF, CHANGELOG, TODO e ROADMAP.

## Critério de aceite da FASE 1

- player se move nas 8 direções;
- diagonal não é mais rápida;
- velocidade independente do FPS;
- câmera acompanha corretamente;
- nenhum script de gameplay lê teclas diretamente;
- nenhum script de gameplay depende da textura do placeholder.

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

# Regra permanente de assets

Falta de sprite, animação ou efeito **não é bloqueio**. Use placeholder sob o nó `Visual`, mantenha gameplay desacoplado da arte e siga `docs/ASSET_WORKFLOW.md`.
