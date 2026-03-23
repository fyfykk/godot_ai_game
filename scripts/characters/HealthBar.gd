extends Node2D

@export var width: float = 64.0
@export var height: float = 12.0
@export var offset: Vector2 = Vector2(0.0, 0.0)
@export var back_color: Color = Color(0, 0, 0, 0.6)
@export var fill_color: Color = Color(0.6, 1.0, 0.6, 1.0)
@export var padding: Vector2 = Vector2(8.0, 4.0)
@export var head_gap: float = 18.0

var ratio: float = 1.0
var text_label: Label
var bar_width: float = 0.0
var bar_height: float = 0.0
var auto_offset: Vector2 = Vector2.ZERO
var last_scale: Vector2 = Vector2.ONE

func _ready():
	z_index = 50
	text_label = Label.new()
	add_child(text_label)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	text_label.add_theme_constant_override("outline_size", 6)
	text_label.add_theme_color_override("outline_color", Color(0, 0, 0, 1.0))
	text_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar_width = width
	bar_height = height
	_update_metrics()
	_update_auto_offset()
	_update_label_position()
	_apply_ui_scale()
	queue_redraw()

func _process(_delta):
	_apply_ui_scale()
	if owner:
		var hp = owner.get("hp")
		var max_hp = owner.get("max_hp")
		if hp != null and max_hp != null and float(max_hp) > 0.0:
			ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
			if text_label:
				text_label.text = "%d/%d" % [int(hp), int(max_hp)]
				_update_metrics()
				_update_auto_offset()
				_update_label_position()
	queue_redraw()

func _draw():
	if not _should_draw():
		return
	var center := _get_center()
	var origin := center - Vector2(bar_width * 0.5, bar_height * 0.5)
	var full_rect := Rect2(origin, Vector2(bar_width, bar_height))
	draw_rect(full_rect, back_color, true)
	var fill_rect := Rect2(origin, Vector2(bar_width * ratio, bar_height))
	draw_rect(fill_rect, fill_color, true)

func _update_metrics():
	if text_label:
		var label_size := text_label.get_minimum_size()
		bar_width = max(width, label_size.x + padding.x * 2.0)
		bar_height = max(height, label_size.y + padding.y * 2.0)

func _update_label_position():
	if text_label:
		var label_size := text_label.get_minimum_size()
		text_label.custom_minimum_size = Vector2(bar_width, label_size.y)
		text_label.position = _get_center() - Vector2(bar_width * 0.5, label_size.y * 0.5)

func _get_center() -> Vector2:
	return offset + auto_offset

func _update_auto_offset():
	if owner == null:
		auto_offset = Vector2.ZERO
		return
	if not (owner is CharacterBody2D):
		auto_offset = Vector2.ZERO
		return
	var top_y: float = _get_visual_top_y()
	var scale_factor: float = _get_owner_visual_scale_y()
	var boss_extra: float = 0.0
	if owner.get("is_boss") != null and bool(owner.get("is_boss")):
		boss_extra = 40
	auto_offset = Vector2(0.0, top_y - head_gap * scale_factor - bar_height * 0.5 - boss_extra)

func _get_owner_visual_scale_y() -> float:
	if owner == null:
		return 1.0
	var sprite: Sprite2D = null
	if owner.has_node("PlayerSprite"):
		sprite = owner.get_node("PlayerSprite") as Sprite2D
	elif owner.has_node("EnemySprite"):
		sprite = owner.get_node("EnemySprite") as Sprite2D
	else:
		for c in owner.get_children():
			if c is Sprite2D:
				sprite = c as Sprite2D
				break
	if sprite:
		return max(abs(sprite.scale.y), 1.0)
	var poly: Polygon2D = owner.get_node_or_null("Poly") as Polygon2D
	if poly:
		return max(abs(poly.scale.y), 1.0)
	return 1.0

func _get_visual_top_y() -> float:
	var sprite: Sprite2D = null
	if owner.has_node("PlayerSprite"):
		sprite = owner.get_node("PlayerSprite") as Sprite2D
	elif owner.has_node("EnemySprite"):
		sprite = owner.get_node("EnemySprite") as Sprite2D
	else:
		for c in owner.get_children():
			if c is Sprite2D:
				sprite = c as Sprite2D
				break
	if sprite and sprite.texture:
		var size := sprite.texture.get_size()
		if sprite.region_enabled:
			size = sprite.region_rect.size
		var bounds: Vector2 = _get_texture_opaque_bounds_y(sprite.texture)
		var top_from_center: float = (bounds.x - size.y * 0.5) * sprite.scale.y
		if sprite.centered:
			return sprite.position.y + top_from_center
		return sprite.position.y
	var poly: Polygon2D = owner.get_node_or_null("Poly") as Polygon2D
	if poly:
		var min_y: float = INF
		for p in poly.polygon:
			min_y = min(min_y, p.y)
		if min_y < INF:
			return poly.position.y + min_y * poly.scale.y
	var cs: CollisionShape2D = owner.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape and cs.shape is RectangleShape2D:
		var rect := cs.shape as RectangleShape2D
		return cs.position.y - rect.size.y * 0.5
	return -12.0

func _get_texture_opaque_bounds_y(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2(0.0, 0.0)
	var size := tex.get_size()
	var h: int = int(size.y)
	var w: int = int(size.x)
	if h <= 0 or w <= 0:
		return Vector2(0.0, 0.0)
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return Vector2(0.0, float(h - 1))
	var top: int = -1
	var bottom: int = -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.01:
				if top < 0:
					top = y
				bottom = y
	if top < 0:
		return Vector2(0.0, float(h - 1))
	return Vector2(float(top), float(bottom))

func _apply_ui_scale():
	var cam := get_viewport().get_camera_2d()
	if cam:
		var z := cam.zoom
		if z.x > 0.0 and z.y > 0.0:
			var target := Vector2(1.0 / z.x, 1.0 / z.y)
			if target.x <= 4.0 and target.y <= 4.0:
				scale = target
				last_scale = target
				return
			scale = last_scale
			return
	scale = last_scale

func _should_draw() -> bool:
	if owner == null:
		return false
	if owner is Node:
		var n := owner as Node
		if not n.is_inside_tree():
			return false
		if n.is_queued_for_deletion():
			return false
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return false
	var sx: float = abs(float(scale.x))
	var sy: float = abs(float(scale.y))
	if bar_width * sx > vp.x * 1.5:
		return false
	if bar_height * sy > vp.y * 0.6:
		return false
	return true

func get_top_y() -> float:
	var center_world := to_global(_get_center())
	return center_world.y - bar_height * 0.5 * abs(scale.y)
