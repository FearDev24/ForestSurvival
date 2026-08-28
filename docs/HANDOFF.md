# HANDOFF

Última atualização: 2026-08-28

# Projeto

Forest Survival

# Stack

- Godot 4.7.2 stable
- GDScript
- 2D top-down
- survivor-like
- Android como plataforma prioritária futura

# Estado atual

## Documentação

Estrutura inicial de documentação definida.

Política de assets progressivos registrada (`DEC-013`) e detalhada em `docs/ASSET_WORKFLOW.md`.

Nenhum asset existe ainda em nenhum estado (`PLACEHOLDER`/`CANDIDATE`/`APPROVED`/`INTEGRATED`).

## Código

Ainda não validado por este handoff.

O próximo assistente deve inspecionar o repositório antes de presumir que `project.godot` ou cenas já existem.

# Última tarefa concluída

Registro da política de assets progressivos: criação de `docs/ASSET_WORKFLOW.md`, registro de `DEC-013` e atualização de README, AGENTS, arquitetura, direção de arte, changelog e prompts.

Nenhuma alteração de gameplay foi feita. A FASE 1 não foi iniciada.

# Tarefa atual

FASE 0 — Fundação.

# Próxima tarefa

1. Inspecionar conteúdo real do repositório.
2. Criar ou validar projeto Godot 4.7.2.
3. Criar estrutura mínima de pastas.
4. Configurar Input Map.
5. Criar `game.tscn`.
6. Executar projeto vazio sem erros.
7. Atualizar este HANDOFF.

# Regra permanente de assets

Falta de sprite, animação ou efeito **não é bloqueio**. Use placeholder sob o nó `Visual`, mantenha gameplay desacoplado da arte e siga `docs/ASSET_WORKFLOW.md`.

# Critério de aceite

- projeto abre no Godot;
- F6/F5 não produz erro estrutural;
- estrutura inicial está versionada;
- documentação permanece intacta.

# Arquivos esperados após FASE 0

- `project.godot`
- `scenes/game/game.tscn`
- diretórios definidos em arquitetura
- `.gitignore`

# Bugs conhecidos

Nenhum bug de gameplay registrado ainda.

# Bloqueios

O repositório fornecido não estava acessível publicamente durante a preparação desta documentação. Pode estar privado ou ainda não disponível para indexação.

# Não alterar sem registrar decisão

- Godot 4.7.2 stable
- GDScript
- survivor-like original
- protagonista druida
- offline-first
- sem serviços pagos no MVP
- arquitetura preparada para mobile
- desenvolvimento independente de arte final (DEC-013 / `docs/ASSET_WORKFLOW.md`)
