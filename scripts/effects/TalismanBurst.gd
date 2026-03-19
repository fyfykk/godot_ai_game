extends Node2D

@export var radius: float = 80.0
@export var life: float = 0.6
@export var count: int = 12
@export var ring_thickness: float = 6.0
@export var light_curve: float = 1.4

var t: float = 0.0
var sprites: Array = []
var angles: Array = []
var tex: Texture2D

func _ready():
	tex = _build_talisman_texture(10, 16)
	var n: int = max(count, 1)
	for i in range(n):
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = true
		sp.z_index = 210
		add_child(sp)
		sprites.append(sp)
		angles.append(TAU * float(i) / float(n))

func _process(delta):
	t += delta
	var tt: float = clamp(t / max(life, 0.01), 0.0, 1.0)
	for i in range(sprites.size()):
		var sp: Sprite2D = sprites[i]
		var ang: float = float(angles[i])
		var dist: float = radius * tt
		sp.position = Vector2(cos(ang), sin(ang)) * dist
		sp.rotation = ang + tt * 1.4
		var scale: float = 0.5 + tt * 0.8
		sp.scale = Vector2(scale, scale)
		sp.modulate = Color(1, 1, 1, 1.0)
	queue_redraw()
	if t > life:
		queue_free()

func _draw():
	var tt: float = clamp(t / max(life, 0.01), 0.0, 1.0)
	var lt: float = pow(tt, max(light_curve, 0.2))
	var r: float = radius * lt
	var glow: Color = Color(1.0, 0.88, 0.35, 0.85 * (1.0 - tt))
	var glow2: Color = Color(1.0, 0.7, 0.2, 0.65 * (1.0 - tt))
	var pts := PackedVector2Array()
	var pts2 := PackedVector2Array()
	var segs: int = 64
	for i in range(segs):
		var ang: float = TAU * float(i) / float(segs)
		var wobble: float = 1.0 + 0.12 * sin(ang * 3.0 + t * 6.0) + 0.08 * sin(ang * 7.0 - t * 5.0)
		var wobble2: float = 0.9 + 0.1 * sin(ang * 4.0 - t * 4.0)
		var rr: float = r * wobble
		var rr2: float = r * wobble2
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
		pts2.append(Vector2(cos(ang), sin(ang)) * rr2)
	if pts.size() >= 2:
		draw_polyline(pts, glow, ring_thickness * 1.2, true)
		draw_polyline(pts, Color(glow.r, glow.g, glow.b, glow.a * 0.6), ring_thickness * 2.0, true)
	if pts2.size() >= 2:
		draw_polyline(pts2, glow2, ring_thickness * 0.9, true)

func _build_talisman_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var paper := Color(0.93, 0.86, 0.72, 1.0)
	var edge := Color(0.35, 0.26, 0.18, 1.0)
	var red := Color(0.88, 0.2, 0.2, 1.0)
	var ink := Color(0.2, 0.15, 0.1, 1.0)
	img.fill(paper)
	_outline_rect(img, 0, 0, w, h, edge)
	_rect(img, 1, 1, w - 2, 2, red)
	_rect(img, 1, h - 3, w - 2, 2, red)
	_rect(img, int(w / 2), 3, 1, h - 6, ink)
	_rect(img, int(w / 2) - 2, 5, 4, 1, ink)
	_rect(img, int(w / 2) - 1, 8, 3, 1, ink)
	_rect(img, int(w / 2) - 2, 11, 4, 1, ink)
	_rect(img, int(w / 2) - 1, 13, 3, 1, ink)
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)

func _outline_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for xx in range(w):
		var px := x + xx
		if px >= 0 and px < img.get_width():
			if y >= 0 and y < img.get_height():
				img.set_pixel(px, y, col)
			var by := y + h - 1
			if by >= 0 and by < img.get_height():
				img.set_pixel(px, by, col)
	for yy in range(h):
		var py := y + yy
		if py >= 0 and py < img.get_height():
			if x >= 0 and x < img.get_width():
				img.set_pixel(x, py, col)
			var bx := x + w - 1
			if bx >= 0 and bx < img.get_width():
				img.set_pixel(bx, py, col)
