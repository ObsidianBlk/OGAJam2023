extends Trigger
class_name TriggerPointLight


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Point Light Trigger")
@export var input : Trigger = null:								set = set_input

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _light : PointLight2D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_input(i : Trigger) -> void:
	if i != input:
		if input != null:
			if input.activated.is_connected(_on_activated):
				input.activated.disconnect(_on_activated)
			if input.deactivated.is_connected(_on_deactivated):
				input.deactivated.disconnect(_on_deactivated)
		input = i
		if input != null:
			if not input.activated.is_connected(_on_activated):
				input.activated.connect(_on_activated)
			if not input.deactivated.is_connected(_on_deactivated):
				input.deactivated.connect(_on_deactivated)
			if input.is_activated():
				_on_activated()
			else:
				_on_deactivated()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exited)
	_FindPointLight()
	_CheckInputState.call_deferred()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CheckInputState() -> void:
	if input != null:
		if input.is_activated():
			_on_activated()
		else:
			_on_deactivated


func _FindPointLight() -> void:
	if _light != null: return
	for child in get_children():
		if is_instance_of(child, PointLight2D):
			_light = child
			_light.enabled = is_activated()
			break

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_activated() -> void:
	set_activated(true)
	if _light == null: return
	_light.enabled = true

func _on_deactivated() -> void:
	set_activated(false)
	if _light == null: return
	_light.enabled = false

func _on_child_entered(child : Node) -> void:
	if _light == null and is_instance_of(child, PointLight2D):
		_light = child
		_light.enabled = is_activated()

func _on_child_exited(child : Node) -> void:
	if child == _light:
		_light = null
		_FindPointLight()

