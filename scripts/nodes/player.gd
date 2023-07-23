extends Node
class_name Player


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_node_path("CharacterBody2D") var control_node_path : NodePath = ^"":		set = set_control_node_path


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _control : CharacterBody2D = null


func set_control_node_path(path : NodePath) -> void:
	if path != control_node_path:
		control_node_path = path
		_UpdateControlNode()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateControlNode()

func _unhandled_input(event : InputEvent) -> void:
	if _control == null: return
	
	#_CheckControlModeFromEvent(event)
	if not _control.visible: return
	
	if Game.get_control_mode() == Game.CTRLMode.Mouse:
		if is_instance_of(event, InputEventMouseMotion):
			_control.face_position(_control.get_local_mouse_position() + _control.position)
	elif Game.get_control_mode() == Game.CTRLMode.Joypad:
		var _fdir : Vector2 = Vector2.ZERO
		if event.is_action("up") or event.is_action("down"):
			_fdir.y = event.get_action_strength("down") - event.get_action_strength("up")
		elif event.is_action("left") or event.is_action("right"):
			_fdir.x = event.get_action_strength("right") - event.get_action_strength("left")
		_control.face_position(_control.position + _fdir)
	
	var _dir : Vector2 = _control.get_direction()
	if event.is_action("north") or event.is_action("south"):
		_dir.y = event.get_action_strength("south") - event.get_action_strength("north")
	elif event.is_action("east") or event.is_action("west"):
		_dir.x = event.get_action_strength("east") - event.get_action_strength("west")
	elif event.is_action_pressed("attack"):
		_control.attack(true)
	elif event.is_action_released("attack"):
		_control.attack(false)
	elif event.is_action_pressed("interact"):
		_control.interact()
	_control.move(_dir)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
#func _CheckControlModeFromEvent(event : InputEvent) -> void:
#	if is_instance_of(event, InputEventKey) or is_instance_of(event, InputEventMouse):
#		Game.set_control_mode(Game.CTRLMode.Mouse)
#	else:
#		Game.set_control_mode(Game.CTRLMode.Joypad)

func _UpdateControlNode() -> void:
	if _control != null:
		# TODO: Disconnect _control signals as needed
		_control = null
	
	if control_node_path == ^"":
		var parent = get_parent()
		if is_instance_of(parent, CharacterBody2D):
			#_control = parent
			control_node_path = get_path_to(parent)
			return
	else:
		var target = get_node_or_null(control_node_path)
		if is_instance_of(target, CharacterBody2D):
			_control = target
		else:
			printerr("Player failed to find node at ", control_node_path)
	
	if _control != null:
		# TODO: Connect _control signals as needed
		pass
