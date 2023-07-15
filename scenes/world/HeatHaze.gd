extends ColorRect


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func enable(enabled : bool = true) -> void:
	material.set_shader_parameter("enabled", enabled)

func is_enabled() -> bool:
	return material.get_shader_parameter("enabled")

func set_temprature(t : float) -> void:
	var feq : float = 1.0 if t < 100.0 else t - 100.0
	var speed : float = t / 10.0
	material.set_shader_parameter("frequency", feq)
	material.set_shader_parameter("speed", speed)
