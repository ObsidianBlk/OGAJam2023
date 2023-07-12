extends CanvasLayer

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(request)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("UI")
@export var initial_menu : StringName = &""

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ConnectMenus()
	show_menu(initial_menu)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectMenus() -> void:
	for child in get_children():
		if not is_instance_of(child, UIMenu): continue
		if not child.requested.is_connected(_on_menu_requested):
			child.requested.connect(_on_menu_requested)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : StringName) -> void:
	for child in get_children():
		if not is_instance_of(child, UIMenu): continue
		child.show_menu(menu_name)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_menu_requested(request : Dictionary) -> void:
	if not "action" in request: return
	match request.action:
		&"show_menu":
			if not "payload" in request: return
			show_menu(request.payload)
		_:
			requested.emit(request)


