extends Node2D

var a: Vector2
var b: Vector2
var life: float = 0.12
var col := Color(1, 1, 0.2, 1)
var width: float = 2.0

func setup(p1: Vector2, p2: Vector2):
	a = p1
	b = p2
	queue_redraw()

func _ready():
	z_index = 20

func _process(delta):
	life -= delta
	if life <= 0.0:
		queue_free()

func _draw():
	draw_line(a, b, col, width)
