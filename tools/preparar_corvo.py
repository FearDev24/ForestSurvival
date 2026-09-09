"""Recorta o sheet do Corvo Espiritual em frames de tamanho igual.

O gerador entrega os frames em celulas do mesmo tamanho, mas o desenho dentro
de cada uma varia de tamanho e de posicao -- num quadro o corvo tem as asas
erguidas e ocupa 179x161, noutro esta mergulhando e ocupa 230x131. Colado
assim, o projetil pularia de posicao a cada quadro.

O script recorta cada celula no conteudo e recentraliza todas numa tela comum,
para que o corpo do corvo fique parado enquanto so as asas se mexem.

Saida: assets/effects/corvo.png (linha unica) e o SpriteFrames ao lado.

Uso: python tools/preparar_corvo.py (a partir da raiz do projeto)
"""

from PIL import Image
import numpy as np

ORIGEM = "assets/_raw/ui/Corvo Espiritual — sprite do efeito.png"
FRAMES = 6
## Largura de cada quadro no arquivo final. A altura sai da proporcao.
LARGURA_FINAL = 96


def main():
    im = Image.open(ORIGEM).convert("RGBA")
    a = np.array(im)
    largura_celula = im.size[0] // FRAMES

    recortes = []
    for i in range(FRAMES):
        cel = a[:, i * largura_celula:(i + 1) * largura_celula]
        ys, xs = np.where(cel[:, :, 3] > 16)
        if len(xs) == 0:
            continue
        recortes.append(Image.fromarray(cel[ys.min():ys.max() + 1, xs.min():xs.max() + 1]))

    maior_w = max(r.size[0] for r in recortes)
    maior_h = max(r.size[1] for r in recortes)
    altura_final = max(1, int(round(LARGURA_FINAL * maior_h / maior_w)))

    folha = Image.new("RGBA", (LARGURA_FINAL * len(recortes), altura_final), (0, 0, 0, 0))
    for i, r in enumerate(recortes):
        tela = Image.new("RGBA", (maior_w, maior_h), (0, 0, 0, 0))
        tela.alpha_composite(r, ((maior_w - r.size[0]) // 2, (maior_h - r.size[1]) // 2))
        folha.alpha_composite(tela.resize((LARGURA_FINAL, altura_final), Image.LANCZOS),
                              (i * LARGURA_FINAL, 0))

    folha.save("assets/effects/corvo.png")
    escrever_sprite_frames(len(recortes), LARGURA_FINAL, altura_final)
    print("corvo: %d frames de %dx%d (tela comum %dx%d)"
          % (len(recortes), LARGURA_FINAL, altura_final, maior_w, maior_h))


def escrever_sprite_frames(quantos, largura, altura):
    linhas = ['[gd_resource type="SpriteFrames" load_steps=%d format=3 uid="uid://bfscorvoframes"]'
              % (quantos + 2), "",
              '[ext_resource type="Texture2D" path="res://assets/effects/corvo.png" id="1_corvo"]', ""]
    for i in range(quantos):
        linhas += ['[sub_resource type="AtlasTexture" id="AtlasTexture_corvo_%02d"]' % i,
                   'atlas = ExtResource("1_corvo")',
                   "region = Rect2(%d, 0, %d, %d)" % (i * largura, largura, altura), ""]
    linhas += ["[resource]", "animations = [{", '"frames": [{']
    corpo = []
    for i in range(quantos):
        corpo.append('"duration": 1.0,\n"texture": SubResource("AtlasTexture_corvo_%02d")' % i)
    linhas.append("}, {".join(corpo))
    # `loop` verdadeiro: o corvo voa ate acertar ou expirar, nao ate a animacao
    # acabar -- ao contrario dos golpes, que se liberam no fim da animacao.
    linhas += ["}],", '"loop": true,', '"name": &"fly",', '"speed": 12.0', "}]", ""]
    open("assets/effects/corvo_sprite_frames.tres", "w", encoding="utf-8",
         newline="\n").write("\n".join(linhas))


main()
