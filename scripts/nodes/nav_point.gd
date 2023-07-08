@tool
extends Node2D
class_name NavPoint


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Nav Point")
@export var group_name : String = "nav_point":			set = set_group_name
@export var group_color : Color = Color.YELLOW_GREEN:	set = set_group_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _group_name : StringName = &"np_nav_point"

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_group_name(gn : String) -> void:
	if not gn.is_empty() and gn != group_name:
		remove_from_group(_group_name)
		group_name = gn
		_group_name = StringName("np_%s"%[group_name])
		add_to_group(_group_name)

func set_group_color(c : Color) -> void:
	if c != group_color:
		group_color = c
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_group_name = StringName("np_%s"%[group_name])
	add_to_group(_group_name)

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	#draw_circle(Vector2.ZERO, 5.0, group_color)
	draw_arc(Vector2.ZERO, 5.0, 0.0, 360.0, 16, group_color, 1.0)
	draw_line(Vector2(4.0, 0.0), Vector2(-3.0, 0.0), Color.WHITE_SMOKE, 1.0)
	draw_line(Vector2(0.0, 4.0), Vector2(0.0, -3.0), Color.WHITE_SMOKE, 1.0)



