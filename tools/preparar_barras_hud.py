"""Prepara as barras do HUD a partir da arte bruta em assets/_raw.

Há dois caminhos, porque as duas barras chegaram de formas diferentes.

**Barra de vida — par de peças.** Vieram uma vazia e uma cheia. O script encaixa
a cheia na vazia e extrai só o líquido. Funciona porque o vermelho do líquido é
a única cor quente da arte: dá para isolá-lo por cor.

**Barra de XP — uma peça só, líquido pintado.** O verde do líquido não se
distingue do musgo nem do brilho da moldura, então isolar por cor é impossível.
Em vez disso o script acha a fenda na barra vazia e pinta uma rampa verde dentro
dela. O alinhamento passa a ser garantido por construção, e some de vez o risco
de as duas peças não serem a mesma barra — que foi o que aconteceu quando se
tentou gerar o par.

O líquido pintado respeita o musgo: só entra onde a fenda é de fato escura, de
modo que a hera que cai dentro do sulco continua na frente da energia.

Saída em assets/ui/barra_<nome>_fundo.png e barra_<nome>_preenchimento.png, do
mesmo tamanho, como o TextureProgressBar exige.

As texturas saem já na largura em que aparecem na tela. Não é escolha estética:
o TextureProgressBar usa o tamanho da textura como tamanho mínimo do controle,
então uma textura grande demais não tem como ser encolhida pelo `size`. Mudar o
tamanho do HUD é mudar LARGURA_EM_TELA aqui e rodar o script de novo (DEC-023).

Uso: python tools/preparar_barras_hud.py (a partir da raiz do projeto)
"""

from PIL import Image
import numpy as np
from scipy import ndimage as nd

LIMIAR = 40   # alfa a partir do qual o pixel conta como desenhado
ESCURO = 70   # luminância abaixo da qual o pixel conta como fundo de fenda

## Largura de cada barra dentro da viewport de 1280x720. A altura sai da
## proporção da arte, para não deformar a moldura.
LARGURA_EM_TELA = {"xp": 1040, "vida": 620}

## Rampa vertical do líquido de XP, do topo da fenda até a base. Cores da
## paleta do jogo (`docs/05_ART_DIRECTION.md`): escuro nas bordas, núcleo claro.
RAMPA_XP = [
    (0.00, (10, 58, 34)),
    (0.16, (26, 150, 74)),
    (0.40, (90, 226, 122)),
    (0.50, (176, 255, 186)),
    (0.60, (90, 226, 122)),
    (0.84, (26, 150, 74)),
    (1.00, (10, 58, 34)),
]


# ------------------------------------------------------------------ entrada --


def recortar(caminho):
    """Carrega, tira o fundo da geração e recorta no conteúdo.

    Cortar o fundo só por cor não basta: a barra brilha e desbota o magenta em
    volta até um rosa pálido que escapa de qualquer limiar que não coma a arte
    junto. Por isso o corte é por cor **e** conexão com a borda da imagem — o
    fundo é uma mancha única que toca a moldura, o desenho não.

    Também limpa o chroma verde antigo, para as peças geradas antes de o fundo
    passar a ser magenta continuarem funcionando.
    """
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))

    # 20 e não 35: o fundo desbota nas bordas até um rosa de r-g 33. Exigir os
    # **dois** canais acima do verde protege a arte — a pedra chega a r-g 19 mas
    # tem b-g negativo, e o roxo escuro da fenda tem b-g 29 mas r-g 4.
    familia = (r > g + 20) & (b > g + 20)
    rot, n = nd.label(familia)
    da_borda = set(np.unique(rot[0, :])) | set(np.unique(rot[-1, :])) \
             | set(np.unique(rot[:, 0])) | set(np.unique(rot[:, -1]))
    da_borda.discard(0)
    magenta = np.isin(rot, list(da_borda)) if da_borda else np.zeros_like(familia)

    chroma_verde = (al < 210) & (g > 190) & (r < 90) & (b < 90)

    a[magenta | chroma_verde] = 0
    ys, xs = np.where(a[:, :, 3] > LIMIAR)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1], int((magenta | chroma_verde).sum())


def luminancia(c):
    return np.where(c[:, :, 3] > LIMIAR, c[:, :, :3].mean(axis=2), 255.0)


# -------------------------------------------------------------------- fenda --


