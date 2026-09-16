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

## Padroes, quando o inimigo nao diz outra coisa.
##
## `altura_de_frente` e a altura do corpo na vista de frente, em pixels de
## arquivo. Com o no `Visual` da cena em 0.5 e `visual_scale` em 1, ela vale
## metade disso em tela: 80 aqui sao os 40 px do cao.
##
## `altura_quadro` precisa caber o quadro mais alto da animacao -- o corpo sobe
## e desce andando --, e e dela que sai o pivo: o pe encosta na base do quadro.
ALTURA_DE_FRENTE = 80
ALTURA_QUADRO = 96
QUADROS_POR_DIRECAO = 12

## Limite de largura de textura das GPUs Android antigas (BUG-001). Uma folha
## acima disso nao carrega no aparelho, e e melhor descobrir aqui.
LARGURA_MAXIMA = 4096

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
        # 184 px de corpo dao 92 px em tela, acima dos 86 do druida. O cao media
        # 40 -- menor que o diabrete, que e a criatura mais fraca do jogo.
        "altura_de_frente": 184,
        "altura_quadro": 224,
        "referencia": "south",
        # Acima desta linha fica o texto da direcao, nao o bicho.
        "linha_do_rotulo": 140,
        # Quadros de folga nas pontas de cada trecho, para nao pegar transicao.
        "folga": 16,
        # Travado no valor com que as folhas do cao entraram no jogo. O detector
        # mudou depois (passou a comparar pixel, por causa da meia-passada do
        # Guardiao) e agora mede 22 aqui. Os dois valores servem; trocar sem
        # necessidade so mexeria numa arte ja aprovada.
        "ciclo": 24,
    },
    # Os tres videos abaixo tem o mesmo formato: 240 quadros a 24 fps, quatro
    # vistas de 60 -- frente, perfil, perfil de novo, costas -- e uma estrelinha
    # de marca d'agua flutuando ao lado do bicho, que sai no recorte do maior
    # componente (ver `tirar_verde`). Nao tem texto: `linha_do_rotulo` e zero.
    #
    # Qual perfil o video traz esta no **nome do arquivo**, posto por quem
    # gerou, e foi conferido por silhueta: no bruto e na elite os dois trechos
    # de perfil sao o mesmo lado (21% e 15% de diferenca entre eles, contra 30%
    # e 53% espelhados), entao um lado sai espelhado do outro. No Guardiao os
    # trechos sao lados opostos de verdade (37% iguais contra 21% espelhados), e
    # a galhada clara diz qual e qual: a 0,33 da largura no trecho 2 (cabeca a
    # esquerda, oeste) e a 0,68 no trecho 3 (leste).
    "bruto": {
        "video": PASTA + "_raw/Bruto-espelharEast.mp4",
        "prefixo": "bruto",
        "trechos": {"south": (0, 59), "perfil": (59, 120), "north": (180, 240)},
        "direcoes": {
            "south": ("south", False),
            "north": ("north", False),
            "west": ("perfil", False),
            "east": ("perfil", True),
        },
        "referencia": "south",
        "ciclo_de": "perfil",
        "linha_do_rotulo": 0,
        # Um quadro de folga, e nao dezesseis: os cortes destes videos sao secos
        # -- medidos em 59, 120 e 180 -- e o trecho inteiro faz falta, porque a
        # passada do Guardiao leva 50 quadros e nao cabe num pedaco menor.
        "folga": 1,
        # 236 px de corpo dao 118 px em tela, contra os 86 do druida. A arte
        # propria trouxe a chance de corrigir o tamanho: com a folha do diabrete
        # ampliada o bruto media 67 px, menor que o personagem que ele deveria
        # intimidar.
        "altura_de_frente": 236,
        "altura_quadro": 264,
    },
    "elite": {
        "video": PASTA + "_raw/elite-espelharWest.mp4",
        "prefixo": "elite",
        "trechos": {"south": (0, 59), "perfil": (59, 120), "north": (180, 240)},
        "direcoes": {
            "south": ("south", False),
            "north": ("north", False),
            "west": ("perfil", True),
            "east": ("perfil", False),
        },
        "referencia": "south",
        "ciclo_de": "perfil",
        "linha_do_rotulo": 0,
        "folga": 1,
        # 104 px em tela: maior que o druida, e mais esguia que o bruto.
        "altura_de_frente": 208,
        "altura_quadro": 232,
    },
    "guardiao": {
        "video": PASTA + "_raw/Guardião movimentaão.mp4",
        "prefixo": "guardiao",
        "trechos": {"south": (0, 59), "west": (59, 120), "east": (120, 180),
                    "north": (180, 240)},
        "direcoes": {
            "south": ("south", False),
            "north": ("north", False),
            "west": ("west", False),
            "east": ("east", False),
        },
        "referencia": "south",
        "ciclo_de": "west",
        "linha_do_rotulo": 0,
        "folga": 1,
        # 220 px em tela: quase o dobro do bruto (118) e dois druidas e meio.
        # Um chefe tem de ser reconhecivel de longe, no meio da horda.
        "altura_de_frente": 440,
        "altura_quadro": 500,
    },
}

