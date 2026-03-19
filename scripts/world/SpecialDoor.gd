extends "res://scripts/world/Door.gd"

@export var special: bool = true
@export var special_locked: bool = true

var lock_sprite: Sprite2D = null
var puzzle_active: bool = false
var e_was_down: bool = false
var puzzle_seed: int = 0

func _ready():
	super._ready()
	lock_sprite = Sprite2D.new()
	lock_sprite.texture = _build_lock_texture(20, 20)
	lock_sprite.centered = true
	lock_sprite.z_index = 6
	lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_sprite.position = Vector2(0, -door_h - 8.0)
	add_child(lock_sprite)
	set_special_locked(special_locked)

func _process(delta):
	if special_locked:
		_process_locked()
		return
	super._process(delta)

func _process_locked():
	if lock_sprite:
		lock_sprite.visible = true
	set_open(false)
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var near: bool = false
	var d_anchor: float = 999999.0
	if player_ref != null:
		var anchor := _anchor_position()
		d_anchor = player_ref.global_position.distance_to(anchor)
		near = d_anchor <= 28.0
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt_e and is_instance_valid(prompt_e):
		prompt_e.visible = near and target_ok
		if prompt_e.visible:
			var prompt_y: float = _get_prompt_y()
			var anchor2 := _anchor_position()
			prompt_e.set_world_position(Vector2(anchor2.x, prompt_y))
	if prompt_r and is_instance_valid(prompt_r):
		prompt_r.visible = false
	if hb:
		var top_cur := _closed_top_position()
		hb.position = to_local(top_cur + Vector2(0, -6))
	var e_down: bool = Input.is_key_pressed(KEY_E)
	var just_started: bool = e_down and not e_was_down
	if just_started and near and target_ok:
		_open_puzzle()
	e_was_down = e_down

func _open_puzzle():
	if puzzle_active:
		return
	puzzle_active = true
	if puzzle_seed == 0:
		var root := get_tree().get_root().get_node_or_null("GameRoot")
		var run_seed: int = 0
		if root and root.get("run_seed") != null:
			run_seed = int(root.get("run_seed"))
		var px: int = int(round(global_position.x))
		var py: int = int(round(global_position.y))
		var base: int = int(get_instance_id())
		puzzle_seed = abs(run_seed * 1315423911 + px * 374761393 + py * 668265263 + base) % 2147483000
	var PuzzleScript := preload("res://scripts/ui/CircuitLink.gd")
	var puzzle = PuzzleScript.new()
	if puzzle.has_method("setup"):
		puzzle.call("setup", puzzle_seed, 4)
	get_tree().get_root().add_child(puzzle)
	if puzzle is CanvasItem:
		(puzzle as CanvasItem).z_index = 10000
		(puzzle as CanvasItem).z_as_relative = false
	if puzzle.has_method("open"):
		puzzle.open()
	puzzle.completed.connect(_on_puzzle_completed)
	puzzle.tree_exited.connect(_on_puzzle_closed)

func _on_puzzle_completed():
	set_special_locked(false)

func _on_puzzle_closed():
	puzzle_active = false

func set_special_locked(v: bool):
	special_locked = v
	if lock_sprite:
		lock_sprite.visible = special_locked
	set_open(false)
	if body:
		body.collision_layer = 8 if special_locked else 4

func set_open(v: bool):
	if special_locked:
		open = false
		if open_sprite:
			open_sprite.visible = false
		if body:
			body.collision_layer = 8
		return
	super.set_open(v)

func is_interactable() -> bool:
	if special_locked:
		return true
	return super.is_interactable()

func try_interact(p: Node2D):
	if special_locked:
		_open_puzzle()
		return
	super.try_interact(p)

func take_damage(d: int):
	if special_locked:
		return
	super.take_damage(d)

func _build_lock_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var dark := Color(0.35, 0.36, 0.4, 1.0)
	var mid := Color(0.6, 0.62, 0.68, 1.0)
	var hi := Color(0.82, 0.84, 0.9, 1.0)
	var edge := Color(0.18, 0.2, 0.24, 1.0)
	var ban := Color(0.85, 0.12, 0.12, 0.9)
	var ban_dark := Color(0.5, 0.05, 0.05, 0.9)
	var cx: float = float(tw) * 0.5 - 0.5
	var cy: float = float(th) * 0.5 - 0.5
	var body_w: int = int(round(float(min(tw, th)) * 0.42))
	var body_h: int = int(round(float(min(tw, th)) * 0.36))
	var body_left: int = int(round(cx)) - int(body_w * 0.5)
	var body_right: int = int(round(cx)) + int(body_w * 0.5)
	var body_top: int = int(round(cy)) - int(body_h * 0.1)
	var body_bottom: int = body_top + body_h
	var shackle_top: int = int(round(cy)) - int(body_h * 0.55)
	var shackle_bottom: int = body_top + 1
	var shackle_left: int = body_left + 1
	var shackle_right: int = body_right - 1
	var key_cx: int = int(round(cx))
	var key_cy: int = body_top + int(round(body_h * 0.55))
	for y in range(th):
		for x in range(tw):
			var col := Color(0, 0, 0, 0)
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var r2: float = dx * dx + dy * dy
			var ban_outer: float = float(min(tw, th)) * 0.54
			var ban_inner: float = float(min(tw, th)) * 0.4
			if r2 <= ban_outer * ban_outer and r2 >= ban_inner * ban_inner:
				col = ban if ((x + y) % 2) == 0 else ban_dark
			elif x == body_left or x == body_right or y == body_top or y == body_bottom:
				col = edge
			elif x >= body_left and x <= body_right and y >= body_top and y <= body_bottom:
				col = mid
			elif x >= shackle_left and x <= shackle_right and y >= shackle_top and y <= shackle_bottom:
				col = hi
			if abs(x - key_cx) <= 1 and abs(y - key_cy) <= 1:
				col = dark
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
