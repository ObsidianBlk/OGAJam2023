@tool
extends PointLight2D
class_name ModulatingPointLight

# ------------------------------------------------------------------------------
# Signal
# ------------------------------------------------------------------------------
signal loop_complete()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Modulating Point Light")
@export var curve : Curve = null
@export_range(0.0, 16.0) var base_energy : float = 1.0:			set = set_base_energy
@export var gradient : Gradient = null
@export_range(0.0, 1.0) var modulation_offset : float = 0.0:	set = set_modulation_offset
@export var loop : bool = true:									set = set_loop
@export var loop_time : float = 1.0:							set = set_loop_time
@export var enable_in_editor : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _loop_offset : float = 0.0


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_base_energy(e : float) -> void:
	if e >= 0.0 and e < 16.0:
		base_energy = e
		if not (loop and loop_time > 0.0) or (not enable_in_editor and Engine.is_editor_hint()):
			energy = base_energy

func set_modulation_offset(weight : float) -> void:
	weight = max(0.0, min(1.0, weight))
	if weight != modulation_offset:
		modulation_offset = weight
		if curve != null:
			var sample : float = curve.sample(weight)
			energy = sample * base_energy
		else:
			energy = base_energy
		
		if gradient != null:
			color = gradient.sample(weight)

func set_loop_time(lt : float) -> void:
	if lt >= 0.0:
		loop_time = lt
		_loop_offset = 0.0


func set_loop(l : bool) -> void:
	if l != loop:
		loop = l
		if loop:
			_loop_offset = 0.0
			set_process(true)



# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if loop_time <= 0.0: return
	if not enable_in_editor and Engine.is_editor_hint(): return
	
	_loop_offset += delta
	modulation_offset = min(1.0, _loop_offset / loop_time)
	
	if _loop_offset >= loop_time:
		_loop_offset -= loop_time
		if not loop:
			set_process(false)
		loop_complete.emit()


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


