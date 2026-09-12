"""Monta os icones do level up: assunto dentro da moldura comum.

As molduras chegaram melhor do que o pedido -- com alfa de verdade em vez de
fundo magenta, e com a janela interna no mesmo lugar nas duas, ao pixel. Isso
permite compor os dois conjuntos (arma e passiva) com a mesma conta.

Por que a moldura importa: sem ela, um escudo de casca marrom e um corvo eterio
nao parecem do mesmo jogo. Com ela, os nove leem como uma fileira. A gema marca
arma, a folha marca passiva -- o jogador distingue de relance, sem ler o texto.

Alguns assuntos chegaram como ilustracao e nao como icone: o cajado e a vinha
vieram em proporcao 1:2,6 e, encaixados inteiros num quadrado, viravam um fio de
28 px. Para esses ha recorte declarado em RECORTES, que fica com a parte que
identifica a habilidade -- a coroa do cajado, o botao da rosa.

Saida: assets/ui/icones/<id>.png, quadrados, prontos para o TextureRect.

Uso: python tools/preparar_icones_ui.py (a partir da raiz do projeto)
"""

from PIL import Image
import numpy as np
import os

ORIGEM = "assets/_raw/ui/"
DESTINO = "assets/ui/icones/"

## Lado do arquivo final. O painel exibe a 104 px; sobra folga para o HUD da
## FASE 9 querer maior sem regerar nada.
LADO = 256

## Folga entre o assunto e a parede da janela, em fracao do lado da janela.
RESPIRO = 0.03

MOLDURAS = {
    "arma": ORIGEM + "Moldura de arma (gema).png",
    "passiva": ORIGEM + "Moldura de passiva (folha).png",
}

## id do UpgradeData -> arquivo de origem e familia de moldura.
ICONES = [
    ("arma_cajado_raio", "cajado tempestade.png", "arma"),
    ("arma_vinha_espinhosa", "Vinha Espinhosa.png", "arma"),
    ("arma_corvo_espiritual", "Corvo Espiritual.png", "arma"),
    ("arma_orbe_do_cajado", "orbe do cajado icone.png", "arma"),
    ("arma_anel_de_esporos", "anel de esporos.png", "arma"),
    ("arma_vagalumes_guardioes", "vagalumes guardioes.png", "arma"),
    ("casca_de_carvalho", "Casca de Carvalho — vida máxima.png", "passiva"),
    ("passos_do_cervo", "Passos do Cervo — velocidade.png", "passiva"),
    ("coracao_verde", "Coração Verde — regeneração.png", "passiva"),
    ("essencia_viva", "Essência Viva — alcance de coleta.png", "passiva"),
    ("semente_ancestral", "Semente Ancestral — área.png", "passiva"),
    ("ciclo_lunar", "Ciclo Lunar — redução de cooldown.png", "passiva"),
]

## Assuntos altos ou detalhados demais para caber inteiros. O valor e a fracao
## da altura, medida do topo, que sobra depois do recorte.
RECORTES = {
    "arma_cajado_raio": 0.42,      # so a coroa: orbe e raios
    "arma_vinha_espinhosa": 0.42,  # so o botao da rosa e os espinhos
    "ciclo_lunar": 0.78,           # aproxima no disco e na lua
}


def recortar_fundo(caminho):
    """Tira o fundo (magenta ou alfa) e devolve o assunto recortado."""
    a = np.array(Image.open(caminho).convert("RGBA")).astype(int)
    r, g, b, al = (a[:, :, i] for i in range(4))
    fundo = ((r > g + 20) & (b > g + 20)) | (al < 16)
    a[fundo] = 0
    ys, xs = np.where(~fundo)
    if len(xs) == 0:
        raise SystemExit("%s ficou vazio depois do corte" % caminho)
    return Image.fromarray(a.astype("uint8")).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def janela(moldura):
    """O buraco interno da moldura: o vazio que nao toca a borda da imagem."""
    from scipy import ndimage as nd
    al = np.array(moldura)[:, :, 3]
    vazio = al < 16
    rot, n = nd.label(vazio)
    borda = set(np.unique(rot[0, :])) | set(np.unique(rot[-1, :])) \
          | set(np.unique(rot[:, 0])) | set(np.unique(rot[:, -1]))
    borda.discard(0)
    dentro = vazio & ~np.isin(rot, list(borda))
    if not dentro.any():
        raise SystemExit("A moldura nao tem janela vazada")
    rot2, n2 = nd.label(dentro)
    maior = max(range(1, n2 + 1), key=lambda k: (rot2 == k).sum())
    ys, xs = np.where(rot2 == maior)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def montar(assunto, moldura, caixa):
    """Encaixa o assunto na janela e poe a moldura por cima."""
    x0, y0, x1, y1 = caixa
    largura, altura = moldura.size
    livre_x = int((x1 - x0 + 1) * (1.0 - 2.0 * RESPIRO))
    livre_y = int((y1 - y0 + 1) * (1.0 - 2.0 * RESPIRO))

    cabe = assunto.copy()
    cabe.thumbnail((livre_x, livre_y), Image.LANCZOS)

    tela = Image.new("RGBA", (largura, altura), (0, 0, 0, 0))
    tela.alpha_composite(cabe, (
        x0 + ((x1 - x0 + 1) - cabe.size[0]) // 2,
        y0 + ((y1 - y0 + 1) - cabe.size[1]) // 2,
    ))
    tela.alpha_composite(moldura)
    return tela.resize((LADO, LADO), Image.LANCZOS)


def main():
    os.makedirs(DESTINO, exist_ok=True)

    molduras = {}
    for familia, caminho in MOLDURAS.items():
        m = Image.open(caminho).convert("RGBA")
        # A moldura vem com margem morta em volta -- cerca de 5% de cada lado.
        # Recortar no desenho devolve esse espaco ao assunto.
        al = np.array(m)[:, :, 3]
        ys, xs = np.where(al > 16)
        m = m.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        molduras[familia] = (m, janela(m))
        c = molduras[familia][1]
        print("moldura %-8s %dx%d  janela %dx%d em (%d,%d)"
              % (familia, m.size[0], m.size[1], c[2] - c[0] + 1, c[3] - c[1] + 1, c[0], c[1]))

    for id_, arquivo, familia in ICONES:
        assunto = recortar_fundo(ORIGEM + arquivo)
        bruto = assunto.size

        if id_ in RECORTES:
            fatia = max(1, int(assunto.size[1] * RECORTES[id_]))
            assunto = assunto.crop((0, 0, assunto.size[0], fatia))
            ys, xs = np.where(np.array(assunto)[:, :, 3] > 16)
            assunto = assunto.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

        moldura, caixa = molduras[familia]
        montar(assunto, moldura, caixa).save(DESTINO + id_ + ".png")
        marca = "  (recortado de %dx%d)" % bruto if id_ in RECORTES else ""
        print("  %-26s %-8s assunto %dx%d%s" % (id_, familia, assunto.size[0], assunto.size[1], marca))

    print("%d icones de %dx%d em %s" % (len(ICONES), LADO, LADO, DESTINO))


main()
