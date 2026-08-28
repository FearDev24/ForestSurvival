# Frames avulsos do druida

Frames individuais exportados junto com os spritesheets de `assets/characters/`.

São **fonte**, não o que o jogo carrega. O jogo usa os sheets horizontais
(`druida-*.png`) através de `assets/characters/druida_sprite_frames.tres`.

O arquivo `.gdignore` nesta pasta faz a Godot pular o diretório na importação,
para não gerar 71 `.import` desnecessários. Se algum frame precisar entrar no
jogo, mova-o para fora daqui.
