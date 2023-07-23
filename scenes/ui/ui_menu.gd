extends Control
class_name UIMenu


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(request)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("UI Menu")
@export var initial_focus_control : Control = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _audio_requests_enabled : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.control_mode_changed.connect(_on_control_mode_changed)
	if visible:
		visible = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	visible = (menu_name == name)
	if Game.get_control_mode() == Game.CTRLMode.Joypad:
		initial_focus_control.grab_focus()

func enable_audio_requests(enable : bool) -> void:
	_audio_requests_enabled = enable

func request_audio(audio_name : StringName, forced : bool) -> void:
	if not _audio_requests_enabled and not forced: return
	requested.emit({"action":&"play_ui_audio", "payload":audio_name})

func send_request(action : StringName, payload : StringName = &"") -> void:
	requested.emit({
		"action":action,
		"payload":payload
	})

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_control_mode_changed(mode : int) -> void:
	if not visible or initial_focus_control == null: return
	match mode:
		Game.CTRLMode.Joypad:
			initial_focus_control.grab_focus()
		Game.CTRLMode.Mouse:
			var vp : Viewport = get_viewport()
			if vp == null: return
			var fctrl : Control = vp.gui_get_focus_owner()
			if fctrl == null: return
			if is_ancestor_of(fctrl):
				fctrl.release_focus()
