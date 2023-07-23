extends Button

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal audio_requested(audio_name, forced)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mouse_entered : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pressed.connect(_on_pressed)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_mouse_entered = true
			audio_requested.emit(&"focused", false)
		NOTIFICATION_MOUSE_EXIT:
			_mouse_entered = false
		NOTIFICATION_FOCUS_ENTER:
			if not _mouse_entered:
				audio_requested.emit(&"focused", false)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_pressed() -> void:
	audio_requested.emit(&"pressed", true)
