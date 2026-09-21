# Publicação na Google Play

Guia para levar a versão 1.0.0 à Play Store com anúncios. Está dividido pelo que
só o dono da conta pode fazer e pelo que se faz no projeto — e o primeiro grupo é
o que decide o prazo.

## Antes de tudo: o prazo real

**Conta pessoal criada depois de 13/11/2023 não publica direto.** A Google exige
um **teste fechado com pelo menos 12 testadores, por 14 dias seguidos**, antes de
liberar a produção. Isso vale para contas pessoais; conta de organização (com
CNPJ/D-U-N-S) não tem essa exigência.

Na prática, com conta pessoal nova:

| etapa | tempo |
| --- | --- |
| criar a conta e verificar identidade | de 1 a vários dias |
| subir o AAB no teste fechado e juntar 12 testadores | o quanto demorar para juntar |
| manter o teste por 14 dias | 14 dias |
| pedir acesso à produção e passar pela revisão | alguns dias |

Então o lançamento público fica, no mínimo, **três semanas** depois de a conta
estar pronta. Vale usar esse tempo: o teste fechado é exatamente quando
aparecem os defeitos que só um aparelho diferente do seu mostra.

## O que só o dono da conta pode fazer

Nenhum destes passos pode ser feito por quem não é o dono — envolvem pagamento,
identidade, senha ou aceite de contrato.

1. **Conta de desenvolvedor na Play Console** (taxa única de US$ 25, verificação
   de identidade).
2. **Conta no AdMob**, ligada ao app, com uma unidade de anúncio **premiado**
   (rewarded). Ela dá dois códigos: o *App ID* e o *Ad Unit ID*.
3. **Chave de upload.** Gerada uma vez, com uma senha que só você sabe:

   ```bash
   keytool -genkeypair -v -keystore forest-survival-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

   Guarde o arquivo e a senha **fora do repositório**, em dois lugares. Com a
   *Play App Signing* ligada (é o padrão), perder a chave de upload tem
   conserto pelo suporte da Google, mas custa dias.

   Para exportar, a Godot lê a chave de variáveis de ambiente — a senha nunca
   entra no `export_presets.cfg`:

   ```bash
   setx GODOT_ANDROID_KEYSTORE_RELEASE_PATH "C:\caminho\forest-survival-upload.keystore"
   ```
   ```bash
   setx GODOT_ANDROID_KEYSTORE_RELEASE_USER "upload"
   ```
   ```bash
   setx GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD "sua-senha"
   ```

4. **Hospedar a política de privacidade** num endereço público. Com anúncios,
   ela é obrigatória. O texto está pronto mais abaixo; o GitHub Pages do próprio
   repositório serve.
5. **Preencher na Play Console**: classificação etária, segurança dos dados,
   público-alvo, declaração de anúncios e a ficha da loja. As respostas
   sugeridas estão abaixo.
6. **Decidir o nome de pacote.** Hoje é `com.feardev24.forestsurvival`. **Depois
   do primeiro envio ele não muda nunca mais** — nem com o app removido.

## O que o projeto já tem

- preset **"Android Play Store"** em `export_presets.cfg`: AAB (formato que a
  Play exige), Gradle ligado, 32 e 64 bits, versão **1.0.0 (código 1)**. O
  preset "Android" de depuração continua como estava, para os testes no
  aparelho;
- aviso de conteúdo futuro na tela de vitória: *"Novos chefes e dificuldades nas
  próximas atualizações"*;
- ícone do app (512 px) e ícones adaptativos;
- save local, moeda e loja de melhorias — a base para o anúncio premiado.

## O que falta no projeto

Nada que dependa só do projeto. Já entraram o modelo de build Android, o plugin
de anúncios (poing-studios 5.1.0), o anúncio premiado "dobrar as moedas" e o
consentimento (UMP). Faltam os dois códigos da AdMob, que só o dono da conta
gera:

| código | onde entra | hoje |
| --- | --- | --- |
| App ID (`ca-app-pub-...~...`) | `project.godot`, `admob/general/android/app_id` | `ca-app-pub-4397221687948677~3502008100` |
| Ad Unit ID premiado (`ca-app-pub-.../...`) | `scripts/systems/anuncios_admob.gd`, `PREMIADO_REAL` | `ca-app-pub-4397221687948677/8642654141` (`dobrar_moedas`) |

**Armadilha:** a Godot não grava em `project.godot` um valor igual ao padrão
do plugin. Com o App ID de teste, a linha sumia sozinha — e voltar a ela
achando que ali estava o ID real engana. Confira a linha antes de exportar.

Mensagem de consentimento (RGPD) publicada na AdMob: inglês como padrão e
português (pt-PT), com "Não consentir" ligado em todos os países.

A build de depuração usa sempre a unidade de teste, e é com ela que se testa no
aparelho. **Nunca toque no anúncio real do próprio app** — é tráfego inválido e
suspende a conta AdMob.

Na AdMob, ative também a **mensagem de consentimento** (Privacidade e
mensagens → RGPD): sem ela configurada no painel, o formulário não aparece na
Europa e o anúncio não é pedido lá.

## Como os anúncios devem entrar

**Premiado, e não banner.** O jogo é de ação, em paisagem, com o polegar no
joystick: um banner ocupa tela útil e recebe toque acidental — o que a política
da AdMob pune. O anúncio premiado é o formato que o jogador escolhe ver, e ele
casa com o que já existe: ao fim da partida, **assistir para dobrar as moedas**.

**Intersticial, se entrar, só entre partidas** — nunca durante o jogo, e no
máximo um a cada algumas partidas. Anúncio que interrompe a jogada é motivo de
suspensão na Play.

**Expectativa honesta de receita.** Anúncio em jogo novo rende pouco até haver
muitos jogadores por dia: receita de anúncio é proporcional a quem abre o jogo,
e um jogo recém-lançado sem divulgação costuma ter poucas dezenas. O que move o
número é retenção (voltar para outra partida) — e é por isso que a
meta-progressão e as atualizações prometidas importam mais que o formato do
anúncio.

## Ficha da loja

**Nome** (até 30 caracteres):

```text
Forest Survival
```

**Descrição curta** (até 80 caracteres):

```text
Proteja a floresta corrompida: sobreviva à horda e derrube o Guardião Profanado.
```

**Descrição completa:**

```text
A floresta está sendo corrompida, e só um druida ainda resiste.

