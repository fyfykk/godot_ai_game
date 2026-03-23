extends Node2D

@export var size: Vector2 = Vector2(18, 10)
@export var life: float = 0.12
@export var color: Color = Color(1, 0.2, 0.2, 0.7)
@export var texture: Texture2D = preload("res://assets/vfx/fx_melee_slash.png")

var facing: int = 1
var sprite: Sprite2D = null
var total_life: float = 0.12

func setup(center: Vector2, facing_dir: int, sz: Vector2):
	global_position = center
	facing = int(sign(float(facing_dir))) if facing_dir != 0 else 1
	size = sz
	total_life = max(life, 0.01)
	_apply_visual(1.0)
	queue_redraw()

func _ready():
	z_index = 200
	if texture:
		sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.z_index = z_index
		add_child(sprite)
	_apply_visual(1.0)

func _process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()
	else:
		var t: float = clamp(life / total_life, 0.0, 1.0)
		_apply_visual(t)
		queue_redraw()

func _draw():
	if sprite != null:
		return
	var hw: float = size.x
	var hh: float = size.y
	var start_x: float = 0.0 if facing > 0 else -hw
	var rect := Rect2(Vector2(start_x, -hh), Vector2(hw, hh * 2.0))
	draw_rect(rect, color, true)

func _apply_visual(t: float):
	var hw: float = size.x
	var hh: float = size.y
	if sprite:
		var tex_size := sprite.texture.get_size()
		var tw: float = max(tex_size.x, 1.0)
		var th: float = max(tex_size.y, 1.0)
		var sx: float = hw / tw
		var sy: float = (hh * 2.0) / th
		var pulse: float = 1.0 + (1.0 - t) * 0.25
		sprite.scale = Vector2(sx * pulse, sy * pulse)
		sprite.position = Vector2((hw * 0.5) if facing > 0 else (-hw * 0.5), 0.0)
		sprite.flip_h = facing < 0
		sprite.modulate = Color(color.r, color.g, color.b, color.a * t)
