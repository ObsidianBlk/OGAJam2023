extends Node2D


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Trigger Timer Display")
@export var trigger_timer : TriggerTimer = null:			set = set_trigger_timer
@export var count_down : bool = true
@export var hide_while_inactive : bool = true:				set = set_hide_while_inactive

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _timer_label: Label = %TimerLabel

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_trigger_timer(t : TriggerTimer) -> void:
	if t != trigger_timer:
		if trigger_timer != null:
			if trigger_timer.timer_started.is_connected(_on_timer_started):
				trigger_timer.timer_started.disconnect(_on_timer_started)
			if trigger_timer.timer_ended.is_connected(_on_timer_ended):
				trigger_timer.timer_ended.disconnect(_on_timer_ended)
			if trigger_timer.timer_changed.is_connected(_on_timer_changed):
				trigger_timer.timer_changed.disconnect(_on_timer_changed)
		trigger_timer = t
		if trigger_timer != null:
			if not trigger_timer.timer_started.is_connected(_on_timer_started):
				trigger_timer.timer_started.connect(_on_timer_started)
			if not trigger_timer.timer_ended.is_connected(_on_timer_ended):
				trigger_timer.timer_ended.connect(_on_timer_ended)
			if not trigger_timer.timer_changed.is_connected(_on_timer_changed):
				trigger_timer.timer_changed.connect(_on_timer_changed)
			if trigger_timer.is_timer_active():
				visible = true
				_on_timer_changed(trigger_timer.get_time_passed(), trigger_timer.interval)
			else:
				visible = not hide_while_inactive

func set_hide_while_inactive(hwi : bool) -> void:
	if hwi != hide_while_inactive:
		hide_while_inactive = hwi
		if trigger_timer == null:
			visible = not hide_while_inactive
		else:
			visible = true if not hide_while_inactive else trigger_timer.is_timer_active()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_timer_started() -> void:
	visible = true

func _on_timer_ended() -> void:
	if hide_while_inactive:
		visible = false

func _on_timer_changed(passed : float, interval : float) -> void:
	var time = passed if not count_down else interval - passed
	var min : int = floor(time / 60.0)
	var sec : int = floor(time - (min * 60.0))
	_timer_label.text = "%s:%s"%[
		"%d"%[min] if min > 9 else "0%d"%[min],
		"%d"%[sec] if sec > 9 else "0%d"%[sec]
	]


