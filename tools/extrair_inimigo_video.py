"""Extrai as folhas de caminhada de um inimigo a partir de um video.

O video do cao de inferno resolveu de uma vez o problema que as folhas estaticas
tinham: nele as quatro vistas estao na mesma escala de mundo, porque sao a mesma
animacao vista de angulos diferentes. Nas folhas soltas o perfil vinha com um
terco da altura da frente.

O que o script faz:

**Acha o ciclo.** Compara a silhueta de cada quadro com a dos seguintes e
procura o periodo que se repete. No cao deu 24 quadros a 24 fps -- um segundo
exato -- e o script tira 12 deles, um ciclo a 12 fps, que e a velocidade de
animacao do projeto.

**Usa uma escala unica para as quatro direcoes.** Normalizar cada uma para a
mesma altura seria errado: um quadrupede de frente e mais alto que de perfil, e
isso e anatomia, nao defeito. A escala sai da vista de frente e vale para todas.

**Alinha pela pata mais baixa.** A origem do inimigo esta nos pes e o Y-sort
depende disso. Encostar o pixel mais baixo de cada quadro na base do quadro tira
o balanco vertical que a animacao original tinha.

**Tira o verde e o resto do verde.** Alem do fundo, a compressao do video deixa
uma franja esverdeada na borda; ela e despilada, nunca o pelo do bicho.

Uso: python tools/extrair_inimigo_video.py [nome]  (a partir da raiz do projeto)
"""

import json
import os
import sys

import cv2
import numpy as np
from PIL import Image

PASTA = "assets/characters/inimigos/"

## Altura do corpo, em pixels, que a vista de **frente** deve ter no arquivo.
## Com o no `Visual` da cena em 0.5, isso da 40 px em tela -- pouco abaixo dos
## 46 do diabrete, que e o que o `04_CONTENT_PLAN.md` pede para o cao.
ALTURA_DE_FRENTE = 80

## Altura do quadro. Nao muda: e ela que faz o pe cair na origem do no, com o
## `Sprite` em (0,-48) dentro do `Visual`.
ALTURA_QUADRO = 96

## Quantos quadros por direcao entram na folha final.
QUADROS_POR_DIRECAO = 12

INIMIGOS = {
    "cao": {
        "video": PASTA + "_raw/cao demoniaco  movimentação.mp4",
        "prefixo": "cao",
        # Faixa de quadros de cada trecho do video, e o rotulo que aparece nele.
        "trechos": {"south": (0, 60), "north": (60, 120), "perfil": (120, 180)},
        # O video rotula dois trechos como leste e oeste, mas os dois mostram o
        # cao olhando para a **esquerda** -- conferido por comparacao de
        # silhueta: 3,8% de diferenca como estao, 20,5% espelhados. Entao um
        # unico trecho serve de perfil, e o outro lado sai espelhado (regra 9 do
        # `docs/ASSET_WORKFLOW.md`).
        "direcoes": {
            "south": ("south", False),
            "north": ("north", False),
            "west": ("perfil", False),
            "east": ("perfil", True),
        },
        # A vista de frente e a regua da escala.
        "referencia": "south",
        # Acima desta linha fica o texto da direcao, nao o bicho.
        "linha_do_rotulo": 140,
        # Quadros de folga nas pontas de cada trecho, para nao pegar transicao.
        "folga": 16,
    },
}


def ler_video(caminho, linha_do_rotulo):
    """Devolve os quadros ja sem o fundo verde, como RGBA."""
    if not os.path.exists(caminho):
        raise SystemExit("video ausente: " + caminho)

    cap = cv2.VideoCapture(caminho)
    quadros = []
    while True:
        ok, bgr = cap.read()
        if not ok:
            break
        quadros.append(tirar_verde(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB), linha_do_rotulo))
    cap.release()
    if not quadros:
        raise SystemExit("nao consegui ler quadro nenhum de " + caminho)
    return quadros


def tirar_verde(rgb, linha_do_rotulo):
    """Fundo verde fora, franja esverdeada despilada.

    A franja vem da compressao do video: a borda do bicho fica misturada com o
    fundo. Baixar o verde ate o maior dos outros dois canais tira o halo sem
    tocar em pixel que e verde de verdade -- e nao ha nenhum, o cao e cinza e
    laranja.
    """
    a = rgb.astype(int)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]

    fundo = (g > r + 40) & (g > b + 40) & (g > 90)
    fundo[:linha_do_rotulo] = True

    saida = np.dstack([a, np.where(fundo, 0, 255)]).astype(np.uint8)
    franja = (~fundo) & (g > np.maximum(r, b) + 8)
    saida[:, :, 1] = np.where(franja, np.maximum(r, b) + 8, g).astype(np.uint8)
    return saida


def caixa(quadro):
    ys, xs = np.where(quadro[:, :, 3] > 16)
    if len(ys) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def achar_ciclo(quadros, limite=32):
    """O periodo em que a silhueta volta a se parecer consigo mesma."""
    sils = []
    for q in quadros:
        c = caixa(q)
        if c is None:
            continue
        rec = (q[c[1]:c[3] + 1, c[0]:c[2] + 1, 3] > 16).astype(np.uint8)
        sils.append(cv2.resize(rec, (96, 64), interpolation=cv2.INTER_AREA) > 0)

    melhor, periodo = 9e9, 0
    for p in range(6, min(limite, len(sils) - 1)):
        difs = [np.mean(sils[i] != sils[i + p]) for i in range(len(sils) - p)]
        if difs and np.mean(difs) < melhor:
            melhor, periodo = np.mean(difs), p
    return periodo, melhor


