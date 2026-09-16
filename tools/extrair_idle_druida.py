"""Extrai o `idle` do druida, nas quatro direcoes, do video de idle.

O video tem o formato dos videos das criaturas: 240 quadros a 24 fps, fundo
verde, quatro vistas separadas por cortes secos -- frente, perfil para a
esquerda, perfil para a direita, costas. Os cortes foram medidos em 59, 120 e
179, e os dois perfis sao lados opostos de verdade (26% de diferenca entre eles
como estao, 15% espelhados; conferidos contra as folhas de caminhada), entao
nenhum lado sai espelhado.

Tres cuidados que a caminhada nao precisou:

**O laco nao fecha sozinho.** O prompt pedia que cada trecho terminasse na pose
em que comecou, e o gerador chegou perto mas nao la: medido, o primeiro e o
ultimo quadro de cada trecho diferem de 3 a 5 vezes mais que dois quadros
vizinhos. Tocado em volta, isso e um solavanco a cada 2,5 s. Em vez do trecho
inteiro, a ferramenta procura dentro dele o par de quadros mais parecido com
pelo menos `_LACO_MINIMO` de distancia, e usa so o que fica entre os dois.

**A escala e a da caminhada da mesma direcao.** O idle troca com a caminhada a
cada vez que o jogador para. Se a altura nao bater, o druida muda de tamanho ao
parar -- foi o defeito da morte dele. E nao basta uma escala so: as proprias
folhas de caminhada nao tem a mesma altura nas quatro direcoes. Com escala unica
tirada da frente, o idle oeste saiu com 88 px contra 83 da caminhada, e o teste
da FASE 2 acusou. Cada direcao casa com a sua, medida na folha na hora.

**A esfera do cajado e verde.** O corte de fundo das criaturas trata todo verde
vivo como fundo, e depois ainda tira o verde da franja. As criaturas nao tinham
verde nenhum; o druida tem a esfera brilhante no topo do cajado, e ela sumia --
o cajado saia oco nas quatro direcoes. Aqui o fundo e so o verde **ligado a
borda do quadro**. Verde cercado pelo desenho (a esfera dentro do anel de
galhos) fica **so se tiver forma e lugar de esfera**: compacto e no terco de
cima da silhueta. Guardar todo verde cercado deixava lascas de fundo presas
entre o cabo do cajado e o manto em ate metade dos quadros. A franja perde o
verde em tudo, menos na esfera.

**O ritmo e o do video.** A caminhada toca a 15 fps; o idle nao. A velocidade
sai do comprimento do laco, para respirar no tempo em que o video respira.

Uso: python tools/extrair_idle_druida.py (a partir da raiz do projeto)
Depois: godot --headless --path . --script res://tools/ligar_idle_druida.gd
"""

import json
import os
import sys

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extrair_inimigo_video import caixa, maior_componente  # noqa: E402

VIDEO = "assets/characters/_raw/druida-idle.mp4"
PASTA = "assets/characters/"

## Taxa do video, para converter laco em velocidade de animacao.
FPS_VIDEO = 24.0

## Trechos medidos (maior salto de silhueta entre quadros vizinhos).
TRECHOS = {
    "south": (0, 59),
    # O perfil para oeste do video nao e usado: no jogo, oeste e leste espelhado
    # (mesmo tamanho por construcao). Ver `player_visual.gd`.
    "east": (120, 179),
    "north": (179, 240),
}

## Folha de caminhada de cada direcao: e ela a regua do idle.
CAMINHADAS = {
    "south": ("druida-sul-walk-south.png", 64),
    "north": ("druida-north-walk-north.png", 64),
    "east": ("druida-east-walk-east.png", 64),
}

ALTURA_QUADRO = 96
QUADROS = 16

## Menor laco aceito, em quadros do video. Abaixo disto a respiracao vira tique.
_LACO_MINIMO = 36


