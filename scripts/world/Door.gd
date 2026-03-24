extends Node2D

@export var max_hp: int = 300
var hp: int = 100
var open: bool = true
var door_w: float = 6.0
var door_h: float = 36.0
var open_width: float = 14.0
var ring_radius: float = 16.0
var ring_thickness: float = 4.0
var interact_radius: float = 28.0
var repair_amount: int = 100

var prompt_e
var ring
var interacting: bool = false
var interact_time: float = 0.0
var required_time: float = 5.0
var opener: Node2D = null
var door_poly: Polygon2D = null
var open_poly: Polygon2D = null
var open_offset_x: float = 10.0
var hb: Node2D = null
var prompt_r
var r_was_down: bool = false
var body: StaticBody2D = null
var body_shape: CollisionShape2D = null
var door_sprite: Sprite2D = null
var open_sprite: Sprite2D = null
var wall_sprite: Sprite2D = null
var wall_w: float = 6.0
var wall_h: float = 36.0

func _get_const_float(key: String, default_val: float) -> float:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_float"):
		return float(root.call("get_const_float", key, default_val))
	return default_val

func _get_const_int(key: String, default_val: int) -> int:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_int"):
		return int(root.call("get_const_int", key, default_val))
	return default_val

func _ready():
	set_process(true)
	add_to_group("door")
	max_hp = _get_const_int("door.max_hp", max_hp)
	hp = _get_const_int("door.start_hp", hp)
	required_time = _get_const_float("door.repair_time", required_time)
	repair_amount = _get_const_int("door.repair_amount", repair_amount)
	door_w = _get_const_float("door.door_width", door_w)
	door_h = _get_const_float("door.door_height", door_h)
	wall_w = _get_const_float("door.wall_width", wall_w)
	wall_h = _get_const_float("door.wall_height", wall_h)
	open_width = _get_const_float("door.open_width", open_width)
	interact_radius = _get_const_float("door.interact_radius", interact_radius)
	ring_radius = _get_const_float("door.ring_radius", ring_radius)
	ring_thickness = _get_const_float("door.ring_thickness", ring_thickness)
	open_offset_x = _get_const_float("door.open_offset_x", 0.0)
	var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
	prompt_e = PromptScript.new()
	prompt_e.key_text = "E"
	add_child(prompt_e)
	var RingScript := preload("res://scripts/ui/ProgressCircle.gd")
	ring = RingScript.new()
	add_child(ring)
	ring.radius = ring_radius
	ring.thickness = ring_thickness
	ring.show_label = false
	ring.position = Vector2(0, -30)
	ring.visible = false
	door_poly = Polygon2D.new()
	door_poly.z_index = 5
	var hw: float = door_w * 0.5
	door_poly.polygon = PackedVector2Array([
		Vector2(-hw, -door_h), Vector2(hw, -door_h),
		Vector2(hw, 0), Vector2(-hw, 0)
	])
	door_poly.color = Color(0.55, 0.35, 0.2, 1.0)
	door_poly.visible = false
	add_child(door_poly)
	door_sprite = Sprite2D.new()
	door_sprite.texture = _build_door_texture(int(round(door_w)), int(round(door_h)), false)
	door_sprite.centered = false
	door_sprite.position = Vector2(-door_w * 0.5, -door_h)
	door_sprite.z_index = 5
	door_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(door_sprite)
	if wall_h <= 0.0:
		wall_h = door_h
	wall_sprite = Sprite2D.new()
	wall_sprite.texture = _build_wall_texture(int(round(wall_w)), int(round(wall_h)))
	wall_sprite.centered = false
	wall_sprite.position = Vector2(-wall_w * 0.5, -wall_h)
	wall_sprite.z_index = 4
	wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(wall_sprite)
	open_poly = Polygon2D.new()
	open_poly.z_index = 5
	var open_hw: float = open_width * 0.5
	open_poly.polygon = PackedVector2Array([
		Vector2(-open_hw, -door_h), Vector2(open_hw, -door_h),
		Vector2(open_hw, 0), Vector2(-open_hw, 0)
	])
	open_poly.color = Color(0.65, 0.45, 0.25, 1.0)
	open_offset_x = open_offset_x if open_offset_x != 0.0 else door_w * 0.5 + 8.0
	open_poly.position = Vector2(open_offset_x, 0)
	open_poly.visible = false
	add_child(open_poly)
	open_sprite = Sprite2D.new()
	open_sprite.texture = _build_door_texture(int(round(open_width)), int(round(door_h)), true)
	open_sprite.centered = false
	open_sprite.position = Vector2(open_offset_x - 7.0, -door_h)
	open_sprite.z_index = 5
	open_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(open_sprite)
	prompt_r = PromptScript.new()
	prompt_r.key_text = "R"
	add_child(prompt_r)
	var HealthBarScript := preload("res://scripts/characters/HealthBar.gd")
	hb = HealthBarScript.new()
	add_child(hb)
	hb.owner = self
	hb.offset = Vector2.ZERO
	body = StaticBody2D.new()
	body.collision_layer = 0
	body.collision_mask = 0
	add_child(body)
	body.position = Vector2(0, -door_h * 0.5)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(door_w, door_h)
	body_shape = CollisionShape2D.new()
	body_shape.shape = rect
	body.add_child(body_shape)

