extends Node2D

@export var max_radius: float = 420.0
@export var life: float = 1.0
@export var thickness: float = 4.0
@export var color: Color = Color(0.25, 0.65, 1.0, 0.85)
@export var inner_color: Color = Color(0.55, 0.85, 1.0, 0.6)
@export var rune_count: int = 24

var t: float = 0.0
var spin: float = 0.0
var roar_fx: Node2D = null
var roar_triggered: bool = false

func _ready():
	var RoarFx: Script = preload("res://scripts/effects/RoarDragonFX.gd")
	roar_fx = RoarFx.new()
	if roar_fx:
		if roar_fx.get("life") != null:
			roar_fx.life = life
		roar_fx.z_index = 141
		roar_fx.visible = true
		add_child(roar_fx)
		var target_scale: float = max_radius * 0.8 / 64.0
		roar_fx.scale = Vector2(target_scale, target_scale)

func _process(delta):
	t += delta
	spin += delta * 0.8
	var fade: float = clamp(1.0 - t / max(life, 0.001), 0.0, 1.0)
	if roar_fx:
		roar_fx.modulate = Color(1, 1, 1, fade)
	if t >= life:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var p: float = clamp(t / max(life, 0.001), 0.0, 1.0)
	var r: float = max_radius
	var fade: float = 1.0 - p
	var c1: Color = Color(color.r, color.g, color.b, color.a * fade)
	var c2: Color = Color(inner_color.r, inner_color.g, inner_color.b, inner_color.a * fade)
	var outer: float = r
	var mid: float = r * 0.82
	var inner: float = r * 0.6
	_draw_circle(outer, c1, thickness * 1.2)
	_draw_circle(outer * 0.96, Color(c1.r, c1.g, c1.b, c1.a * 0.5), thickness * 2.0)
	_draw_circle(mid, c2, thickness)
	_draw_circle(inner, c2, thickness * 0.9)
	_draw_teeth(outer * 0.98, outer * 1.05, c2, 32)
	_draw_runes(mid * 0.98, c2, rune_count, spin)
	_draw_runes(inner * 0.9, c1, int(rune_count * 0.5), -spin * 0.6)
	_draw_ram_skull(inner * 0.9, c2, c1)

func _draw_circle(radius: float, col: Color, thick: float):
	var segs: int = 128
	var pts: PackedVector2Array = []
	for i in range(segs + 1):
		var ang: float = TAU * float(i) / float(segs)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	draw_polyline(pts, col, thick, true)

func _draw_teeth(r0: float, r1: float, col: Color, count: int):
	var cnt: int = max(count, 1)
	for i in range(cnt):
		var ang: float = TAU * float(i) / float(cnt)
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(dir * r0, dir * r1, col, thickness * 0.7, true)

func _draw_runes(radius: float, col: Color, count: int, phase: float):
	var cnt: int = max(count, 1)
	for i in range(cnt):
		var ang: float = TAU * float(i) / float(cnt) + phase
		var pos := Vector2(cos(ang), sin(ang)) * radius
		var dir := Vector2(cos(ang), sin(ang))
		var ort := Vector2(-dir.y, dir.x)
		var size: float = 10.0
		var p0 := pos - dir * size * 0.3
		var p1 := pos + dir * size * 0.3
		var p2 := pos + ort * size * 0.25
		draw_line(p0, p1, col, thickness * 0.6, true)
		draw_line(pos, p2, col, thickness * 0.6, true)
		draw_line(p1, p2, col, thickness * 0.45, true)

func _draw_ram_skull(radius: float, col: Color, accent: Color):
	var head: PackedVector2Array = []
	head.append(Vector2(-radius * 0.18, -radius * 0.2))
	head.append(Vector2(radius * 0.18, -radius * 0.2))
	head.append(Vector2(radius * 0.26, radius * 0.1))
	head.append(Vector2(0, radius * 0.26))
	head.append(Vector2(-radius * 0.26, radius * 0.1))
	head.append(Vector2(-radius * 0.18, -radius * 0.2))
	draw_polygon(head, [col])
	draw_polyline(head, accent, thickness * 0.8, true)
	var horn_l: PackedVector2Array = []
	var horn_r: PackedVector2Array = []
	for i in range(12):
		var t0: float = float(i) / 11.0
		var ang_l: float = PI * 0.85 - t0 * PI * 0.9
		var ang_r: float = PI * 0.15 + t0 * PI * 0.9
		var rr: float = radius * (0.7 + 0.18 * sin(t0 * PI))
		horn_l.append(Vector2(cos(ang_l), sin(ang_l)) * rr)
		horn_r.append(Vector2(cos(ang_r), sin(ang_r)) * rr)
	draw_polyline(horn_l, col, thickness * 1.2, false)
	draw_polyline(horn_r, col, thickness * 1.2, false)
	draw_polyline(horn_l, accent, thickness * 0.7, false)
	draw_polyline(horn_r, accent, thickness * 0.7, false)
