extends Node2D

@export var life: float = 1.0
@export var scale_factor: float = 1.0

var t: float = 0.0

func _ready():
	scale = Vector2(scale_factor, scale_factor)
	z_index = -100

func _process(delta):
	t += delta
	var p: float = clamp(t / max(life, 0.001), 0.0, 1.0)
	var fade: float = sin(p * PI)
	modulate = Color(1, 1, 1, fade)
	queue_redraw()
	if t >= life:
		queue_free()

func _draw():
	var body_dark := Color(0.72, 0.58, 0.12, 0.6)
	var body := Color(0.95, 0.82, 0.22, 0.6)
	var belly := Color(1.0, 0.9, 0.38, 0.6)
	var edge := Color(0.55, 0.44, 0.12, 0.6)
	var eye := Color(1.0, 0.15, 0.12, 1)
	var pupil := Color(0.35, 0.08, 0.06, 0.6)
	var segs: int = 240
	var turns: float = 2.0
	var rad_start: float = 56.0
	var rad_end: float = 16.0
	var coil: PackedVector2Array = []
	var belly_pts: PackedVector2Array = []
	var end_pos := Vector2.ZERO
	for i in range(segs + 1):
		var t0: float = float(i) / float(segs)
		var ang: float = TAU * (0.2 - turns * t0)
		var rad: float = lerp(rad_start, rad_end, t0)
		var px: float = cos(ang) * rad
		var py: float = sin(ang) * rad
		var pos := Vector2(px, py)
		coil.append(pos)
		end_pos = pos
		var px1: float = cos(ang) * (rad - 5.0)
		var py1: float = sin(ang) * (rad - 5.0)
		belly_pts.append(Vector2(px1, py1))
	draw_polyline(coil, edge, 22.0, false)
	draw_polyline(coil, body_dark, 20.0, false)
	draw_polyline(coil, body, 15.0, false)
	draw_polyline(belly_pts, belly, 8.0, false)
	var neck: PackedVector2Array = [end_pos, Vector2.ZERO]
	draw_polyline(neck, edge, 18.0, false)
	draw_polyline(neck, body_dark, 16.0, false)
	draw_polyline(neck, body, 12.0, false)
	draw_polyline(neck, belly, 6.0, false)
	var tail_tip: PackedVector2Array = [
		coil[0],
		coil[0] + Vector2(8.0, -6.0),
		coil[0] + Vector2(12.0, 2.0)
	]
	draw_polygon(tail_tip, [body_dark])
	draw_polyline(tail_tip, edge, 2.0, true)
	var hx: float = 0.0
	var hy: float = 0.0
	var head: PackedVector2Array = [
		Vector2(hx - 14, hy - 12),
		Vector2(hx + 14, hy - 12),
		Vector2(hx + 18, hy + 6),
		Vector2(hx, hy + 16),
		Vector2(hx - 18, hy + 6),
		Vector2(hx - 14, hy - 12)
	]
	draw_polygon(head, [body])
	draw_polyline(head, edge, 3.0, true)
	var snout: PackedVector2Array = [
		Vector2(hx - 7, hy + 2),
		Vector2(hx + 7, hy + 2),
		Vector2(hx + 5, hy + 9),
		Vector2(hx - 5, hy + 9),
		Vector2(hx - 7, hy + 2)
	]
	draw_polygon(snout, [body_dark])
	draw_polyline(snout, edge, 2.0, true)
	draw_circle(Vector2(hx - 6, hy - 4), 3.0, eye)
	draw_circle(Vector2(hx + 6, hy - 4), 3.0, eye)
	draw_circle(Vector2(hx - 6, hy - 4), 1.2, pupil)
	draw_circle(Vector2(hx + 6, hy - 4), 1.2, pupil)
	var horn_l: PackedVector2Array = [
		Vector2(hx - 12, hy - 16),
		Vector2(hx - 24, hy - 26),
		Vector2(hx - 14, hy - 8)
	]
	var horn_r: PackedVector2Array = [
		Vector2(hx + 12, hy - 16),
		Vector2(hx + 24, hy - 26),
		Vector2(hx + 14, hy - 8)
	]
	draw_polygon(horn_l, [body_dark])
	draw_polygon(horn_r, [body_dark])
	draw_polyline(horn_l, edge, 2.0, true)
	draw_polyline(horn_r, edge, 2.0, true)
