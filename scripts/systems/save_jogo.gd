class_name SaveJogo
extends RefCounted
## Save local do jogo (`docs/03_SYSTEMS.md` §18).
##
## Guarda o que sobrevive entre partidas: quantas foram jogadas, quantas foram
## vencidas, o melhor tempo e o melhor nível. É a base da meta-progressão —
## moeda, desbloqueios e upgrades permanentes moram aqui quando existirem.
##
## **Classe com métodos estáticos, e não autoload**, pela mesma razão do
## `Audio`: o identificador global de um autoload não existe para o compilador
## quando a Godot roda com `--script`, e é assim que as suítes deste projeto
## rodam.
##
## Três regras que o §18 pede, e que este arquivo cumpre:
##
## **Versionado.** O arquivo carrega `versao`. Save de versão desconhecida não é
## adivinhado: vale o padrão, e o arquivo antigo é preservado até o próximo
## salvamento. Perder recorde é ruim; carregar um campo com sentido trocado é
## pior.
##
## **Defaults seguros.** Arquivo ausente, JSON quebrado, tipo errado num campo:
## em todos os casos o jogo abre com os valores padrão em vez de falhar.
##
## **Sem servidor.** É um arquivo em `user://`, que no Android fica na área
## privada do app.

## Onde o save mora. `user://` é a pasta do app, fora do projeto.
const CAMINHO := "user://save.json"

## Versão do formato. Muda quando um campo muda de sentido, não quando um campo
## novo aparece — campo novo cai no padrão sozinho.
const VERSAO := 1

## O que um save vazio contém. É também o que vale quando o arquivo está
## corrompido ou é de uma versão que este jogo não conhece.
const PADRAO := {
	"versao": VERSAO,
	"partidas": 0,
	"vitorias": 0,
	"melhor_tempo": 0.0,
	"melhor_nivel": 0,
	"tempo_total": 0.0,
}

## Guardado em memória depois da primeira leitura: o disco é lido uma vez por
## sessão, e não a cada consulta do menu.
static var _dados: Dictionary = {}

## Caminho em uso. Só os testes trocam isto, para não mexer no save de verdade
## de quem está jogando na mesma máquina.
static var _caminho := CAMINHO


## Os dados do save, lendo do disco na primeira vez.
static func dados() -> Dictionary:
	if _dados.is_empty():
		_dados = _ler()
	return _dados


## Registra o fim de uma partida e grava. Devolve `true` se bateu algum recorde.
static func registrar_partida(vitoria: bool, tempo: float, nivel: int) -> bool:
	var d := dados()
	d["partidas"] = int(d["partidas"]) + 1
	d["tempo_total"] = float(d["tempo_total"]) + maxf(0.0, tempo)
	if vitoria:
		d["vitorias"] = int(d["vitorias"]) + 1

	var recorde := false
	if tempo > float(d["melhor_tempo"]):
		d["melhor_tempo"] = tempo
		recorde = true
	if nivel > int(d["melhor_nivel"]):
		d["melhor_nivel"] = nivel
		recorde = true

	gravar()
	return recorde


## Escreve o que está em memória. Falha de escrita não derruba a partida: o
## jogo continua, e o registro se perde — o contrário seria perder a partida
## inteira por causa de um disco cheio.
static func gravar() -> bool:
	var arquivo := FileAccess.open(_caminho, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Não consegui gravar o save em %s (erro %d)" % [_caminho, FileAccess.get_open_error()])
		return false
	arquivo.store_string(JSON.stringify(dados(), "\t"))
	arquivo.close()
	return true


## Apaga o save e volta ao padrão. Existe para os testes e para um futuro botão
## de "apagar progresso".
static func apagar() -> void:
	if FileAccess.file_exists(_caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_caminho))
	_dados = PADRAO.duplicate()


## Troca o arquivo usado. **Só para teste**: sem isto, rodar a suíte apagaria o
## progresso de quem joga na mesma máquina.
static func usar_caminho(caminho: String) -> void:
	_caminho = caminho
	_dados = {}


static func _ler() -> Dictionary:
	if not FileAccess.file_exists(_caminho):
		return PADRAO.duplicate()

	var arquivo := FileAccess.open(_caminho, FileAccess.READ)
	if arquivo == null:
		push_warning("Save existe mas não abriu: %s" % _caminho)
		return PADRAO.duplicate()
	var texto := arquivo.get_as_text()
	arquivo.close()

	var lido: Variant = JSON.parse_string(texto)
	if typeof(lido) != TYPE_DICTIONARY:
		push_warning("Save ilegível em %s: vale o padrão" % _caminho)
		return PADRAO.duplicate()
	if int((lido as Dictionary).get("versao", -1)) != VERSAO:
		push_warning("Save da versão %s; este jogo lê a %d. Vale o padrão."
			% [str((lido as Dictionary).get("versao", "?")), VERSAO])
		return PADRAO.duplicate()

	# Campo a campo, com o tipo do padrão: um campo faltando ou com tipo trocado
	# vira o padrão em vez de contaminar o resto.
	var saida := PADRAO.duplicate()
	for chave in PADRAO:
		if not (lido as Dictionary).has(chave):
			continue
		var valor: Variant = (lido as Dictionary)[chave]
		match typeof(PADRAO[chave]):
			TYPE_INT:
				if typeof(valor) == TYPE_FLOAT or typeof(valor) == TYPE_INT:
					saida[chave] = int(valor)
			TYPE_FLOAT:
				if typeof(valor) == TYPE_FLOAT or typeof(valor) == TYPE_INT:
					saida[chave] = float(valor)
			_:
				saida[chave] = valor
	return saida
