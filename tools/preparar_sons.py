"""Sintetiza os sons do jogo e escreve os WAV em assets/audio/.

Nao ha biblioteca de audio aqui e nao ha arquivo de origem: cada som e
osciladores, ruido e envelopes, como as formas que os efeitos desenhavam em
codigo antes da arte chegar. O registro e o mesmo da arte -- retro, curto, seco.

Por que gerar em vez de pedir arquivo pronto: o som fica **regeravel**. Mudar o
tom do acerto e mudar um numero e rodar de novo, e a diferenca aparece no
relatorio impresso, nao no ouvido de quem lembrar de conferir. E o mesmo
contrato de `tools/preparar_efeitos.py` com as folhas de animacao.

O que NAO sai daqui: trilha e ambiencia organica. Floresta com folha e madeira
de verdade e geracao externa; estes doze sao os efeitos curtos.

Uso: python tools/preparar_sons.py (a partir da raiz do projeto)
"""

import os
import wave

import numpy as np
from scipy import signal

TAXA = 44100
DESTINO = "assets/audio/"

## Volume de pico de cada som, em fracao da escala.
##
## Nao e normalizacao cega: coleta toca centenas de vezes por partida e nao pode
## ter o mesmo pico do rugido do chefe, que toca uma vez. Quem toca mais, soa
## mais baixo.
VOLUMES = {
    "coleta_orbe": 0.22,
    "arma_orbe": 0.30,
    "arma_corvo": 0.34,
    "arma_vinha": 0.40,
    "arma_esporos": 0.34,
    "criatura_morre": 0.34,
    "escolha": 0.45,
    "arma_raio": 0.60,
    "dano_druida": 0.62,
    "nivel": 0.65,
    "guardiao_rugido": 0.90,
    "guardiao_queda": 0.95,
}


# ----------------------------------------------------------------- oficina --


def envelope(n, ataque=0.005, queda=0.0, sustento=1.0, solta=0.05):
    """ADSR em segundos. Sem ataque e sem solta, todo som estala nas pontas."""
    a = max(1, int(ataque * TAXA))
    d = int(queda * TAXA)
    r = max(1, int(solta * TAXA))
    s = max(0, n - a - d - r)
    partes = [
        np.linspace(0.0, 1.0, a, endpoint=False),
        np.linspace(1.0, sustento, d, endpoint=False),
        np.full(s, sustento),
        np.linspace(sustento, 0.0, max(0, n - a - d - s)),
    ]
    return np.concatenate(partes)[:n]


def tom(freq, dur, forma="sine", fase=0.0):
    """Oscilador com frequencia fixa ou variando amostra a amostra.

    A fase sai da soma acumulada da frequencia, e nao de `freq * t`: com
    frequencia variavel, a segunda forma quebra a onda no meio do caminho e o
    som estala.
    """
    n = int(dur * TAXA)
    f = np.asarray(freq, dtype=float)
    if f.ndim == 0:
        f = np.full(n, float(freq))
    f = f[:n] if len(f) >= n else np.pad(f, (0, n - len(f)), mode="edge")
    ang = 2.0 * np.pi * np.cumsum(f) / TAXA + fase
    if forma == "sine":
        return np.sin(ang)
    if forma == "square":
        return np.sign(np.sin(ang))
    if forma == "saw":
        return 2.0 * ((ang / (2.0 * np.pi)) % 1.0) - 1.0
    if forma == "triangle":
        return 2.0 * np.abs(2.0 * ((ang / (2.0 * np.pi)) % 1.0) - 1.0) - 1.0
    raise ValueError("forma desconhecida: " + forma)


def ruido(dur, semente):
    """Ruido branco com semente fixa: o mesmo comando gera o mesmo arquivo."""
    return np.random.default_rng(semente).uniform(-1.0, 1.0, int(dur * TAXA))


def filtrar(x, tipo, corte, ordem=2):
    """Passa-baixa, passa-alta ou passa-faixa, em Hz."""
    nyq = TAXA * 0.5
    if tipo == "faixa":
        wn = [max(1e-4, corte[0] / nyq), min(0.999, corte[1] / nyq)]
    else:
        wn = min(0.999, corte / nyq)
    b, a = signal.butter(ordem, wn, btype={"baixa": "low", "alta": "high", "faixa": "band"}[tipo])
    return signal.lfilter(b, a, x)


def somar(*camadas):
    """Soma camadas de tamanhos diferentes, alinhadas pelo comeco."""
    n = max(len(c) for c in camadas)
    saida = np.zeros(n)
    for c in camadas:
        saida[:len(c)] += c
    return saida


def rampa(de, para, dur, curva=1.0):
    """Varredura de frequencia. `curva` > 1 desce rapido e alonga o fim."""
    t = np.linspace(0.0, 1.0, int(dur * TAXA), endpoint=False)
    return de + (para - de) * (t ** curva)


# -------------------------------------------------------------------- sons --


