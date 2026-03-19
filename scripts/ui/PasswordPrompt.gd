extends CanvasLayer

signal submitted(code: String)

var root: Control
var input_label: Label
var tip_label: Label
var code: String = ""
var suppress_restore: bool = false

func _ready():
	add_to_group("puzzle")
	layer = 100
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var vp_rect := get_viewport().get_visible_rect()
	root.position = vp_rect.position
	root.size = vp_rect.size
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)
	var center := CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_top = 0.0
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 420)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "输入密码"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	input_label = Label.new()
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_label.text = "----"
	vb.add_child(input_label)
	tip_label = Label.new()
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.text = ""
	vb.add_child(tip_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size = Vector2(240, 240)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	for i in range(1, 10):
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(72, 60)
		btn.pressed.connect(_on_digit_pressed.bind(str(i)))
		grid.add_child(btn)
	var btn0 := Button.new()
	btn0.text = "0"
	btn0.custom_minimum_size = Vector2(72, 60)
	btn0.pressed.connect(_on_digit_pressed.bind("0"))
	grid.add_child(btn0)
	var btn_del := Button.new()
	btn_del.text = "删除"
	btn_del.custom_minimum_size = Vector2(72, 60)
	btn_del.pressed.connect(_on_delete_pressed)
	grid.add_child(btn_del)
	var btn_ok := Button.new()
	btn_ok.text = "确定"
	btn_ok.custom_minimum_size = Vector2(72, 60)
	btn_ok.pressed.connect(_on_submit_pressed)
	grid.add_child(btn_ok)
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.pressed.connect(_on_close_pressed)
	hb.add_child(close_btn)
	_set_input_locked(true)
	_refresh_view()

func open():
	return

func _exit_tree():
	_set_input_locked(false)
	return

func close_forced():
	suppress_restore = true
	_set_input_locked(false)
	queue_free()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			_on_digit_pressed(str(event.keycode - KEY_0))
		elif event.keycode == KEY_BACKSPACE:
			_on_delete_pressed()
		elif event.keycode == KEY_ENTER:
			_on_submit_pressed()

func _on_digit_pressed(d: String):
	if code.length() >= 4:
		return
	code += d
	tip_label.text = ""
	_refresh_view()

func _on_delete_pressed():
	if code.length() <= 0:
		return
	code = code.substr(0, code.length() - 1)
	tip_label.text = ""
	_refresh_view()

func _on_submit_pressed():
	if code.length() < 4:
		tip_label.text = "请输入4位密码"
		return
	emit_signal("submitted", code)

func _on_close_pressed():
	queue_free()

func _refresh_view():
	var shown := ""
	for i in range(4):
		if i < code.length():
			shown += code[i]
		else:
			shown += "-"
	input_label.text = shown

func show_error(msg: String):
	tip_label.text = msg

func _set_input_locked(v: bool):
	var root_node := get_tree().get_root().get_node_or_null("GameRoot")
	if root_node and root_node.has_method("set_input_locked"):
		root_node.call("set_input_locked", v)
