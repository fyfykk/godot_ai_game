extends Node2D

@export var key_text: String = "E"
@export var size: Vector2 = Vector2(18, 12)
@export var pad: Vector2 = Vector2(2, 2)
@export var bg_color: Color = Color(0.12, 0.12, 0.16, 0.75)
@export var key_color: Color = Color(1.0, 0.95, 0.7, 1.0)
@export var font_size: int = 14
@export var outline_size: int = 4
@export var outline_color: Color = Color(0, 0, 0, 1.0)
@export var bg_offset: Vector2 = Vector2(0, 4)
@export var label_z: int = 119
@export var bg_z: int = 118

var key_label: Label
var bg: Polygon2D

func _ready():
	bg = Polygon2D.new()
	bg.z_index = bg_z
	add_child(bg)
	key_label = Label.new()
	key_label.z_index = label_z
	add_child(key_label)
	_apply_style()
	visible = false

func _apply_style():
	key_label.text = key_text
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.custom_minimum_size = size
	key_label.modulate = key_color
	key_label.add_theme_font_size_override("font_size", font_size)
	key_label.add_theme_constant_override("outline_size", outline_size)
	key_label.add_theme_color_override("outline_color", outline_color)
	key_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	key_label.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	bg.color = bg_color
	_update_bg()

func _update_bg():
	var hw: float = (size.x + pad.x * 2.0) * 0.5
	var hh: float = (size.y + pad.y * 2.0) * 0.5
	bg.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	bg.position = bg_offset

func set_key_text(t: String):
	key_text = t
	if key_label:
		key_label.text = key_text

func set_world_position(world_pos: Vector2):
	global_position = world_pos

func get_bg_half_height() -> float:
	return (size.y + pad.y * 2.0) * 0.5
