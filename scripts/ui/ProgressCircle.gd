extends Node2D

@export var radius: float = 28.0
@export var thickness: float = 6.0
@export var back_color: Color = Color(0, 0, 0, 0.6)
@export var fill_color: Color = Color(0.3, 0.8, 1.0, 1.0)
@export var show_label: bool = true

var ratio: float = 0.0
var seconds_text: String = ""
var label: Label = null

func _ready():
	label = Label.new()
	add_child(label)
	label.size = Vector2(64, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-label.size.x * 0.5, radius + thickness * 0.5 + 8.0)
	label.z_index = 101
	label.visible = show_label

func set_ratio(r: float):
	ratio = clamp(r, 0.0, 1.0)
	queue_redraw()

func set_seconds(sec: float):
	seconds_text = "%d" % int(sec)
	if label and show_label:
		label.text = seconds_text

func _draw():
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, back_color, thickness)
	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + TAU * ratio
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 64, fill_color, thickness)
