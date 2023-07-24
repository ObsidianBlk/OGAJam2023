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
@export_subgroup("Audio")
@export var audio_on_focus : AudioStream = null
@export var audio_on_pressed : AudioStream = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _breadcrumb : Array = []

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _audio_ui : AudioStreamPlayer = %AudioUI


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

func _PlayUIAudio(audio_name : StringName) -> void:
	_audio_ui.stream = null
	match audio_name:
		&"focused":
			if audio_on_focus != null:
				_audio_ui.stream = audio_on_focus
		&"pressed":
			if audio_on_pressed != null:
				_audio_ui.stream = audio_on_pressed
	if _audio_ui.stream != null:
		_audio_ui.play()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : StringName) -> void:
	if menu_name != &"":
		_breadcrumb.append(menu_name)
	
	for child in get_children():
		if not is_instance_of(child, UIMenu): continue
		child.show_menu(menu_name)

func menu_back() -> void:
	if _breadcrumb.size() <= 1: return
	_breadcrumb.pop_back()
	show_menu(_breadcrumb[-1])

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_menu_requested(request : Dictionary) -> void:
	if not "action" in request: return
	match request.action:
		&"show_menu":
			if not "payload" in request: return
			show_menu(request.payload)
		&"menu_back":
			menu_back()
		&"play_ui_audio":
			if not "payload" in request: return
			_PlayUIAudio(request.payload)
		_:
			requested.emit(request)


