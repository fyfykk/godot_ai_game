extends CanvasLayer

signal completed

var grid: GridContainer
var tiles: Array = []
var types: Array = []
var rots: Array = []
var solution_rots: Array = []
var board_size: int = 4
var rng := RandomNumberGenerator.new()
var root: Control
var suppress_restore: bool = false
var use_seed: bool = false
var seed_value: int = 0
var puzzle_size: int = 4

func setup(seed: int, size: int):
	if size > 1:
		puzzle_size = size
	if seed != 0:
		use_seed = true
		seed_value = seed

func _ready():
	if use_seed:
		rng.seed = seed_value
	else:
		rng.randomize()
	if puzzle_size > 1:
		board_size = puzzle_size
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
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "电路连线"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var desc := Label.new()
	desc.text = "把左侧绿色连通到右侧红色即可解锁"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(desc)
	grid = GridContainer.new()
	grid.columns = board_size
	grid.custom_minimum_size = Vector2(72 * board_size, 72 * board_size)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.pressed.connect(_on_close_pressed)
	hb.add_child(close_btn)
	tiles.clear()
	types.clear()
	rots.clear()
	solution_rots.clear()
	for i in range(board_size * board_size):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(_on_tile_pressed.bind(i))
		grid.add_child(btn)
		tiles.append(btn)
		types.append(0)
		rots.append(0)
		solution_rots.append(0)
	_build_board()
	_update_view()

func open():
	return

func _exit_tree():
	_set_input_locked(false)
	return

func close_forced():
	suppress_restore = true
	_set_input_locked(false)
	queue_free()

func _process(delta):
	return

func _on_close_pressed():
	queue_free()

func _set_input_locked(v: bool):
	var root_node := get_tree().get_root().get_node_or_null("GameRoot")
	if root_node and root_node.has_method("set_input_locked"):
		root_node.call("set_input_locked", v)

func _set_process_mode_recursive(n: Node, mode: int):
	n.process_mode = mode
	for c in n.get_children():
		if c is Node:
			_set_process_mode_recursive(c, mode)

func _update_timer():
	return

func _tile_char(t: int, rot: int) -> String:
	if t == 0:
		return "─" if (rot % 2) == 0 else "│"
	if rot % 4 == 0:
		return "└"
	if rot % 4 == 1:
		return "┌"
	if rot % 4 == 2:
		return "┐"
	return "┘"

func _tile_connections(t: int, rot: int) -> Array:
	if t == 0:
		return ["l", "r"] if (rot % 2) == 0 else ["u", "d"]
	if rot % 4 == 0:
		return ["u", "r"]
	if rot % 4 == 1:
		return ["r", "d"]
	if rot % 4 == 2:
		return ["d", "l"]
	return ["l", "u"]

func _dir_vec(d: String) -> Vector2i:
	if d == "u":
		return Vector2i(0, -1)
	if d == "r":
		return Vector2i(1, 0)
	if d == "d":
		return Vector2i(0, 1)
	return Vector2i(-1, 0)

func _opposite(d: String) -> String:
	if d == "u":
		return "d"
	if d == "r":
		return "l"
	if d == "d":
		return "u"
	return "r"

func _dir_between(a: Vector2i, b: Vector2i) -> String:
	if b.x > a.x:
		return "r"
	if b.x < a.x:
		return "l"
	if b.y > a.y:
		return "d"
	return "u"

func _type_from_dirs(d1: String, d2: String) -> Array:
	var dirs := [d1, d2]
	dirs.sort()
	if dirs == ["l", "r"]:
		return [0, 0]
	if dirs == ["d", "u"]:
		return [0, 1]
	if dirs == ["r", "u"]:
		return [1, 0]
	if dirs == ["d", "r"]:
		return [1, 1]
	if dirs == ["d", "l"]:
		return [1, 2]
	return [1, 3]

func _generate_path() -> Array:
	for _try in range(80):
		var path: Array = []
		var visited: Dictionary = {}
		var cur := Vector2i(0, 1)
		path.append(cur)
		visited[cur] = true
		var ok: bool = true
		while cur.x < board_size - 1:
			var moves: Array = []
			var right := Vector2i(cur.x + 1, cur.y)
			if right.x < board_size and not visited.has(right):
				moves.append(right)
			var up := Vector2i(cur.x, cur.y - 1)
			if up.y >= 0 and not visited.has(up):
				moves.append(up)
			var down := Vector2i(cur.x, cur.y + 1)
			if down.y < board_size and not visited.has(down):
				moves.append(down)
			if moves.size() == 0:
				ok = false
				break
			var next: Vector2i = moves[rng.randi_range(0, moves.size() - 1)]
			if right in moves and rng.randf() < 0.6:
				next = right
			cur = next
			path.append(cur)
			visited[cur] = true
		if not ok:
			continue
		while cur.y < 1:
			var step := Vector2i(cur.x, cur.y + 1)
			if visited.has(step):
				ok = false
				break
			cur = step
			path.append(cur)
			visited[cur] = true
		if not ok:
			continue
		while cur.y > 1:
			var step2 := Vector2i(cur.x, cur.y - 1)
			if visited.has(step2):
				ok = false
				break
			cur = step2
			path.append(cur)
			visited[cur] = true
		if ok:
			return path
	var fallback: Array = []
	for x in range(board_size):
		fallback.append(Vector2i(x, 1))
	return fallback