func _process(delta):
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.get("input_locked") != null and bool(root.get("input_locked")):
		return
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var _near: bool = false
	var d_anchor: float = 999999.0
	var d_base: float = 999999.0
	if player_ref != null:
		var anchor := _anchor_position()
		d_anchor = player_ref.global_position.distance_to(anchor)
		_near = d_anchor <= interact_radius
	var near_base: bool = false
	if player_ref != null:
		d_base = player_ref.global_position.distance_to(global_position)
		near_base = d_base <= interact_radius
	var can_repair: bool = open and hp < max_hp
	var prompt_y: float = _get_prompt_y()
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt_e and is_instance_valid(prompt_e):
		var show_e: bool = can_repair and d_anchor <= d_base and d_anchor <= interact_radius
		prompt_e.visible = show_e and target_ok
		if prompt_e.visible:
			var anchor := _anchor_position()
			prompt_e.set_world_position(Vector2(anchor.x, prompt_y))
	if prompt_r and is_instance_valid(prompt_r):
		var show_r: bool = false
		if open and hp > 0 and near_base and d_base < d_anchor:
			show_r = true
		elif not open and near_base:
			show_r = true
		prompt_r.visible = show_r and target_ok
		if show_r and target_ok:
			prompt_r.set_world_position(Vector2(global_position.x, prompt_y))
	if door_sprite:
		door_sprite.visible = true
	if open_sprite:
		open_sprite.visible = open
	if wall_sprite:
		wall_sprite.visible = true
	if interacting:
		var moving_horiz: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		if moving_horiz or not can_repair:
			_cancel_interact()
			return
		interact_time += delta
		var r: float = clamp(interact_time / required_time, 0.0, 1.0)
		if ring:
			_update_ring_position(player_ref)
			ring.set_ratio(r)
		if interact_time >= required_time:
			hp = min(hp + repair_amount, max_hp)
			_cancel_interact()
			return
	if ring and ring.visible:
		_update_ring_position(player_ref)
	var r_down: bool = Input.is_key_pressed(KEY_R)
	var r_just: bool = r_down and not r_was_down
	if r_just and near_base and target_ok:
		if open and hp > 0:
			set_open(false)
		else:
			set_open(true)
	r_was_down = r_down
	if not open and hp <= 0:
		set_open(true)
	if hb:
		var top_cur := _open_top_position() if open else _closed_top_position()
		hb.position = to_local(top_cur + Vector2(0, -6))

func try_interact(p: Node2D):
	if not open:
		return
	if hp >= max_hp:
		return
	var anchor := _anchor_position()
	if p != null and p is Node2D:
		var d := (p as Node2D).global_position.distance_to(anchor)
		if d > interact_radius:
			return
	if interacting:
		return
	opener = p
	interact_time = 0.0
	interacting = true
	if ring:
		ring.visible = true
		ring.set_ratio(0.0)

