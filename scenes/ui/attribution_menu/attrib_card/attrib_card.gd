extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
# NOTE: Images used here came from...
# https://creativecommons.org/about/downloads/
const CC_BADGE : Dictionary = {
	"cc0": preload("res://assets/graphics/ccbadges/cc-zero.png"),
	"by": preload("res://assets/graphics/ccbadges/by.png"),
	"by-sa": preload("res://assets/graphics/ccbadges/by-sa.png"),
	"by-nd": preload("res://assets/graphics/ccbadges/by-nd.png"),
	"by-nc": preload("res://assets/graphics/ccbadges/by-nc.png"),
	"by-nc-sa": preload("res://assets/graphics/ccbadges/by-nc-sa.png"),
	"by-nc-nd": preload("res://assets/graphics/ccbadges/by-nc-nd.png"),
	"by-nc.eu": preload("res://assets/graphics/ccbadges/by-nc.eu.png"),
	"by-nc-sa.eu": preload("res://assets/graphics/ccbadges/by-nc-sa.eu.png"),
	"by-nc-nd.eu": preload("res://assets/graphics/ccbadges/by-nc-nd.eu.png")
}
const OGA_CONTENT_BASE : String = "https://opengameart.org/content"

const TEX_GRAPHIC_ICON : Texture = preload("res://assets/graphics/KennyIcons/tablet.png")
const TEX_SFX_ICON : Texture = preload("res://assets/graphics/KennyIcons/audioOn.png")
const TEX_MUSIC_ICON : Texture = preload("res://assets/graphics/KennyIcons/musicOn.png")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var media_type : int = 0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}
var _node_ready : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lbl_name_value : Label = %LblNameValue
@onready var _lbl_author_value : Label = %LblAuthorValue
@onready var _link_resource : LinkButton = %LinkResource
@onready var _texture_license_type : TextureRect = %TextureLicenseType
@onready var _link_license : LinkButton = %LinkLicense
@onready var _modification_notice : Control = %ModificationNotice
@onready var _lbl_mod_description : Label = %LblModDescription
@onready var _tex_asset_type : TextureRect = %TexAssetType

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_media_type(mt : int) -> void:
	if mt >= 0 and mt <= 2:
		media_type = mt
		_UpdateMediaType()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_node_ready = true
	_UpdateMediaType()
	_DisplayData()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateMediaType() -> void:
	if _tex_asset_type == null: return
	match media_type:
		0: # Graphic
			_tex_asset_type.texture = TEX_GRAPHIC_ICON
		1: # SFX
			_tex_asset_type.texture = TEX_SFX_ICON
		2: # Music
			_tex_asset_type.texture = TEX_MUSIC_ICON

func _DisplayData() -> void:
	if _data.is_empty() or not _node_ready: return

	if "name" in _data:
		_lbl_name_value.text = _data.name
	if "author" in _data:
		_lbl_author_value.text = _data.author
	if "resource_url" in _data:
		if _data.resource_url.begins_with(OGA_CONTENT_BASE):
			_link_resource.text = "https://...%s"%[_data.resource_url.substr(OGA_CONTENT_BASE.length())]
			_link_resource.tooltip_text = _data.resource_url
		else:
			_link_resource.text = _data.resource_url
		_link_resource.uri = _data.resource_url
	if "license_url" in _data:
		_link_license.uri = _data.license_url
	if "license" in _data:
		_link_license.text = _data.license.to_upper()
		var lsplit : Array = _data.license.split(" ")
		if lsplit.size() <= 0: return
		var attribs : String = lsplit[0]
		if attribs.begins_with("cc-"):
			attribs = attribs.substr(3)
		if attribs in CC_BADGE:
			_texture_license_type.texture = CC_BADGE[attribs]
		else:
			_texture_license_type.texture = null
	if "mod_description" in _data:
		_modification_notice.visible = true
		_lbl_mod_description.text = _data.mod_description
	else:
		_modification_notice.visible = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_data(data : Dictionary) -> void:
	_data = data
	_DisplayData()

