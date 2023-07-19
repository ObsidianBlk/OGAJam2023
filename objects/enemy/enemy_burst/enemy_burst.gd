extends Node2D


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _die() -> void:
	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_asprite_animation_finished():
	_die.call_deferred()