func _build_board():
	for i in range(types.size()):
		types[i] = 0
		rots[i] = 0
		solution_rots[i] = 0
	var path: Array = _generate_path()
	var conns: Dictionary = {}
	for i in range(path.size()):
		var p: Vector2i = path[i]
		if not conns.has(p):
			conns[p] = []
		if i == 0:
			(conns[p] as Array).append("l")
		if i == path.size() - 1:
			(conns[p] as Array).append("r")
		if i > 0:
			var prev: Vector2i = path[i - 1]
			(conns[p] as Array).append(_dir_between(p, prev))
		if i < path.size() - 1:
			var nxt: Vector2i = path[i + 1]
			(conns[p] as Array).append(_dir_between(p, nxt))
	for k in conns.keys():
		var pos: Vector2i = k
		var arr: Array = conns[k]
		var uniq: Array = []
		for d in arr:
			if not uniq.has(d):
				uniq.append(d)
		if uniq.size() < 2:
			continue
		var res := _type_from_dirs(String(uniq[0]), String(uniq[1]))
		var idx: int = pos.y * board_size + pos.x
		types[idx] = int(res[0])
		rots[idx] = int(res[1])
		solution_rots[idx] = int(res[1])
	for i in range(types.size()):
		var posi := Vector2i(i % board_size, i / board_size)
		if conns.has(posi):
			continue
		types[i] = rng.randi_range(0, 1)
		rots[i] = rng.randi_range(0, 3)
		solution_rots[i] = rots[i]
	for i in range(rots.size()):
		rots[i] = (int(solution_rots[i]) + rng.randi_range(0, 3)) % 4
	if _is_connected():
		var idx2: int = rng.randi_range(0, rots.size() - 1)
		rots[idx2] = (int(rots[idx2]) + 1) % 4
	_set_input_locked(true)

func _has_dir(pos: Vector2i, dir: String) -> bool:
	var idx: int = pos.y * board_size + pos.x
	if idx < 0 or idx >= rots.size():
		return false
	var dirs := _tile_connections(int(types[idx]), int(rots[idx]))
	return dirs.has(dir)

func _is_connected() -> bool:
	var connected := _collect_connected()
	var end := Vector2i(board_size - 1, 1)
	return connected.has(end) and _has_dir(end, "r")

func _collect_connected() -> Dictionary:
	var start := Vector2i(0, 1)
	if not _has_dir(start, "l"):
		return {}
	var queue: Array = [start]
	var visited: Dictionary = {}
	visited[start] = true
	while queue.size() > 0:
		var cur: Vector2i = queue.pop_front()
		var idx: int = cur.y * board_size + cur.x
		var dirs := _tile_connections(int(types[idx]), int(rots[idx]))
		for d in dirs:
			var v := _dir_vec(String(d))
			var nx: int = cur.x + v.x
			var ny: int = cur.y + v.y
			if nx < 0 or nx >= board_size or ny < 0 or ny >= board_size:
				continue
			var npos := Vector2i(nx, ny)
			var back := _opposite(String(d))
			if not _has_dir(npos, back):
				continue
			if visited.has(npos):
				continue
			visited[npos] = true
			queue.append(npos)
	return visited

func _update_view():
	var connected := _collect_connected()
	var start := Vector2i(0, 1)
	var end := Vector2i(board_size - 1, 1)
	for i in range(tiles.size()):
		var btn: Button = tiles[i]
		btn.text = _tile_char(int(types[i]), int(rots[i]))
		var pos := Vector2i(i % board_size, i / board_size)
		if pos == end:
			btn.modulate = Color(1.0, 0.35, 0.35, 1.0)
		elif pos == start or connected.has(pos):
			btn.modulate = Color(0.35, 0.95, 0.5, 1.0)
		else:
			btn.modulate = Color(1, 1, 1, 1)

func _on_tile_pressed(idx: int):
	rots[idx] = int(rots[idx] + 1) % 4
	_update_view()
	if _is_connected():
		completed.emit()
		queue_free()
