@tool
extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DRAW_COLOR : Color = Color.WHEAT

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Platform")
@export var travel_distance : int = 0:									set = set_travel_distance
@export_enum("horizontal", "vertical") var orientation : int = 0:		set = set_orientation
@export var speed_pps : float = 10.0:									set = set_speed_pps
@export var start_at_end : bool = false:								set = set_start_at_end
@export var from_trigger : Trigger = null:								set = set_from_trigger
@export var to_trigger : Trigger = null:								set = set_to_trigger

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _entities : Dictionary = {}
var _moving : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _entity_container: Node2D = %EntityContainer
@onready var _plat_body: Node2D = %Body
@onready var _console: StaticBody2D = %Console

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_travel_distance(d : int) -> void:
	if d >= 0:
		travel_distance = d
		queue_redraw()

func set_orientation(o : int) -> void:
	if o == 0 or o == 1:
		orientation = o
		_UpdateConsolePosition()
		queue_redraw()

func set_speed_pps(pps : float) -> void:
	if pps > 0.0:
		speed_pps = pps

func set_start_at_end(s : bool) -> void:
	start_at_end = s
	_UpdateBodyPosition()

func set_from_trigger(t : Trigger) -> void:
	if t != from_trigger:
		if from_trigger != null:
			if from_trigger.activated.is_connected(_on_from_trigger_activated):
				from_trigger.activated.disconnect(_on_from_trigger_activated)
		from_trigger = t
		if from_trigger != null:
			if Engine.is_editor_hint(): return
			if not from_trigger.activated.is_connected(_on_from_trigger_activated):
				from_trigger.activated.connect(_on_from_trigger_activated)

func set_to_trigger(t : Trigger) -> void:
	if t != to_trigger:
		if to_trigger != null:
			if to_trigger.activated.is_connected(_on_to_trigger_activated):
				to_trigger.activated.disconnect(_on_to_trigger_activated)
		to_trigger = t
		if to_trigger != null:
			if Engine.is_editor_hint(): return
			if not to_trigger.activated.is_connected(_on_to_trigger_activated):
				to_trigger.activated.connect(_on_to_trigger_activated)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateBodyPosition()
	_UpdateConsolePosition()

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	var source : Vector2 = Vector2(8, 8)
	match orientation:
		0: # Horizontal
			var dest : Vector2 = source + Vector2(travel_distance, 0)
			draw_line(source, dest, DRAW_COLOR, 1.0)
			draw_rect(Rect2(Vector2.ZERO, Vector2(travel_distance + 16, 16)), DRAW_COLOR, false, 1.0)
		1: # Vertical
			var dest : Vector2 = source + Vector2(0, travel_distance)
			draw_line(source, dest, DRAW_COLOR, 1.0)
			print("Rect: ", Rect2(Vector2.ZERO, Vector2(16, travel_distance + 16)))
			draw_rect(Rect2(Vector2.ZERO, Vector2(16, travel_distance + 16)), DRAW_COLOR, false, 1.0)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateBodyPosition() -> void:
	if _plat_body == null: return
	var target : Vector2 = Vector2.ZERO
	if start_at_end:
		match orientation:
			0: # Horizontal
				target = Vector2(travel_distance, 0)
			1: # Vertical
				target = Vector2(0, travel_distance)
	_plat_body.position = target

func _UpdateConsolePosition() -> void:
	if _console == null: return
	match orientation:
		0: # Horizontal
			_console.position = Vector2(4, -4)
		1: # Vertical
			_console.position = Vector2(-4, 4)

func _SwapContainers(origin : Node2D, body : Node2D, to_platform : bool) -> void:
	if to_platform:
		if origin != null:
			origin.remove_child(body)
		_entity_container.add_child(body)
		body.position -= _plat_body.global_position
	else:
		_entity_container.remove_child(body)
		if origin != null:
			origin.add_child(body)
		body.position += _plat_body.global_position

func _MoveTo(target : Vector2) -> void:
	if _moving : return
	if speed_pps <= 0: return
	
	_moving = true
	var tween : Tween = create_tween()
	var duration : float = float(travel_distance) / speed_pps
	tween.tween_property(_plat_body, "position", target, duration)
	await tween.finished
	_moving = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_entity_pickup_area_body_entered(body: Node2D) -> void:
	if body.name in _entities: return
	var origin : Node2D = body.get_parent()
	_entities[body.name] = {"body":weakref(body), "origin":weakref(origin)}
	if body.has_method("set_on_platform"):
		body.set_on_platform(true)
	_SwapContainers.call_deferred(origin, body, true)


func _on_entity_pickup_area_body_exited(body: Node2D) -> void:
	if not body.name in _entities: return
	if not _entity_container.is_ancestor_of(body): return
	var origin : Node2D = _entities[body.name].origin.get_ref()
	if origin == null:
		printerr("Body origin node no longer exists!")
		return
	_entities.erase(body.name)
	if body.has_method("set_on_platform"):
		body.set_on_platform(false)
	_SwapContainers.call_deferred(origin, body, false)


func _on_toggle_trigger_activated() -> void:
	if _moving: return
	var target : Vector2 = Vector2.ZERO
	if _plat_body.position.is_equal_approx(target):
		match orientation:
			0: # Horizontal
				target = Vector2.RIGHT * travel_distance
			1: # Vertical
				target = Vector2.DOWN * travel_distance
	_MoveTo(target)

func _on_from_trigger_activated() -> void:
	if _moving: return
	if _plat_body.position.is_equal_approx(Vector2.ZERO): return
	_MoveTo(Vector2.ZERO)

func _on_to_trigger_activated() -> void:
	if _moving : return
	var target : Vector2 = Vector2.ZERO
	match orientation:
		0: # Horizontal
			target = Vector2.RIGHT * travel_distance
		1: # Vertical
			target = Vector2.DOWN * travel_distance
	if _plat_body.position.is_equal_approx(target): return
	_MoveTo(target)

