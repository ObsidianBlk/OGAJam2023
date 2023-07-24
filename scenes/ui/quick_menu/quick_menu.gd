extends UIMenu

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	super.show_menu(menu_name)
	enable_audio_requests(visible)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_requested(audio_name : StringName, forced : bool) -> void:
	request_audio(audio_name, forced)


func _on_resume_pressed() -> void:
	send_request(&"resume_game")


func _on_options_pressed() -> void:
	send_request(&"show_menu", &"OptionsMenu")


func _on_quit_menu_pressed() -> void:
	send_request(&"quit_game")


func _on_quit_desktop_pressed() -> void:
	send_request(&"quit_application")
