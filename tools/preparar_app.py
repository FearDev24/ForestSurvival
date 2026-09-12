"""Prepara o icone do app a partir da arte crua.

O Android pede tres pecas, e o projeto mais uma:

- `icone_app.png` (512) — icone da janela e do editor da Godot;
- `android/icone_192.png` — icone antigo, ainda usado por lancadores velhos.
  Opaco: um icone com buraco transparente fica feio em fundo claro;
- `android/adaptativo_frente_432.png` — camada da frente do icone adaptativo.
  O lancador recorta em circulo, quadrado arredondado ou gota, e so garante os
  **66% centrais**: o desenho entra dentro desse circulo seguro;
- `android/adaptativo_fundo_432.png` — camada de tras, cor chapada do jogo.

Uso: python tools/preparar_app.py (a partir da raiz do projeto)
"""

import os

import numpy as np
from PIL import Image
from scipy import ndimage as nd

ORIGEM = "assets/_raw/ui/icone app.png"
DESTINO = "assets/ui/"

## Verde do fundo do menu, para a camada de tras e o icone opaco.
FUNDO = (14, 23, 17)

## Fracao do lado que o lancador garante no icone adaptativo.
SEGURO = 0.66


def recortar(caminho):
    """Tira o magenta da geracao, inclusive o que fica cercado de desenho."""
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))
    familia = (r > g + 20) & (b > g + 20)
    rot, n = nd.label(familia)
    borda = set(np.unique(rot[0, :])) | set(np.unique(rot[-1, :])) \
          | set(np.unique(rot[:, 0])) | set(np.unique(rot[:, -1]))
    borda.discard(0)
    fundo = np.zeros_like(familia)
    for i in range(1, n + 1):
        bolsao = rot == i
        cor = [a[:, :, c][bolsao].mean() for c in range(3)]
        chapado = cor[1] < 20 and min(cor[0], cor[2]) > 150 and abs(cor[0] - cor[2]) < 25
        if i in borda or chapado:
            fundo |= bolsao
    a[fundo | (al < 16)] = 0
    ys, xs = np.where(a[:, :, 3] > 16)
    return Image.fromarray(a[ys.min():ys.max() + 1, xs.min():xs.max() + 1].astype("uint8"))


def encaixar(assunto, lado, ocupacao, fundo=None):
    """Centra o assunto num quadrado, ocupando `ocupacao` do lado."""
    tela = Image.new("RGBA", (lado, lado), (fundo + (255,)) if fundo else (0, 0, 0, 0))
    livre = int(lado * ocupacao)
    copia = assunto.copy()
    copia.thumbnail((livre, livre), Image.LANCZOS)
    tela.paste(copia, ((lado - copia.width) // 2, (lado - copia.height) // 2), copia)
    return tela


def main():
    assunto = recortar(ORIGEM)
    print("assunto %dx%d" % assunto.size)
    os.makedirs(DESTINO + "android", exist_ok=True)

    encaixar(assunto, 512, 0.94).save(DESTINO + "icone_app.png")
    encaixar(assunto, 192, 0.88, FUNDO).convert("RGB").save(DESTINO + "android/icone_192.png")
    # Dentro do circulo seguro: o lancador pode recortar tudo que estiver fora.
    encaixar(assunto, 432, SEGURO * 0.95).save(DESTINO + "android/adaptativo_frente_432.png")
    Image.new("RGB", (432, 432), FUNDO).save(DESTINO + "android/adaptativo_fundo_432.png")
    for nome in ["icone_app.png", "android/icone_192.png",
                 "android/adaptativo_frente_432.png", "android/adaptativo_fundo_432.png"]:
        print("  %-34s %dx%d" % ((nome,) + Image.open(DESTINO + nome).size))


if __name__ == "__main__":
    main()
