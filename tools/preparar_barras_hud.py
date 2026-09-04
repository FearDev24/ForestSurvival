"""Prepara as barras do HUD a partir da arte bruta em assets/_raw.

As duas peca de cada barra chegam em canvas diferentes e com o vao construido de
formas diferentes: no XP ele e um buraco transparente, no HP ja vem pintado de
escuro. Este script normaliza o par, encaixa o liquido na moldura, escurece o vao
onde ele for vazado e separa o liquido da moldura -- sem essa separacao, clipar a
barra pela metade cortaria a gema da direita junto.

Saida em assets/ui/barra_<nome>_fundo.png e barra_<nome>_preenchimento.png, do
mesmo tamanho, como o TextureProgressBar exige.

As texturas saem ja na largura em que aparecem na tela. Nao e escolha estetica:
o TextureProgressBar usa o tamanho da textura como tamanho minimo do controle,
entao uma textura grande demais nao tem como ser encolhida pelo `size`. Mudar o
tamanho do HUD e mudar LARGURA_EM_TELA aqui e rodar o script de novo.

Uso: python tools/preparar_barras_hud.py (a partir da raiz do projeto)
"""

from PIL import Image
import numpy as np
from scipy import ndimage as nd

LIMIAR = 40  # alfa a partir do qual o pixel conta como desenhado


def recortar(caminho):
    a = np.array(Image.open(caminho).convert("RGBA"))
    ys, xs = np.where(a[:, :, 3] > 16)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def limpar_chroma(a):
    """Restos do fundo verde do chroma: claros, saturados e sem vermelho nem azul.
    O musgo da moldura e mais escuro e amarelado, entao nao entra."""
    r, g, b, al = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
    chroma = (al < 210) & (g > 190) & (r < 90) & (b < 90)
    a = a.copy()
    a[chroma] = 0
    return a, int(chroma.sum())


def borda_superior(alfa):
    """Primeira linha desenhada de cada coluna. Serve de referencia para o encaixe."""
    desenhado = alfa > LIMIAR
    topo = np.argmax(desenhado, axis=0).astype(float)
    topo[~desenhado.any(axis=0)] = np.nan
    return topo


def encaixar(cheia, largura, altura):
    """Escala uniforme pela largura e depois procura o deslocamento vertical que
    faz a borda superior da cheia coincidir com a da vazia."""
    escala = largura / cheia.shape[1]
    nova_altura = max(1, int(round(cheia.shape[0] * escala)))
    red = np.array(Image.fromarray(cheia).resize((largura, nova_altura), Image.LANCZOS))
    tela = np.zeros((altura + 2 * 40, largura, 4), np.uint8)
    tela[40:40 + min(nova_altura, tela.shape[0] - 40)] = red[:tela.shape[0] - 40]
    return tela, escala


def vao_vazado(vazia):
    """O vao da moldura, quando ele e um buraco transparente fechado (caso do XP).
    No par de HP o vao ja vem pintado de escuro, entao nao ha buraco: devolve None."""
    solido = vazia[:, :, 3] > LIMIAR
    buracos = nd.binary_fill_holes(solido) & ~solido
    rot, n = nd.label(buracos)
    for i in range(1, n + 1):
        ys, xs = np.where(rot == i)
        if xs.max() - xs.min() + 1 >= vazia.shape[1] * 0.5:
            return int(ys.min()), int(ys.max())
    return None


def melhor_deslocamento(vazia, tela, altura, cor):
    """Escolhe o deslocamento vertical do liquido sobre a moldura.

    Havendo vao vazado, alinhamos o liquido com o vao: e o encaixe que o jogador
    ve. Sem vao vazado, a borda superior da moldura serve de referencia."""
    largura = vazia.shape[1]
    vao = vao_vazado(vazia)

    if vao is not None:
        alvo = (vao[0] + vao[1]) / 2.0
        melhor, escolhido = None, 0
        for dy in range(-30, 31):
            rec = tela[40 - dy:40 - dy + altura]
            if rec.shape[0] != altura:
                continue
            m = mascara_preenchimento(rec, cor)
            if not m.any():
                continue
            ys = np.where(m)[0]
            val = abs((int(ys.min()) + int(ys.max())) / 2.0 - alvo)
            if melhor is None or val < melhor:
                melhor, escolhido = val, dy
        return escolhido, float(melhor), "vao"

    alvo = borda_superior(vazia[:, :, 3])
    faixa = slice(int(largura * 0.2), int(largura * 0.8))
    melhor, escolhido = None, 0
    for dy in range(-30, 31):
        rec = tela[40 - dy:40 - dy + altura]
        if rec.shape[0] != altura:
            continue
        cand = borda_superior(rec[:, :, 3])
        val = np.nanmean((cand[faixa] - alvo[faixa]) ** 2)
        if not np.isnan(val) and (melhor is None or val < melhor):
            melhor, escolhido = val, dy
    return escolhido, float(np.sqrt(melhor)), "borda"


