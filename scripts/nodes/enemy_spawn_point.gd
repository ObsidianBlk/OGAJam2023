@tool
extends Node2D
class_name EnemySpawnPoint


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LINE_WIDTH : float = 1.0
const RADIUS : float = 4.0
const POINT_COUNT : int = 12
const DISTANCE : float = 8.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Enemy Spawn Point")
@export var color : Color = Color.WHITE:			set = set_color
@export var spawn_north : bool = true:				set = set_spawn_north
@export var spawn_east : bool = true:				set = set_spawn_east
@export var spawn_south : bool = true:				set = set_spawn_south
@export var spawn_west : bool = true:				set = set_spawn_west

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	color = c
	queue_redraw()

func set_spawn_north(n : bool) -> void:
	spawn_north = n
	queue_redraw()

func set_spawn_east(e : bool) -> void:
	spawn_east = e
	queue_redraw()

func set_spawn_south(s : bool) -> void:
	spawn_south = s
	queue_redraw()

func set_spawn_west(w : bool) -> void:
	spawn_west = w
	queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _draw() -> void:
	if not Engine.is_editor_hint(): return
	
	if spawn_north:
		draw_arc(
			Vector2.UP * DISTANCE,
			RADIUS,
			0.0, TAU,
			POINT_COUNT,
			color,
			LINE_WIDTH,
			true
		)
	if spawn_east:
		draw_arc(
			Vector2.RIGHT * DISTANCE,
			RADIUS,
			0.0, TAU,
			POINT_COUNT,
			color,
			LINE_WIDTH,
			true
		)
	if spawn_south:
		draw_arc(
			Vector2.DOWN * DISTANCE,
			RADIUS,
			0.0, TAU,
			POINT_COUNT,
			color,
			LINE_WIDTH,
			true
		)
	if spawn_west:
		draw_arc(
			Vector2.LEFT * DISTANCE,
			RADIUS,
			0.0, TAU,
			POINT_COUNT,
			color,
			LINE_WIDTH,
			true
		)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_random_spawn_position() -> Vector2:
	var available : Array = []
	if spawn_north:
		available.append(global_position + Vector2.UP * DISTANCE)
	if spawn_east:
		available.append(global_position + Vector2.RIGHT * DISTANCE)
	if spawn_south:
		available.append(global_position + Vector2.DOWN * DISTANCE)
	if spawn_west:
		available.append(global_position + Vector2.LEFT * DISTANCE)
	if available.size() > 0:
		var idx : int = randi_range(0, available.size() - 1)
		return available[idx]
	return global_position
