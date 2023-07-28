extends Node
class_name AudioStreamGroup2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal finished(group_name)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mas : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)
	for child in get_children():
		_on_child_entered_tree(child)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func play(group_name : String, force : bool = false) -> void:
	if not group_name in _mas: return
	var mas : MultiAudioStreamer2D = _mas[group_name].get_ref()
	if mas != null:
		mas.play(&"", force)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_child_entered_tree(child : Node) -> void:
	if is_instance_of(child, MultiAudioStreamer2D):
		_mas[child.name] = weakref(child)
		if not child.finished.is_connected(_on_child_finished.bind(child.name)):
			child.finished.connect(_on_child_finished.bind(child.name))

func _on_child_exited_tree(child : Node) -> void:
	if child.name in _mas:
		if child.finished.is_connected(_on_child_finished.bind(child.name)):
			child.finished.disconnect(_on_child_finished.bind(child.name))
		_mas.erase(child.name)

func _on_child_finished(group_name : String) -> void:
	finished.emit(group_name)
