extends Trigger
class_name TriggerDialog


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Trigger Dialog")
@export var dialogue : DialogueResource = null
@export var start : String = ""
@export var input_trigger : Trigger = null:				set = set_input_trigger
@export var once : bool = false


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _triggered : bool = false

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_input_trigger(t : Trigger) -> void:
	if t != input_trigger:
		if input_trigger != null:
			if input_trigger.activated.is_connected(_on_trigger_activated):
				input_trigger.activated.disconnect(_on_trigger_activated)
			if input_trigger.deactivated.is_connected(_on_trigger_deactivated):
				input_trigger.deactivated.disconnect(_on_trigger_deactivated)
		input_trigger = t
		if input_trigger != null:
			if not input_trigger.activated.is_connected(_on_trigger_activated):
				input_trigger.activated.connect(_on_trigger_activated)
			if not input_trigger.deactivated.is_connected(_on_trigger_deactivated):
				input_trigger.deactivated.connect(_on_trigger_deactivated)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_trigger_activated() -> void:
	if once and _triggered: return
	_triggered = true
	if dialogue != null and not start.is_empty():
		Game.request_dialog(dialogue, start)
	set_activated(true)

func _on_trigger_deactivated() -> void:
	set_activated(false)
