extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal control_mode_changed(mode)

signal config_changed(config)
signal config_update_requested(config)
signal config_saved()

signal gameplay_option_changed(option_name, value)

signal xeno_kills_changed(count)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
enum CTRLMode {Mouse=0, Joypad=1}

const CONFIG_FILE_PATH : String = "user://game.conf"

const SECTION_GAMEPLAY : String = "GamePlay"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _lock_control_mode : bool = false
var _control_mode : CTRLMode = CTRLMode.Mouse:		set = set_control_mode
var _active_joypad_device : int = 0

var _xenos_killed : int = 0

var _config : ConfigFile = null

var _gameplay_disable_heat_haze : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _lock_control_mode: return
	
	var nmode : CTRLMode = _control_mode
	if is_instance_of(event, InputEventKey) or is_instance_of(event, InputEventMouse):
		nmode = CTRLMode.Mouse
	elif is_instance_of(event, InputEventJoypadButton):
		nmode = CTRLMode.Joypad
		_active_joypad_device = event.device
	elif is_instance_of(event, InputEventJoypadMotion):
		if abs(event.axis_value) >= 0.5:
			nmode = CTRLMode.Joypad
			_active_joypad_device = event.device
	
	if nmode != _control_mode:
		_control_mode = nmode

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateHandledConfigValues() -> void:
	gameplay_set_disable_heat_haze(
		_config.get_value(SECTION_GAMEPLAY, "disable_heat_haze", false),
		true
	)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func load_config() -> void:
	_config = ConfigFile.new()
	var err : int = _config.load(CONFIG_FILE_PATH)
	if err != OK:
		save_config()
	else:
		_UpdateHandledConfigValues()
	config_changed.emit(_config)

func save_config() -> void:
	if _config == null: return
	config_update_requested.emit(_config)
	var err : int = _config.save(CONFIG_FILE_PATH)
	if err == OK:
		config_saved.emit()

func get_config() -> ConfigFile:
	return _config

func gameplay_set_disable_heat_haze(disable : bool, ignore_config : bool = false) -> void:
	if disable != _gameplay_disable_heat_haze:
		_gameplay_disable_heat_haze = disable
		if _config != null and not ignore_config:
			_config.set_value(SECTION_GAMEPLAY, "disable_heat_haze", disable)
		gameplay_option_changed.emit("disable_heat_haze", disable)

func gameplay_get_disable_heat_haze() -> bool:
	return _gameplay_disable_heat_haze

func reset_xeno_count() -> void:
	_xenos_killed = 0
	xeno_kills_changed.emit(_xenos_killed)

func xeno_killed() -> void:
	_xenos_killed += 1
	xeno_kills_changed.emit(_xenos_killed)

func set_control_mode(mode : CTRLMode) -> void:
	_control_mode = mode
	control_mode_changed.emit(_control_mode)

func get_control_mode() -> CTRLMode:
	return _control_mode

func get_active_joypad_device() -> int:
	return _active_joypad_device

func lock_control_mode(lock : bool) -> void:
	_lock_control_mode = lock

func is_control_mode_locked() -> bool:
	return _lock_control_mode

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

func get_random_reachable_nav_point_in_group(nav_group : String, map : RID, from : Vector2, exclude : NavPoint = null) -> NavPoint:
	var reachable : Array = get_reachable_nav_points_in_group(nav_group, map, from)
	if reachable.size() > 0:
		var idx : int = randi_range(0, reachable.size() - 1)
		if reachable[idx] != exclude:
			return reachable[idx]
		elif reachable.size() > 1:
			return get_random_reachable_nav_point_in_group(nav_group, map, from, exclude)
	return null

func get_reachable_nav_points_in_group(nav_group : String, map : RID, from : Vector2) -> Array:
	if nav_group.is_empty(): return []
	if not NavigationServer2D.map_is_active(map): return []
	var reachable : Array = []
	
	var ng : StringName = StringName("np_%s"%[nav_group])
	var np_nodes : Array = get_tree().get_nodes_in_group(ng)
	for nav in np_nodes:
		if not is_instance_of(nav, NavPoint): continue
		var path : PackedVector2Array = NavigationServer2D.map_get_path(
			map, from, nav.global_position, true
		)
		if path.size() > 0 and path[path.size() - 1] == nav.global_position:
			reachable.append(nav)
	return reachable

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

