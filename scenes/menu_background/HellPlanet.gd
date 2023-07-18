@tool
extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Hell Planet")
@export_range(0, 10) var planet_seed : float = 1.0:			set = set_planet_seed
@export_range(-1.0, 1.0) var time_speed : float = 0.2:		set = set_time_speed
@export_range(0.0, 6.28) var planet_rotation : float = 1.0:	set = set_planet_rotation


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
func set_planet_seed(ps : float) -> void:
	planet_seed = ps
	_UpdateShaderParam("seed", planet_seed)

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
	set_planet_seed(planet_seed)
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
	var ctrl_size : Vector2 = get_size()
	var pixels = min(ctrl_size.x, ctrl_size.y)
	_UpdateShaderParam("pixels", pixels)
