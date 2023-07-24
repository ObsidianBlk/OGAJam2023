extends Control


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _level : WeakRef = weakref(null)
var _temp_scale : int = 0 # 0 = F | 1 = C

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _temperature: Label = %Temperature
@onready var _health_bar: ProgressBar = %HealthBar


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false

func _process(_delta : float) -> void:
	if _level.get_ref() == null and visible:
		visible = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_level(level : GameLevel) -> void:
	if _level.get_ref() != level:
		if _level.get_ref() != null:
			var l : GameLevel = _level.get_ref()
			if l.temprature_changed.is_connected(_on_temprature_changed):
				l.temprature_changed.disconnect(_on_temprature_changed)
			if l.player_health_changed.is_connected(_on_player_health_changed):
				l.player_health_changed.disconnect(_on_player_health_changed)
		
		_level = weakref(level)
		if level != null:
			visible = true
			if not level.temprature_changed.is_connected(_on_temprature_changed):
				level.temprature_changed.connect(_on_temprature_changed)
			if not level.player_health_changed.is_connected(_on_player_health_changed):
				level.player_health_changed.connect(_on_player_health_changed)
		else:
			visible = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_temprature_changed(temp : float) -> void:
	if _temp_scale == 1:
		_temperature.text = "%.2d°C"%[(temp - 32)/1.8]
	else:
		_temperature.text = "%.2d°F"%[temp]

func _on_player_health_changed(percent : float) -> void:
	_health_bar.value = 100.0 * percent
