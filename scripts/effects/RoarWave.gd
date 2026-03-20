extends Node2D

@export var max_radius: float = 360.0
@export var thickness: float = 6.0
@export var color: Color = Color(0.55, 0.9, 1.0, 0.7)
@export var life: float = 1.0
@export var rings: int = 2
@export var noise_strength: float = 0.08
@export var white_mix: float = 0.35

var t: float = 0.0
var phase1: float = 0.0
var phase2: float = 0.0
var freq1: float = 4.0
var freq2: float = 7.0

func _process(delta):
	t += delta
	if t >= life:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var p: float = clamp(t / max(life, 0.001), 0.0, 1.0)
	for i in range(rings):
		var ring_t: float = p - float(i) * 0.26
		if ring_t <= 0.0:
			continue
		var rt: float = clamp(ring_t, 0.0, 1.0)
		var alpha: float = color.a * (1.0 - rt)
		var mix_w: float = float(clamp(white_mix + 0.2 * (1.0 - rt), 0.0, 1.0))
		var base_col: Color = color.lerp(Color(1, 1, 1, 1), mix_w)
		var col: Color = Color(base_col.r, base_col.g, base_col.b, alpha)
		var points: PackedVector2Array = []
		var segments: int = 72
		for s in range(segments + 1):
			var ang: float = TAU * float(s) / float(segments)
			var wobble: float = sin(ang * freq1 + phase1) * 0.6 + sin(ang * freq2 + phase2) * 0.4
			var amp: float = noise_strength * (0.6 + 0.4 * (1.0 - rt))
			var r: float = max_radius * rt * (1.0 + wobble * amp)
			points.append(Vector2(cos(ang), sin(ang)) * r)
		draw_polyline(points, col, thickness, true)

func _ready():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	phase1 = rng.randf_range(0.0, TAU)
	phase2 = rng.randf_range(0.0, TAU)
	freq1 = rng.randf_range(3.0, 5.0)
	freq2 = rng.randf_range(6.0, 9.0)
