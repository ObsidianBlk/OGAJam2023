@tool
extends CharacterBody2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal collided(last_collision, collision_count)

# ------------------------------------------------------------------------------
# Constants and ENUMS
# ------------------------------------------------------------------------------
const FRAMES_XENO : SpriteFrames = preload("res://objects/xeno/xeno_frames.tres")

const DIRECTIONAL_THRESHOLD : float = 0.1

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var max_speed : float = 125.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _action : StringName = &"idle"

var _facing : Vector2 = Vector2.DOWN
var _direction : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body : AnimatedSprite2D = $ASprite2D

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateViz()

func _physics_process(_delta : float) -> void:
	if _direction.length_squared() > DIRECTIONAL_THRESHOLD:
		velocity = _direction * max_speed
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.7)
	
	if move_and_slide():
		collided.emit(get_last_slide_collision(), get_slide_collision_count())
	
	_action = &"move" if velocity.length() > 0.1 else &"idle"
	_UpdateViz()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _VecToFacingName(f : Vector2) -> StringName:
	var angle : float = rad_to_deg(f.angle()) + 180.0
	if angle > 45 and angle <= 135:
		return &"north"
	if angle > 135 and angle <= 225:
		return &"east"
	if angle > 225 and angle <= 315:
		return &"south"
	return &"west"


func _GetSpriteFrames() -> SpriteFrames:
	var frames : SpriteFrames = FRAMES_XENO
	
	# TODO: Code section for swapping atlas texture!!
	
	return frames

func _UpdateViz() -> void:
	var frames : SpriteFrames = _GetSpriteFrames()
	if frames != null:
		_body.sprite_frames = frames
		
	if Engine.is_editor_hint(): return
	var facing : StringName = _VecToFacingName(_facing)
	_body.play("%s_%s"%[_action, facing])

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func face_position(pos : Vector2) -> void:
	if pos.is_equal_approx(position): return
	_facing = position.direction_to(pos)
	_UpdateViz()

func move(dir : Vector2) -> void:
	_direction = dir

func get_direction() -> Vector2:
	return _direction

func damage(amount : float) -> void:
	print("Ouch!")