Forest Survival é um jogo de sobrevivência contra hordas: você se move, e o
druida ataca sozinho. A cada nível, escolha uma nova magia ou fortaleça as que já
tem — raios que caem do céu, vinhas que brotam do chão, um corvo espiritual,
anéis de esporos e vagalumes guardiões.

Resista às ondas de criaturas corrompidas por sete minutos e enfrente o
Guardião Profanado, um cervo colossal de madeira e lava que atravessa a floresta
para chegar até você.

• Controles simples, feitos para o toque: um dedo para andar, o resto é
  estratégia
• Seis magias e várias melhorias por partida
• Moedas a cada partida, para melhorias permanentes de vida, dano e velocidade
• Pixel art com criaturas e chefe animados
• Jogue offline, sem conta e sem conexão

O jogo continua crescendo: novos chefes e novos níveis de dificuldade chegam nas
próximas atualizações.
```

A arte do jogo e da ficha foi gerada com IA, e os recursos da ficha estão
**rotulados como criados com IA** na Play Console. Por isso a descrição não diz
"feita à mão": afirmação falsa na ficha fere a política de metadados.

A última frase promete conteúdo sem data — é o que a política da Play permite
sem risco. Prometer data ou recurso específico que não chega é propaganda
enganosa, e rende avaliação ruim antes de render punição.

**Categoria:** Jogos › Ação. **Tags sugeridas:** sobrevivência, roguelite,
pixel art, fantasia.

## Classificação etária (questionário IARC)

Respostas que descrevem o jogo como ele é:

- violência: **fantasia**, contra criaturas não humanas, sem sangue realista;
- sem linguagem ofensiva, sexo, drogas, apostas ou jogo de azar;
- sem interação entre usuários, sem compartilhamento de localização;
- **contém anúncios: sim**.

A classificação esperada fica na faixa de 10 a 12 anos. Com anúncios, **não
marque o público-alvo como infantil**: app para crianças segue a política de
Famílias, que restringe quais anúncios podem aparecer.

## Segurança dos dados

O jogo em si não coleta nada: o save fica no aparelho e não há servidor. O que
coleta é o **SDK do AdMob**:

- **coletado:** identificador de publicidade do aparelho, dados de uso e
  diagnóstico do app (pelo SDK de anúncios);
- **finalidade:** publicidade e análise;
- **compartilhado:** sim, com a Google (AdMob);
- **criptografado em trânsito:** sim;
- **o usuário pode pedir exclusão:** o identificador de publicidade é
  redefinível nas configurações do Android;
- **o jogo não coleta** nome, e-mail, localização precisa, contatos, fotos nem
  arquivos.

## Política de privacidade (rascunho)

```text
Política de Privacidade — Forest Survival

Última atualização: [data da publicação]

