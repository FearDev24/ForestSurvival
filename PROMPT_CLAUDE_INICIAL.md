# Prompt inicial para Claude

Copie e cole o texto abaixo no Claude após colocar esta documentação no repositório.

---

Você será o desenvolvedor principal temporário do projeto **Forest Survival**, um jogo 2D survivor-like feito em Godot 4.7.2 stable e GDScript.

IMPORTANTE: este projeto será alternado entre Claude, ChatGPT e possivelmente outros agentes. Portanto, o histórico desta conversa NÃO é a fonte de verdade.

Antes de alterar qualquer arquivo:

1. Leia `README.md`.
2. Leia `AGENTS.md`.
3. Leia `docs/HANDOFF.md`.
4. Leia `docs/DECISIONS.md`.
5. Leia `docs/ROADMAP.md`.
6. Leia `docs/00_MASTER_PLAN.md`.
7. Leia `docs/01_GAME_DESIGN.md`.
8. Leia `docs/02_ARCHITECTURE.md`.
9. Leia `docs/ASSET_WORKFLOW.md`.
10. Inspecione o conteúdo real do repositório.

Depois, execute SOMENTE a próxima etapa necessária da FASE 0 indicada em `docs/HANDOFF.md` e `docs/ROADMAP.md`.

Regras:

- Não pule direto para criar armas, inimigos ou conteúdo.
- Não reestruture documentação sem necessidade.
- Não use C#.
- Não adicione backend.
- Não adicione serviços pagos.
- Não adicione plugins externos sem necessidade.
- Não faça uma cópia literal de Vampire Survivors; este é um survivor-like original.
- Faça mudanças pequenas e testáveis.
- Preserve compatibilidade futura com Android.
- Não crie abstrações complexas prematuramente.
- Se já existir código, leia antes de substituir.
- Se encontrar conflito entre código e documentação, registre claramente.
- Não bloqueie nenhuma fase por falta de arte final (DEC-013).
- Use placeholder quando não houver sprite, deixando claro que é placeholder.
- Não invente nem redesenhe arte final sem solicitação explícita.
- Mantenha sprites sob um nó `Visual` substituível e gameplay desacoplado da textura.

Ao terminar:

1. valide que o projeto abre/roda;
2. atualize `docs/HANDOFF.md`;
3. atualize `docs/CHANGELOG.md`;
4. atualize `docs/TODO.md`;
5. atualize `docs/BUGS.md` se encontrar problemas;
6. atualize `docs/DECISIONS.md` se uma decisão estrutural nova for tomada.

No final da sua resposta, informe:
- o que foi feito;
- arquivos alterados;
- testes executados;
- resultado;
- próxima tarefa exata;
- commit sugerido.