def pontas(c):
    """Onde acabam os losangos das duas extremidades.

    O líquido não pode correr por baixo deles. Medir pela gema não serve — a
    peça de pedra é bem mais larga que a joia, e o verde acabava entrando no
    losango.

    O sinal é a altura ocupada por coluna: nos losangos a barra é bem mais alta
    que no miolo. A medida é a **extensão** vertical, não a contagem de pixels,
    e passa por um filtro de mediana — senão as gotas de musgo, que descem
    abaixo da barra, contariam como ponta.
    """
    op = c[:, :, 3] > LIMIAR
    h, w = c.shape[:2]
    extensao = np.zeros(w)
    for x in range(w):
        ys = np.where(op[:, x])[0]
        extensao[x] = (ys.max() - ys.min() + 1) if len(ys) else 0
    extensao = nd.median_filter(extensao, size=41)

    miolo = np.median(extensao[int(w * 0.3):int(w * 0.7)])
    rot, n = nd.label(extensao > miolo * 1.25)
    if n < 2:
        return None

    blocos = []
    for k in range(1, n + 1):
        xs = np.where(rot == k)[0]
        blocos.append((len(xs), int(xs.min()), int(xs.max())))
    blocos.sort(reverse=True)

    esquerda = next((b for b in blocos if b[1] < w * 0.25), None)
    direita = next((b for b in blocos if b[2] > w * 0.75), None)
    if esquerda is None or direita is None:
        return None
    return esquerda[2] + 1, direita[1] - 1