def arma_raio():
    """Raio caindo: estalo seco, cauda de trovao."""
    estalo = filtrar(ruido(0.12, 11), "alta", 2200.0) * envelope(int(0.12 * TAXA), 0.0005, 0.01, 0.2, 0.05)
    corpo = tom(rampa(320.0, 60.0, 0.45, 2.2), 0.45, "sine") * envelope(int(0.45 * TAXA), 0.002, 0.05, 0.4, 0.3)
    trovao = filtrar(ruido(0.45, 12), "baixa", 700.0) * envelope(int(0.45 * TAXA), 0.01, 0.08, 0.3, 0.3)
    return somar(estalo * 0.9, corpo * 0.8, trovao * 0.5)


def arma_vinha():
    """Chicote: ruido varrido de agudo para grave, curto."""
    dur = 0.26
    n = int(dur * TAXA)
    base = ruido(dur, 21)
    # Passa-faixa fixo mais um tom varrendo: imita o assobio sem filtro variante.
    assobio = filtrar(base, "faixa", (900.0, 5000.0)) * envelope(n, 0.004, 0.02, 0.25, 0.12)
    chicote = tom(rampa(1600.0, 220.0, dur, 2.6), dur, "saw") * envelope(n, 0.002, 0.03, 0.18, 0.1)
    return somar(assobio * 0.9, chicote * 0.35)


def arma_corvo():
    """Duas batidas de asa e um grasnado curto."""
    def batida(semente, atraso):
        d = 0.09
        x = filtrar(ruido(d, semente), "faixa", (200.0, 1400.0)) * envelope(int(d * TAXA), 0.006, 0.01, 0.4, 0.06)
        return np.concatenate([np.zeros(int(atraso * TAXA)), x])

    grasnado = tom(rampa(880.0, 520.0, 0.14, 1.6), 0.14, "saw") * envelope(int(0.14 * TAXA), 0.004, 0.02, 0.3, 0.08)
    grasnado = np.concatenate([np.zeros(int(0.16 * TAXA)), grasnado * 0.5])
    return somar(batida(31, 0.0), batida(32, 0.11), grasnado)


def arma_orbe():
    """Orbe saindo do cajado: estalo magico curto."""
    dur = 0.13
    n = int(dur * TAXA)
    nucleo = tom(rampa(900.0, 300.0, dur, 1.8), dur, "sine") * envelope(n, 0.001, 0.02, 0.3, 0.07)
    brilho = tom(rampa(1800.0, 900.0, dur, 2.0), dur, "triangle") * envelope(n, 0.001, 0.01, 0.15, 0.06)
    return somar(nucleo, brilho * 0.4)


def arma_esporos():
    """Zona brotando: sopro que abre e assenta. Toca ao nascer, nao a cada dano."""
    dur = 0.55
    n = int(dur * TAXA)
    sopro = filtrar(ruido(dur, 41), "faixa", (300.0, 2200.0)) * envelope(n, 0.06, 0.12, 0.35, 0.3)
    fundo = tom(rampa(180.0, 120.0, dur, 1.2), dur, "triangle") * envelope(n, 0.05, 0.1, 0.4, 0.3)
    return somar(sopro * 0.8, fundo * 0.5)


def criatura_morre():
    """Criatura comum somindo: baque curto e um sopro para cima."""
    dur = 0.22
    n = int(dur * TAXA)
    baque = tom(rampa(400.0, 110.0, dur, 2.0), dur, "square") * envelope(n, 0.002, 0.03, 0.25, 0.12)
    sopro = filtrar(ruido(dur, 51), "baixa", 1800.0) * envelope(n, 0.004, 0.02, 0.2, 0.14)
    return somar(baque * 0.7, sopro * 0.7)


def coleta_orbe():
    """Orbe de XP: blip subindo, curto. Toca centenas de vezes por partida."""
    dur = 0.085
    n = int(dur * TAXA)
    corpo = tom(rampa(680.0, 1480.0, dur), dur, "triangle")
    # Triangulo, e nao quadrada: medida, a quadrada punha 70% da energia acima
    # de 2 kHz, e este e o som que mais toca na partida.
    return corpo * envelope(n, 0.002, 0.0, 1.0, 0.05)


def nivel():
    """Level up: triade maior subindo, com a fundamental segurando embaixo."""
    notas = [523.25, 659.25, 783.99, 1046.50]
    passo = 0.085
    total = passo * len(notas) + 0.3
    saida = np.zeros(int(total * TAXA))
    for i, f in enumerate(notas):
        dur = 0.32 if i == len(notas) - 1 else 0.17
        n = int(dur * TAXA)
        voz = tom(f, dur, "triangle") * 0.7 + tom(f * 2.0, dur, "triangle") * 0.22
        voz *= envelope(n, 0.004, 0.03, 0.5, max(0.02, dur - 0.05))
        inicio = int(i * passo * TAXA)
        cabe = min(n, len(saida) - inicio)
        saida[inicio:inicio + cabe] += voz[:cabe]
    base = tom(261.63, total, "triangle") * envelope(len(saida), 0.01, 0.1, 0.25, 0.3)
    return somar(saida, base * 0.35)


