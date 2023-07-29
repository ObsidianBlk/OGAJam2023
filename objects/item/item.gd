@tool
extends Node2D


# ------------------------------------------------------------------------------
# Contants
# ------------------------------------------------------------------------------
enum ITEM_TYPE {KeyRed=0, KeyGreen=1, KeyBlue=2, KeyOrange=3, KeyYellow=4, Ammo=5, Health=6}
const LOOKUP : Array = [
	"key_red",
	"key_green",
	"key_blue",
	"key_orange",
	"key_yellow",
	"ammo"
]
const TWEEN_HEIGHT : float = -4.0
const TWEEN_DURATION : float = 1.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Item")
@export var type : ITEM_TYPE = ITEM_TYPE.KeyRed:	set = set_type
@export var amount : int = 1:						set = set_amount
@export var pickup_sfx : AudioStream = null:		set = set_pickup_sfx

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _body: Sprite2D = $Body
@onready var _asp: AudioStreamPlayer2D = $AudioStreamPlayer2D

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_type(t : ITEM_TYPE) -> void:
	if t != type:
		type = t
		_UpdateViz()

func set_amount(a : int) -> void:
	if a > 0:
		amount = a

func set_pickup_sfx(p : AudioStream) -> void:
	pickup_sfx = p
	if _asp != null:
		_asp.stream = pickup_sfx

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_asp.stream = pickup_sfx
	_UpdateViz()
	_UpdateTween()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateViz() -> void:
	if _body == null: return
	var x : int = 8 * type
	_body.region_rect = Rect2(x, 456, 8, 8)

func _UpdateTween() -> void:
	if _body == null: return
	if _tween != null: return
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_body, "position", Vector2(0.0, TWEEN_HEIGHT), TWEEN_DURATION)
	_tween.tween_property(_body, "position", Vector2.ZERO, TWEEN_DURATION)
	_tween.set_loops()

func _die() -> void:
	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_pickup_area_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	if not _body.visible: return
	if type == ITEM_TYPE.Health:
		if body.has_method("heal"):
			body.heal(amount)
	else:
		Game.update_inventory(LOOKUP[type], amount)
	if pickup_sfx != null:
		_body.visible = false
		_asp.play()
	else:
		_die()

func _on_audio_stream_player_2d_finished() -> void:
	_die()
