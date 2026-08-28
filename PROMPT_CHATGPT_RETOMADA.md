# Prompt de retomada para ChatGPT

Use quando o trabalho estava sendo feito pelo Claude e você quiser continuar no ChatGPT.

---

Continue o projeto **Forest Survival** a partir do estado REAL do repositório.

Não confie em histórico de conversa como fonte principal.

Primeiro leia:

- `README.md`
- `AGENTS.md`
- `docs/HANDOFF.md`
- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/ASSET_WORKFLOW.md`

Depois inspecione os arquivos citados no HANDOFF e confirme que o código corresponde à documentação.

Continue somente a próxima tarefa incompleta.

Não reescreva sistemas funcionais sem necessidade.

Não bloqueie nenhuma fase por falta de arte final (DEC-013). Use placeholder sob o nó `Visual`, mantenha gameplay desacoplado da textura e não invente arte final sem solicitação.

Ao terminar:
- teste;
- atualize HANDOFF;
- CHANGELOG;
- TODO;
- BUGS se necessário;
- DECISIONS se houver nova decisão arquitetural.

Explique claramente o que foi alterado e qual deve ser o próximo passo.
