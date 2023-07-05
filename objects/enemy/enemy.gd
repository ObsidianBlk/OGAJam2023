@tool
extends CharacterBody2D


# ------------------------------------------------------------------------------
# Constants and ENUMS
# ------------------------------------------------------------------------------
const FRAMES_XENO : SpriteFrames = preload("res://objects/enemy/xeno_frames.tres")
const FRAMES_CRAWLER : SpriteFrames = preload("res://objects/enemy/crawler_frames.tres")
const FRAMES_BABY : SpriteFrames = preload("res://objects/enemy/baby_frames.tres")

enum ENEMY_TYPE {Crawler=0, Baby=1, Xeno=2, Super=3}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var enemy_type : ENEMY_TYPE = ENEMY_TYPE.Xeno:			set = set_enemy_type


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _action : StringName = &"idle"
var _facing_name : StringName = &"south"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body : AnimatedSprite2D = $ASprite2D


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_enemy_type(et : ENEMY_TYPE) -> void:
	if et != enemy_type:
		enemy_type = et
		_UpdateViz()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
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
	var frames : SpriteFrames = null
	match enemy_type:
		ENEMY_TYPE.Crawler:
			frames = FRAMES_CRAWLER
		ENEMY_TYPE.Baby:
			frames = FRAMES_BABY
		ENEMY_TYPE.Xeno:
			frames = FRAMES_XENO
		ENEMY_TYPE.Super:
			# TODO: Actually use the correct frames once created.
			frames = FRAMES_XENO
	
	# TODO: Code section for swapping atlas texture!!
	
	return frames

func _UpdateViz() -> void:
	var frames : SpriteFrames = _GetSpriteFrames()
	if frames != null:
		_body.sprite_frames = frames
		
	if Engine.is_editor_hint(): return
	_body.play("%s_%s"%[_action, _facing_name])
