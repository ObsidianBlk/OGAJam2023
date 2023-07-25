extends ColorRect


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func enable(enabled : bool = true) -> void:
	material.set_shader_parameter("enabled", enabled)

func is_enabled() -> bool:
	return material.get_shader_parameter("enabled")

func set_temprature(t : float) -> void:
	var weight : float = 0.0 if t < 100.0 else min((t - 100.0) * 0.01, 1.0)
	if weight > 0.0 and not is_enabled():
		enable()
	
	if is_enabled():
		var strength : float = lerpf(0.001, 0.05, weight)
		material.set_shader_parameter("strength", strength)
