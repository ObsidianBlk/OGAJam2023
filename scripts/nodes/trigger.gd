extends Node2D
class_name Trigger


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal activated()
signal deactivated()

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _activated : bool = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func is_activated() -> bool:
	return _activated

func set_activated(a : bool) -> void:
	if a != _activated:
		_activated = a
		if Engine.is_editor_hint(): return
		if _activated:
			activated.emit()
		else:
			deactivated.emit()