## Cor chapada do fundo, em HSV do OpenCV (tom 0-180), medida no video.
_FUNDO_TOM = 61
_FUNDO_SAT_MIN = 222
_FUNDO_VAL = (214, 240)

## Menor bolsao verde que pode ser a esfera, em pixels do video (1280x720).
_ESFERA_AREA_MINIMA = 60

## Raio da esfera a partir do nucleo, em pixels do video. A esfera inteira cabe
## em uns 56 px de diametro; o brilho dela fica dentro do anel de galhos.
_ESFERA_RAIO = 36


def tirar_verde(rgb):
    """Fundo fora, esfera do cajado preservada. Ver o cabecalho."""
    a = rgb.astype(int)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    verde = (g > r + 40) & (g > b + 40) & (g > 90)

    # Fundo e o verde que encosta na borda do quadro.
    _, rotulos = cv2.connectedComponents(verde.astype(np.uint8), connectivity=4)
    borda = np.unique(np.concatenate([rotulos[0, :], rotulos[-1, :], rotulos[:, 0], rotulos[:, -1]]))
    borda = borda[borda != 0]
    fundo = np.isin(rotulos, borda)

    # Verde cercado pelo desenho: so fica o que tem forma e lugar de esfera.
    #
    # A primeira versao guardava todo verde cercado, e guardou junto os bolsoes
    # de fundo presos entre o cabo do cajado e o manto -- lascas verdes em ate
    # metade dos quadros das costas e do perfil. A esfera e diferente de uma
    # lasca em duas coisas medidas: e compacta (ocupa boa parte da propria caixa,
    # e nao e comprida) e fica no terco de cima da silhueta, no topo do cajado.
    cercado = verde & ~fundo
    esfera = np.zeros_like(cercado)
    hsv = cv2.cvtColor(rgb[:, :, :3].astype(np.uint8), cv2.COLOR_RGB2HSV).astype(int)
    corpo = ~fundo & ~cercado
    linhas = np.where(corpo.any(axis=1))[0]
    if len(linhas) > 0:
        topo, base = int(linhas[0]), int(linhas[-1])
        n, rot, st, centro = cv2.connectedComponentsWithStats(cercado.astype(np.uint8), connectivity=8)
        for k in range(1, n):
            x, y, w, h, area = st[k]
            if area < _ESFERA_AREA_MINIMA:
                continue
            compacta = area / float(w * h) >= 0.35 and 0.5 <= w / float(h) <= 2.0
            no_alto = (centro[k][1] - topo) / max(1.0, float(base - topo)) <= 0.30
            # E acesa: a esfera tem nucleo quase branco dentro da caixa dela. Um
            # bolsao de fundo entre o cajado e o capuz tambem e compacto e alto --
            # nas costas passavam lascas assim em sete quadros --, mas nao brilha.
            caixa_hsv = hsv[y:y + h, x:x + w]
            # Branco-esverdeado, e nao so claro: num quadro das costas a caixa da
            # mancha pegava a gola de pele, creme e quase branca, e o "nucleo"
            # descia ate ela -- arrastando o centro da esfera para longe dela.
            nucleo = (caixa_hsv[:, :, 2] >= 235) & (caixa_hsv[:, :, 1] <= 140)                 & (caixa_hsv[:, :, 0] >= 35) & (caixa_hsv[:, :, 0] <= 85)
            if not (compacta and no_alto and nucleo.any()):
                continue
            # So o que fica perto do nucleo. Num quadro das costas, bolsoes de
            # fundo descendo pelo cabo encostavam no brilho da esfera e viravam
            # uma mancha so com ela -- passavam inteiros pelo filtro.
            ny, nx = np.where(nucleo)
            cy, cx = y + ny.mean(), x + nx.mean()
            yy, xx = np.mgrid[0:rgb.shape[0], 0:rgb.shape[1]]
            perto = (yy - cy) ** 2 + (xx - cx) ** 2 <= _ESFERA_RAIO ** 2
            esfera |= (rot == k) & perto

    chapado = (np.abs(hsv[:, :, 0] - _FUNDO_TOM) <= 3) & (hsv[:, :, 1] >= _FUNDO_SAT_MIN) \
        & (hsv[:, :, 2] >= _FUNDO_VAL[0]) & (hsv[:, :, 2] <= _FUNDO_VAL[1])
    esfera &= ~chapado
    fundo |= cercado & ~esfera
    fundo |= ~maior_componente(~fundo)

    saida = np.dstack([a, np.where(fundo, 0, 255)]).astype(np.uint8)
    # Franja: o verde que a compressao espalha na borda do desenho. Tudo perde o
    # verde, menos a esfera.
    franja = (~fundo) & (~esfera) & (g > np.maximum(r, b) + 8)
    saida[:, :, 1] = np.where(franja, np.maximum(r, b) + 8, g).astype(np.uint8)
    return saida


