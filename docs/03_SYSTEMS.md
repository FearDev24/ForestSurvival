# 03 — Sistemas do Jogo

Este documento lista os sistemas e contratos esperados.

# 1. Game Manager

Responsabilidades:
- estado da partida;
- iniciar;
- pausar;
- terminar;
- vitória;
- derrota;
- tempo geral quando apropriado.

Estados possíveis:

- MENU
- PLAYING
- LEVEL_UP
- PAUSED
- GAME_OVER
- VICTORY

# 2. Player Controller

Responsabilidades:
- input;
- movimentação;
- orientação do sprite;
- integração com stats.

Não deve:
- implementar cada arma diretamente;
- gerenciar waves;
- spawnar inimigos.

# 3. Health System

Deve suportar:
- max_health;
- current_health;
- damage();
- heal();
- death signal.

# 4. Damage System

Fluxo:

Attack/Hitbox
→ Hurtbox
→ HealthComponent
→ death

# 5. Enemy System

Responsabilidades:
- locomover em direção ao player;
- receber dano;
- causar dano;
- morrer;
- conceder/drop XP.

# 6. Spawn Manager

Responsabilidades:
- escolher ponto de spawn;
- manter spawn fora da câmera;
- respeitar taxa da wave;
- limitar população quando necessário.

# 7. Wave Manager

Responsabilidades:
- tempo;
- tabela de waves;
- tipos de inimigos disponíveis;
- frequência;
- elites;
- boss.

# 8. Weapon Manager

Responsabilidades:
- armas possuídas;
- níveis;
- adicionar;
- melhorar;
- limite de armas.

# 9. Weapon Runtime

Cada arma controla:
- cooldown;
- targeting quando necessário;
- criação de ataque;
- comportamento específico.

# 10. Projectile System

Projétil deve poder configurar:
- direção;
- velocidade;
- dano;
- duração;
- perfuração;
- quantidade de impactos.

# 11. XP / Pickup

Quando inimigo morre:
- gera XP;
- pickup permanece no mundo;
- coleta adiciona XP.

Futuro:
pickups distantes podem ser agregados/otimizados.

# 12. Level System

Responsabilidades:
- XP atual;
- XP necessário;
- level;
- emissão de signal de level up;
- lidar corretamente com XP excedente.

IMPORTANTE:
se o jogador ganhar XP suficiente para múltiplos níveis, não perder XP.

# 13. Upgrade System

Ao subir de nível:
- pausar gameplay;
- gerar opções válidas;
- evitar opções impossíveis;
- escolher uma;
- aplicar;
- continuar.

No MVP:
até 3 opções.

# 14. Stat System

Stats sugeridos:
- max_health
- move_speed
- damage_multiplier
- cooldown_multiplier
- area_multiplier
- duration_multiplier
- projectile_speed_multiplier
- amount_bonus
- pickup_radius

# 15. HUD

Exibir:
- HP;
- XP;
- level;
- timer;
- armas;
- pausa.

# 16. Game Over

Deve:
- interromper spawn;
- interromper gameplay;
- mostrar tempo;
- mostrar level;
- permitir restart;
- permitir voltar ao menu.

# 17. Victory

No vertical slice:
- boss derrotado;
- partida encerra;
- tela de resultado.

# 18. Save

Não implementar antes de existir meta-progressão.

Quando chegar:
- save local;
- versionamento do save;
- defaults seguros;
- nenhuma dependência de servidor para jogar.
