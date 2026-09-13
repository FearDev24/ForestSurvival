"""Monta o SpriteFrames de um inimigo a partir das quatro folhas de caminhada.

O `.tres` do diabrete foi escrito a mao. Com cinco criaturas no plano, isso deixa
de ser razoavel -- e, mais importante, escrever a mao nao confere nada.

Este script confere tres coisas que so aparecem em jogo se ninguem olhar antes:

**A altura do corpo bate entre as quatro direcoes.** E o erro que o cao de
inferno trouxe: as folhas de perfil vieram com 35 px de corpo contra 92 das de
frente e de costas, o que faria a criatura encolher ao virar de lado.

Com `normalizar` ligado o script conserta em vez de recusar -- ver `normalizar()`
para o porque de reduzir e nunca ampliar.

**Os pes ficam na mesma linha.** A origem do inimigo esta nos pes e o Y-sort
depende disso; um quadro com o corpo alguns pixels mais alto faz o bicho flutuar
enquanto anda.

**A folha e um multiplo exato do quadro.** Sobra de pixel vira um quadro extra
cortado no fim da animacao.

A direcao de cada folha e declarada, nunca deduzida do nome do arquivo: o cao
chegou com `caoinfeast-walk-west.png`, em que o prefixo diz uma coisa e o sufixo
diz o contrario.

Uso: python tools/preparar_inimigo.py [nome]   (a partir da raiz do projeto)
"""

from PIL import Image
import json
import os
import sys

PASTA = "assets/characters/inimigos/"

## Quanto a altura do corpo pode variar entre direcoes antes de virar defeito.
## 25% cobre a diferenca legitima entre uma criatura de frente e de perfil.
TOLERANCIA_ALTURA = 0.25

## Quanto os pes podem variar dentro de uma mesma folha, em pixels.
TOLERANCIA_BASE = 8

## Escala do no `Visual` em `enemy.tscn`. Entra na conta da `visual_scale`
## recomendada quando as folhas precisam ser normalizadas.
ESCALA_DA_CENA = 0.5

## Quadros por segundo de cada animacao de caminhada.
VELOCIDADE = 12.0

## Cada inimigo: uid do recurso e a folha de cada direcao. A ordem aqui e a
## ordem em que as animacoes entram no arquivo.
INIMIGOS = {
    "diabrete": {
        "uid": "bfsdiabreteframes",
        "saida": "diabrete_sprite_frames.tres",
        "folhas": {
            "south": "diabrete-south-walk-south.png",
            "north": "diabrete-north-walk-north.png",
            "west": "diabrete-west-walk-west.png",
            "east": "diabrete-east-walk-east.png",
        },
    },
    "cao": {
        "uid": "bfscaoframes",
        "saida": "cao_sprite_frames.tres",
        # Estas folhas saem de `tools/extrair_inimigo_video.py`, que tira os
        # quadros do video de movimentacao. As folhas estaticas que vieram
        # antes ficaram em `_raw/`: nelas o perfil tinha um terco da altura da
        # frente, e o video nao tem esse problema porque as quatro vistas sao a
        # mesma animacao de angulos diferentes.
        "folhas": {
            "south": "cao-south.png",
            "north": "cao-north.png",
            "west": "cao-west.png",
            "east": "cao-east.png",
        },
    },
    # As tres criaturas abaixo sairam de video, como o cao, e ja vem na escala
    # de mundo certa: `visual_scale` vale 1 no `EnemyData` delas. Antes de terem
    # arte propria, as tres usavam a folha do diabrete ampliada (1,45, 1,70 e
    # 2,80), e as alturas de `extrair_inimigo_video.py` foram escolhidas para
    # que nenhuma mudasse de tamanho em tela ao ganhar a sua.
    "bruto": {
        "uid": "bfsbrutoframes",
        "saida": "bruto_sprite_frames.tres",
        "folhas": {
            "south": "bruto-south.png",
            "north": "bruto-north.png",
            "west": "bruto-west.png",
            "east": "bruto-east.png",
        },
    },
    "elite": {
        "uid": "bfseliteframes",
        "saida": "elite_sprite_frames.tres",
        "folhas": {
            "south": "elite-south.png",
            "north": "elite-north.png",
            "west": "elite-west.png",
            "east": "elite-east.png",
        },
    },
    "guardiao": {
        "uid": "bfsguardiaoframes",
        "saida": "guardiao_sprite_frames.tres",
        "folhas": {
            "south": "guardiao-south.png",
            "north": "guardiao-north.png",
            "west": "guardiao-west.png",
            "east": "guardiao-east.png",
        },
        # A unica criatura com morte encenada (DEC-024). O nome `death` e o que
        # `enemy_visual.gd` procura; havendo, a queda provisoria desenhada em
        # codigo sai de cena sozinha.
        "morte": {"arquivo": "guardiao-death.png", "animacao": "death", "velocidade": 12.0},
    },
}