Forest Survival é um jogo para Android desenvolvido por [seu nome ou nome de
desenvolvedor]. Esta política explica quais dados são tratados quando você joga.

1. Dados que o jogo guarda
O jogo guarda o seu progresso (recordes, moedas e melhorias compradas) somente
no seu aparelho. Esses dados não são enviados para nenhum servidor nosso. Ao
desinstalar o jogo, eles são apagados.

2. Anúncios
O jogo exibe anúncios fornecidos pelo Google AdMob. Para isso, o SDK do AdMob
pode coletar e processar o identificador de publicidade do seu aparelho,
informações sobre o aparelho e dados de uso, com a finalidade de exibir e medir
anúncios. Esse tratamento segue a Política de Privacidade da Google:
https://policies.google.com/privacy

Você pode redefinir ou restringir o identificador de publicidade nas
configurações do Android (Google > Anúncios). Usuários do Espaço Econômico
Europeu e do Reino Unido podem escolher, na primeira abertura, se aceitam
anúncios personalizados.

3. Crianças
O jogo não é direcionado a crianças menores de 13 anos e não coleta
intencionalmente dados pessoais delas.

4. Dados que não coletamos
Não coletamos nome, e-mail, número de telefone, localização precisa, contatos,
fotos ou arquivos do seu aparelho.

5. Alterações
Esta política pode ser atualizada. A versão vigente estará sempre neste
endereço, com a data da última atualização.

6. Contato
[seu e-mail de contato]
```

## Capturas de tela

Seis capturas em 1920×1080 em `publicacao/screenshots/`, **já na ordem da
ficha** — a primeira é a que decide o clique, então ela é o chefe em combate, e
o menu vai por último:

| arquivo | o que mostra |
| --- | --- |
| `01_chefe.png` | o Guardião no meio da horda, com vinha e esporos em ação |
| `02_partida.png` | a horda do cerco e as magias do druida |
| `03_escolha.png` | a tela de subir de nível, com três magias para escolher |
| `04_vitoria.png` | a vitória, com o ganho de moedas e o aviso de atualizações |
| `05_loja.png` | a loja de melhorias permanentes |
| `06_menu.png` | o menu com a ilustração de fundo |

São partidas de verdade, geradas por `tools/capturar_loja_play.gd`. Para
regerar depois de uma mudança visual:

```bash
godot --path . --resolution 1920x1080 --script res://tools/capturar_loja_play.gd --fixed-fps 60
```

## Estado na Play Console (21/09/2026)

App criado (`com.feardev24.forestsurvival`, jogo, grátis). Concluídos: política
de privacidade (`https://feardev24.github.io/ForestSurvival/privacidade.html`,
branch `gh-pages`), anúncios, login, ID de publicidade, público-alvo (13+),
segurança dos dados, classificação IARC (ClassInd 10, PEGI 7, ESRB 10+),
apps governamentais, recursos financeiros, saúde, categoria Ação, contato e a
ficha da loja completa.

**Teste fechado enviado para revisão em 21/09/2026**: faixa "Teste fechado -
Alpha", versão 1 (1.0.0) assinada com a chave de upload (SHA-256
`0A:1C:47:90:…:12:F5:75`), 177 países, testadores pelo Grupo do Google
`forest-survival-testers@googlegroups.com` (qualquer pessoa pode entrar),
feedback para `leonardodev24@gmail.com`. Google Play Games no PC desativado.
A versão 1 (1.0.0) **não tem anúncios**; a 2 (1.0.1) já sai com a unidade real.

Depois da aprovação: divulgar o link do grupo e o de participação (post em
inglês para r/AndroidClosedTesting), juntar ~20 testadores, manter 12
instalados por 14 dias e pedir o acesso à produção.

A chave de upload fica em `C:\Users\CPU\forest-survival-upload.keystore`, fora
do repositório; a senha, só com o dono, nas variáveis de ambiente.

## Imagem de destaque (1024 x 500)

Prompt de geração, no estilo dos outros pacotes de arte do projeto:

```text
Wide promotional banner for a pixel art survival game, 1024x500, no text. A
hooded forest druid in a green cloak with a glowing green orb staff stands on
the left, facing a colossal corrupted stag made of charred wood and molten lava
cracks on the right, with a horde of small red demonic creatures between them.
Dark enchanted forest at dusk, a burning corrupted castle glowing orange on the
horizon, mist and ember particles. Detailed painterly pixel art, strong
silhouettes, high contrast, dramatic rim lighting, cinematic composition, empty
space at the center top for the game logo.
```

Deixe o **centro de cima vazio**: é onde entra o nome do jogo, que já existe
como arte (`assets/ui/titulo_jogo.png`).