def montar(nome):
    config = INIMIGOS[nome]
    quadros = ler_video(config["video"], config["linha_do_rotulo"])
    print("  video: %d quadros" % len(quadros))

    trechos = {}
    for rotulo, (a, b) in config["trechos"].items():
        folga = config["folga"]
        miolo = quadros[a + folga:b - folga]
        periodo, erro = achar_ciclo(miolo)
        alturas = [caixa(q)[3] - caixa(q)[1] + 1 for q in miolo if caixa(q)]
        trechos[rotulo] = {"quadros": miolo, "periodo": periodo}
        print("  %-7s %2d quadros uteis | ciclo de %d | corpo %d-%d px"
              % (rotulo, len(miolo), periodo, min(alturas), max(alturas)))

    # O periodo vale para as tres vistas: e a mesma animacao de angulos
    # diferentes. Detectar em cada uma daria numeros ligeiramente distintos --
    # a silhueta de perfil tem mais movimento e confunde a comparacao -- e um
    # periodo errado faz a caminhada dar um salto ao voltar ao primeiro quadro.
    periodo = trechos[config["referencia"]]["periodo"]
    outros = [t["periodo"] for r, t in trechos.items() if r != config["referencia"]]
    if any(abs(p - periodo) > 3 for p in outros):
        print("  aviso: os trechos discordam do ciclo (%s); vale o da referencia, %d"
              % (outros, periodo))

    ref = trechos[config["referencia"]]
    alturas_ref = [caixa(q)[3] - caixa(q)[1] + 1 for q in ref["quadros"] if caixa(q)]
    escala = ALTURA_DE_FRENTE / float(np.median(alturas_ref))
    print("\n  escala unica: %.4f (frente %d px -> %d px)"
          % (escala, int(np.median(alturas_ref)), ALTURA_DE_FRENTE))

    saidas = {}
    for direcao, (rotulo, espelhar) in config["direcoes"].items():
        trecho = trechos[rotulo]
        # Espalha os quadros por **um ciclo inteiro**, e nao de um em um: pegar
        # os doze primeiros de um ciclo de vinte e tres mostraria metade da
        # passada e a animacao saltaria ao voltar para o inicio.
        indices = [int(round(i * periodo / QUADROS_POR_DIRECAO)) % len(trecho["quadros"])
                   for i in range(QUADROS_POR_DIRECAO)]

        recortes = []
        for i in indices:
            q = trecho["quadros"][i]
            c = caixa(q)
            corpo = Image.fromarray(q[c[1]:c[3] + 1, c[0]:c[2] + 1])
            if espelhar:
                corpo = corpo.transpose(Image.FLIP_LEFT_RIGHT)
            recortes.append(corpo.resize((
                max(1, int(round(corpo.size[0] * escala))),
                max(1, int(round(corpo.size[1] * escala))),
            ), Image.LANCZOS))

        largura = max(r.size[0] for r in recortes) + 4
        largura += largura % 2  # par: quadro impar deixa o corpo meio pixel fora do centro

        folha = Image.new("RGBA", (largura * len(recortes), ALTURA_QUADRO), (0, 0, 0, 0))
        for i, r in enumerate(recortes):
            folha.alpha_composite(r, (
                i * largura + (largura - r.size[0]) // 2,
                ALTURA_QUADRO - r.size[1],
            ))

        arquivo = "%s-%s.png" % (config["prefixo"], direcao)
        folha.save(PASTA + arquivo)

        # O JSON ao lado, no mesmo formato do gerador de sprites: e por ele que
        # `preparar_inimigo.py` sabe a largura do quadro. Cada direcao tem a sua
        # -- o cao de perfil e mais que o dobro da largura do cao de frente --
        # e deduzir isso da imagem daria 64 para todo mundo.
        json.dump({
            "generator": {"name": "extrair_inimigo_video.py", "version": "1"},
            "sheet": arquivo, "frameWidth": largura, "frameHeight": ALTURA_QUADRO,
            "frames": len(recortes), "layout": "horizontal",
            "columns": len(recortes), "rows": 1,
            "pivot": {"x": 0.5, "y": 1.0},
        }, open(PASTA + arquivo[:-4] + ".json", "w", encoding="utf-8"), indent=1)
        saidas[direcao] = (arquivo, len(recortes), largura, max(r.size[1] for r in recortes))
        print("  %-6s %-16s %2d quadros de %dx%d | corpo %d px%s"
              % (direcao, arquivo, len(recortes), largura, ALTURA_QUADRO,
                 max(r.size[1] for r in recortes), "  (espelhado)" if espelhar else ""))

    return saidas


def main():
    for nome in (sys.argv[1:] or list(INIMIGOS)):
        if nome not in INIMIGOS:
            raise SystemExit("inimigo desconhecido: " + nome)
        print(nome + ":")
        montar(nome)
        print("\n  agora: python tools/preparar_inimigo.py %s" % nome)


main()
