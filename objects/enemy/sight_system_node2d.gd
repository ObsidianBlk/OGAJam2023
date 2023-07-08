extends Node2D
class_name SightSystemNode2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal spotted(body)
signal detected(body, distance)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const COLOR_UNSEEN : Color = Color.RED
const COLOR_SEEN : Color = Color.GREEN

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Sight System Node2D")
@export var sight_area : Area2D = null:						set = set_sight_area
@export_flags_2d_physics var collision_mask : int = 1
@export var detect_range_per_second : float = 30.0:			set = set_detect_range_per_second
@export var render_detection_lines : bool = false


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _spotted : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_sight_area(a : Area2D) -> void:
	if a != sight_area:
		_DisconnectSightArea()
		sight_area = a
		_ConnectSightArea()


func set_detect_range_per_second(drps : float) -> void:
	if drps > 0.0 and drps != detect_range_per_second:
		detect_range_per_second = drps
		# TODO: Possibly update _spotted timers?

func set_render_detection_lines(r : bool) -> void:
	if r != render_detection_lines:
		render_detection_lines = r
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ConnectSightArea()

func _draw() -> void:
	if not render_detection_lines:
		return
	
	for sname in _spotted:
		var target : Node2D = _spotted[sname].node.get_ref()
		if target == null: continue
		var dist : float = global_position.distance_to(target.global_position)
		if dist == 0.0: continue
		var p = min(_spotted[sname].detect_dist / dist, 1.0)
		
		var dir : Vector2 = global_position.direction_to(target.global_position)
		var mid_point : Vector2 = dir * (dist * p)
		var end_point : Vector2 = dir * dist
		
		draw_line(Vector2.ZERO, mid_point, COLOR_SEEN, 1, true)
		draw_line(mid_point, end_point, COLOR_UNSEEN, 1, true)
		
		

func _physics_process(delta : float) -> void:
	if sight_area == null: return
	
	var snames : Array = _spotted.keys()
	for sname in snames:
		# Check if the target object still exists
		var target : Node2D = _spotted[sname].node.get_ref()
		if target == null:
			_spotted.erase(sname)
			continue
		
		# Check if there's a line-of-sight on the target
		var result : Dictionary = _CanSee(target, collision_mask)
		if result.is_empty():
			# If no line-of-sight, reset detection system
			_spotted[sname].detect_dist = 0.0
			# If the target left the field of view (sight_area), clear from the dictionary
			if not _spotted[sname].in_sight:
				_spotted.erase(sname)
			continue
		
		# Get the distance to the target
		var dist : float = global_position.distance_to(target.global_position)
		_spotted[sname].last_distance = dist
		# Update the detection distance
		if _spotted[sname].detect_dist <= 0.0:
			spotted.emit(target) # This is the first update to being spotted. Announce it!
		_spotted[sname].detect_dist += delta * detect_range_per_second
		# If the detected distance is gte the actual distance, the target is spotted!!
		if dist <= _spotted[sname].detect_dist:
			detected.emit(target, dist)
			_spotted.erase(sname)
	
	if render_detection_lines:
		queue_redraw()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DisconnectSightArea() -> void:
	if sight_area != null:
		if sight_area.body_entered.is_connected(_on_body_entered):
			sight_area.body_entered.disconnect(_on_body_entered)
		if sight_area.body_exited.is_connected(_on_body_exited):
			sight_area.body_exited.disconnect(_on_body_exited)
		sight_area = null

func _ConnectSightArea() -> void:
	if sight_area != null:
		if not sight_area.body_entered.is_connected(_on_body_entered):
			sight_area.body_entered.connect(_on_body_entered)
		if not sight_area.body_exited.is_connected(_on_body_exited):
			sight_area.body_exited.connect(_on_body_exited)

func _CastTo(pos : Vector2, coll_mask : int = 4294967295) -> Dictionary:
	return  get_world_2d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(global_position, pos, coll_mask)
	)

func _CanSee(obj : Node2D, coll_mask : int = 4294967295) -> Dictionary:
	var result : Dictionary = _CastTo(obj.global_position, coll_mask)
	if not result.is_empty() and result.collider == obj:
		return result
	return {}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	if body.name in _spotted:
		_spotted[body.name].in_sight = true
	else:
		_spotted[body.name] = {
			"node": weakref(body),
			"in_sight": true,
			"detect_dist": 0.0,
			"last_distance": 0.0
		}

func _on_body_exited(body : Node2D) -> void:
	if not body.name in _spotted: return
	_spotted[body.name].in_sight = false

