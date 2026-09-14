# Origem e licença dos sons

Cinco dos sete efeitos que restaram vêm de bibliotecas **CC0** (domínio público: uso comercial
liberado, sem obrigação de atribuição). Os créditos ficam aqui mesmo assim —
saber de onde veio cada arquivo é o que permite trocar um sem caçar o resto, e
é o que se responde se alguém reclamar depois da publicação.

Os arquivos de origem estão em `assets/_raw/audio/`, junto com as licenças
originais dos pacotes, e `tools/importar_sons.py` os converte: corta o silêncio
das pontas, encurta o que é longo demais, iguala a 44,1 kHz mono e aplica o
volume de pico da tabela.

| som no jogo | arquivo de origem | pacote |
| --- | --- | --- |
| `criatura_morre` | `impactSoft_medium_000.ogg` | Kenney — Impact Sounds |
| `coleta_orbe` | `click3.ogg` | Kenney — UI Audio |
| `nivel` | `impactBell_heavy_000.ogg` | Kenney — Impact Sounds |
| `escolha` | `switch7.ogg` | Kenney — UI Audio |
| `dano_druida` | `impactPunch_heavy_000.ogg` | Kenney — Impact Sounds |

As cinco habilidades ficaram **mudas** a pedido do jogador — cinco armas
disparando em recargas diferentes viravam tapete de ruído —, e quem sustenta a
partida passou a ser a trilha.

## Trilha

| faixa | origem | autor | licença |
| --- | --- | --- | --- |
| `musica/trilha_floresta.ogg` | *Dark Forest Theme* (`GameMusic_ForestTheme_24_0.mp3`), opengameart.org/content/dark-forest-theme | cynicmusic | CC0 |

Entra por `tools/importar_musica.py`, que normaliza o pico e mede o salto na
volta do laço. Medido: esta faixa já fecha o laço sozinha (salto de 0,5 vez o
normal, e sem fade-out no fim), então a emenda cruzada da ferramenta está
desligada para ela.

**Licença dos três pacotes:** CC0 1.0 Universal. Criados e distribuídos por
Kenney (www.kenney.nl). As licenças completas estão em
`assets/_raw/audio/kenney_*_License.txt`.

## Os dois que não vêm daí

`guardiao_rugido` e `guardiao_queda` continuam **sintetizados** por
`tools/preparar_sons.py`. Nenhum pacote de impacto tem garganta de criatura, e
os dois são o caso em que síntese por oscilador soa pior: são justamente os sons
que precisam parecer orgânicos. Estão marcados para vir de geração externa, com
prompt, como a arte.
