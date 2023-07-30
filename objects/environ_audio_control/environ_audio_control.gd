extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUDIO_BUS_OUTSIDE : StringName = &"Outside"
const AUDIO_BUS_INSIDE : StringName = &"Inside"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var indoor_trigger : Trigger = null:		set = set_indoor_trigger

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _asp : AudioStreamPlayer = $AudioStreamPlayer

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_indoor_trigger(t : Trigger) -> void:
	if t != indoor_trigger:
		if indoor_trigger != null:
			if indoor_trigger.activated.is_connected(_on_trigger_activated):
				indoor_trigger.activated.disconnect(_on_trigger_activated)
			if indoor_trigger.deactivated.is_connected(_on_trigger_deactivated):
				indoor_trigger.deactivated.disconnect(_on_trigger_deactivated)
		indoor_trigger = t
		if indoor_trigger != null:
			if not indoor_trigger.activated.is_connected(_on_trigger_activated):
				indoor_trigger.activated.connect(_on_trigger_activated)
			if not indoor_trigger.deactivated.is_connected(_on_trigger_deactivated):
				indoor_trigger.deactivated.connect(_on_trigger_deactivated)
			if indoor_trigger.is_activated():
				_on_trigger_activated()
			else:
				_on_trigger_deactivated()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if indoor_trigger != null:
		if indoor_trigger.is_activated():
			_on_trigger_activated()
		else:
			_on_trigger_deactivated()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_activated() -> void:
	if _asp == null: return
	_asp.bus = AUDIO_BUS_INSIDE

func _on_trigger_deactivated() -> void:
	if _asp == null: return
	_asp.bus = AUDIO_BUS_OUTSIDE
