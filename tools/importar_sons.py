"""Traz os sons gravados de `assets/_raw/audio/` para `assets/audio/`.

Os doze efeitos nasceram sintetizados em `tools/preparar_sons.py`, e o
resultado ficou com cara de chiptune: osciladores puros contra uma arte pixel
quase pintada. Dez deles passaram a vir de biblioteca CC0 (Kenney), que soa
gravado porque e gravado.

O que este script faz com cada arquivo de origem:

**Corta o silencio das pontas.** Amostra de biblioteca costuma trazer meio
segundo de nada antes do golpe, e meio segundo de nada e meio segundo de atraso
entre o golpe na tela e o som.

**Encurta o que e longo demais.** Um passo na grama de 0,78 s nao serve para uma
zona que nasce: o rabo do som atropela o proximo disparo.

**Iguala a taxa e o volume.** Parte dos pacotes vem a 48 kHz; o jogo trabalha a
44,1. E o pico sai da mesma tabela do gerador sintetico -- a coleta continua bem
mais baixa que a queda do chefe, porque toca centenas de vezes.

O que NAO vem daqui: o rugido e a queda do Guardiao. Nenhum pacote de impacto
tem garganta de criatura; esses dois seguem sintetizados ate virem de geracao.

Uso: python tools/importar_sons.py (a partir da raiz do projeto)
"""

import os
import sys
import wave

import numpy as np
import soundfile as sf
from scipy import signal

# Roda da raiz do projeto, como as outras ferramentas; o import do irmao precisa
# da pasta dele no caminho.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from preparar_sons import TAXA, VOLUMES  # noqa: E402

ORIGEM = "assets/_raw/audio/"
DESTINO = "assets/audio/"

## Nome no jogo -> arquivo de origem, duracao maxima em segundos, e por que.
##
## As cinco habilidades sairam desta tabela a pedido do jogador: com cinco armas
## disparando em recargas diferentes, o combate virava tapete de ruido. Agora o
## combate e mudo e quem sustenta a partida e a musica de fundo.
##
## A escolha saiu do nome e da medida (duracao, pico, centro espectral), nao do
## ouvido: quem escreveu isto nao consegue ouvir. Trocar um por outro e trocar
## uma linha desta tabela e rodar de novo.
MAPA = {
    # Corpo mole, grave e curto.
    "criatura_morre": ("impactSoft_medium_000.ogg", 0.30),
    # Clique curto e brilhante; e o som que mais toca na partida.
    "coleta_orbe": ("click3.ogg", 0.12),
    # Sino: o unico som destes pacotes que soa como conquista.
    "nivel": ("impactBell_heavy_000.ogg", 1.10),
    # Interruptor: a placa de upgrade sendo apertada.
    "escolha": ("switch7.ogg", 0.25),
    # Soco pesado.
    "dano_druida": ("impactPunch_heavy_000.ogg", 0.55),
}

## Abaixo disto e silencio, para efeito de corte das pontas.
_SILENCIO = 0.004


def carregar(nome):
    x, taxa = sf.read(ORIGEM + nome, always_2d=True)
    x = x.mean(axis=1)
    if taxa != TAXA:
        # 48000 -> 44100 e 147/160; `resample_poly` faz a conta exata.
        de = int(taxa)
        x = signal.resample_poly(x, TAXA, de)
    return x


def cortar_pontas(x):
    forte = np.where(np.abs(x) > _SILENCIO)[0]
    if len(forte) == 0:
        return x
    inicio = max(0, forte[0] - int(0.002 * TAXA))
    fim = min(len(x), forte[-1] + int(0.01 * TAXA))
    return x[inicio:fim]


def encurtar(x, maximo):
    limite = int(maximo * TAXA)
    if len(x) <= limite:
        return x
    x = x[:limite].copy()
    # Desce o fim em 25 ms, senao o corte vira um estalo.
    saida = min(int(0.025 * TAXA), len(x))
    x[-saida:] *= np.linspace(1.0, 0.0, saida)
    return x


def gravar(nome, x):
    x = np.nan_to_num(x)
    x = x - float(np.mean(x))
    pico = float(np.abs(x).max())
    if pico < 1e-9:
        raise SystemExit("%s saiu mudo" % nome)
    x = np.clip(x / pico * VOLUMES[nome], -1.0, 1.0)
    borda = int(0.0005 * TAXA)
    x[:borda] *= np.linspace(0.0, 1.0, borda)
    x[-borda:] *= np.linspace(1.0, 0.0, borda)
    with wave.open(DESTINO + nome + ".wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    return x


def main():
    os.makedirs(DESTINO, exist_ok=True)
    print("%-16s %-28s %7s %7s %6s" % ("som", "origem", "antes", "depois", "pico"))
    for nome, (arquivo, maximo) in MAPA.items():
        bruto = carregar(arquivo)
        antes = len(bruto) / TAXA
        x = gravar(nome, encurtar(cortar_pontas(bruto), maximo))
        print("%-16s %-28s %6.2fs %6.2fs %6.2f" % (
            nome, arquivo, antes, len(x) / TAXA, float(np.abs(x).max())))
    print("\nO rugido e a queda do Guardiao continuam sintetizados:"
          " rode tools/preparar_sons.py para regera-los.")


if __name__ == "__main__":
    main()
