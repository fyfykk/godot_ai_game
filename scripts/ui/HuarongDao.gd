extends CanvasLayer

signal completed

var grid: GridContainer
var tiles: Array = []
var board: Array = []
var board_size: int = 3
var rng := RandomNumberGenerator.new()
var prev_paused: bool = false
var root: Control
var suppress_restore: bool = false

func _ready():
	rng.randomize()
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
	panel.custom_minimum_size = Vector2(300, 360)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "华容道"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	grid = GridContainer.new()
	grid.columns = board_size
	grid.custom_minimum_size = Vector2(240, 240)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	tiles.clear()
	for i in range(board_size * board_size):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.pressed.connect(_on_tile_pressed.bind(i))
		grid.add_child(btn)
		tiles.append(btn)
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var cancel := Button.new()
	cancel.text = "退出"
	cancel.custom_minimum_size = Vector2(120, 36)
	cancel.pressed.connect(_on_cancel_pressed)
	hb.add_child(cancel)
	_shuffle_board()
	_update_view()

func open():
	prev_paused = get_tree().paused
	get_tree().paused = true
	_set_process_mode_recursive(self, Node.PROCESS_MODE_WHEN_PAUSED)

func _exit_tree():
	if suppress_restore:
		return
	var root_node := get_tree().get_root().get_node_or_null("GameRoot")
	if root_node and root_node.get("run_ended") != null and bool(root_node.get("run_ended")):
		return
	get_tree().paused = prev_paused

func close_forced():
	suppress_restore = true
	queue_free()

func _set_process_mode_recursive(n: Node, mode: int):
	n.process_mode = mode
	for c in n.get_children():
		if c is Node:
			_set_process_mode_recursive(c, mode)

func _shuffle_board():
	board = []
	for i in range(1, board_size * board_size):
		board.append(i)
	board.append(0)
	var tries: int = 0
	while true:
		board.shuffle()
		if _is_solvable(board) and not _is_solved(board):
			break
		tries += 1
		if tries > 200:
			break

func _is_solved(arr: Array) -> bool:
	for i in range(board_size * board_size - 1):
		if int(arr[i]) != i + 1:
			return false
	return int(arr[board_size * board_size - 1]) == 0

func _is_solvable(arr: Array) -> bool:
	var inv: int = 0
	for i in range(arr.size()):
		var vi := int(arr[i])
		if vi == 0:
			continue
		for j in range(i + 1, arr.size()):
			var vj := int(arr[j])
			if vj != 0 and vi > vj:
				inv += 1
	return inv % 2 == 0

func _update_view():
	for i in range(tiles.size()):
		var v: int = int(board[i])
		var btn: Button = tiles[i]
		if v == 0:
			btn.text = ""
			btn.disabled = true
		else:
			btn.text = str(v)
			btn.disabled = false

func _on_tile_pressed(idx: int):
	var empty_idx := board.find(0)
	if empty_idx == -1:
		return
	if _is_adjacent(idx, empty_idx):
		var t: int = int(board[idx])
		board[idx] = board[empty_idx]
		board[empty_idx] = t
		_update_view()
		if _is_solved(board):
			completed.emit()
			queue_free()

func _is_adjacent(a: int, b: int) -> bool:
	var ax := a % board_size
	var ay := a / board_size
	var bx := b % board_size
	var by := b / board_size
	return abs(ax - bx) + abs(ay - by) == 1

func _on_cancel_pressed():
	queue_free()
