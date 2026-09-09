"""Prepara o painel do level up, as placas de opcao e a palavra do titulo.

O painel ja veio com o miolo escuro e vazio, como pedido: so precisa do corte.

As placas nao. O veio da madeira saiu claro demais para texto por cima, e o
nome da opcao em fonte 26 lia no limite. O script escurece o **centro** delas,
poupando as pedras das pontas, as gemas e o musgo -- que sao justamente o que
distingue o estado normal do destacado.

Saida em assets/ui/, prontos para TextureRect e StyleBoxTexture.

Uso: python tools/preparar_painel_ui.py (a partir da raiz do projeto)
"""

from PIL import Image
import numpy as np
from scipy import ndimage as nd

ORIGEM = "assets/_raw/ui/"

## Quanto do centro da placa escurece, e quanto.
FAIXA_CENTRAL = 0.86
ESCURECER = 0.42


def recortar(caminho):
    """Tira o fundo da geracao e recorta no desenho.

    Corte por cor **e** conexao com a borda: as pecas brilham e desbotam o
    magenta em volta ate um rosa palido que escapa de qualquer limiar de cor
    que nao coma a arte junto (ver tools/preparar_barras_hud.py).
    """
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))

    familia = (r > g + 20) & (b > g + 20)
    rot, n = nd.label(familia)
    da_borda = set(np.unique(rot[0, :])) | set(np.unique(rot[-1, :])) \
             | set(np.unique(rot[:, 0])) | set(np.unique(rot[:, -1]))
    da_borda.discard(0)
    fundo = np.isin(rot, list(da_borda)) if da_borda else np.zeros_like(familia)
    a[fundo | (al < 16)] = 0

    ys, xs = np.where(a[:, :, 3] > 16)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def escurecer_centro(a):
    """Abaixa a luz do miolo, poupando o que e verde.

    O verde fica de fora porque o musgo e o brilho das gemas sao o sinal do
    estado destacado: escurece-los apagaria a diferenca entre as duas placas.
    """
    h, w = a.shape[:2]
    margem = int(w * (1.0 - FAIXA_CENTRAL) * 0.5)
    r, g, b, al = (a[:, :, i] for i in range(4))

    dentro = np.zeros((h, w), bool)
    dentro[:, margem:w - margem] = True
    verde = g > np.maximum(r, b) + 18
    alvo = dentro & (al > 40) & ~verde

    saida = a.copy()
    for c in range(3):
        canal = saida[:, :, c]
        canal[alvo] = np.clip(canal[alvo] * ESCURECER, 0, 255).astype(canal.dtype)
    return saida, int(alvo.sum())


def salvar(a, destino):
    Image.fromarray(a.astype("uint8")).save(destino)
    return a.shape[1], a.shape[0]


def main():
    titulo = recortar(ORIGEM + "subir nivel.png")
    w, h = salvar(titulo, "assets/ui/titulo_subiu_de_nivel.png")
    print("titulo        %dx%d  proporcao %.2f:1" % (w, h, w / h))

    painel = recortar(ORIGEM + "Painel da tela de escolha — 720 × 520.png")
    w, h = salvar(painel, "assets/ui/painel_escolha.png")
    print("painel        %dx%d  proporcao %.2f:1" % (w, h, w / h))

    for arquivo, destino, rotulo in [
        ("Fundo de opção — 640 × 112, versão 1.png", "assets/ui/opcao_normal.png", "opcao normal"),
        ("Fundo de opção — 640 × 112,  versão 2.png", "assets/ui/opcao_destaque.png", "opcao destaque"),
    ]:
        a = recortar(ORIGEM + arquivo)
        a, escurecidos = escurecer_centro(a)
        w, h = salvar(a, destino)
        print("%-13s %dx%d  proporcao %.2f:1  miolo escurecido: %d px"
              % (rotulo, w, h, w / h, escurecidos))


main()
