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


## Um bolsao de fundo que nao encosta na borda so conta como fundo se for
## magenta **quase puro**. E o que separa o miolo de um "A" -- rgb(249,2,247),
## chapado -- das particulas de cinza que caem sob a palavra CAIU, que sao roxo
## fosco e assimetrico, rgb(170,53,120). Um limiar de cor cego comeria as duas.
VERDE_DE_FUNDO = 20
MINIMO_DE_FUNDO = 150
DESVIO_DE_FUNDO = 25


def _tirar_respingo(a):
    """Tira o rosa que sobra nas bordas do desenho.

    O contorno foi antisserrilhado contra o magenta, entao a beirada de cada
    letra guarda uma mistura rosada -- o mesmo efeito que virou contorno roxo
    nos props de cenario (ver docs/ASSET_WORKFLOW.md). Sao poucos pixels, 0,1%
    da tinta, mas rosa num quadro escuro salta.

    A troca e por cinza de mesma luminancia, e nao por transparencia: parte
    desses pixels sao as particulas de cinza que caem sob a palavra CAIU, que
    devem continuar existindo -- so que cinzentas, como cinza de verdade.

    E seguro varrer tudo porque a paleta do jogo nao tem rosa nem roxo: verde,
    marrom, cinza e o laranja de brasa. Nada legitimo cai neste teste.
    """
    r, g, b, al = (a[:, :, i] for i in range(4))
    alvo = (r > g + 20) & (b > g + 20) & (al > 16)
    if not alvo.any():
        return a, 0
    luz = (0.299 * r + 0.587 * g + 0.114 * b).astype(int)
    saida = a.copy()
    for c in range(3):
        saida[:, :, c][alvo] = luz[alvo]
    return saida, int(alvo.sum())


def _e_fundo_chapado(a, bolsao):
    """Diz se um bolsao ilhado tem a cor chapada do fundo da geracao."""
    r, g, b = (a[:, :, i][bolsao].mean() for i in range(3))
    return (g < VERDE_DE_FUNDO and min(r, b) > MINIMO_DE_FUNDO
            and abs(r - b) < DESVIO_DE_FUNDO)


def recortar(caminho):
    """Tira o fundo da geracao e recorta no desenho.

    Corte por cor **e** conexao com a borda: as pecas brilham e desbotam o
    magenta em volta ate um rosa palido que escapa de qualquer limiar de cor
    que nao coma a arte junto (ver tools/preparar_barras_hud.py).

    Conexao com a borda sozinha nao basta quando a peca e uma palavra: o miolo
    de um A, de um O ou de um R e fundo cercado de tinta por todos os lados, e
    sobrevivia como um triangulo magenta dentro da letra. Esses bolsoes ilhados
    entram pelo teste de cor chapada acima.
    """
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))

    familia = (r > g + 20) & (b > g + 20)
    rot, n = nd.label(familia)
    da_borda = set(np.unique(rot[0, :])) | set(np.unique(rot[-1, :])) \
             | set(np.unique(rot[:, 0])) | set(np.unique(rot[:, -1]))
    da_borda.discard(0)
    fundo = np.zeros_like(familia)
    for i in range(1, n + 1):
        bolsao = rot == i
        if i in da_borda or _e_fundo_chapado(a, bolsao):
            fundo |= bolsao
    a[fundo | (al < 16)] = 0

    a, _ = _tirar_respingo(a)

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

    # Os dois desfechos saem da mesma tela, e por isso vieram da mesma sessao
    # de geracao: altura de letra igual nas duas, so a palavra de baixo muda.
    for arquivo, destino, rotulo in [
        ("floresta caiu.png", "assets/ui/titulo_floresta_caiu.png", "derrota"),
        ("floresta resistiu.png", "assets/ui/titulo_floresta_resistiu.png", "vitoria"),
    ]:
        w, h = salvar(recortar(ORIGEM + arquivo), destino)
        print("%-13s %dx%d  proporcao %.2f:1" % (rotulo, w, h, w / h))

    # Menu principal: o nome do jogo vem sobre magenta; o fundo é ilustração
    # opaca de tela cheia e só é normalizada aqui.
    w, h = salvar(recortar(ORIGEM + "titulo jogo.png"), "assets/ui/titulo_jogo.png")
    print("%-13s %dx%d  proporcao %.2f:1" % ("titulo jogo", w, h, w / h))
    fundo = Image.open(ORIGEM + "fundo menu.png").convert("RGB")
    fundo.save("assets/ui/fundo_menu.png")
    print("%-13s %dx%d  proporcao %.2f:1" % ("fundo menu", fundo.size[0], fundo.size[1],
                                             fundo.size[0] / fundo.size[1]))

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


if __name__ == "__main__":
    main()
