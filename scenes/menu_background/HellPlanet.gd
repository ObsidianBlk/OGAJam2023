@tool
extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Hell Planet")
@export_range(0, 10) var seed = 1.0:						set = set_seed
@export_range(-1.0, 1.0) var time_speed = 0.2:				set = set_time_speed


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

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_seed(seed)
	set_time_speed(time_speed)

func _process(delta : float):
	_time += delta
	_UpdateShaderParam("time", _time)

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

