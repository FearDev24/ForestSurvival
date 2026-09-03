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

# Limpeza de resíduo de chroma key

Os sheets vindos do SpriteForge AI são recortados sobre fundo verde
(`settings.despill.hex`, por volta de `#11D121`). Mesmo depois de limpar o
fundo, sobra um contorno de pixels esverdeados semitransparentes em volta da
silhueta, mais alguns pontos de spill dentro dela. Sobre o chão escuro quase não
aparece; sobre fundo claro vira um halo verde.

Isto é **limpeza técnica de resíduo**, não redesenho: nenhum pixel de arte é
inventado, recolorido de forma criativa ou substituído. Continua valendo a regra
3 (IA não inventa nem redesenha arte).

Procedimento aplicado (feito no diabrete, 2026-08-29):

1. **remoção da franja** — pixel com `verde > max(vermelho, azul) + 3` **e**
   `alpha <= 200` tem o alpha zerado. Só atinge borda semitransparente, que é
   onde o chroma sobra;
2. **despill do que ficou** — nos pixels mantidos, `verde` é limitado a
   `max(vermelho, azul)`, removendo o tingimento sem mexer na luminância;
3. **verificação** — nenhum pixel com componente verde dominante pode restar, e
   nenhuma ilha de pixels soltos pode aparecer ou sumir.

Antes de sobrescrever, o PNG original é copiado para uma pasta `_raw/` ao lado,
com `.gdignore`, no mesmo espírito de `assets/characters/frames/`. Nada é
apagado.

O passo 2 só é seguro em arte **sem verde legítimo**. Na morte do druida (manto
verde), no `gameover` (folhas) e no raio, **só o passo 1 foi aplicado**: a franja
some e o interior não é tocado. Vale a regra: se a peça tem verde de verdade,
remove-se a franja e não se faz despill.

# Chroma magenta e contorno roxo

Os props de cenário vieram sobre magenta (`#FF00FF`), como o prompt pedia. A
remoção é a mesma ideia do verde, mas apareceu um problema a mais: o **contorno
escuro do desenho foi antisserrilhado contra o magenta e virou roxo**, inclusive
em pixels totalmente opacos — 3.603 deles nos oito objetos.

Regra usada: onde vermelho **e** azul estão acima do verde, os dois são
puxados para o nível do verde. Isso devolve o contorno quase preto original.

Só vale em arte sem roxo legítimo — madeira, pedra, folha e cogumelo verde
passam; um objeto roxo de verdade exigiria outra abordagem.

# De vídeo para sprite sheet

A morte do druida veio como vídeo (720 x 1280, 24 fps, 10 s, fundo verde). O
caminho até a folha de sprites, na ordem:

1. **chroma por distância da cor de fundo**, não por "verde dominante": o manto
   do druida é verde e seria comido por uma regra de dominância;
2. **remoção da decoração fixa do fundo** — havia estrelinhas desenhadas no
   verde. Detectadas por persistência: presentes em ≥90% dos frames **e** em
   manchas pequenas. O filtro de tamanho é essencial, porque o torso também
   persiste;
3. **despill só na franja**, pelos mesmos motivos de sempre;
4. **medição do quadro necessário** em todos os frames, não só no primeiro: o
   cajado sobe acima da cabeça e, no fim, cai deitado no chão;
5. **escala calibrada pelo corpo**, não pela caixa — a caixa inclui o cajado e
   engana (ver "Escala da morte" no HANDOFF);
6. **amostragem uniforme** para caber na folha: 216 frames de origem viraram 36,
   e 9 s de vídeo viraram 2,4 s de animação a 15 fps.

O vídeo original fica em `assets/_raw/`, versionado, como fonte.

# Como registrar o estado dos assets

Enquanto não houver um inventário dedicado, o estado de cada asset relevante deve ser mencionado em `docs/HANDOFF.md` na seção de estado atual, e a promoção para `INTEGRATED` registrada em `docs/CHANGELOG.md`.
