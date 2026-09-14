# Prompts de geração de áudio

O que falta de som no jogo e não sai de biblioteca nem de síntese: os dois sons
do Guardião — que precisam de garganta de criatura — e a trilha.

Os prompts estão em inglês porque os geradores de áudio respondem melhor assim.
Onde gerar: **ElevenLabs Sound Effects** (efeitos curtos, texto → som) e
**Stable Audio** ou equivalente (trilha). Os dois aceitam o texto como está.

## Bloco técnico comum

Vale para tudo abaixo, e é o que faz o arquivo entrar no jogo sem retrabalho:

- **WAV, 44,1 kHz.** Efeitos em **mono**; trilha em estéreo;
- **sem silêncio no começo.** Meio segundo de nada é meio segundo de atraso
  entre o que acontece na tela e o som;
- **sem fade-in** e sem cauda de reverberação longa — o jogo corta o som quando
  o próximo entra;
- **pico normalizado em -1 dBFS**, sem compressão pesada: quem nivela é
  `tools/importar_sons.py`, contra a tabela de volumes do jogo;
- a trilha precisa de **loop sem emenda**: nada de reverberação atravessando o
  ponto de volta, e o último compasso tem de encostar no primeiro.

## 1. Rugido do Guardião — `guardiao_rugido.wav`

Toca quando o chefe nasce, aos 420 s de partida. É o aviso de que ele chegou:
tem de ser reconhecível no meio de uma horda inteira em tela.

```text
A single deep monstrous roar from a massive elk-like beast made of charred wood
and molten lava. It starts as a low guttural growl and opens into a full-throated
bellow, with a rough rasping texture in the throat and a faint crackling ember
layer underneath. Heavy chest resonance, most of the energy below 300 Hz, dark
and earthy rather than metallic or screeching. Close-miked and dry, ending
cleanly with no long reverb tail. No music, no other animals, no human voice.
Duration: 1.4 seconds.
```

## 2. Queda do Guardião — `guardiao_queda.wav`

Toca na morte, por cima de uma animação de 2,5 s em que ele cambaleia, dobra as
patas e desaba levantando poeira. O som precisa contar a mesma história na mesma
ordem.

```text
A huge heavy creature collapsing and dying, in one continuous take: first bones
and charred wood cracking under weight, then a long heavy body falling to the
ground, gravel and dry dirt sliding out from under it, one final deep
ground-shaking thud, and embers hissing as they die out. Dominant low
frequencies, dry and close, no reverb tail, no music, no voice, no screaming.
Duration: 2.0 seconds.
```

## 3. Trilha da floresta — `trilha_floresta.ogg`

Toca a partida inteira, e por isso não pode chamar atenção: o jogador vai ouvir
isso por sete minutos seguidos, muitas vezes seguidas.

```text
A dark fantasy forest loop for a top-down survival game. Slow and patient, quiet
tension rather than action: a low sustained drone, sparse plucked strings, a soft
wooden flute motif that repeats without resolving, and distant hand percussion
low in the mix. Minor key, around 70 BPM. Organic acoustic instruments only, no
synth leads, no vocals, no drum kit, no build-up and no climax. It must loop
seamlessly: end on the same harmony it starts, with no reverb tail crossing the
loop point. Duration: 90 seconds.
```

## 4. Trilha do Guardião — `trilha_guardiao.ogg`

Entra na wave do chefe, aos 420 s, e substitui a de cima. Mesma floresta, agora
com pressa.

```text
The boss version of a dark fantasy forest theme, same instruments and same minor
key as the calm forest loop, now driven and urgent: low war drums keeping steady
eighth notes, bowed low strings holding long dissonant notes, and the same wooden
flute motif played faster and higher. Around 100 BPM. Heavy but not chaotic — it
has to sit under combat, not compete with it. No vocals, no synth leads, no
orchestral brass fanfare. Seamless loop, ending on the same harmony it starts.
Duration: 75 seconds.
```

## Quando os arquivos chegarem

Os dois efeitos entram por `tools/importar_sons.py`: põe o arquivo em
`assets/_raw/audio/`, acrescenta a linha na tabela `MAPA` e roda. O teste
`tests/test_audio.gd` confere que os doze continuam existindo, carregando e
tocando nos eventos certos.

A trilha ainda **não tem código**: o barramento `Musica` existe e está vazio.
Quando ela chegar, entra um tocador só, com troca suave entre a floresta e o
Guardião na virada da wave — é trabalho pequeno, mas não foi feito, e não vale
fazer antes de ter o arquivo para ouvir.
