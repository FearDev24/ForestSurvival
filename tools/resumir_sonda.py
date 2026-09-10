"""Resume as partidas da sonda de balanceamento.

Le os JSON gravados por tools/sonda_balanceamento.gd e imprime uma linha por
partida e a media por grupo (politica, ou controle parado).

A coluna que valida a sonda e a do controle: se o druida parado dura o mesmo
que o bot, a direcao nao esta fazendo nada e o resto da tabela nao vale.

Uso: python tools/resumir_sonda.py <pasta com os .json>
"""

import glob
import json
import math
import os
import sys
from collections import defaultdict


def resumo(r):
    am = r["amostras"]
    percorrido = 0.0
    for a, b in zip(am, am[1:]):
        if "x" in a and "x" in b:
            percorrido += math.hypot(b["x"] - a["x"], b["y"] - a["y"])
    primeiro_golpe = next((a["t"] for a in am if a["dano_recebido"] > 0), None)
    boss = r.get("boss") or []
    return {
        "grupo": "parado" if r.get("parado") else r["politica"],
        "semente": r["semente"],
        "desfecho": r["fim"].get("desfecho", "?"),
        "tempo": r["fim"].get("tempo", 0.0),
        "nivel": r["fim"].get("nivel", 0),
        "abates": r["abates"],
        "xp": am[-1]["xp"],
        "orbes_perdidos": am[-1]["orbes_no_chao"],
        "pop_max": max(a["populacao"] for a in am),
        "dano_recebido": am[-1]["dano_recebido"],
        "primeiro_golpe": primeiro_golpe,
        "percorrido": percorrido,
        "boss_vida_final": boss[-1][1] if boss else None,
        "armas": am[-1]["armas"],
        "dano_por_tipo": r.get("dano_por_tipo", {}),
    }


def main():
    pasta = sys.argv[1] if len(sys.argv) > 1 else "."
    arquivos = sorted(glob.glob(os.path.join(pasta, "*.json"))
                      + glob.glob(os.path.join(pasta, "*", "*.json")))
    linhas = []
    for p in arquivos:
        l = resumo(json.load(open(p, encoding="utf-8")))
        sub = os.path.basename(os.path.dirname(p))
        if os.path.normpath(os.path.dirname(p)) != os.path.normpath(pasta):
            l["grupo"] = sub
        linhas.append(l)
    if not linhas:
        print("nenhum .json em", pasta)
        return

    cab = "%-9s %3s %-14s %6s %4s %6s %5s %6s %5s %7s %6s %8s  %s"
    print(cab % ("grupo", "sem", "desfecho", "tempo", "niv", "abates", "xp",
                 "perdeu", "popmx", "d_rec", "1ºgolp", "andou", "armas"))
    for l in sorted(linhas, key=lambda l: (l["grupo"], l["semente"])):
        print(cab % (l["grupo"], l["semente"], l["desfecho"], "%.0f" % l["tempo"],
                     l["nivel"], l["abates"], "%.0f" % l["xp"], l["orbes_perdidos"],
                     l["pop_max"], "%.0f" % l["dano_recebido"],
                     "-" if l["primeiro_golpe"] is None else "%.0f" % l["primeiro_golpe"],
                     "%.0f" % l["percorrido"],
                     " ".join("%s:%d" % (k[:5], v) for k, v in l["armas"].items())))

    # Quem bate no druida, somado sobre todas as partidas do grupo.
    print()
    por_grupo = defaultdict(lambda: defaultdict(float))
    for l in linhas:
        for tipo, q in l["dano_por_tipo"].items():
            por_grupo[l["grupo"]][tipo] += q
    for g, tipos in sorted(por_grupo.items()):
        total = sum(tipos.values()) or 1.0
        partes = sorted(tipos.items(), key=lambda kv: -kv[1])
        print("dano recebido (%s): " % g + ", ".join(
            "%s %.0f%%" % (t, 100.0 * q / total) for t, q in partes))

    print()
    grupos = defaultdict(list)
    for l in linhas:
        grupos[l["grupo"]].append(l)
    print("%-9s %3s %11s %9s %8s %9s" % ("grupo", "n", "tempo med", "min-max", "niv med", "vitorias"))
    for g, ls in sorted(grupos.items()):
        tempos = [l["tempo"] for l in ls]
        print("%-9s %3d %11.0f %9s %8.1f %9d" % (
            g, len(ls), sum(tempos) / len(ls), "%.0f-%.0f" % (min(tempos), max(tempos)),
            sum(l["nivel"] for l in ls) / len(ls),
            sum(1 for l in ls if l["desfecho"] == "vitoria")))


if __name__ == "__main__":
    main()
