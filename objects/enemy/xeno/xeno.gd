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
# Variables
# ------------------------------------------------------------------------------
var _spotted : Dictionary = {}


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _nav_agent : NavigationAgent2D = $NavAgent
@onready var _sight_area : Area2D = $SightArea
@onready var _attack_area : Area2D = $AttackArea


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_SetSpriteFrames(FRAMES_XENO)
	_SetBodySprite($ASprite2D)
	super._ready()

func _physics_process(_delta : float) -> void:
	pass

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func face_position(pos : Vector2) -> void:
	super.face_position(pos)
	_sight_area.rotation = _facing.angle()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_attack_area_body_entered(body : Node2D) -> void:
	pass

func _on_attack_area_body_exited(body : Node2D) -> void:
	pass