func set_open(v: bool):
	open = v
	if open_sprite:
		open_sprite.visible = open
	if body:
		body.collision_layer = 0 if open else 4

func set_wall_dimensions(w: float, h: float):
	wall_w = max(w, 1.0)
	wall_h = max(h, 1.0)
	if wall_sprite:
		wall_sprite.texture = _build_wall_texture(int(round(wall_w)), int(round(wall_h)))
		wall_sprite.position = Vector2(-wall_w * 0.5, -wall_h)

func _cancel_interact():
	interacting = false
	interact_time = 0.0
	opener = null
	if ring:
		ring.visible = false
	if hb:
		var top := _open_top_position() if open else _closed_top_position()
		hb.position = to_local(top + Vector2(0, -6))

func _get_prompt_y() -> float:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		var p := ps[0] as Node2D
		var hb_node := p.get_node_or_null("HealthBar")
		if hb_node and hb_node.has_method("get_top_y"):
			var hb_top: float = float(hb_node.call("get_top_y"))
			var bg_half: float = prompt_e.get_bg_half_height() if prompt_e else 0.0
			return hb_top - 5.0 - bg_half
		if hb_node:
			var bh = hb_node.get("bar_height")
			if bh != null:
				var hb_top2: float = hb_node.global_position.y - float(bh) * 0.5
				var bg_half2: float = prompt_e.get_bg_half_height() if prompt_e else 0.0
				return hb_top2 - 5.0 - bg_half2
		var bg_half3: float = prompt_e.get_bg_half_height() if prompt_e else 0.0
		return p.global_position.y - 40.0 - bg_half3
	var bg_half4: float = prompt_e.get_bg_half_height() if prompt_e else 0.0
	return global_position.y - 26.0 - bg_half4

func _update_ring_position(p: Node2D):
	if p == null:
		return
	ring.position = to_local(p.global_position + Vector2(0, -30))
func is_interactable() -> bool:
	if not open:
		return true
	return hp > 0 or hp < max_hp
func get_interact_position(p: Vector2 = Vector2.ZERO) -> Vector2:
	var anchor := _anchor_position()
	var d_anchor: float = p.distance_to(anchor)
	var d_base: float = p.distance_to(global_position)
	return anchor if d_anchor <= d_base else global_position
func _anchor_position() -> Vector2:
	if open and open_poly:
		return open_poly.global_position
	return global_position
func _open_top_position() -> Vector2:
	if open and open_poly:
		return open_poly.global_position + Vector2(0, -door_h)
	return global_position + Vector2(0, -door_h)
func _closed_top_position() -> Vector2:
	return global_position + Vector2(0, -door_h)
func take_damage(d: int):
	if open:
		return
	hp = max(hp - int(d), 0)
	if hp <= 0:
		set_open(true)

func _build_door_texture(w: int, h: int, opened: bool) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.62, 0.39, 0.22, 1.0) if not opened else Color(0.7, 0.47, 0.28, 1.0)
	var c2 := Color(0.46, 0.28, 0.14, 1.0) if not opened else Color(0.55, 0.34, 0.18, 1.0)
	var edge := Color(0.28, 0.16, 0.08, 1.0)
	var knob := Color(0.96, 0.84, 0.42, 1.0)
	for y in range(th):
		for x in range(tw):
			var col := c1 if ((int(x / 2.0) + int(y / 3.0)) % 2) == 0 else c2
			if x == 0 or x == tw - 1 or y == 0 or y == th - 1:
				col = edge
			img.set_pixel(x, y, col)
	var knob_x: int = max(min(tw - 2, int(tw / 2.0)), 1)
	var knob_y: int = clampi(int(th / 2.0), 1, th - 2)
	img.set_pixel(knob_x, knob_y, knob)
	return ImageTexture.create_from_image(img)

func _build_wall_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.51, 0.51, 0.66, 1.0)
	var c2 := Color(0.38, 0.38, 0.5, 1.0)
	var edge := Color(0.22, 0.22, 0.28, 1.0)
	for y in range(th):
		for x in range(tw):
			var stripe: bool = (int(y / 4.0) % 2) == 0
			var col := c1 if stripe else c2
			if x == 0 or x == tw - 1:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
