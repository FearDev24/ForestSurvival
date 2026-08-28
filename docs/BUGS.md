# Bugs conhecidos

## BUG-001 — Sheet do druida excede o limite de textura de GPUs Android antigas

**Status:** corrigido

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

**Correção:** o asset foi substituído na origem por cinco sheets por direção, todos com no máximo **1088 x 96 px** (`druida-west-walk-west.png`, o mais largo). O arquivo de 7680 px foi removido do repositório. Nenhuma largura fica perto do limite de 4096, então o risco deixou de existir.

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
