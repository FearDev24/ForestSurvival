# Prompt para aplicar a política de assets progressivos no repositório

Use este prompt se a documentação inicial já estiver no GitHub.

---

Antes de programar gameplay, atualize a documentação do Forest Survival para registrar oficialmente a seguinte política:

**Sprites, animações, efeitos e demais assets finais serão adicionados progressivamente durante o desenvolvimento. A ausência de arte final não deve bloquear nenhuma fase de programação.**

Leia primeiro:
- README.md
- AGENTS.md
- CLAUDE.md
- docs/HANDOFF.md
- docs/DECISIONS.md
- docs/02_ARCHITECTURE.md
- docs/05_ART_DIRECTION.md
- docs/ROADMAP.md

Depois faça somente uma atualização de documentação, sem iniciar a Fase 1.

A política deve estabelecer obrigatoriamente:

1. Placeholders são permitidos durante prototipagem.
2. Placeholder não é asset final.
3. Claude não deve inventar/redesenhar arte final sem solicitação.
4. Gameplay e camada visual devem permanecer desacoplados.
5. Sprites devem ficar sob uma camada/nó visual substituível quando apropriado.
6. Movimento, HP, IA, combate, XP e armas não devem depender da textura provisória.
7. CollisionShape/Hurtbox/Hitbox devem ser configurados separadamente da arte sempre que possível.
8. Sprites e animações poderão chegar gradualmente.
9. A falta de `idle/walk` de alguma direção deve permitir fallback temporário.
10. Um asset só é considerado oficial após aprovação.
11. Quando um asset aprovado entrar, deve ser possível integrá-lo sem reescrever sistemas de gameplay.

Crie também:

`docs/ASSET_WORKFLOW.md`

Ele deve documentar os estados:

- PLACEHOLDER
- CANDIDATE
- APPROVED
- INTEGRATED

E o fluxo:

placeholder
→ sistema funcional
→ asset aprovado
→ integração visual
→ animação/offset/escala
→ colisão
→ teste

Registre uma nova decisão:

`DEC-013 — Desenvolvimento independente de arte final`

Atualize:
- README.md
- AGENTS.md
- docs/02_ARCHITECTURE.md
- docs/05_ART_DIRECTION.md
- docs/DECISIONS.md
- docs/HANDOFF.md
- docs/CHANGELOG.md
- PROMPT_CLAUDE_INICIAL.md, se existir
- PROMPT_CHATGPT_RETOMADA.md, se existir

Não altere gameplay.
Não crie sprites.
Não comece Player.
Não avance o ROADMAP nesta tarefa.

Ao terminar, me mostre:
- arquivos alterados;
- resumo das mudanças;
- confirmação de que DEC-013 foi registrada;
- confirmação de que ASSET_WORKFLOW.md foi criado;
- commit sugerido.

Commit sugerido:

docs: define fluxo progressivo de sprites e assets
