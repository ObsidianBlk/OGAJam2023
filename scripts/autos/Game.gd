extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal control_mode_changed(mode)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum CTRLMode {Mouse=0, Joypad=1}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _control_mode : CTRLMode = CTRLMode.Mouse:		set = set_control_mode


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_control_mode(mode : CTRLMode) -> void:
	_control_mode = mode
	control_mode_changed.emit(_control_mode)

func get_control_mode() -> CTRLMode:
	return _control_mode

func get_random_nav_point_in_group(nav_group : String) -> NavPoint:
	if nav_group.is_empty(): return null
	var ng : StringName = StringName("np_%s"%[nav_group])
	var np_nodes : Array = get_tree().get_nodes_in_group(ng)
	if np_nodes.size() > 0:
		var idx = randi_range(0, np_nodes.size() - 1)
		if is_instance_of(np_nodes[idx], NavPoint):
			return np_nodes[idx]
	return null

