"""Prepara as folhas de animacao dos efeitos e escreve os SpriteFrames.

As folhas do orbe, do anel de esporos e do vagalume chegaram com transparencia
de verdade, e nao sobre magenta. Mas o fundo **cercado de desenho** ficou: o
miolo do anel e os vaos entre as asas do vagalume vieram magenta, o mesmo caso
do miolo das letras (ver tools/preparar_painel_ui.py). Aqui esses bolsoes saem,
e o rosa que sobra da beirada antisserrilhada vira cinza de mesma luminancia.

A ferramenta tambem **mede o desenho quadro a quadro** e imprime o raio visivel
de cada um: e esse numero que decide a escala do sprite na cena, para a arte
casar com a colisao -- a regra do `tests/test_acerto.gd`.

Uso: python tools/preparar_efeitos.py (a partir da raiz do projeto)
"""

import numpy as np
from PIL import Image
from scipy import ndimage as nd

ORIGEM = "assets/_raw/ui/"
DESTINO = "assets/effects/"

## Folhas: origem, nome no jogo, largura do quadro, animacao, fps e quais
## quadros entram (lista vazia: todos).
##
## O anel de esporos cresce de 84 a 128 px de raio ao longo da folha. Como
## **zona** ele precisa de tamanho constante -- a colisao e um circulo fixo, e
## quadro pequeno acertaria antes de a nuvem encostar. Ficam os dois maiores.
FOLHAS = [
    ("orbe do cajado.png", "orbe", 64, "fly", 10.0, []),
    ("anel de esporos efeito.png", "esporos", 256, "idle", 4.0, [2, 3]),
    ("vagalume.png", "vagalume", 32, "idle", 10.0, []),
]

VERDE_DE_FUNDO = 20
MINIMO_DE_FUNDO = 150
DESVIO_DE_FUNDO = 25


def limpar(caminho):
    """Tira o magenta que sobrou, inclusive o cercado de desenho."""
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))
    familia = (r > g + 20) & (b > g + 20) & (al > 16)
    if familia.any():
        rot, n = nd.label(familia)
        for i in range(1, n + 1):
            bolsao = rot == i
            cor = [a[:, :, c][bolsao].mean() for c in range(3)]
            chapado = (cor[1] < VERDE_DE_FUNDO and min(cor[0], cor[2]) > MINIMO_DE_FUNDO
                       and abs(cor[0] - cor[2]) < DESVIO_DE_FUNDO)
            if chapado:
                a[bolsao] = 0
    # O que restar de rosa e beirada antisserrilhada: vira cinza, nao buraco.
    r, g, b, al = (a[:, :, i] for i in range(4))
    resto = (r > g + 20) & (b > g + 20) & (al > 16)
    if resto.any():
        luz = (0.299 * r + 0.587 * g + 0.114 * b).astype(int)
        for c in range(3):
            a[:, :, c][resto] = luz[resto]
    return a.astype("uint8")


def medir(a, lado, quadros):
    """Raio visivel de cada quadro, a partir do centro dele."""
    medidas = []
    for i in range(quadros):
        fatia = a[:, i * lado:(i + 1) * lado, 3]
        ys, xs = np.where(fatia > 16)
        if len(xs) == 0:
            medidas.append(0.0)
            continue
        cx = cy = (lado - 1) / 2.0
        medidas.append(float(max(xs.max() - cx, cx - xs.min(), ys.max() - cy, cy - ys.min())))
    return medidas


def escrever_frames(nome, usados, lado, animacao, fps, uid):
    caminho = DESTINO + nome + "_sprite_frames.tres"
    partes = ['[gd_resource type="SpriteFrames" load_steps=%d format=3 uid="uid://%s"]\n'
              % (len(usados) + 2, uid),
              '[ext_resource type="Texture2D" path="res://%s%s.png" id="1_%s"]\n'
              % (DESTINO, nome, nome)]
    for i in usados:
        partes.append('[sub_resource type="AtlasTexture" id="AtlasTexture_%s_%02d"]\n'
                      'atlas = ExtResource("1_%s")\n'
                      'region = Rect2(%d, 0, %d, %d)\n' % (nome, i, nome, i * lado, lado, lado))
    corpo = ",\n".join('{"duration": 1.0,\n"texture": SubResource("AtlasTexture_%s_%02d")}'
                       % (nome, i) for i in usados)
    partes.append('[resource]\nanimations = [{\n"frames": [%s],\n"loop": true,\n'
                  '"name": &"%s",\n"speed": %.1f\n}]\n' % (corpo, animacao, fps))
    open(caminho, "w", encoding="utf-8", newline="\n").write("\n".join(partes))
    return caminho


def main():
    for arquivo, nome, lado, animacao, fps, recorte in FOLHAS:
        a = limpar(ORIGEM + arquivo)
        altura, largura = a.shape[:2]
        assert altura == lado and largura % lado == 0, \
            "%s: folha %dx%d nao bate com quadro de %d" % (arquivo, largura, altura, lado)
        quadros = largura // lado
        Image.fromarray(a).save(DESTINO + nome + ".png")
        raios = medir(a, lado, quadros)
        usados = recorte or list(range(quadros))
        caminho = escrever_frames(nome, usados, lado, animacao, fps, "bfs%sframes" % nome)
        print("%-9s %d de %d quadros de %d px | raio visivel: %s | usados %s" % (
            nome, len(usados), quadros, lado, ", ".join("%.0f" % r for r in raios), str(usados)))


if __name__ == "__main__":
    main()
