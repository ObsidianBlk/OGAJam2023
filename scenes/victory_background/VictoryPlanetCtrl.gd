@tool
extends Control

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Victory Planet Control")
@export var center_offset : Vector2 = Vector2.ZERO:		set = set_center_ffset

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _planet: AspectRatioContainer = $Planet


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_center_ffset(o : Vector2) -> void:
	if not o.is_equal_approx(center_offset):
		center_offset = o
		_PositionPlanet()
		

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_PositionPlanet()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_PositionPlanet()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _PositionPlanet() -> void:
	if _planet == null: return
	var wsize : Vector2 = get_size()
	var ppostion : Vector2 = Vector2(wsize.x, wsize.y * 0.5)
	_planet.size = wsize * 0.85
	_planet.position = (ppostion - (_planet.size * 0.5)) + center_offset
