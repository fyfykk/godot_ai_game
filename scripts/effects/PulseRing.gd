extends Node2D

@export var radius: float = 60.0
@export var thickness: float = 4.0
@export var color: Color = Color(0.5, 0.8, 1.0, 0.9)
@export var life: float = 0.35

var t: float = 0.0

func _process(delta):
	t += delta
	if t >= life:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var r := radius * (0.9 + 0.3 * (t / life))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color, thickness)
