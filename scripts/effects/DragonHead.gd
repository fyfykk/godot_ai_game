extends Node2D

@export var base_offset: Vector2 = Vector2(0, -36)
@export var bob_height: float = 2.5
@export var bob_speed: float = 4.0

var t: float = 0.0
var sprite: Sprite2D
var mouth: Sprite2D
var roar_time: float = 0.0
var roar_duration: float = 0.25
var head_ready: bool = false

func _ready():
	position = base_offset
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.texture = _build_head_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 120
	add_child(sprite)
	mouth = Sprite2D.new()
	mouth.centered = true
	mouth.texture = _build_mouth_texture()
	mouth.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouth.z_index = 121
	mouth.visible = false
	add_child(mouth)

func _process(delta):
	t += delta
	position = base_offset + Vector2(0.0, sin(t * bob_speed) * bob_height)
	if not head_ready:
		head_ready = true
	_update_roar(delta)

func is_ready() -> bool:
	return head_ready

func get_origin() -> Vector2:
	return global_position

func trigger_roar():
	roar_time = roar_duration
	if mouth:
		mouth.visible = true

func _update_roar(delta: float):
	if roar_time <= 0.0:
		if mouth:
			mouth.visible = false
		scale = Vector2(1, 1)
		rotation = 0.0
		return
	roar_time = max(roar_time - delta, 0.0)
	var p: float = 1.0 - (roar_time / max(roar_duration, 0.001))
	var s: float = 1.0 + 0.12 * sin(p * PI)
	scale = Vector2(s, 1.0 + 0.18 * sin(p * PI))
	rotation = 0.06 * sin(p * PI * 2.0)
	if mouth:
		mouth.visible = true
		mouth.position = Vector2(10.0, 6.0 + 2.0 * sin(p * PI))
		mouth.scale = Vector2(1.0, 1.0 + 0.8 * sin(p * PI))
	if roar_time <= 0.0:
		if mouth:
			mouth.visible = false
		scale = Vector2(1, 1)
		rotation = 0.0

func _build_head_texture() -> Texture2D:
	var img := Image.create(28, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var main := Color(0.98, 0.82, 0.26, 1.0)
	var mid := Color(0.92, 0.7, 0.2, 1.0)
	var dark := Color(0.62, 0.42, 0.12, 1.0)
	var horn := Color(1.0, 0.95, 0.7, 1.0)
	var whisker := Color(1.0, 0.96, 0.82, 0.85)
	var eye := Color(1.0, 0.45, 0.25, 1.0)
	var pupil := Color(0.18, 0.08, 0.02, 1.0)
	var nose := Color(0.3, 0.2, 0.08, 1.0)
	_rect(img, 5, 8, 14, 7, main)
	_rect(img, 7, 6, 12, 3, mid)
	_rect(img, 10, 4, 8, 3, mid)
	_rect(img, 19, 9, 5, 5, dark)
	_rect(img, 20, 8, 4, 2, dark)
	_rect(img, 22, 10, 2, 2, dark)
	_rect(img, 6, 5, 3, 1, dark)
	_rect(img, 16, 5, 2, 1, dark)
	_rect(img, 9, 3, 3, 2, horn)
	_rect(img, 15, 3, 3, 2, horn)
	_rect(img, 8, 2, 2, 1, horn)
	_rect(img, 17, 2, 2, 1, horn)
	_rect(img, 7, 7, 2, 2, eye)
	_rect(img, 8, 8, 1, 1, pupil)
	_rect(img, 18, 7, 1, 1, nose)
	_rect(img, 6, 10, 4, 1, whisker)
	_rect(img, 6, 11, 5, 1, whisker)
	_rect(img, 6, 12, 4, 1, whisker)
	_rect(img, 17, 10, 5, 1, whisker)
	_rect(img, 16, 11, 6, 1, whisker)
	_rect(img, 17, 12, 5, 1, whisker)
	_rect(img, 3, 11, 3, 1, dark)
	_rect(img, 23, 11, 3, 1, dark)
	return ImageTexture.create_from_image(img)

func _build_mouth_texture() -> Texture2D:
	var img := Image.create(6, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var inner := Color(0.5, 0.1, 0.05, 0.9)
	var edge := Color(0.9, 0.75, 0.35, 1.0)
	_rect(img, 0, 1, 6, 2, inner)
	_rect(img, 0, 0, 6, 1, edge)
	_rect(img, 0, 3, 6, 1, edge)
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)
