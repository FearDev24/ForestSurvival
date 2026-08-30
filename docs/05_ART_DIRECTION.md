# 05 — Direção de Arte

# Entrega progressiva de arte

Este documento descreve o **alvo** de arte, não um pré-requisito de programação.

Conforme `DEC-013`, sprites, animações e efeitos finais entram progressivamente e a ausência deles **não bloqueia nenhuma fase do roadmap**. Prototipagem usa placeholders.

Estados de um asset: `PLACEHOLDER` → `CANDIDATE` → `APPROVED` → `INTEGRATED`.

Um asset só é oficial após aprovação do responsável pelo projeto. Assistentes de IA não devem inventar nem redesenhar arte final sem solicitação explícita.

Fluxo completo em `docs/ASSET_WORKFLOW.md`.

# Estilo

- pixel art;
- fantasia natural;
- leitura clara;
- formas bem definidas;
- personagens reconhecíveis em tamanho pequeno;
- evitar excesso de ruído visual.

# Protagonista

Druida guardião:
- capuz e manto verdes;
- elementos naturais;
- cajado de madeira com orbe verde;
- mochila/equipamentos de explorador;
- silhueta consistente.

# Sprites direcionais

Para personagens top-down:
- sul/frente;
- norte/costas;
- oeste/esquerda;
- leste/direita.

Direções podem chegar uma de cada vez. Enquanto faltar alguma, é permitido fallback temporário (espelhar a direção oposta ou reutilizar a direção sul).

Cada direção deve preservar:
- identidade;
- proporções;
- equipamento;
- escala;
- baseline.

# Animações

Prioridade:
1. walk
2. hurt
3. death, se necessário

**`idle` existe só para o druida.** Inimigos e demais personagens terão apenas
caminhada; parados, congelam no primeiro frame do `walk` da direção que
encaram. Não é uma pendência de arte: é o alvo. Ver `DEC-019`.

Como o combate é automático, animações específicas de ataque só entram quando aumentarem leitura.

Animações também chegam gradualmente. A falta de uma animação nunca deve gerar erro em runtime.

# Equipamento

Objetos segurados:
- devem permanecer conectados à mão;
- cabos não devem aparecer quebrados;
- não devem flutuar;
- direção deve permanecer coerente.

# Efeitos

Ataques precisam ser distinguíveis:
- jogador;
- inimigo;
- pickup;
- perigo de boss.

# Mobile

Nunca depender de detalhes minúsculos.

Testar leitura em tela de celular.

# Asset policy

Política completa em `docs/ASSET_WORKFLOW.md` (`DEC-013`).

Cada asset deve registrar origem/licença quando não for produzido especificamente para o projeto.

Criar futuramente:
`docs/ASSET_LICENSES.md`
