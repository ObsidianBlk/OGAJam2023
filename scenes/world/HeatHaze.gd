extends ColorRect


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Game.gameplay_option_changed.connect(_on_gameplay_options_changed)
	enable(not Game.gameplay_get_disable_heat_haze())

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func enable(enabled : bool = true) -> void:
	material.set_shader_parameter("haze_enabled", enabled)

func is_enabled() -> bool:
	return material.get_shader_parameter("haze_enabled")

func set_temprature(t : float) -> void:
	var progress : float = min((t - 80) * 0.01, 1.0)
	material.set_shader_parameter("mask_progress", progress)

	if is_enabled():
		var weight : float = 0.0 if t < 100.0 else min((t - 100.0) * 0.01, 1.0)
		var strength : float = lerpf(0.001, 0.02, weight)
		material.set_shader_parameter("strength", strength)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_gameplay_options_changed(option_name : String, value : Variant) -> void:
	match option_name:
		"disable_heat_haze":
			if typeof(value) == TYPE_BOOL:
				enable(not value)
