extends Node2D

@export var life: float = 0.6
@export var speed: float = 160.0
@export var fps: float = 14.0
@export var frame_count: int = 4
@export var direction: int = 1
@export var use_path: bool = false
@export var end_position: Vector2 = Vector2.ZERO

var t: float = 0.0
var sp: Sprite2D
var tex: Texture2D
var start_pos: Vector2 = Vector2.ZERO

func _ready():
	tex = _build_crow_sheet(14, 10, frame_count)
	sp = Sprite2D.new()
	sp.texture = tex
	sp.hframes = frame_count
	sp.vframes = 1
	sp.frame = 0
	sp.centered = true
	sp.z_index = 60
	sp.scale = Vector2(1.2, 1.2)
	add_child(sp)
	start_pos = position
	if use_path and end_position != Vector2.ZERO:
		if speed > 0.0:
			life = max(start_pos.distance_to(end_position) / speed, 0.2)
	else:
		if direction < 0 and sp:
			sp.flip_h = true

func _process(delta):
	t += delta
	var idx: int = int(floor(t * fps)) % max(frame_count, 1)
	if sp:
		sp.frame = idx
	if use_path and end_position != Vector2.ZERO:
		var ratio: float = clamp(t / max(life, 0.01), 0.0, 1.0)
		position = start_pos.lerp(end_position, ratio) + Vector2(0.0, sin(ratio * PI) * -6.0)
		if sp:
			sp.flip_h = (end_position.x - start_pos.x) < 0.0
	else:
		var drift: float = float(direction) * speed * delta
		position.x += drift
		position.y = start_pos.y + sin(t * 8.0) * 3.0
	if t >= life:
		queue_free()

func _build_crow_sheet(w: int, h: int, frames: int) -> Texture2D:
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_crow_frame(img, i * w, 0, w, h, i)
	return ImageTexture.create_from_image(img)

func _draw_crow_frame(img: Image, ox: int, oy: int, w: int, h: int, idx: int):
	var body := Color(0.08, 0.08, 0.1, 1.0)
	var beak := Color(0.85, 0.75, 0.3, 1.0)
	var eye := Color(0.95, 0.2, 0.2, 1.0)
	var wing_up: bool = idx % 2 == 0
	_rect(img, ox + 5, oy + 4, 4, 3, body)
	_rect(img, ox + 8, oy + 5, 2, 1, beak)
	_rect(img, ox + 6, oy + 5, 1, 1, eye)
	if wing_up:
		_rect(img, ox + 1, oy + 2, 6, 2, body)
		_rect(img, ox + 7, oy + 2, 6, 2, body)
	else:
		_rect(img, ox + 1, oy + 5, 6, 2, body)
		_rect(img, ox + 7, oy + 5, 6, 2, body)
	_rect(img, ox + 4, oy + 7, 2, 2, body)
	_rect(img, ox + 7, oy + 7, 2, 2, body)

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)
