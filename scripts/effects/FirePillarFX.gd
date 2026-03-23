extends Node2D

@export var life: float = 0.55
@export var fps: float = 14.0
@export var frame_count: int = 6

var t: float = 0.0
var sp: Sprite2D
var tex: Texture2D
static var texture_cache: Dictionary = {}

func _ready():
	tex = _build_fire_sheet(8, 22, frame_count)
	sp = Sprite2D.new()
	sp.texture = tex
	sp.hframes = frame_count
	sp.vframes = 1
	sp.frame = 0
	sp.centered = true
	sp.z_index = 60
	sp.scale = Vector2(0.75, 0.85)
	sp.modulate = Color(1, 1, 1, 0.3)
	add_child(sp)

func _process(delta):
	t += delta
	var idx: int = min(int(floor(t * fps)), frame_count - 1)
	if sp:
		sp.frame = idx
	if t >= life:
		queue_free()

func _build_fire_sheet(w: int, h: int, frames: int) -> Texture2D:
	var key := "fire:%d:%d:%d" % [w, h, frames]
	if texture_cache.has(key):
		return texture_cache[key]
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_fire_frame(img, i * w, 0, w, h, i, frames)
	var tex2 := ImageTexture.create_from_image(img)
	texture_cache[key] = tex2
	return tex2

func _draw_fire_frame(img: Image, ox: int, oy: int, w: int, h: int, idx: int, frames: int):
	var core := Color(1.0, 0.9, 0.4, 1.0)
	var mid := Color(0.98, 0.5, 0.15, 1.0)
	var edge := Color(0.9, 0.2, 0.1, 0.9)
	var smoke := Color(0.4, 0.1, 0.08, 0.6)
	var t: float = float(idx) / max(float(frames - 1), 1.0)
	var top: int = int(4 + t * 2)
	var base_w: int = 10
	var wobble: int = -1 if idx % 2 == 0 else 1
	for y in range(h - top):
		var ry: float = float(y) / float(max(h - 1, 1))
		var width: int = int(base_w * (1.0 - ry * 0.7))
		var cx: int = ox + w / 2 + wobble
		for x in range(-width, width + 1):
			var px := cx + x
			var py := oy + (h - 1 - y)
			var dist: float = abs(float(x)) / float(max(width, 1))
			var col: Color = edge
			if dist < 0.35:
				col = core
			elif dist < 0.7:
				col = mid
			_draw_pixel(img, px, py, col)
	if idx >= frames - 2:
		for y in range(4):
			for x in range(6):
				_draw_pixel(img, ox + 5 + x, oy + y, smoke)

func _draw_pixel(img: Image, x: int, y: int, col: Color):
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)
