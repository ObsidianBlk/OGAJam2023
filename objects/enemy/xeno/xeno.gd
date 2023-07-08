@tool
extends "res://objects/enemy/enemy.gd"


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Constants and ENUMS
# ------------------------------------------------------------------------------
const FRAMES_XENO : SpriteFrames = preload("res://objects/enemy/xeno/xeno_frames.tres")


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Xeno")
@export var nav_point_group : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _nav_group : StringName = &""
var _target_nav_point : NavPoint = null
var _last_target_pos : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _nav_agent : NavigationAgent2D = $NavAgent
@onready var _sight_area : Area2D = $SightArea
@onready var _attack_area : Area2D = $AttackArea


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_nav_point_group(npg : String) -> void:
	if npg != nav_point_group:
		nav_point_group = npg
		_target_nav_point = Game.get_random_nav_point_in_group(nav_point_group)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_SetSpriteFrames(FRAMES_XENO)
	_SetBodySprite($ASprite2D)
	super._ready()

func _draw() -> void:
	if _target_nav_point == null: return
	var target_pos : Vector2 = _target_nav_point.global_position - global_position
	draw_line(Vector2.ZERO, target_pos, Color.VIOLET, 1, true)

func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint(): return
	_TrackNavPoints(delta)
	
	if _direction.length() > DIRECTIONAL_THRESHOLD:
		var weight : float = _CalculateFacingWeight(delta)
		_facing = Vector2.RIGHT.rotated(lerp(_facing.angle(), _direction.angle(), weight))
		velocity = _direction * max_speed * weight
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.7)
	
	if move_and_slide():
		collided.emit(get_last_slide_collision(), get_slide_collision_count())

	_sight_area.rotation = _facing.angle()
	_action = &"move" if velocity.length() > 0.1 else &"idle"
	_UpdateViz()
	queue_redraw()

# ------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------a---------------

func _CalculateFacingWeight(delta : float) -> float:
	var rps : float = deg_to_rad(180.0) * delta
	var fangle : float = _facing.angle()
	var dangle : float = _direction.angle()
	var d : float = abs(fangle - dangle)
	if abs(dangle - fangle) < d:
		d = abs(dangle - fangle)
	
	if d < deg_to_rad(0.5):
		return 1.0
	return min(1.0, rps / d)

func _TrackNavPoints(delta : float) -> void:
	if _target_nav_point == null:
		_last_target_pos = global_position
		_target_nav_point = Game.get_random_nav_point_in_group(nav_point_group)
	
	if not _nav_agent.target_position.is_equal_approx(_target_nav_point.global_position):
		_nav_agent.target_position = _target_nav_point.global_position
		_direction = Vector2.ZERO
	elif not _nav_agent.is_target_reachable():
		_target_nav_point = null
	else:
		if _nav_agent.is_target_reached():
			_target_nav_point = null
		
		var dist : float = _last_target_pos.distance_to(global_position)
		if dist <= 8.0:
			var target_pos : Vector2 = _nav_agent.get_next_path_position()
			if not target_pos.is_equal_approx(_last_target_pos):
				_direction = global_position.direction_to(target_pos)
				_last_target_pos = target_pos
			elif not _target_nav_point == null:
				_nav_agent.target_position = _target_nav_point.global_position

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
#func face_position(pos : Vector2) -> void:
#	super.face_position(pos)
#	_sight_area.rotation = _facing.angle()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_attack_area_body_entered(body : Node2D) -> void:
	pass

func _on_attack_area_body_exited(body : Node2D) -> void:
	pass