def medir(caminho, largura_quadro, altura_quadro):
    """Altura do corpo, largura e linha dos pes, quadro a quadro."""
    import numpy as np

    a = np.array(Image.open(caminho).convert("RGBA"))
    total = a.shape[1] // largura_quadro
    alturas, bases = [], []
    for i in range(total):
        cel = a[:, i * largura_quadro:(i + 1) * largura_quadro]
        ys, xs = np.where(cel[:, :, 3] > 16)
        if len(ys) == 0:
            continue
        alturas.append(int(ys.max() - ys.min() + 1))
        bases.append(int(ys.max()))
    return total, alturas, bases


def ler_quadros(caminho_png):
    """Tamanho e contagem de quadros, do JSON quando existe, da imagem quando nao."""
    caminho_json = caminho_png[:-4] + ".json"
    largura, altura = 64, 96
    if os.path.exists(caminho_json):
        d = json.load(open(caminho_json, encoding="utf-8"))
        largura = int(d.get("frameWidth", largura))
        altura = int(d.get("frameHeight", altura))
    im = Image.open(caminho_png)
    return largura, altura, im.size


def normalizar(config, dados):
    """Reduz todas as direcoes ate a menor e escreve folhas novas.

    **Reduz, nunca amplia.** O inimigo aparece com cerca de 38 px em tela e a
    folha de perfil ja tem 35 px nativos; ampliar ate 92 para o motor reduzir de
    volta perderia definicao duas vezes, sem ganhar nada.

    O preco e que a `visual_scale` do `EnemyData` deixa de significar "relativo
    ao diabrete" e passa a compensar a arte menor. O valor a usar sai impresso.

    Os pes ficam na borda de baixo do quadro e o corpo, centrado na horizontal.
    A altura do quadro nao muda: e ela que faz o pe cair na origem do no, com o
    `Sprite` em (0,-48) dentro do `Visual`.
    """
    import numpy as np

    alvo = min(d["altura"] for d in dados.values())
    novas = {}

    for direcao, d in dados.items():
        fator = alvo / d["altura"]
        origem = np.array(Image.open(PASTA + d["arquivo"]).convert("RGBA"))

        recortes = []
        for i in range(d["quadros"]):
            cel = origem[:, i * d["lq"]:(i + 1) * d["lq"]]
            ys, xs = np.where(cel[:, :, 3] > 16)
            if len(ys) == 0:
                continue
            corpo = Image.fromarray(cel[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
            recortes.append(corpo.resize((
                max(1, int(round(corpo.size[0] * fator))),
                max(1, int(round(corpo.size[1] * fator))),
            ), Image.LANCZOS))

        largura_quadro = max(max(r.size[0] for r in recortes), 8)
        # Par: quadro impar deixa o corpo meio pixel fora do centro.
        largura_quadro += largura_quadro % 2

        folha = Image.new("RGBA", (largura_quadro * len(recortes), d["aq"]), (0, 0, 0, 0))
        for i, r in enumerate(recortes):
            folha.alpha_composite(r, (
                i * largura_quadro + (largura_quadro - r.size[0]) // 2,
                d["aq"] - r.size[1],
            ))

        saida = "%s-%s.png" % (config["prefixo"], direcao)
        folha.save(PASTA + saida)
        novas[direcao] = {
            "arquivo": saida, "quadros": len(recortes),
            "lq": largura_quadro, "aq": d["aq"],
            "altura": alvo, "alturas": (int(alvo), int(alvo)),
        }
        print("  %-6s %-24s fator %.2f -> quadro %dx%d"
              % (direcao, saida, fator, largura_quadro, d["aq"]))

    escala = config["altura_em_tela"] / (alvo * ESCALA_DA_CENA)
    print("\n  corpo normalizado: %.0f px" % alvo)
    print("  para %.0f px em tela, use visual_scale = %.2f no EnemyData"
          % (config["altura_em_tela"], escala))
    return novas


def montar(nome):
    config = INIMIGOS[nome]
    folhas = config["folhas"]

    avisos = []
    dados = {}

    for direcao, arquivo in folhas.items():
        caminho = PASTA + arquivo
        if not os.path.exists(caminho):
            raise SystemExit("folha ausente: " + caminho)

        lq, aq, tamanho = ler_quadros(caminho)
        if tamanho[0] % lq != 0:
            avisos.append("%s: largura %d nao e multiplo de %d — o ultimo quadro sai cortado"
                          % (arquivo, tamanho[0], lq))
        if tamanho[1] != aq:
            avisos.append("%s: altura %d difere do quadro declarado %d" % (arquivo, tamanho[1], aq))

        total, alturas, bases = medir(caminho, lq, aq)
        if not alturas:
            raise SystemExit("%s: nenhuma folha com desenho" % arquivo)

        if max(bases) - min(bases) > TOLERANCIA_BASE:
            avisos.append("%s: os pes variam %d px entre quadros (limite %d) — o corpo flutua ao andar"
                          % (arquivo, max(bases) - min(bases), TOLERANCIA_BASE))

        dados[direcao] = {
            "arquivo": arquivo, "quadros": total, "lq": lq, "aq": aq,
            "altura": sum(alturas) / len(alturas), "alturas": (min(alturas), max(alturas)),
        }

    medias = [d["altura"] for d in dados.values()]
    maior, menor = max(medias), min(medias)
    if maior > 0 and (maior - menor) / maior > TOLERANCIA_ALTURA:
        piores = sorted(dados.items(), key=lambda kv: kv[1]["altura"])
        avisos.append(
            "as direcoes nao tem o mesmo tamanho: %s tem %.0f px de corpo e %s tem %.0f — "
            "a criatura mudaria de tamanho ao virar"
            % (piores[0][0], piores[0][1]["altura"], piores[-1][0], piores[-1][1]["altura"]))

    for direcao, d in dados.items():
        print("  %-6s %-30s %2d quadros | corpo %d-%d px"
              % (direcao, d["arquivo"], d["quadros"], d["alturas"][0], d["alturas"][1]))

    if avisos and not config.get("normalizar"):
        print("\n  PROBLEMAS:")
        for a in avisos:
            print("   - " + a)
        return False

    if config.get("normalizar"):
        print("\n  normalizando:")
        dados = normalizar(config, dados)

    escrever(config, dados)
    print("\n  %s escrito" % config["saida"])
    return True


def ler_morte(config):
    """A folha da queda, que vem em grade e nao em fila."""
    morte = config.get("morte")
    if morte is None:
        return None
    caminho = PASTA + morte["arquivo"]
    if not os.path.exists(caminho):
        raise SystemExit("folha da queda ausente: " + caminho)
    d = json.load(open(caminho[:-4] + ".json", encoding="utf-8"))
    im = Image.open(caminho)
    colunas, linhas_ = int(d["columns"]), int(d["rows"])
    lq, aq = int(d["frameWidth"]), int(d["frameHeight"])
    if im.size != (lq * colunas, aq * linhas_):
        raise SystemExit("%s mede %dx%d e a grade declarada pede %dx%d"
                         % (morte["arquivo"], im.size[0], im.size[1], lq * colunas, aq * linhas_))
    return {"arquivo": morte["arquivo"], "animacao": morte["animacao"],
            "velocidade": morte.get("velocidade", VELOCIDADE),
            "quadros": int(d["frames"]), "colunas": colunas, "lq": lq, "aq": aq}


def escrever(config, dados):
    ordem = list(config["folhas"].keys())
    morte = ler_morte(config)
    passos = 1 + len(ordem) + sum(dados[d]["quadros"] for d in ordem)
    if morte is not None:
        passos += 1 + morte["quadros"]

    linhas = ['[gd_resource type="SpriteFrames" load_steps=%d format=3 uid="uid://%s"]'
              % (passos, config["uid"]), ""]
    for i, direcao in enumerate(ordem):
        linhas.append('[ext_resource type="Texture2D" path="res://%s%s" id="%d_walk_%s"]'
                      % (PASTA, dados[direcao]["arquivo"], i + 1, direcao))
    if morte is not None:
        linhas.append('[ext_resource type="Texture2D" path="res://%s%s" id="%d_morte"]'
                      % (PASTA, morte["arquivo"], len(ordem) + 1))
    linhas.append("")

    for i, direcao in enumerate(ordem):
        d = dados[direcao]
        for k in range(d["quadros"]):
            linhas += ['[sub_resource type="AtlasTexture" id="AtlasTexture_walk_%s_%02d"]' % (direcao, k),
                       'atlas = ExtResource("%d_walk_%s")' % (i + 1, direcao),
                       "region = Rect2(%d, 0, %d, %d)" % (k * d["lq"], d["lq"], d["aq"]), ""]

    if morte is not None:
        for k in range(morte["quadros"]):
            coluna, linha = k % morte["colunas"], k // morte["colunas"]
            linhas += ['[sub_resource type="AtlasTexture" id="AtlasTexture_morte_%02d"]' % k,
                       'atlas = ExtResource("%d_morte")' % (len(ordem) + 1),
                       "region = Rect2(%d, %d, %d, %d)"
                       % (coluna * morte["lq"], linha * morte["aq"], morte["lq"], morte["aq"]), ""]

    linhas += ["[resource]", "animations = ["]
    blocos = []
    for direcao in ordem:
        quadros = ",\n".join(
            '{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_walk_%s_%02d")\n}' % (direcao, k)
            for k in range(dados[direcao]["quadros"]))
        blocos.append('{\n"frames": [%s],\n"loop": true,\n"name": &"walk_%s",\n"speed": %.1f\n}'
                      % (quadros, direcao, VELOCIDADE))
    if morte is not None:
        quadros = ",\n".join(
            '{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_morte_%02d")\n}' % k
            for k in range(morte["quadros"]))
        # `loop` falso de proposito: `enemy_visual.gd` espera o
        # `animation_finished`, e animacao em loop nunca o emite -- a vitoria
        # ficaria esperando para sempre.
        blocos.append('{\n"frames": [%s],\n"loop": false,\n"name": &"%s",\n"speed": %.1f\n}' 
                      % (quadros, morte["animacao"], morte["velocidade"]))
    linhas.append(", ".join(blocos) + "]")
    linhas.append("")

    open(PASTA + config["saida"], "w", encoding="utf-8", newline="\n").write("\n".join(linhas))


def main():
    alvos = sys.argv[1:] or list(INIMIGOS)
    tudo_certo = True
    for nome in alvos:
        if nome not in INIMIGOS:
            raise SystemExit("inimigo desconhecido: " + nome)
        print(nome + ":")
        tudo_certo = montar(nome) and tudo_certo
        print()
    if not tudo_certo:
        raise SystemExit(1)


main()
