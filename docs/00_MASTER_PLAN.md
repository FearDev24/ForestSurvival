# 00 — Master Plan

## Nome de trabalho

**Forest Survival**

O nome pode mudar antes da publicação.

## Elevator pitch

Um survivor-like 2D top-down em que um druida guardião enfrenta ondas crescentes de criaturas demoníacas para impedir a corrupção da floresta. O jogador se move, coleta essência, escolhe habilidades e constrói combinações cada vez mais poderosas durante partidas curtas.

## Pilar 1 — Fácil de jogar

- movimentação simples;
- ataque automático;
- decisões através de posicionamento e upgrades;
- leitura clara em tela pequena.

## Pilar 2 — Builds variadas

Cada partida deve permitir combinações diferentes de:
- armas;
- habilidades naturais;
- passivas;
- evoluções;
- sinergias.

## Pilar 3 — Escalada de poder

O jogador deve sentir:

fraco → competente → poderoso → sobrecarregado pela horda → build completa.

## Pilar 4 — Performance

O jogo precisa suportar grande quantidade de unidades em celulares intermediários.

## Pilar 5 — Produção sustentável

Primeiro criar sistemas reutilizáveis. Depois adicionar conteúdo.

Não criar dezenas de inimigos/armas antes de validar o núcleo.

# Loop principal

1. iniciar partida;
2. mover;
3. inimigos perseguem;
4. habilidades atacam automaticamente;
5. inimigos morrem;
6. essência/XP cai;
7. jogador coleta;
8. sobe de nível;
9. escolhe 1 de 3 melhorias;
10. dificuldade cresce;
11. elites/chefes aparecem;
12. sobreviver até o objetivo;
13. resultado;
14. futuras recompensas permanentes.

# Escopo MVP

## Incluído

- 1 personagem: Druida Guardião
- 1 mapa
- 3 inimigos
- 1 elite
- 1 boss
- 3 armas/habilidades ativas
- 6 upgrades/passivas
- XP
- level up com 3 escolhas
- cronômetro
- HP
- pausa
- game over
- vitória
- HUD
- controles teclado
- base preparada para controles mobile

## Não incluído inicialmente

- multiplayer
- PvP
- conta online
- loja
- anúncios
- compras
- leaderboard online
- achievements externos
- cloud save
- dezenas de personagens
- sistema complexo de quests

# Meta de qualidade do vertical slice

A primeira versão é considerada aprovada quando:

- começa sem erros;
- jogador consegue completar uma partida;
- upgrades funcionam;
- boss aparece;
- game over funciona;
- restart funciona;
- não existem erros recorrentes no debugger;
- desempenho permanece aceitável com grande horda;
- lógica não depende de assets finais.
