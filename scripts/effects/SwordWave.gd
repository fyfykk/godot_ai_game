extends Node2D

@export var life: float = 0.22
@export var color: Color = Color(0.6, 0.95, 1.0, 0.9)
@export var trail_gap: float = 0.14
@export var trail_count: int = 3

var t: float = 0.0
var start_pos: Vector2
var end_pos: Vector2
var start_size: Vector2
var end_size: Vector2
var texture: Texture2D
var rot_start: float = 0.0
var rot_end: float = 0.0
var flip_h: bool = false
var sprites: Array = []

func setup(p0: Vector2, p1: Vector2, s0: Vector2, s1: Vector2, tex: Texture2D, dir: float):
	start_pos = p0
	end_pos = p1
	start_size = s0
	end_size = s1
	texture = tex
	rot_start = -0.9 * dir
	rot_end = 0.2 * dir
	flip_h = dir < 0.0
	_build_sprites()

func _ready():
	if sprites.size() == 0:
		_build_sprites()

func _build_sprites():
	for c in get_children():
		c.queue_free()
	sprites.clear()
	var cnt: int = max(trail_count, 1)
	for i in range(cnt):
		var sp := Sprite2D.new()
		sp.centered = true
		sp.texture = texture
		sp.z_index = 200 - i
		sp.flip_h = flip_h
		add_child(sp)
		sprites.append(sp)

func _process(delta):
	t += delta
	if t >= life:
		queue_free()
		return
	_apply()

func _apply():
	var tt: float = clamp(t / max(life, 0.01), 0.0, 1.0)
	for i in range(sprites.size()):
		var lag: float = float(i) * trail_gap
		var lt: float = clamp(tt - lag, 0.0, 1.0)
		var sp: Sprite2D = sprites[i]
		if sp == null:
			continue
		if lt <= 0.0:
			sp.visible = false
			continue
		sp.visible = true
		sp.global_position = start_pos.lerp(end_pos, lt)
		sp.rotation = lerp(rot_start, rot_end, lt)
		if sp.texture:
			var tex_size := sp.texture.get_size()
			var tw: float = max(tex_size.x, 1.0)
			var th: float = max(tex_size.y, 1.0)
			var sz := start_size.lerp(end_size, lt)
			sp.scale = Vector2(sz.x / tw, sz.y / th)
		var alpha: float = color.a * (0.35 + 0.65 * lt) * (1.0 - float(i) * 0.2)
		var c1 := Color(1.0, 0.35, 0.35, alpha)
		var c2 := Color(1.0, 0.7, 0.2, alpha)
		var c3 := Color(1.0, 1.0, 0.35, alpha)
		var c4 := Color(0.35, 1.0, 0.45, alpha)
		var c5 := Color(0.35, 0.8, 1.0, alpha)
		var c6 := Color(0.75, 0.45, 1.0, alpha)
		var mix_t: float = clamp(lt, 0.0, 1.0)
		var col := c1
		col = col.lerp(c2, clamp(mix_t * 6.0, 0.0, 1.0))
		col = col.lerp(c3, clamp((mix_t - 0.16) * 6.0, 0.0, 1.0))
		col = col.lerp(c4, clamp((mix_t - 0.32) * 6.0, 0.0, 1.0))
		col = col.lerp(c5, clamp((mix_t - 0.5) * 6.0, 0.0, 1.0))
		col = col.lerp(c6, clamp((mix_t - 0.68) * 6.0, 0.0, 1.0))
		sp.modulate = col