## Animacoes avulsas: nao sao ciclo, tocam uma vez e acabam (DEC-024).
##
## O recorte aqui e **o mesmo para todos os quadros** -- a janela e a uniao das
## caixas da faixa inteira. Recortar quadro a quadro, como na caminhada,
## apagaria justamente o movimento: o corpo que tomba ficaria centrado a cada
## quadro e o Guardiao morreria sem sair do lugar.
MORTES = {
    "guardiao": {
        "video": PASTA + "_raw/guardian Defeat.mp4",
        "prefixo": "guardiao",
        "animacao": "death",
        # Do cambaleio ate o corpo assentar. Depois disso o video so segura a
        # pose, e segurar pose e trabalho do `AnimatedSprite2D`, nao de quadro.
        "faixa": (0, 186),
        "quadros": 30,
        "linha_do_rotulo": 0,
        # Quadros em que ele ainda esta de pe: e por eles que a escala da queda
        # casa com a da caminhada.
        "de_pe": (4, 40),
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
    fundo |= ~maior_componente(~fundo)

    saida = np.dstack([a, np.where(fundo, 0, 255)]).astype(np.uint8)
    franja = (~fundo) & (g > np.maximum(r, b) + 8)
    saida[:, :, 1] = np.where(franja, np.maximum(r, b) + 8, g).astype(np.uint8)
    return saida


def maior_componente(mascara):
    """So o bicho sobrevive; respingo solto vira fundo.

    Os videos novos tem uma estrelinha de marca d'agua flutuando ao lado do
    bicho. Ela nao e verde, entao passa pelo corte de fundo -- e ai entra na
    caixa do recorte, que e quem decide enquadramento e escala. Uma criatura
    inteira e sempre um so pedaco ligado; a estrelinha, outro, menor.
    """
    total, rotulos, stats, _ = cv2.connectedComponentsWithStats(
        mascara.astype(np.uint8), 8)
    if total <= 1:
        return mascara
    maior = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return rotulos == maior


def caixa(quadro):
    ys, xs = np.where(quadro[:, :, 3] > 16)
    if len(ys) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def achar_ciclo(quadros, limite=0):
    """O periodo em que a caminhada volta ao mesmo pe.

    Compara **pixel**, e nao silhueta. De perfil, a meia-passada tem silhueta
    quase igual a da passada inteira -- as pernas trocam de lugar e o contorno
    mal muda --, e por silhueta o cao dava 24 mas o Guardiao daria 24 no lugar
    de 50. Em pixel a perna de tras e mais escura que a da frente, e o minimo
    da passada inteira fica mais fundo que o da meia.

    A escolha e o **melhor minimo local**, nao o menor valor absoluto: a curva
    cai de novo perto do fim do trecho, onde sobram poucos pares para comparar.
    """
    amostras = []
    for q in quadros:
        c = caixa(q)
        if c is None:
            continue
        corpo = q[c[1]:c[3] + 1, c[0]:c[2] + 1]
        cinza = cv2.cvtColor(corpo[:, :, :3], cv2.COLOR_RGB2GRAY)
        cinza = np.where(corpo[:, :, 3] > 16, cinza, 0)
        amostras.append(cv2.resize(cinza, (96, 64), interpolation=cv2.INTER_AREA) / 255.0)

    teto = min(limite, len(amostras) - 6) if limite > 0 else len(amostras) - 6
    if teto < 8:
        return 0, 1.0
    erro = {}
    for p in range(4, teto + 1):
        erro[p] = float(np.mean([np.mean(np.abs(amostras[i] - amostras[i + p]))
                                 for i in range(len(amostras) - p)]))

    alto = max(erro.values())
    locais = [p for p in range(6, teto)
              if erro[p] < erro[p - 1] and erro[p] <= erro[p + 1] and erro[p] < 0.75 * alto]
    if not locais:
        p = min(erro, key=erro.get)
        return p, erro[p]
    melhor = min(locais, key=lambda p: erro[p])
    return melhor, erro[melhor]


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
    # O ciclo sai da vista de **perfil**, nao da referencia de escala: de frente
    # o bicho anda para a camera e a silhueta quase nao muda, que e o pior lugar
    # para medir passada. A escala continua saindo da frente.
    fonte_do_ciclo = config.get("ciclo_de", config["referencia"])
    periodo = config.get("ciclo") or trechos[fonte_do_ciclo]["periodo"]
    outros = [t["periodo"] for r, t in trechos.items() if r != fonte_do_ciclo]
    if any(abs(p - periodo) > 3 for p in outros):
        print("  aviso: os trechos discordam do ciclo (%s); vale o de %s, %d"
              % (outros, fonte_do_ciclo, periodo))

    ref = trechos[config["referencia"]]
    alturas_ref = [caixa(q)[3] - caixa(q)[1] + 1 for q in ref["quadros"] if caixa(q)]
    altura_alvo = config.get("altura_de_frente", ALTURA_DE_FRENTE)
    altura_quadro = config.get("altura_quadro", ALTURA_QUADRO)
    por_direcao = config.get("quadros", QUADROS_POR_DIRECAO)
    escala = altura_alvo / float(np.median(alturas_ref))
    print("\n  escala unica: %.4f (frente %d px -> %d px)"
          % (escala, int(np.median(alturas_ref)), altura_alvo))

    saidas = {}
    for direcao, (rotulo, espelhar) in config["direcoes"].items():
        trecho = trechos[rotulo]
        # Espalha os quadros por **um ciclo inteiro**, e nao de um em um: pegar
        # os doze primeiros de um ciclo de vinte e tres mostraria metade da
        # passada e a animacao saltaria ao voltar para o inicio.
        indices = [int(round(i * periodo / por_direcao)) % len(trecho["quadros"])
                   for i in range(por_direcao)]

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

        mais_alto = max(r.size[1] for r in recortes)
        if mais_alto > altura_quadro:
            raise SystemExit(
                "o corpo de %s-%s chega a %d px e o quadro tem %d: aumente `altura_quadro`"
                % (config["prefixo"], direcao, mais_alto, altura_quadro))

        # Em fila enquanto couber; em grade quando nao couber. O perfil do
        # Guardiao tem 367 px de quadro e doze deles passariam de 4096, que e o
        # limite de textura das GPUs Android antigas (BUG-001). Dobrar a folha
        # em linhas custa nada e e melhor do que jogar fora quadros de animacao.
        colunas = max(1, min(len(recortes), LARGURA_MAXIMA // largura))
        linhas_da_grade = (len(recortes) + colunas - 1) // colunas
        if linhas_da_grade * altura_quadro > LARGURA_MAXIMA:
            raise SystemExit(
                "a folha de %s-%s nao cabe em %d px nem em grade: reduza `altura_de_frente`"
                % (config["prefixo"], direcao, LARGURA_MAXIMA))

        folha = Image.new("RGBA", (largura * colunas, altura_quadro * linhas_da_grade), (0, 0, 0, 0))
        for i, r in enumerate(recortes):
            folha.alpha_composite(r, (
                (i % colunas) * largura + (largura - r.size[0]) // 2,
                (i // colunas) * altura_quadro + (altura_quadro - r.size[1]),
            ))

        arquivo = "%s-%s.png" % (config["prefixo"], direcao)
        folha.save(PASTA + arquivo)

        # O JSON ao lado, no mesmo formato do gerador de sprites: e por ele que
        # `preparar_inimigo.py` sabe a largura do quadro. Cada direcao tem a sua
        # -- o cao de perfil e mais que o dobro da largura do cao de frente --
        # e deduzir isso da imagem daria 64 para todo mundo.
        json.dump({
            "generator": {"name": "extrair_inimigo_video.py", "version": "1"},
            "sheet": arquivo, "frameWidth": largura, "frameHeight": altura_quadro,
            "frames": len(recortes),
            "layout": "horizontal" if linhas_da_grade == 1 else "grid",
            "columns": colunas, "rows": linhas_da_grade,
            "pivot": {"x": 0.5, "y": 1.0},
        }, open(PASTA + arquivo[:-4] + ".json", "w", encoding="utf-8"), indent=1)
        saidas[direcao] = (arquivo, len(recortes), largura, max(r.size[1] for r in recortes))
        print("  %-6s %-16s %2d quadros de %dx%d em %dx%d | corpo %d px%s"
              % (direcao, arquivo, len(recortes), largura, altura_quadro,
                 colunas, linhas_da_grade,
                 max(r.size[1] for r in recortes), "  (espelhado)" if espelhar else ""))

    return saidas


def montar_morte(nome):
    """A queda: uma animacao so, que toca uma vez e acaba (DEC-024)."""
    config = MORTES[nome]
    caminho_da_caminhada = INIMIGOS[nome]
    quadros = ler_video(config["video"], config["linha_do_rotulo"])
    a, b = config["faixa"]
    faixa = quadros[a:b]
    print("  video: %d quadros, usando %d a %d" % (len(quadros), a, b))

    # A escala nao pode sair daqui sozinha: a queda e a caminhada tem de ter o
    # mesmo tamanho de mundo. Os quadros em que ele ainda esta de pe sao a
    # regua, e o alvo e a mesma altura de frente da caminhada.
    de_pe = [caixa(q) for q in quadros[config["de_pe"][0]:config["de_pe"][1]]]
    alturas = [c[3] - c[1] + 1 for c in de_pe if c]
    altura_alvo = caminho_da_caminhada.get("altura_de_frente", ALTURA_DE_FRENTE)
    altura_quadro = caminho_da_caminhada.get("altura_quadro", ALTURA_QUADRO)
    escala = altura_alvo / float(np.median(alturas))
    print("  de pe: %d px -> escala %.4f (a mesma altura da caminhada, %d px)"
          % (int(np.median(alturas)), escala, altura_alvo))

    # Janela unica para todos os quadros. Recortar quadro a quadro, como na
    # caminhada, centraria o corpo a cada quadro e o Guardiao morreria sem sair
    # do lugar -- justamente o movimento que esta animacao existe para mostrar.
    caixas = [caixa(q) for q in faixa]
    x0 = min(c[0] for c in caixas if c)
    y0 = min(c[1] for c in caixas if c)
    x1 = max(c[2] for c in caixas if c)
    y1 = max(c[3] for c in caixas if c)

    indices = [int(round(i * (len(faixa) - 1) / (config["quadros"] - 1)))
               for i in range(config["quadros"])]
    recortes = []
    for i in indices:
        janela = Image.fromarray(faixa[i][y0:y1 + 1, x0:x1 + 1])
        recortes.append(janela.resize((
            max(1, int(round(janela.size[0] * escala))),
            max(1, int(round(janela.size[1] * escala))),
        ), Image.LANCZOS))

    largura = recortes[0].size[0] + 2
    largura += largura % 2
    if max(r.size[1] for r in recortes) > altura_quadro:
        raise SystemExit("a queda de %s chega a %d px e o quadro da caminhada tem %d"
                         % (nome, max(r.size[1] for r in recortes), altura_quadro))

    # Em grade, e nao em fila: trinta quadros de 346 px dariam uma folha de
    # 10 mil px de largura, muito acima do limite das GPUs Android (BUG-001).
    colunas = max(1, min(len(recortes), LARGURA_MAXIMA // largura))
    linhas_da_grade = (len(recortes) + colunas - 1) // colunas
    folha = Image.new("RGBA", (largura * colunas, altura_quadro * linhas_da_grade), (0, 0, 0, 0))
    for i, r in enumerate(recortes):
        folha.alpha_composite(r, (
            (i % colunas) * largura + (largura - r.size[0]) // 2,
            (i // colunas) * altura_quadro + (altura_quadro - r.size[1]),
        ))

    arquivo = "%s-%s.png" % (config["prefixo"], config["animacao"])
    folha.save(PASTA + arquivo)
    json.dump({
        "generator": {"name": "extrair_inimigo_video.py", "version": "2"},
        "sheet": arquivo, "frameWidth": largura, "frameHeight": altura_quadro,
        "frames": len(recortes), "layout": "grid",
        "columns": colunas, "rows": linhas_da_grade,
        "pivot": {"x": 0.5, "y": 1.0},
    }, open(PASTA + arquivo[:-4] + ".json", "w", encoding="utf-8"), indent=1)
    print("  %-6s %-20s %2d quadros de %dx%d em grade de %dx%d"
          % (config["animacao"], arquivo, len(recortes), largura, altura_quadro,
             colunas, linhas_da_grade))


def main():
    for nome in (sys.argv[1:] or list(INIMIGOS)):
        if nome not in INIMIGOS:
            raise SystemExit("inimigo desconhecido: " + nome)
        print(nome + ":")
        montar(nome)
        if nome in MORTES:
            print("\n  queda:")
            montar_morte(nome)
        print("\n  agora: python tools/preparar_inimigo.py %s" % nome)


if __name__ == "__main__":
    main()
