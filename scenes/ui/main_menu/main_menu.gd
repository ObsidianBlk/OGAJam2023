extends UIMenu


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_menu(menu_name : String) -> void:
	super.show_menu(menu_name)
	if visible:
		send_request(&"background", &"MainMenu")
	enable_audio_requests(visible)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_requested(audio_name : StringName, forced : bool) -> void:
	request_audio(audio_name, forced)

func _on_game_pressed() -> void:
	send_request(&"start_game")

func _on_options_pressed() -> void:
	send_request(&"show_menu", &"OptionsMenu")

func _on_attributions_pressed():
	send_request(&"show_menu", &"AttributionMenu")

func _on_quit_pressed() -> void:
	send_request(&"quit_application")

func _on_obs_logo_pressed() -> void:
	OS.shell_open("https://obsidianblk.itch.io/")
