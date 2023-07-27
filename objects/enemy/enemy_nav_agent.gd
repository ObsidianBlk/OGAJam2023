extends NavigationAgent2D
class_name EnemyNavigationAgent


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal target_unreachable()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy Navigation Agent")
@export var follow_update_interval : float = 0.1

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active : bool = false
var _timer : Timer = null
var _owner : WeakRef = weakref(null)

var _follow_target : WeakRef = weakref(null)

var _cannot_reach : bool = false


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = follow_update_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_follow_interval_timeout)
	add_child(_timer)


func _physics_process(_delta : float) -> void:
	if not _active: return
	_UpdatePathPosition.call_deferred()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdatePathPosition() -> void:
	var parent : Enemy = _owner.get_ref()
	if parent == null:
		parent = get_parent()
		if not is_instance_of(parent, Enemy):
			return
		_owner = weakref(parent)
	
	var new_position : Vector2 = get_next_path_position()
	if _active:
		parent.set_direction(parent.global_position.direction_to(new_position))
	
	if is_target_reachable():
		_cannot_reach = false
	elif _cannot_reach == false:
		_cannot_reach = true
		target_unreachable.emit()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func follow_target(t : Node2D) -> void:
	if t != _follow_target.get_ref():
		_follow_target = weakref(t)
		if _active and t != null:
			_cannot_reach = false
			target_position = t.global_position

func is_following_a_target() -> bool:
	return _follow_target.get_ref() != null

func is_following_target(t : Node2D) -> bool:
	return _follow_target.get_ref() == t

func get_follow_target() -> Node2D:
	return _follow_target.get_ref()

func activate(enable : bool) -> void:
	if enable != _active:
		_active = enable
		if _active:
			if _timer != null and _timer.is_inside_tree():
				_timer.start(follow_update_interval)
		else:
			if _owner.get_ref() != null:
				_owner.get_ref().set_direction(Vector2.ZERO)
			_timer.stop()

func is_activated() -> bool:
	return _active

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_follow_interval_timeout() -> void:
	if not _active or _follow_target.get_ref() == null: return
	target_position = _follow_target.get_ref().global_position

