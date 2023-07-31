extends UIMenu


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	super.show_menu(menu_name)
	if visible:
		send_request(&"background", &"Victory")
	enable_audio_requests(visible)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_requested(audio_name : StringName, forced : bool) -> void:
	request_audio(audio_name, forced)

func _on_btn_main_menu_pressed() -> void:
	send_request(&"show_menu", &"MainMenu")
