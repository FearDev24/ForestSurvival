extends Node
## Provedor de anúncios do Android, sobre o plugin da Poing Studios (AdMob).
##
## Só `Anuncios.iniciar` carrega este script, e só no Android com o plugin
## presente: ele cita as classes do plugin, e ler essas classes fora do celular
## acorda o simulador do editor (ver `anuncios.gd`).
##
## A ordem é a que a Google pede: primeiro o **consentimento** (UMP), depois
## iniciar o SDK, depois carregar. Pedir anúncio antes do consentimento, na
## Europa, é infração de política.

## Unidade premiada de teste da própria Google. Build de depuração usa sempre
## esta: clicar no anúncio real do próprio app, mesmo testando, é tráfego
## inválido e pode suspender a conta AdMob.
const PREMIADO_TESTE := "ca-app-pub-3940256099942544/5224354917"

## Unidade premiada de verdade ("dobrar_moedas", no painel da AdMob). Só a build
## de lançamento usa; vazia, ela simplesmente não mostraria anúncio.
const PREMIADO_REAL := "ca-app-pub-4397221687948677/8642654141"

## Espera entre tentativas depois de uma falha de carga, em segundos. Sem rede
## a falha é imediata, e tentar em laço gastaria bateria à toa.
const _ESPERA_FALHA := 30.0

var _anuncio: RewardedAd = null
var _carregando := false
var _sdk_pronto := false
var _ao_ganhar := Callable()
var _espera := 0.0
var _premio_pendente := false

var _ao_carregar := RewardedAdLoadCallback.new()
var _ao_exibir := FullScreenContentCallback.new()
var _ao_ganhar_premio := OnUserEarnedRewardListener.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ao_carregar.on_ad_loaded = _carregou
	_ao_carregar.on_ad_failed_to_load = _falhou_carga
	_ao_exibir.on_ad_dismissed_full_screen_content = _fechou
	_ao_exibir.on_ad_failed_to_show_full_screen_content = _falhou_exibir
	_ao_ganhar_premio.on_user_earned_reward = _ganhou
	_pedir_consentimento()


func _process(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		if _espera <= 0.0:
			_carregar()


func premiado_pronto() -> bool:
	return _anuncio != null


func mostrar_premiado(ao_ganhar: Callable) -> bool:
	if _anuncio == null:
		return false
	_ao_ganhar = ao_ganhar
	_anuncio.show(_ao_ganhar_premio)
	return true


func privacidade_necessaria() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func mostrar_privacidade() -> void:
	UserMessagingPlatform.show_privacy_options_form()


func _id_premiado() -> String:
	return PREMIADO_TESTE if OS.is_debug_build() else PREMIADO_REAL


# --- consentimento -----------------------------------------------------------

func _pedir_consentimento() -> void:
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(),
		_consentimento_atualizado, _consentimento_falhou)


func _consentimento_atualizado() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available() \
			and _status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(_formulario_carregou,
			func(_erro: FormError) -> void: _iniciar_se_permitido())
		return
	_iniciar_se_permitido()


## Sem rede, a atualização falha — mas o consentimento dado numa sessão
## anterior continua valendo, e é por ele que se decide.
func _consentimento_falhou(_erro: FormError) -> void:
	_iniciar_se_permitido()


func _formulario_carregou(formulario: ConsentForm) -> void:
	formulario.show(func(_erro: FormError) -> void: _iniciar_se_permitido())


func _status() -> int:
	return UserMessagingPlatform.consent_information.get_consent_status()


func _iniciar_se_permitido() -> void:
	if _sdk_pronto:
		return
	var status := _status()
	if status != ConsentInformation.ConsentStatus.OBTAINED \
			and status != ConsentInformation.ConsentStatus.NOT_REQUIRED:
		return
	_sdk_pronto = true
	var pronto := OnInitializationCompleteListener.new()
	pronto.on_initialization_complete = func(_s: InitializationStatus) -> void: _carregar()
	MobileAds.initialize(pronto)


# --- anúncio premiado --------------------------------------------------------

func _carregar() -> void:
	if not _sdk_pronto or _carregando or _anuncio != null or _id_premiado().is_empty():
		return
	_carregando = true
	RewardedAdLoader.new().load(_id_premiado(), AdRequest.new(), _ao_carregar)


func _carregou(anuncio: RewardedAd) -> void:
	_carregando = false
	anuncio.full_screen_content_callback = _ao_exibir
	_anuncio = anuncio


func _falhou_carga(_erro: LoadAdError) -> void:
	_carregando = false
	_espera = _ESPERA_FALHA


## O prêmio chega **antes** de o anúncio fechar; por isso é guardado e entregue
## só no fechamento, quando o jogo já voltou a desenhar.
func _ganhou(_item: RewardedItem) -> void:
	_premio_pendente = true


func _fechou() -> void:
	_descartar()
	if _premio_pendente and _ao_ganhar.is_valid():
		_ao_ganhar.call()
	_premio_pendente = false
	_ao_ganhar = Callable()
	# O próximo já começa a carregar: a próxima partida acaba em minutos.
	_carregar()


func _falhou_exibir(_erro: AdError) -> void:
	_descartar()
	_premio_pendente = false
	_ao_ganhar = Callable()
	_carregar()


## Anúncio premiado serve uma vez só.
func _descartar() -> void:
	if _anuncio != null:
		_anuncio.destroy()
		_anuncio = null
