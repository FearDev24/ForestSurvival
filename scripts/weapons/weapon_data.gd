class_name WeaponData
extends Resource
## Dados de uma arma (`docs/02_ARCHITECTURE.md`, "Recursos"; DEC-010).
##
## Aqui não há comportamento: só os números e a cena do ataque. Criar uma arma
## nova é criar um `.tres`, não escrever código — que é o ponto da DEC-010.
##
## O que varia entre as armas existentes já está coberto: o raio cai **em cima**
## do inimigo e não tem direção; a vinha nasce **no druida** e é girada para o
## alvo. São dois campos, não duas classes (DEC-021).

## Identificador estável. É por ele que o `WeaponManager` sabe se já tem a arma —
## nunca pelo nome de exibição, que muda com tradução.
@export var id: StringName = &""

## Nome mostrado ao jogador, na tela de level up da FASE 5.
@export var display_name: String = ""

## Cena instanciada a cada disparo. Precisa aceitar `set_damage()` e, quando a
## arma mira, `aim()` — o contrato de `AbilityEffect`.
@export var effect_scene: PackedScene

@export_group("Combate")
## Dano no nível 1.
@export var base_damage: float = 10.0

## Segundos entre disparos no nível 1.
@export var cooldown: float = 1.0

## Alcance de mira, em pixels. Fora disso a arma não encontra alvo e **não**
## gasta o cooldown: guardar o disparo para quando houver inimigo é mais justo
## do que desperdiçá-lo no vazio.
@export var attack_range: float = 400.0

## Quantos alvos são atingidos por disparo. Cada um recebe seu próprio efeito.
@export var amount: int = 1

@export_group("Posicionamento")

## Onde o ataque nasce.
##
## `EM_VOLTA` sorteia um ponto no chão dentro de um anel em torno do druida: a
## vinha brota da terra em volta dele, não sai do corpo dele.
enum Spawn { NO_ALVO, NO_DRUIDA, EM_VOLTA }
@export var spawn_mode: Spawn = Spawn.NO_ALVO

## Raio do anel usado por `EM_VOLTA`. O ponto sai entre 45% e 100% dele, para os
## ataques não nascerem todos colados no druida nem todos na borda.
@export var spawn_radius: float = 140.0

## Para onde o ataque aponta.
##
## `HORIZONTAL` é a regra do jogo: habilidade com direção aponta para a esquerda
## ou para a direita, nunca na diagonal. A arte é desenhada de lado, e girá-la
## em ângulo qualquer denuncia que é um desenho girado.
enum Aim { NENHUMA, PARA_O_ALVO, HORIZONTAL }
@export var aim_mode: Aim = Aim.NENHUMA

@export_group("Progressão")
## Teto de nível. A FASE 6 decide como os níveis são oferecidos; aqui só existe
## o limite.
@export var max_level: int = 5

## Dano somado a cada nível acima do primeiro.
@export var damage_per_level: float = 5.0

## Fator aplicado ao cooldown a cada nível. 0.9 significa 10% mais rápido por
## nível — multiplicativo, para nunca chegar a zero.
@export var cooldown_multiplier_per_level: float = 0.9


func damage_at(level: int) -> float:
	return base_damage + damage_per_level * float(maxi(1, level) - 1)


func cooldown_at(level: int) -> float:
	return cooldown * pow(cooldown_multiplier_per_level, float(maxi(1, level) - 1))


## Uma arma sem cena de ataque ou sem id não deveria existir; vale conferir na
## carga, porque `.tres` é editado à mão com frequência.
func is_valid() -> bool:
	return id != &"" and effect_scene != null and base_damage > 0.0 and cooldown > 0.0
