extends Trigger
class_name TriggerArea


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Tigger Area")
@export var trigger_delay : float = 0.5


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _area : Area2D = null
var _bodies : Dictionary = {}

var _awaiting_trigger : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)
	_FindArea()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectArea() -> void:
	if _area == null: return
	if not _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.connect(_on_body_entered)
	if not _area.body_exited.is_connected(_on_body_exited):
		_area.body_exited.connect(_on_body_exited)

func _DisconnectArea() -> void:
	if _area == null: return
	if _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.disconnect(_on_body_entered)
	if _area.body_exited.is_connected(_on_body_exited):
		_area.body_exited.disconnect(_on_body_exited)
	_bodies.clear()

func _FindArea() -> void:
	if _area != null: return
	for child in get_children():
		if is_instance_of(child, Area2D):
			_area = child
			_ConnectArea()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_child_entered_tree(child : Node) -> void:
	if _area == null and is_instance_of(child, Area2D):
		_area = child
		_ConnectArea()

func _on_child_exited_tree(child : Node) -> void:
	if _area == child:
		_DisconnectArea()
		_area = null
		_FindArea.call_deferred()

func _on_body_entered(body : Node2D) -> void:
	if not body.name in _bodies:
		_bodies[body.name] = weakref(body)
		if not _awaiting_trigger:
			if trigger_delay <= 0:
				set_activated(true)
			else:
				_awaiting_trigger = true
				get_tree().create_timer(trigger_delay).timeout.connect(_on_trigger_delay_timeout, CONNECT_ONE_SHOT)

func _on_body_exited(body : Node2D) -> void:
	if body.name in _bodies:
		_bodies.erase(body.name)
		if _bodies.size() <= 0:
			set_activated(false)

func _on_trigger_delay_timeout() -> void:
	_awaiting_trigger = false
	if _bodies.size() > 0:
		set_activated(true)
