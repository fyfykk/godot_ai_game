extends Node2D

@export var radius: float = 28.0
@export var base_color: Color = Color(0.92, 0.92, 0.96, 1.0)
@export var eclipse_color: Color = Color(0.88, 0.16, 0.16, 1.0)
@export var rim_color: Color = Color(0, 0, 0, 0.6)
@export var show_label: bool = true

var ratio: float = 0.0
var seconds_text: String = ""
var label: Label = null
var moon_tex: Texture2D = null
var tex_dirty: bool = true

func _ready():
	label = Label.new()
	add_child(label)
	label.size = Vector2(64, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-label.size.x * 0.5, radius + 10.0)
	label.z_index = 101
	label.visible = show_label

func set_ratio(r: float):
	ratio = clamp(r, 0.0, 1.0)
	tex_dirty = true
	queue_redraw()

func set_seconds(sec: float):
	seconds_text = "%d" % max(0, int(sec))
	if label and show_label:
		label.text = seconds_text

func _draw():
	if moon_tex == null or tex_dirty:
		moon_tex = _build_moon_texture()
		tex_dirty = false
	if moon_tex:
		var size: Vector2i = moon_tex.get_size()
		draw_texture(moon_tex, Vector2(-float(size.x) * 0.5, -float(size.y) * 0.5))

func _build_moon_texture() -> Texture2D:
	var r: float = max(1.0, radius)
	var size: int = int(ceil(r * 2.0)) + 2
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = size * 0.5 - 0.5
	var cy: float = size * 0.5 - 0.5
	var shadow_cx: float = -2.0 * r * ratio
	var edge_soft: float = 2.0
	for y in range(size):
		for x in range(size):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist > r:
				continue
			var n: float = 0.5 + 0.25 * sin(dx * 0.35) + 0.2 * cos(dy * 0.27) + 0.1 * sin((dx + dy) * 0.2)
			n = clamp(n, 0.0, 1.0)
			var bcol: Color = base_color.lerp(base_color.darkened(0.25), 1.0 - n)
			var ecol: Color = eclipse_color.lerp(eclipse_color.darkened(0.2), 1.0 - n)
			var sdx: float = dx - shadow_cx
			var sdist: float = sqrt(sdx * sdx + dy * dy)
			var t: float = clamp((sdist - (r - edge_soft)) / (edge_soft * 2.0), 0.0, 1.0)
			var col: Color = bcol.lerp(ecol, t)
			var rim_t: float = clamp((dist - (r - 1.5)) / 1.5, 0.0, 1.0)
			col = col.lerp(rim_color, rim_t * 0.4)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
