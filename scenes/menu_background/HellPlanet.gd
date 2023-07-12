@tool
extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Hell Planet")
@export_range(0, 10) var seed = 1.0:						set = set_seed
@export_range(-1.0, 1.0) var time_speed = 0.2:				set = set_time_speed
@export_range(0.0, 6.28) var planet_rotation = 1.0:			set = set_planet_rotation


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _time : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _planet_under : ColorRect = $PlanetUnder
@onready var _craters : ColorRect = $Craters
@onready var _rivers : ColorRect = $Rivers

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_seed(s : float) -> void:
	seed = s
	_UpdateShaderParam("seed", seed)

func set_time_speed(s : float) -> void:
	if s >= -1.0 and s <= 1.0:
		time_speed = s
		_UpdateShaderParam("time_speed", time_speed)

func set_planet_rotation(r : float) -> void:
	if r >= 0.0 and r <= 6.28:
		planet_rotation = r
		_UpdateShaderParam("rotation", planet_rotation)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_seed(seed)
	set_time_speed(time_speed)
	set_planet_rotation(planet_rotation)
	_UpdateSize()

func _process(delta : float):
	_time += delta
	_UpdateShaderParam("time", _time)

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_UpdateSize()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateShaderParam(param : StringName, value : Variant) -> void:
	if _planet_under != null:
		_planet_under.material.set_shader_parameter(param, value)
	if _craters != null:
		_craters.material.set_shader_parameter(param, value)
	if _rivers != null:
		_rivers.material.set_shader_parameter(param, value)

func _UpdateSize() -> void:
	var size : Vector2 = get_size()
	var pixels = min(size.x, size.y)
	_UpdateShaderParam("pixels", pixels)
	#_UpdateShaderParam("size", )
