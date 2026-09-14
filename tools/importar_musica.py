"""Traz a trilha de `assets/_raw/audio/` para `assets/audio/musica/`.

Musica de biblioteca costuma nao fechar o laco: foi feita para ser ouvida uma
vez, do comeco ao fim. Num jogo ela toca em volta, e o salto entre o ultimo
instante e o primeiro aparece a cada volta.

Por isso existe a **emenda cruzada** aqui -- desvanecer a cauda por cima do
comeco. Ela e opcional e vem desligada: medida, a faixa que entrou ja fecha o
laco sozinha (salto de 0,5 vez o normal, e sem fade-out no fim), e a emenda
piorava o numero para 1,8. Ficou no codigo porque a proxima faixa pode precisar,
e o numero impresso diz quando.

A ferramenta mede o **salto na emenda** antes e depois -- quantas vezes a
diferenca entre a ultima amostra e a primeira e maior que a diferenca tipica
entre amostras vizinhas. Degrau grande ali se ouve como estalo a cada volta.
O que ela nao mede e se a frase musical volta bem: isso e ouvido.

Uso: python tools/importar_musica.py (a partir da raiz do projeto)
"""

import os

import numpy as np
import soundfile as sf

ORIGEM = "assets/_raw/audio/"
DESTINO = "assets/audio/musica/"

TAXA = 44100

## Faixas: nome no jogo -> arquivo de origem, segundos de emenda cruzada e pico.
##
## O pico e baixo de proposito: a trilha fica **embaixo** do jogo, e o
## barramento `Musica` ainda tira 6 dB por cima disto.
FAIXAS = {
    # Emenda em zero: esta faixa ja volta limpa. Ver o cabecalho.
    "trilha_floresta": ("GameMusic_ForestTheme_24_0.mp3", 0.0, 0.70),
}


def salto_na_emenda(x):
    """Quantas vezes o salto do fim para o comeco e maior que um salto normal.

    Quando a faixa volta ao inicio, a ultima amostra encosta na primeira. Se a
    diferenca entre as duas for muito maior que a diferenca tipica entre duas
    amostras vizinhas, isso e um degrau na forma de onda -- e degrau se ouve
    como estalo, a cada volta.

    Nao mede musicalidade: uma faixa pode nao ter estalo nenhum e mesmo assim
    voltar de um jeito estranho, porque a frase musical foi cortada no meio. Isso
    so o ouvido julga. Aqui se cobra o que da para cobrar.
    """
    passo = np.abs(np.diff(x, axis=0))
    tipico = float(np.median(passo)) if passo.size else 0.0
    if tipico < 1e-9:
        return 0.0
    degrau = float(np.mean(np.abs(x[0] - x[-1])))
    return degrau / tipico


def emendar(x, segundos):
    """Desvanece a cauda por cima do comeco e joga fora o que sobrou."""
    if segundos <= 0.0:
        return x
    n = int(segundos * TAXA)
    if len(x) < 3 * n:
        raise SystemExit("faixa curta demais para uma emenda de %.0f s" % segundos)
    cauda = x[-n:].copy()
    corpo = x[:-n].copy()
    sobe = np.linspace(0.0, 1.0, n)
    if corpo.ndim > 1:
        sobe = sobe[:, None]
    corpo[:n] = corpo[:n] * sobe + cauda * (1.0 - sobe)
    return corpo


def main():
    os.makedirs(DESTINO, exist_ok=True)
    for nome, (arquivo, segundos, pico) in FAIXAS.items():
        x, taxa = sf.read(ORIGEM + arquivo, always_2d=True)
        if taxa != TAXA:
            raise SystemExit("%s veio a %d Hz; esperado %d" % (arquivo, taxa, TAXA))

        antes = salto_na_emenda(x)
        emendada = emendar(x, segundos)
        depois = salto_na_emenda(emendada)

        emendada = emendada / max(1e-9, float(np.abs(emendada).max())) * pico
        caminho = DESTINO + nome + ".ogg"
        # Em blocos: passar os quatro milhoes de amostras de uma vez estoura a
        # pilha do libsndfile ao codificar vorbis.
        with sf.SoundFile(caminho, "w", TAXA, emendada.shape[1],
                          format="OGG", subtype="VORBIS") as saida:
            passo = TAXA * 5
            for i in range(0, len(emendada), passo):
                saida.write(emendada[i:i + passo])

        print("%-18s %s" % (nome, arquivo))
        print("   %.1f s -> %.1f s | salto na volta %.1fx -> %.1fx o normal | pico %.2f | %.1f MB" % (
            len(x) / TAXA, len(emendada) / TAXA, antes, depois, pico,
            os.path.getsize(caminho) / 1048576.0))


if __name__ == "__main__":
    main()
