extends UIMenu


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _slider_master: HSlider = %SliderMaster
@onready var _slider_music: HSlider = %SliderMusic
@onready var _slider_sfx: HSlider = %SliderSFX
@onready var _check_disable_heat_haze: CheckButton = %Check_DisableHeatHaze

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.gameplay_option_changed.connect(_on_gameplay_option_changed)
	GAS.audio_bus_volume_changed.connect(_on_audio_bus_volume_changed)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ResetAudioValues() -> void:
	var vol : float = GAS.get_audio_volume(GAS.AUDIO_BUS.Master)
	_slider_master.value = vol * 1000
	vol = GAS.get_audio_volume(GAS.AUDIO_BUS.Music)
	_slider_music.value = vol * 1000
	vol = GAS.get_audio_volume(GAS.AUDIO_BUS.SFX)
	_slider_sfx.value = vol * 1000

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	super.show_menu(menu_name)
	enable_audio_requests(visible)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_requested(audio_name : StringName, forced : bool) -> void:
	request_audio(audio_name, forced)

func _on_audio_bus_volume_changed(_bus_name : String, bus_id : int, linear_volume : float) -> void:
	var vol : float = linear_volume * 1000
	match bus_id:
		GAS.AUDIO_BUS.Master:
			_slider_master.value = vol
		GAS.AUDIO_BUS.Music:
			_slider_music.value = vol
		GAS.AUDIO_BUS.SFX:
			_slider_sfx.value = vol

func _on_gameplay_option_changed(gameplay_option : String, value : Variant) -> void:
	match gameplay_option:
		"disable_heat_haze":
			if typeof(value) == TYPE_BOOL:
				_check_disable_heat_haze.button_pressed = value

func _on_slider_master_value_changed(value: float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.Master, value * 0.001)

func _on_slider_music_value_changed(value: float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.Music, value * 0.001)

func _on_slider_sfx_value_changed(value: float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.SFX, value * 0.001)

func _on_check_disable_heat_haze_toggled(pressed : bool) -> void:
	Game.gameplay_set_disable_heat_haze(pressed)

func _on_apply_pressed() -> void:
	Game.save_config()
	send_request(&"menu_back")

func _on_reset_pressed() -> void:
	GAS.load_from_config()
	_ResetAudioValues()