def mascara_preenchimento(img, cor):
    """Onde esta o liquido da barra: vermelho ou verde dominante e opaco."""
    r, g, b, al = (img[:, :, i].astype(int) for i in range(4))
    if cor == "vermelho":
        m = (al > LIMIAR) & (r > g + 25) & (r > b + 25) & (r > 30)
    else:
        m = (al > LIMIAR) & (g > r + 40) & (g > b + 25) & (g > 110)
    m = nd.binary_closing(m, np.ones((7, 7), bool))
    rot, n = nd.label(m)
    if n == 0:
        return m
    largo = np.zeros_like(m)
    for i in range(1, n + 1):
        ys, xs = np.where(rot == i)
        if xs.max() - xs.min() + 1 >= img.shape[1] * 0.5:
            largo[ys, xs] = True
    return nd.binary_fill_holes(largo)


## Largura de cada barra dentro da viewport de 1280x720. A altura sai da
## proporcao da arte, para nao deformar a moldura.
LARGURA_EM_TELA = {"xp": 1040, "vida": 620}


def para_tela(img, largura):
    altura = max(1, int(round(img.shape[0] * largura / img.shape[1])))
    return np.array(Image.fromarray(img).resize((largura, altura), Image.LANCZOS)), altura


def processar(arq_vazia, arq_cheia, nome, cor, fundo_canal):
    vazia, n1 = limpar_chroma(recortar(arq_vazia))
    bruta, n2 = limpar_chroma(recortar(arq_cheia))
    altura, largura = vazia.shape[:2]

    tela, escala = encaixar(bruta, largura, altura)
    dy, erro, criterio = melhor_deslocamento(vazia, tela, altura, cor)
    cheia = tela[40 - dy:40 - dy + altura].copy()

    canal = mascara_preenchimento(cheia, cor)
    ys, xs = np.where(canal)

    # fundo: a moldura vazia, com o vao escurecido onde ele for transparente
    fundo = vazia.copy()
    vazado = canal & (fundo[:, :, 3] <= LIMIAR)
    fundo[vazado] = fundo_canal

    # preenchimento: so o liquido, recuado 2 px para nao levar borda da moldura junto
    dentro = nd.binary_erosion(canal, np.ones((3, 3), bool), iterations=2)
    barra = np.zeros_like(vazia)
    barra[dentro] = cheia[dentro]

    largura_final = LARGURA_EM_TELA[nome]
    fundo, altura_final = para_tela(fundo, largura_final)
    barra, _ = para_tela(barra, largura_final)

    Image.fromarray(fundo).save("assets/ui/barra_%s_fundo.png" % nome)
    Image.fromarray(barra).save("assets/ui/barra_%s_preenchimento.png" % nome)

    print("%-4s  %dx%d  escala %.4f  dy %+d  encaixe pelo %s, erro %.2f px" % (nome, largura, altura, escala, dy, criterio, erro))
    print("      canal  x %d-%d (%d px, %.1f%% da largura)   y %d-%d (%d px)"
          % (xs.min(), xs.max(), xs.max() - xs.min() + 1,
             100 * (xs.max() - xs.min() + 1) / largura,
             ys.min(), ys.max(), ys.max() - ys.min() + 1))
    print("      vao transparente coberto: %d px   chroma removido: %d/%d" % (int(vazado.sum()), n1, n2))
    print("      textura final: %dx%d" % (largura_final, altura_final))


RAIZ = "assets/_raw/"

processar(RAIZ + "barra-xp-vazia-original.png", RAIZ + "barra-xp-cheia-original.png",
          "xp", "verde", (14, 18, 12, 245))
processar(RAIZ + "barra-vida-vazia-original.png", RAIZ + "barra-vida-cheia-original.png",
          "vida", "vermelho", (18, 12, 12, 245))
