extends Control
class_name UIMenu


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(request)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if visible:
		visible = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	visible = (menu_name == name)

func send_request(action : StringName, payload : StringName = &"") -> void:
	requested.emit({
		"action":action,
		"payload":payload
	})
