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

func get_random_nav_point_in_group(nav_group : String, exclude : NavPoint = null) -> NavPoint:
	if nav_group.is_empty(): return null
	var ng : StringName = StringName("np_%s"%[nav_group])
	var np_nodes : Array = get_tree().get_nodes_in_group(ng)
	if np_nodes.size() > 0:
		var idx = randi_range(0, np_nodes.size() - 1)
		if is_instance_of(np_nodes[idx], NavPoint):
			if np_nodes[idx] != exclude:
				return np_nodes[idx]
			elif np_nodes.size() > 1:
				return get_random_nav_point_in_group(nav_group, exclude)
	return null

func get_closest_nav_point_reachable_in_group(nav_group : String, map : RID, from : Vector2, to : Vector2) -> NavPoint:
	if nav_group.is_empty(): return null
	if not NavigationServer2D.map_is_active(map): return null
	
	var nav_point : NavPoint = null
	var distance : float = -1.0
	
	var ng : StringName = StringName("np_%s"%[nav_group])
	var np_nodes : Array = get_tree().get_nodes_in_group(ng)
	for nav in np_nodes:
		var path : PackedVector2Array = NavigationServer2D.map_get_path(
			map, from, nav.global_position, true
		)
		if path.size() > 0 and path[path.size() - 1] == nav.global_position:
			var dist : float = nav.global_position.distance_to(to)
			if nav_point == null or dist < distance:
				nav_point = nav
				distance = dist
	return nav_point

