# 01 — Game Design Document

# Tema

A floresta ancestral está sendo invadida por forças demoníacas.

O protagonista é um druida guardião que usa magia natural, raízes, espíritos animais e artefatos da floresta.

# Perspectiva

- 2D top-down
- câmera acompanha jogador
- mapa maior que a viewport
- leitura visual clara
- pixel art

# Controles

## PC

- WASD ou setas: movimento
- ESC: pausa

Ataques são automáticos.

## Mobile — futuro

- joystick virtual
- botão de pausa
- menus por toque

# Condição principal

No vertical slice:

**sobreviver 10 minutos e derrotar o chefe final.**

A duração poderá ser alterada após testes.

# Jogador

## Druida Guardião

Características iniciais sugeridas:

- HP: 100
- velocidade: 180–220 px/s
- defesa: 0
- coleta: curta distância
- arma inicial: Cajado da Floresta

Valores são provisórios e devem ser balanceados por testes.

# Experiência

Inimigos deixam Essência Natural / Essência Corrompida.

Ao atingir XP necessário:
- o jogo pausa;
- são apresentadas até 3 opções;
- jogador escolhe 1;
- gameplay continua.

# Upgrades

Categorias:

## Armas

Adicionam ou melhoram ataques.

## Passivas

Modificam stats globais.

Exemplos:
- velocidade;
- vida máxima;
- regeneração;
- área;
- duração;
- cooldown;
- dano;
- velocidade de projéteis;
- quantidade;
- alcance de coleta.

# Armas iniciais do vertical slice

## 1. Cajado da Floresta

Tipo:
projétil direcionado.

Comportamento:
- encontra alvo próximo;
- dispara energia;
- causa dano;
- evolução aumenta dano, quantidade e cadência.

## 2. Espinhos Ancestrais

Tipo:
AoE periódico.

Comportamento:
- espinhos surgem ao redor do druida;
- causam dano em área;
- níveis aumentam raio/dano/frequência.

## 3. Corvo Espiritual

Tipo:
orbital.

Comportamento:
- espírito orbita o jogador;
- causa dano por contato;
- níveis aumentam número/velocidade/dano.

# Inimigos do vertical slice

## Imp Corrompido

- baixo HP
- velocidade média/alta
- grande quantidade

## Cão Demoníaco

- HP médio
- muito rápido
- força movimentação

## Bruto Corrompido

- HP alto
- lento
- ocupa espaço

## Elite

Versão fortalecida com:
- HP elevado;
- tamanho visual diferente;
- recompensa maior.

## Boss

Criatura demoníaca de grande porte.

Primeira versão pode usar:
- perseguição;
- investida;
- ataque em área sinalizado.

Evitar boss excessivamente complexo no MVP.

# Dano

Inicialmente:

`dano_final = dano_base * modificador_global`

Sistemas de crítico, armadura e resistências devem entrar somente se agregarem valor.

# Invulnerabilidade do jogador

Depois de receber dano:
- pequena janela de invulnerabilidade;
- feedback visual;
- evita dano por frame.

# Spawn

Inimigos devem nascer fora da visão imediata do jogador, em uma faixa ao redor da câmera/jogador.

# Progressão da partida — exemplo

00:00–02:00
- Imps

02:00–04:00
- Imps + Cães

04:00–06:00
- mais densidade
- Brutos

06:00–08:00
- elite
- aumento de frequência

08:00–10:00
- horda intensa

10:00
- boss

# Filosofia de balanceamento

Nunca balancear copiando números exatos de outro jogo.

Balanceamento deve partir de:
- tempo para matar;
- quantidade de inimigos;
- sensação de progressão;
- taxa de XP;
- sobrevivência média;
- desempenho mobile.
