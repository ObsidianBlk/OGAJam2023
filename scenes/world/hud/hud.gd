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
@onready var _ammo_count: Label = %AmmoCount
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _key_red: HBoxContainer = %KeyRed
@onready var _key_green: HBoxContainer = %KeyGreen
@onready var _key_blue: HBoxContainer = %KeyBlue
@onready var _key_orange: HBoxContainer = %KeyOrange
@onready var _key_yellow: HBoxContainer = %KeyYellow
@onready var _red_count: Label = %RedCount
@onready var _green_count: Label = %GreenCount
@onready var _blue_count: Label = %BlueCount
@onready var _orange_count: Label = %OrangeCount
@onready var _yellow_count: Label = %YellowCount


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	Game.inventory_changed.connect(_on_inventory_changed)

func _process(_delta : float) -> void:
	if _level.get_ref() == null and visible:
		visible = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateKeyInfo(container : Control, label : Label, count : int) -> void:
	if count <= 0:
		container.visible = false
	else:
		container.visible = true
		if count == 1:
			label.visible = false
		else:
			label.visible = true
			label.text = "x%s"%[count]

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

func _on_inventory_changed(item : String, count : int) -> void:
	match item:
		"ammo":
			_ammo_count.text = "%s"%[count]
		"key_red":
			_UpdateKeyInfo(_key_red, _red_count, count)
		"key_green":
			_UpdateKeyInfo(_key_green, _green_count, count)
		"key_blue":
			_UpdateKeyInfo(_key_blue, _blue_count, count)
		"key_orange":
			_UpdateKeyInfo(_key_orange, _orange_count, count)
		"key_yellow":
			_UpdateKeyInfo(_key_yellow, _yellow_count, count)

