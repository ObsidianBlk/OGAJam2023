extends NavigationAgent2D
class_name EnemyNavigationAgent


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy Navigation Agent")
@export var follow_target : Node2D = null:				set = set_follow_target
@export var follow_update_interval : float = 0.1

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active : bool = false
var _timer : Timer = null
var _owner : WeakRef = weakref(null)


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_follow_target(t : Node2D) -> void:
	if t != follow_target:
		follow_target = t
		if _active:
			target_position = follow_target.global_position

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = follow_update_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_follow_interval_timeout)
	add_child(_timer)


func _physics_process(delta : float) -> void:
	if not _active: return
	
	var parent : Enemy = _owner.get_ref()
	if parent == null:
		parent = get_parent()
		if not is_instance_of(parent, Enemy):
			return
		_owner = weakref(parent)
	
	var new_position : Vector2 = get_next_path_position()
	parent.set_direction(parent.global_position.direction_to(new_position))

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func activate(enable : bool) -> void:
	if enable != _active:
		_active = enable
		if _active:
			_timer.start(follow_update_interval)
		else:
			_timer.stop()

func is_active() -> bool:
	return _active

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_follow_interval_timeout() -> void:
	if not _active or follow_target == null: return
	target_position = follow_target.global_position

