# AGENTS.md — Protocolo universal para assistentes de IA

Este projeto pode ser desenvolvido por Claude, ChatGPT, Codex ou outro assistente.

## Prioridade

Sempre preservar continuidade, funcionamento e legibilidade.

## Antes de qualquer alteração

Leia:

1. `README.md`
2. `docs/HANDOFF.md`
3. `docs/DECISIONS.md`
4. `docs/ROADMAP.md`
5. `docs/ASSET_WORKFLOW.md` quando a tarefa envolver sprites, animações ou efeitos
6. arquivo de documentação do sistema relacionado
7. arquivos de código afetados

## Regras

- Godot 4.7.2 stable.
- GDScript.
- Não migrar de engine.
- Não migrar para C# sem decisão registrada.
- Não adicionar serviços pagos sem autorização.
- Não adicionar multiplayer no MVP.
- Não adicionar backend no MVP.
- Não reescrever sistema funcional apenas por preferência de estilo.
- Evitar dependências externas quando a Godot puder resolver.
- Preferir componentes reutilizáveis.
- Preferir dados em `Resource` quando houver muitas variantes.
- Evitar acoplamento entre Player e armas específicas.
- Evitar lógica pesada por inimigo a cada frame.
- Pensar desde o início em centenas de inimigos e Android.
- Não fazer alterações fora do escopo da tarefa sem necessidade.
- Nunca apagar assets ou arquivos aparentemente não usados sem confirmação por busca no projeto.
- Nunca bloquear ou adiar programação por falta de arte final (DEC-013).
- Usar placeholder quando a arte final não existir, deixando claro que é placeholder.
- Não inventar, gerar ou redesenhar arte final sem solicitação explícita.
- Manter sprites sob um nó `Visual` substituível.
- Não fazer gameplay depender de textura, tamanho de sprite ou frame de animação.
- Configurar `CollisionShape`/`Hurtbox`/`Hitbox` separadamente da arte.
- Prever fallback quando faltar `idle`/`walk` de alguma direção, sem erro em runtime.

## Tamanho das mudanças

Preferir tarefas pequenas e verificáveis.

Cada tarefa deve ter:
- objetivo;
- arquivos alterados;
- critério de aceite;
- teste;
- atualização de documentação.

## Ao concluir uma tarefa

Atualizar:

- `docs/HANDOFF.md`
- `docs/CHANGELOG.md`
- `docs/TODO.md`
- `docs/BUGS.md` quando aplicável
- `docs/DECISIONS.md` quando houver decisão arquitetural
- `docs/ASSET_WORKFLOW.md` quando o estado de algum asset mudar

## Commit recomendado

Formato:

`tipo: descrição curta`

Exemplos:

- `feat: adiciona movimento do jogador`
- `feat: adiciona spawn básico de inimigos`
- `fix: corrige level up duplicado`
- `refactor: separa weapon manager do player`
- `docs: atualiza handoff da fase 1`

## Proibição de "memória oculta"

Se uma decisão importante existe apenas na conversa, registrá-la nos documentos antes de depender dela.
