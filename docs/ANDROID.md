# Android / Google Play

# Objetivo

Forest Survival deve ser construído de modo que a versão Android não seja uma adaptação tardia.

# Estratégia

Desenvolvimento inicial:
PC + teclado por velocidade de iteração.

Arquitetura:
compatível com input mobile desde o início.

# Regras

- UI escalável;
- botões grandes;
- evitar texto pequeno;
- não depender de hover;
- não depender de clique direito;
- evitar efeitos caros sem opção;
- controlar quantidade de partículas;
- profiling em hardware real.

# Input abstraction

Gameplay deve consultar ações:

- `move_left`
- `move_right`
- `move_up`
- `move_down`

Não programar movimento diretamente para teclas específicas.

Assim joystick virtual poderá acionar o mesmo sistema.

# Backend

MVP é offline.

Não adicionar:
- Supabase;
- Firebase;
- servidor próprio;
- APIs pagas;

sem uma necessidade aprovada.

# Save

Meta-progressão deve funcionar localmente.

Cloud save poderá ser avaliado depois.

# Publicação

Antes de release verificar requisitos atuais da Google Play, SDK alvo, assinatura, AAB, políticas e testes exigidos. Esses requisitos mudam com o tempo e devem ser confirmados na época do lançamento.
