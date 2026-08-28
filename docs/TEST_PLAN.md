# Plano de Testes

# Regra

Cada sistema novo precisa de:
- teste funcional;
- teste de regressão básico;
- critério observável.

# Movimento

- diagonal não deve ser mais rápida;
- velocidade independente do FPS;
- câmera acompanha corretamente.

# Enemy

- encontra player;
- persegue;
- recebe dano;
- morre uma única vez;
- não deixa erro após player morrer.

# Spawn

- não nasce visivelmente sobre player;
- respeita limites;
- densidade aumenta como esperado.

# Projectile

- viaja no FPS correto;
- causa dano uma vez quando apropriado;
- expira;
- não deixa nodes eternos.

# XP

- drop correto;
- coleta correta;
- XP excedente preservado;
- múltiplos levels possíveis.

# Upgrade

- aparecem opções válidas;
- não oferece upgrade já máximo quando não permitido;
- pausa;
- somente uma escolha é aplicada;
- retoma gameplay.

# Stress

Testar aproximadamente:

- 50 inimigos
- 100
- 250
- 500

Registrar:
- FPS;
- frametime;
- quantidade de nodes;
- memória;
- erros.

Não estabelecer "500 inimigos" como obrigação antes de medir dispositivo alvo.

# Mobile

Testar:
- toque;
- resolução;
- orientação;
- pausa/retorno;
- desempenho;
- aquecimento;
- memória;
- carregamento;
- fechamento e reabertura.

# Definition of Done

Uma tarefa só é concluída quando:
- funciona;
- não adiciona erros;
- critério de aceite passa;
- documentação foi atualizada.
