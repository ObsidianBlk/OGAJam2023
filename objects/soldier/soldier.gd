@tool
extends CharacterBody2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal collided(last_collision, collision_count)
signal interacted()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const FRAMES_GREEN_SOLDIER : SpriteFrames = preload("res://objects/soldier/green_soldier.tres")
const FRAMES_RED_SOLDIER : SpriteFrames = preload("res://objects/soldier/red_soldier.tres")

const DIRECTIONAL_THRESHOLD : float = 0.1

enum SOLDIER {Green=0, Red=1}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var soldier : SOLDIER = SOLDIER.Red:				set = set_soldier
@export var max_speed : float = 100.0:						set = set_max_speed

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _action : StringName = &"idle"
var _firing : bool = false

var _facing : Vector2 = Vector2.DOWN
var _direction : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body : AnimatedSprite2D = $Body
@onready var _muzzle : AnimatedSprite2D = $Muzzle

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_soldier(s : SOLDIER) -> void:
	if s != soldier:
		soldier = s
		_UpdateViz()

func set_max_speed(m : float) -> void:
	if m > 0.0 and m != max_speed:
		max_speed = m

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

func _UpdateViz() -> void:
	match soldier:
		SOLDIER.Green:
			if _body.sprite_frames != FRAMES_GREEN_SOLDIER:
				_body.sprite_frames = FRAMES_GREEN_SOLDIER
		SOLDIER.Red:
			if _body.sprite_frames != FRAMES_RED_SOLDIER:
				_body.sprite_frames = FRAMES_RED_SOLDIER
	
	if Engine.is_editor_hint(): return
	var facing : StringName = _VecToFacingName(_facing)
	_body.play("%s_%s"%[_action, facing])
	_muzzle.visible = _firing
	_muzzle.play(facing)

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

func attack(active : bool = true) -> void:
	_firing = active
	_UpdateViz()

func interact() -> void:
	interacted.emit()

