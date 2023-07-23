extends UIMenu

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ATTRIB_CARD : PackedScene = preload("res://scenes/ui/attribution_menu/attrib_card/attrib_card.tscn")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Attribution Menu")
@export_file() var attrib_json_path : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _attrib_data : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _attrib_cards : Control = %AttribCards

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if visible:
		visible = false
	if not _attrib_data.is_empty():
		_UpdateCards()
	else:
		reload_attrib_data()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearCards() -> void:
	if _attrib_cards == null: return
	for child in _attrib_cards.get_children():
		_attrib_cards.remove_child(child)
		child.queue_free()

func _UpdateCardSection(section : String) -> void:
	if _attrib_cards == null: return
	if not section in _attrib_data: return
	if typeof(_attrib_data[section]) != TYPE_ARRAY: return
	
	for item in _attrib_data[section]:
		if typeof(item) != TYPE_DICTIONARY: continue
		var card : Control = ATTRIB_CARD.instantiate()
		if card != null and card.has_method("set_data"):
			_attrib_cards.add_child(card)
			card.set_data(item)

func _UpdateCards() -> void:
	if _attrib_cards == null: return
	_ClearCards()
	_UpdateCardSection("graphics")
	_UpdateCardSection("sfx")
	_UpdateCardSection("music")
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reload_attrib_data() -> void:
	var file = FileAccess.open(attrib_json_path, FileAccess.READ)
	if file == null:
		printerr("Failed to load ", attrib_json_path, " - File not found.")
		return
	var content = file.get_as_text()
	file.close()
	
	var json : JSON = JSON.new()
	var err : int = json.parse(content)
	if err == OK and typeof(json.data) == TYPE_DICTIONARY:
		_attrib_data = json.data
		_UpdateCards()
	else:
		printerr("Failed to load ", attrib_json_path, " - File missing or invalid.")

func show_menu(menu_name : String) -> void:
	super.show_menu(menu_name)
	enable_audio_requests(visible)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_requested(audio_name : StringName, forced : bool) -> void:
	request_audio(audio_name, forced)

func _on_btn_back_pressed():
	send_request(&"show_menu", &"MainMenu")
