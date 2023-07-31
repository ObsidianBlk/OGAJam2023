extends Area2D
class_name ExitArea2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal level_exited()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Exit Area 2D")
@export var delay_to_exit : float = 1.0
@export var trigger : Trigger = null:				set = set_trigger

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _bodies : Dictionary = {}
var _time_passed : float = 0.0
var _triggered : bool = false


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_trigger(t : Trigger) -> void:
	if t != trigger:
		if trigger != null:
			if trigger.activated.is_connected(_on_trigger_activated):
				trigger.activated.disconnect(_on_trigger_activated)
		trigger = t
		if trigger != null:
			if not trigger.activated.is_connected(_on_trigger_activated):
				trigger.activated.connect(_on_trigger_activated)
			if trigger.is_activated():
				_triggered = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_ClearBodyDict()
	if trigger != null:
		if not _triggered: return
	if _bodies.size() > 0 and _time_passed < delay_to_exit:
		_time_passed += delta
		if _time_passed >= delay_to_exit:
			level_exited.emit()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearBodyDict() -> void:
	var keys : Array = _bodies.keys()
	for key in keys:
		if _bodies[key].get_ref() == null:
			_bodies.erase(key)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	_bodies[body.name] = weakref(body)

func _on_body_exited(body : Node2D) -> void:
	_ClearBodyDict()
	if body.name in _bodies:
		_bodies.erase(body.name)
	if _bodies.size() <= 0:
		_time_passed = 0.0

func _on_trigger_activated() -> void:
	print("Exit Triggered")
	_triggered = true