def ler_video(caminho):
    cap = cv2.VideoCapture(caminho)
    quadros = []
    while True:
        ok, bgr = cap.read()
        if not ok:
            break
        quadros.append(tirar_verde(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)))
    cap.release()
    if not quadros:
        raise SystemExit("nao consegui ler " + caminho)
    return quadros


def linhas_largas(alfa, minimo):
    """Primeira e ultima linha com `minimo` pixels acesos ou mais.

    E a regua do teste da FASE 2: o cajado e fino e sobe acima da cabeca, e medir
    pela caixa inteira seria medir o cajado.
    """
    linhas = np.where(alfa.sum(axis=1) >= minimo)[0]
    if len(linhas) == 0:
        return None
    return int(linhas[0]), int(linhas[-1])


def altura_da_caminhada(direcao):
    arquivo, largura = CAMINHADAS[direcao]
    a = np.array(Image.open(PASTA + arquivo).convert("RGBA"))[:, :, 3] > 40
    alturas = []
    for k in range(a.shape[1] // largura):
        faixa = linhas_largas(a[:, k * largura:(k + 1) * largura], 10)
        if faixa:
            alturas.append(faixa[1] - faixa[0] + 1)
    return float(np.median(alturas))


def assinatura(quadro):
    """Recorte em cinza pequeno, para comparar poses."""
    c = caixa(quadro)
    corpo = quadro[c[1]:c[3] + 1, c[0]:c[2] + 1]
    cinza = cv2.cvtColor(corpo[:, :, :3], cv2.COLOR_RGB2GRAY)
    cinza = np.where(corpo[:, :, 3] > 16, cinza, 0)
    return cv2.resize(cinza, (96, 64), interpolation=cv2.INTER_AREA) / 255.0


def melhor_laco(quadros):
    """O par de quadros mais parecido, com distancia minima."""
    sig = [assinatura(q) for q in quadros]
    vizinho = float(np.mean([np.mean(np.abs(sig[i] - sig[i + 1])) for i in range(len(sig) - 1)]))
    melhor = (0, len(sig) - 1, 9e9)
    for i in range(len(sig)):
        for j in range(i + _LACO_MINIMO, len(sig)):
            erro = float(np.mean(np.abs(sig[i] - sig[j])))
            if erro < melhor[2] - 1e-6 or (abs(erro - melhor[2]) < 1e-6 and j - i > melhor[1]):
                melhor = (i, j - i, erro)
    inteiro = float(np.mean(np.abs(sig[0] - sig[-1])))
    return melhor, inteiro, vizinho


def recortar(quadro, escala):
    """Recorta e reduz, com alfa pre-multiplicado.

    O fundo recortado fica transparente mas **guarda a cor verde**. Reduzir em
    RGBA comum mistura essa cor invisivel com os pixels do desenho em volta, e o
    verde volta como aro nas bordas de buracos estreitos -- entre o cajado e o
    capuz, por exemplo. Em `RGBa` (pre-multiplicado) pixel transparente pesa
    zero na mistura.
    """
    c = caixa(quadro)
    corpo = Image.fromarray(quadro[c[1]:c[3] + 1, c[0]:c[2] + 1]).convert("RGBa")
    reduzido = corpo.resize((
        max(1, int(round(corpo.size[0] * escala))),
        max(1, int(round(corpo.size[1] * escala))),
    ), Image.LANCZOS).convert("RGBA")
    # O LANCZOS deixa um halo de alfa quase zero em volta do desenho. Invisivel
    # (ate 5/255), mas com cor verde de chroma: fora, para nao sobrar rastro.
    a = np.array(reduzido)
    a[a[:, :, 3] < 10] = 0
    return Image.fromarray(a)


def altura_escalada(imagem):
    a = np.array(imagem)[:, :, 3] > 40
    faixa = linhas_largas(a, 10)
    return (faixa[1] - faixa[0] + 1) if faixa else imagem.size[1]


def main():
    quadros = ler_video(VIDEO)
    print("video: %d quadros\n" % len(quadros))

    for direcao, (a, b) in TRECHOS.items():
        trecho = quadros[a + 1:b - 1]
        (inicio, tamanho, erro), inteiro, vizinho = melhor_laco(trecho)
        indices = [inicio + int(round(k * tamanho / QUADROS)) for k in range(QUADROS)]

        # A regua de "linha larga" nao escala linearmente com o tamanho: dez
        # pixels numa folha de 96 nao sao dez num video de 720. Entao a escala
        # sai por tentativa -- recorta, mede na folha, corrige, ate bater.
        alvo = altura_da_caminhada(direcao)
        escala = alvo / float(np.median([caixa(q)[3] - caixa(q)[1] + 1 for q in trecho[::4]]))
        for _ in range(6):
            medida = np.median([altura_escalada(recortar(trecho[i], escala)) for i in indices[::4]])
            if abs(medida - alvo) < 0.5:
                break
            escala *= alvo / medida

        recortes = [recortar(trecho[i], escala) for i in indices]
        alto = max(r.size[1] for r in recortes)
        if alto > ALTURA_QUADRO:
            raise SystemExit("idle %s chega a %d px e o quadro tem %d" % (direcao, alto, ALTURA_QUADRO))
        largura = max(r.size[0] for r in recortes) + 4
        largura += largura % 2

        folha = Image.new("RGBA", (largura * QUADROS, ALTURA_QUADRO), (0, 0, 0, 0))
        for k, r in enumerate(recortes):
            folha.alpha_composite(r, (k * largura + (largura - r.size[0]) // 2, ALTURA_QUADRO - r.size[1]))

        arquivo = "druida-idle-%s.png" % direcao
        folha.save(PASTA + arquivo)
        velocidade = QUADROS / (tamanho / FPS_VIDEO)
        json.dump({
            "generator": {"name": "extrair_idle_druida.py", "version": "2"},
            "sheet": arquivo, "frameWidth": largura, "frameHeight": ALTURA_QUADRO,
            "frames": QUADROS, "layout": "horizontal", "columns": QUADROS, "rows": 1,
            "pivot": {"x": 0.5, "y": 1.0}, "speed": round(velocidade, 2),
        }, open(PASTA + arquivo[:-4] + ".json", "w", encoding="utf-8"), indent=1)
        final = np.median([altura_escalada(r) for r in recortes])
        print("%-6s laco de %d quadros (%.2f s) | volta %.3f, trecho inteiro %.3f, vizinhos %.3f"
              % (direcao, tamanho, tamanho / FPS_VIDEO, erro, inteiro, vizinho))
        print("       %s  %dx%d | corpo %.0f px, caminhada %.0f px | %.1f fps"
              % (arquivo, largura, ALTURA_QUADRO, final, alvo, velocidade))


if __name__ == "__main__":
    main()
