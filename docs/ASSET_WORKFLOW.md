# ASSET WORKFLOW — Fluxo progressivo de sprites e assets

Documento oficial da política de assets do Forest Survival.

Referência de decisão: `DEC-013 — Desenvolvimento independente de arte final` em `docs/DECISIONS.md`.

# Princípio central

**Sprites, animações, efeitos e demais assets finais serão adicionados progressivamente durante o desenvolvimento. A ausência de arte final não deve bloquear nenhuma fase de programação.**

Programação de gameplay e produção de arte são trilhas paralelas.

Nenhuma fase do `docs/ROADMAP.md` pode ser adiada, marcada como bloqueada ou considerada incompleta apenas porque a arte definitiva ainda não existe.

# Regras obrigatórias

1. **Placeholders são permitidos durante prototipagem.** Retângulos coloridos, `ColorRect`, `Polygon2D`, ícones internos da Godot ou sprites temporários são aceitáveis para validar sistemas.
2. **Placeholder não é asset final.** Nenhum placeholder pode ser tratado como arte aprovada, nem apresentado como entrega visual.
3. **Claude (ou qualquer IA) não deve inventar nem redesenhar arte final sem solicitação explícita.** Gerar, substituir ou "melhorar" arte por iniciativa própria é proibido.
4. **Gameplay e camada visual devem permanecer desacoplados.** A lógica nunca lê estado a partir da textura, do tamanho do sprite ou do frame atual da animação.
5. **Sprites devem ficar sob uma camada/nó visual substituível quando apropriado** — por convenção, o nó `Visual` de cada entidade (ver `docs/02_ARCHITECTURE.md`).
6. **Movimento, HP, IA, combate, XP e armas não devem depender da textura provisória.** Trocar a textura não pode alterar comportamento, dano, velocidade ou alcance.
7. **CollisionShape / Hurtbox / Hitbox devem ser configurados separadamente da arte sempre que possível.** Colisão é dado de gameplay, não consequência do sprite.
8. **Sprites e animações poderão chegar gradualmente.** Uma direção, uma animação ou um inimigo por vez é um fluxo válido.
9. **A falta de `idle`/`walk` de alguma direção deve permitir fallback temporário** — por exemplo: espelhar a direção oposta, reutilizar a direção sul, ou manter o frame de `idle` enquanto `walk` não existe. O fallback não pode gerar erro em runtime.
10. **Um asset só é considerado oficial após aprovação** do responsável pelo projeto.
11. **Quando um asset aprovado entrar, deve ser possível integrá-lo sem reescrever sistemas de gameplay.** Se a integração exigir alterar lógica, o acoplamento é um defeito de arquitetura e deve ser corrigido antes.

# Estados de um asset

Todo asset percorre quatro estados.

## PLACEHOLDER

- Provisório, criado apenas para destravar a programação.
- Pode ser forma geométrica, cor sólida ou sprite temporário.
- Não representa a direção de arte definida em `docs/05_ART_DIRECTION.md`.
- Pode ser descartado a qualquer momento sem aviso.

## CANDIDATE

- Arte proposta para o projeto, ainda não aprovada.
- Pode ser testada no jogo para avaliar leitura, escala e contraste.
- Não deve ser usada como base para ajustes definitivos de offset, escala ou colisão.
- Não pode ser divulgada como arte oficial.

## APPROVED

- Aprovada explicitamente pelo responsável pelo projeto.
- É arte oficial, mas ainda não necessariamente presente no jogo.
- Origem e licença devem estar registradas quando o asset não tiver sido produzido para o projeto (ver `docs/05_ART_DIRECTION.md` e o futuro `docs/ASSET_LICENSES.md`).

## INTEGRATED

- Asset aprovado já presente na cena, com escala, offset, animação e colisão ajustados.
- Testado em jogo.
- Registrado em `docs/CHANGELOG.md`.

# Fluxo

```text
placeholder
  → sistema funcional
    → asset aprovado
      → integração visual
        → animação / offset / escala
          → colisão
            → teste
```

Detalhamento de cada etapa:

1. **placeholder** — cria-se a representação mínima sob o nó `Visual`.
2. **sistema funcional** — o comportamento é implementado e validado com o placeholder. Esta etapa encerra a dependência de arte.
3. **asset aprovado** — a arte passa de `CANDIDATE` para `APPROVED` por decisão do responsável.
4. **integração visual** — o asset substitui o placeholder dentro do nó `Visual`. Nenhum script de gameplay deve mudar.
5. **animação / offset / escala** — ajustes de `AnimatedSprite2D`/`AnimationPlayer`, ponto de origem, alinhamento de baseline e escala.
6. **colisão** — revisão de `CollisionShape2D`, `Hurtbox` e `Hitbox`. A colisão é ajustada por critério de gameplay, e só então conferida contra a nova silhueta.
7. **teste** — execução em jogo, verificação de leitura em resolução mobile e registro no `CHANGELOG`.

# Convenções técnicas

- Toda entidade visível expõe um nó `Visual` como único ponto de troca de arte.
- Scripts de gameplay não referenciam `texture`, `sprite_frames` ou nomes de animação fora da camada visual, quando isso puder ser evitado.
- Trocar animação deve ser um pedido à camada visual (ex.: "estou andando para o sul"), não uma decisão da lógica de movimento.
- Uma animação ausente deve resultar em fallback silencioso, nunca em erro.
- Placeholders ficam sob `assets/` seguindo a mesma estrutura da arte final, para que a substituição seja direta.

# Como registrar o estado dos assets

Enquanto não houver um inventário dedicado, o estado de cada asset relevante deve ser mencionado em `docs/HANDOFF.md` na seção de estado atual, e a promoção para `INTEGRATED` registrada em `docs/CHANGELOG.md`.
