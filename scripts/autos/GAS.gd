extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal audio_bus_volume_changed(bus_name, bus_id, linear_volume)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SECTION : String = "AUDIO_SETTINGS"

enum AUDIO_BUS {Master=0, Music=1, SFX=2}
const AUDIO_BUS_NAMES : Array = [
	"Master",
	"Music",
	"SFX"
]

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.config_changed.connect(_LoadFromConfig)
	Game.config_update_requested.connect(_SaveToConfig)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _LoadFromConfig(conf : ConfigFile) -> void:
	if conf == null: return
	for i in range(AUDIO_BUS_NAMES.size()):
		var key : String = AUDIO_BUS_NAMES[i]
		if conf.has_section_key(SECTION, key):
			var val = conf.get_value(SECTION, key)
			if typeof(val) == TYPE_INT:
				set_audio_volume(i, float(val) * 0.001)

func _SaveToConfig(conf : ConfigFile) -> void:
	# Stores volume as an integer from 0 to 1000
	if conf == null: return
	for i in range(AUDIO_BUS_NAMES.size()):
		var key : String = AUDIO_BUS_NAMES[i]
		var vol : int = floor(get_audio_volume(i) * 1000)
		conf.set_value(SECTION, key, vol)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func load_from_config() -> void:
	_LoadFromConfig(Game.get_config())

func save_to_config() -> void:
	_SaveToConfig(Game.get_config())

func set_audio_volume(bus_id : int, vol : float) -> void:
	var bus_idx : int = -1
	if bus_id >= 0 and bus_id < AUDIO_BUS_NAMES.size():
		bus_idx = AudioServer.get_bus_index(AUDIO_BUS_NAMES[bus_id])
	
	if bus_idx >= 0:
		vol = max(0.0, min(1.0, vol))
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(vol))
		audio_bus_volume_changed.emit(AUDIO_BUS_NAMES[bus_id], bus_id, vol)

func get_audio_volume(bus_id : int) -> float:
	var bus_idx : int = -1
	if bus_id >= 0 and bus_id < AUDIO_BUS_NAMES.size():
		bus_idx = AudioServer.get_bus_index(AUDIO_BUS_NAMES[bus_id])
	
	if bus_idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return -1.0


