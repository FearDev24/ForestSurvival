# Bugs conhecidos

## BUG-001 — Sheet do druida excede o limite de textura de GPUs Android antigas

**Status:** investigando

`assets/characters/druidwalkesquerda-walk-west.png` tem **7680 x 96 px** (120 frames de 64 x 96 em linha única).

GPUs Android antigas expõem `GL_MAX_TEXTURE_SIZE` de 4096. Nelas a textura falha ao carregar ou é reduzida, e o personagem some ou fica borrado. Aparelhos modernos (Vulkan) costumam suportar 8192 ou mais, então no PC e em celulares recentes funciona — foi verificado rodando em Vulkan.

**Como reproduzir:**
1. exportar para Android;
2. rodar em aparelho com limite de textura 4096;
3. observar o Player.

**Esperado:** druida renderiza normalmente.

**Atual:** desconhecido — ainda não testado em device real.

**Arquivos relacionados:**
- `assets/characters/druidwalkesquerda-walk-west.png`
- `scenes/player/player.tscn`

**Correção possível (não aplicada):** reexportar o sheet em grade (por exemplo 12 x 10) em vez de linha única, o que traria a largura para 768 px. Exige regerar o asset na origem, não editar o arquivo aqui — alterar arte sem solicitação é vedado por DEC-013.

---

Nenhum bug de gameplay registrado.

## Modelo

### BUG-001 — Título

**Status:** aberto / corrigido / investigando

**Como reproduzir:**
1.
2.
3.

**Esperado:**

**Atual:**

**Arquivos relacionados:**

**Correção:**
