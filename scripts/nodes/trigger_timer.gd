extends Trigger
class_name TriggerTimer


# ------------------------------------------------------------------------------
# Signal
# ------------------------------------------------------------------------------
signal timer_changed(time_passed, interval)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Timer Trigger")
@export var interval : float = 1.0
@export var continuous : bool = false
@export var input : Trigger = null:								set = set_input

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _timer_active : bool = false
var _time_passed : float = 0.0

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_input(i : Trigger) -> void:
	if i != input:
		if input != null:
			if input.activated.is_connected(_on_activated):
				input.activated.disconnect(_on_activated)
		input = i
		if input != null:
			if not input.activated.is_connected(_on_activated):
				input.activated.connect(_on_activated)

func set_continuous(c : bool) -> void:
	continuous = c
	if continuous:
		_timer_active = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if continuous:
		_timer_active = true


func _process(delta: float) -> void:
	if not _timer_active: return
	if _time_passed < interval:
		_time_passed += delta
		timer_changed.emit(_time_passed, interval)
		if _time_passed >= interval:
			force_activated()
			if not continuous:
				_timer_active = false
				_time_passed -= interval

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_activated() -> void:
	if _timer_active: return
	set_activated(false)
	_time_passed = 0.0
	_timer_active = true