def fenda(c):
    """O sulco onde o líquido corre: a faixa de linhas mais escuras do miolo.

    Procura no miolo horizontal de propósito — nas pontas a moldura é escura
    por causa da pedra das gemas, e isso contaminaria o perfil.
    """
    h, w = c.shape[:2]
    lum = luminancia(c)
    perfil = np.array([lum[y, int(w * 0.25):int(w * 0.75)].mean() for y in range(h)])

    rot, n = nd.label(perfil <= ESCURO)
    if n == 0:
        return None
    maior = max(range(1, n + 1), key=lambda k: (rot == k).sum())
    ys = np.where(rot == maior)[0]
    y0, y1 = int(ys.min()), int(ys.max())

    limites = pontas(c)
    if limites is not None:
        x0, x1 = limites
    else:
        escuras = np.where(lum[(y0 + y1) // 2] < ESCURO)[0]
        x0, x1 = int(escuras.min()), int(escuras.max())
    return x0, x1, y0, y1


# ----------------------------------------------------------------- líquido --


def pintar_liquido(c, caixa, paradas):
    """Pinta a rampa dentro da fenda, sem cobrir o que não é fundo de fenda.

    A máscara exige o pixel escuro: assim o musgo e a hera que caem dentro do
    sulco continuam na frente da energia, em vez de sumirem debaixo dela.
    """
    x0, x1, y0, y1 = caixa
    h, w = c.shape[:2]
    alt = y1 - y0 + 1

    t = np.linspace(0.0, 1.0, alt)
    pontos = [p for p, _ in paradas]
    rampa = np.stack([np.interp(t, pontos, [cor[k] for _, cor in paradas]) for k in range(3)], axis=1)

    dentro = np.zeros((h, w), bool)
    dentro[y0:y1 + 1, x0:x1 + 1] = True
    visivel = nd.binary_opening(dentro & (luminancia(c) < ESCURO), np.ones((2, 2), bool))

    liquido = np.zeros_like(c)
    faixa = np.zeros((h, w, 3))
    faixa[y0:y1 + 1] = rampa[:, None, :]
    liquido[:, :, :3] = faixa
    liquido[:, :, 3] = np.where(visivel, 255, 0)

    # Cintilância: pontos de luz espalhados pelo núcleo, sempre os mesmos.
    rng = np.random.default_rng(7)
    for _ in range(60):
        sy = int(rng.integers(y0 + alt // 4, max(y0 + alt // 4 + 1, y1 - alt // 4)))
        sx = int(rng.integers(x0 + 30, max(x0 + 31, x1 - 30)))
        if visivel[sy, sx]:
            janela = liquido[sy - 1:sy + 2, sx - 3:sx + 4, :3]
            liquido[sy - 1:sy + 2, sx - 3:sx + 4, :3] = np.minimum(255, janela + 70)

    return liquido, int(visivel.sum()), int(dentro.sum() - visivel.sum())


def mascara_preenchimento(img, cor):
    """Onde está o líquido numa peça 'cheia': vermelho ou verde dominante."""
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


# ------------------------------------------------------------------- saída --


def para_tela(img, largura):
    altura = max(1, int(round(img.shape[0] * largura / img.shape[1])))
    return np.array(Image.fromarray(img.astype("uint8")).resize((largura, altura), Image.LANCZOS)), altura


def salvar(nome, fundo, liquido):
    largura = LARGURA_EM_TELA[nome]
    fundo, altura = para_tela(fundo, largura)
    liquido, _ = para_tela(liquido, largura)
    Image.fromarray(fundo).save("assets/ui/barra_%s_fundo.png" % nome)
    Image.fromarray(liquido).save("assets/ui/barra_%s_preenchimento.png" % nome)
    return largura, altura


# ---------------------------------------------------------------- caminhos --


def processar_pintado(arq_vazia, nome, paradas):
    """Uma peça só; o líquido é pintado dentro da fenda."""
    vazia, limpos = recortar(arq_vazia)
    h, w = vazia.shape[:2]

    caixa = fenda(vazia)
    if caixa is None:
        raise SystemExit("%s: não achei a fenda na arte" % nome)
    x0, x1, y0, y1 = caixa

    liquido, pintados, poupados = pintar_liquido(vazia, caixa, paradas)
    lw, lh = salvar(nome, vazia, liquido)

    print("%-4s  %dx%d  (uma peça, líquido pintado)" % (nome, w, h))
    print("      fenda  x %d-%d (%.0f%% da largura)   y %d-%d (%d px, %.0f%% da altura)"
          % (x0, x1, 100 * (x1 - x0 + 1) / w, y0, y1, y1 - y0 + 1, 100 * (y1 - y0 + 1) / h))
    print("      pintados %d px, musgo poupado %d px, fundo removido %d px"
          % (pintados, poupados, limpos))
    print("      textura final: %dx%d" % (lw, lh))


def processar_par(arq_vazia, arq_cheia, nome, cor, fundo_canal):
    """Duas peças; o líquido é extraído da cheia e encaixado na vazia."""
    vazia, n1 = recortar(arq_vazia)
    bruta, n2 = recortar(arq_cheia)
    altura, largura = vazia.shape[:2]

    escala = largura / bruta.shape[1]
    nova = max(1, int(round(bruta.shape[0] * escala)))
    red = np.array(Image.fromarray(bruta.astype("uint8")).resize((largura, nova), Image.LANCZOS))
    tela = np.zeros((altura + 80, largura, 4), int)
    tela[40:40 + min(nova, tela.shape[0] - 40)] = red[:tela.shape[0] - 40]

    # Encaixe pela borda superior da moldura, no miolo horizontal.
    def topo(alfa):
        desenhado = alfa > LIMIAR
        t = np.argmax(desenhado, axis=0).astype(float)
        t[~desenhado.any(axis=0)] = np.nan
        return t

    alvo = topo(vazia[:, :, 3])
    faixa = slice(int(largura * 0.2), int(largura * 0.8))
    melhor, dy = None, 0
    for d in range(-30, 31):
        rec = tela[40 - d:40 - d + altura]
        if rec.shape[0] != altura:
            continue
        val = np.nanmean((topo(rec[:, :, 3])[faixa] - alvo[faixa]) ** 2)
        if not np.isnan(val) and (melhor is None or val < melhor):
            melhor, dy = val, d
    cheia = tela[40 - dy:40 - dy + altura].copy()

    canal = mascara_preenchimento(cheia, cor)
    ys, xs = np.where(canal)

    fundo = vazia.copy()
    vazado = canal & (fundo[:, :, 3] <= LIMIAR)
    fundo[vazado] = fundo_canal

    dentro = nd.binary_erosion(canal, np.ones((3, 3), bool), iterations=2)
    liquido = np.zeros_like(vazia)
    liquido[dentro] = cheia[dentro]

    lw, lh = salvar(nome, fundo, liquido)
    print("%-4s  %dx%d  (par de peças)  escala %.4f  dy %+d  erro de borda %.2f px"
          % (nome, largura, altura, escala, dy, float(np.sqrt(melhor))))
    print("      canal  x %d-%d (%.0f%% da largura)   y %d-%d (%d px)"
          % (xs.min(), xs.max(), 100 * (xs.max() - xs.min() + 1) / largura, ys.min(), ys.max(),
             ys.max() - ys.min() + 1))
    print("      vão transparente coberto %d px, fundo removido %d/%d px" % (int(vazado.sum()), n1, n2))
    print("      textura final: %dx%d" % (lw, lh))


RAIZ = "assets/_raw/"

processar_pintado(RAIZ + "barra-xp-vazia-original.png", "xp", RAMPA_XP)
processar_par(RAIZ + "barra-vida-vazia-original.png", RAIZ + "barra-vida-cheia-original.png",
              "vida", "vermelho", (18, 12, 12, 245))
