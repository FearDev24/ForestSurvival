# Forest Survival

Jogo 2D top-down do gênero **survivor-like**, inspirado na estrutura de partidas de jogos como Vampire Survivors, mas com universo, personagens, inimigos, habilidades, arte, nomes e progressão próprios.

## Visão

O jogador controla um **druida guardião da floresta** que precisa resistir a invasões demoníacas cada vez maiores. O combate é predominantemente automático; a habilidade do jogador está em movimentação, posicionamento, construção da build e escolha de melhorias.

## Stack oficial

- Engine: **Godot 4.7.2 stable**
- Linguagem: **GDScript**
- Projeto: 2D / top-down
- Plataforma inicial: PC para desenvolvimento
- Plataforma prioritária de publicação: Android / Google Play
- Plataforma futura possível: Windows / Steam
- Orientação de tela inicial: landscape
- Arquitetura: offline-first
- Backend: nenhum no MVP
- Serviços pagos recorrentes: evitar

## Regra de propriedade intelectual

Forest Survival é um jogo **inspirado no gênero survivor-like**.

Não copiar de Vampire Survivors ou outros jogos:
- nomes de personagens;
- sprites;
- ícones;
- músicas;
- efeitos sonoros;
- textos;
- mapas;
- nomes de armas;
- interface;
- balanceamento exato;
- personagens reconhecíveis;
- qualquer asset protegido.

Podemos reproduzir ideias genéricas do gênero, como:
- hordas;
- ataque automático;
- experiência;
- level up;
- escolha de upgrades;
- armas evolutivas;
- chefes;
- dificuldade crescente.

## Fonte de verdade do projeto

Assistentes de IA **não devem usar o histórico da conversa como fonte principal**.

A fonte de verdade é:

1. `README.md`
2. `docs/HANDOFF.md`
3. `docs/DECISIONS.md`
4. `docs/ROADMAP.md`
5. documentação específica do sistema
6. código existente

## Protocolo obrigatório para IA

Antes de programar:

1. Ler `docs/HANDOFF.md`.
2. Ler `docs/DECISIONS.md`.
3. Ler `docs/ROADMAP.md`.
4. Ler os documentos relacionados à tarefa.
5. Examinar o código existente.
6. Não recriar sistemas que já existem.
7. Não fazer refatorações grandes sem necessidade.

Ao terminar:

1. testar a alteração;
2. atualizar `docs/HANDOFF.md`;
3. atualizar `docs/CHANGELOG.md`;
4. atualizar `docs/TODO.md`;
5. atualizar `docs/BUGS.md`, se necessário;
6. registrar decisões importantes em `docs/DECISIONS.md`.

## Documentação

- `docs/00_MASTER_PLAN.md` — visão geral de produção
- `docs/01_GAME_DESIGN.md` — regras do jogo
- `docs/02_ARCHITECTURE.md` — arquitetura técnica
- `docs/03_SYSTEMS.md` — especificação dos sistemas
- `docs/04_CONTENT_PLAN.md` — conteúdo planejado
- `docs/05_ART_DIRECTION.md` — direção visual
- `docs/ASSET_WORKFLOW.md` — política e fluxo progressivo de assets
- `docs/ROADMAP.md` — fases de desenvolvimento
- `docs/TEST_PLAN.md` — estratégia de testes
- `docs/ANDROID.md` — requisitos mobile
- `docs/DECISIONS.md` — decisões permanentes
- `docs/HANDOFF.md` — estado atual para troca de IA
- `docs/CHANGELOG.md` — histórico
- `docs/TODO.md` — próximas tarefas
- `docs/BUGS.md` — bugs conhecidos

## Política de assets

Sprites, animações, efeitos e demais assets finais serão adicionados **progressivamente** durante o desenvolvimento.

A ausência de arte final **não bloqueia nenhuma fase de programação**.

- placeholders são permitidos durante prototipagem;
- placeholder não é asset final;
- assistentes de IA não devem inventar nem redesenhar arte final sem solicitação;
- gameplay e camada visual permanecem desacoplados;
- movimento, HP, IA, combate, XP e armas não dependem da textura provisória;
- um asset só é oficial após aprovação.

Estados: `PLACEHOLDER` → `CANDIDATE` → `APPROVED` → `INTEGRATED`.

Detalhes em `docs/ASSET_WORKFLOW.md` e `DEC-013` em `docs/DECISIONS.md`.

## Primeira meta

Criar um vertical slice totalmente jogável:

- 1 personagem;
- 1 mapa;
- movimentação;
- câmera;
- 3 tipos de inimigos;
- spawn progressivo;
- HP e dano;
- 3 armas;
- experiência;
- level up;
- escolha de 3 melhorias;
- 1 chefe;
- HUD;
- game over;
- vitória;
- partida de aproximadamente 10 minutos.

Somente após esse núcleo estar divertido e estável iniciaremos expansão de conteúdo.