def escolha():
    """Placa de upgrade escolhida: dois toques limpos."""
    a = tom(880.0, 0.05, "triangle") * envelope(int(0.05 * TAXA), 0.002, 0.0, 0.8, 0.03)
    b = tom(1318.5, 0.09, "triangle") * envelope(int(0.09 * TAXA), 0.002, 0.0, 0.7, 0.06)
    return somar(a, np.concatenate([np.zeros(int(0.055 * TAXA)), b]))


def dano_druida():
    """Druida levando dano: grave sujo, sem nota definida."""
    dur = 0.28
    n = int(dur * TAXA)
    grunhido = tom(rampa(300.0, 85.0, dur, 1.8), dur, "saw") * envelope(n, 0.002, 0.04, 0.3, 0.16)
    sujeira = filtrar(ruido(dur, 61), "baixa", 900.0) * envelope(n, 0.001, 0.02, 0.25, 0.16)
    return somar(grunhido * 0.7, sujeira * 0.8)


def guardiao_rugido():
    """Chefe entrando: grave modulado, com crescimento lento.

    A modulacao em anel -- portadora grave vezes um oscilador de 27 Hz -- e o
    que da a aspereza de garganta sem precisar de gravacao.
    """
    dur = 1.3
    n = int(dur * TAXA)
    portadora = tom(rampa(95.0, 62.0, dur, 1.4), dur, "saw")
    aspereza = 0.55 + 0.45 * tom(27.0, dur, "sine")
    corpo = portadora * aspereza * envelope(n, 0.12, 0.3, 0.75, 0.45)
    ar = filtrar(ruido(dur, 71), "faixa", (90.0, 700.0)) * envelope(n, 0.15, 0.3, 0.5, 0.45)
    # A serra crua e a modulacao enchem de harmonico agudo, e o resultado zumbe
    # em vez de rugir: medido, 28% da energia abaixo de 300 Hz e centro em
    # 4 kHz. O passa-baixa devolve o rugido para a garganta.
    return filtrar(somar(corpo, ar * 0.45), "baixa", 520.0, ordem=3)


def guardiao_queda():
    """Queda do chefe: o corpo desabando, cascalho e um baque final."""
    dur = 1.8
    n = int(dur * TAXA)
    desabar = tom(rampa(140.0, 38.0, dur, 2.4), dur, "sine") * envelope(n, 0.01, 0.25, 0.45, 0.8)
    cascalho = filtrar(ruido(dur, 81), "faixa", (400.0, 3000.0)) * envelope(n, 0.02, 0.4, 0.22, 0.9)
    baque = tom(rampa(90.0, 30.0, 0.5, 2.0), 0.5, "sine") * envelope(int(0.5 * TAXA), 0.002, 0.06, 0.5, 0.4)
    baque = np.concatenate([np.zeros(int(1.05 * TAXA)), baque * 1.1])
    return somar(desabar, cascalho * 0.5, baque)


SONS = {
    "arma_raio": arma_raio,
    "arma_vinha": arma_vinha,
    "arma_corvo": arma_corvo,
    "arma_orbe": arma_orbe,
    "arma_esporos": arma_esporos,
    "criatura_morre": criatura_morre,
    "coleta_orbe": coleta_orbe,
    "nivel": nivel,
    "escolha": escolha,
    "dano_druida": dano_druida,
    "guardiao_rugido": guardiao_rugido,
    "guardiao_queda": guardiao_queda,
}


# ------------------------------------------------------------------ saida --


def gravar(nome, x):
    """Normaliza para o volume da tabela e escreve WAV mono de 16 bits."""
    x = np.nan_to_num(x)
    x = x - np.mean(x)  # tira o deslocamento, que rouba margem e estala no fim
    pico = float(np.abs(x).max())
    if pico < 1e-9:
        raise SystemExit("%s saiu mudo" % nome)
    x = np.clip(x / pico * VOLUMES[nome], -1.0, 1.0)
    # Meio milissegundo de rampa nas pontas: corta o clique de comeco e fim.
    borda = int(0.0005 * TAXA)
    x[:borda] *= np.linspace(0.0, 1.0, borda)
    x[-borda:] *= np.linspace(1.0, 0.0, borda)

    caminho = DESTINO + nome + ".wav"
    with wave.open(caminho, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    return x


def main():
    os.makedirs(DESTINO, exist_ok=True)
    print("%-16s %6s %6s %6s %6s" % ("som", "dur", "pico", "rms", "kB"))
    for nome, fabrica in SONS.items():
        x = gravar(nome, fabrica())
        tamanho = os.path.getsize(DESTINO + nome + ".wav") / 1024.0
        print("%-16s %5.2fs %6.2f %6.3f %6.1f" % (
            nome, len(x) / TAXA, float(np.abs(x).max()),
            float(np.sqrt(np.mean(x ** 2))), tamanho))


if __name__ == "__main__":
    main()
