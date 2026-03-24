extends Area2D

@export var width: float = 12.0
@export var height: float = 80.0
@export var locked: bool = false
@export var leads_to_top: bool = false

var cs: CollisionShape2D
var poly: Polygon2D
var lock_node: Node2D
var prompt
var ring
var coin_icon: Sprite2D
var coin_label: Label
var interacting: bool = false
var coin_timer: float = 0.0
var opener: Node2D = null
var start_pos: Vector2 = Vector2.ZERO
var unlock_progress: int = 0
var locked_color: Color = Color(0.5, 0.3, 0.1, 0.9)
var unlocked_color: Color = Color(0.6, 0.6, 0.2, 0.7)
var e_was_down: bool = false
var ladder_sprite: Sprite2D = null
var lock_sprite: Sprite2D = null
var interact_radius: float = 40.0
var unlock_cost: int = 100
var unlock_spend_per_sec: int = 10
var ring_radius: float = 16.0
var ring_thickness: float = 4.0

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
	width = _get_const_float("ladder.width", width)
	height = _get_const_float("ladder.height", height)
	interact_radius = _get_const_float("ladder.interact_radius", interact_radius)
	unlock_cost = _get_const_int("ladder.unlock_cost", unlock_cost)
	unlock_spend_per_sec = _get_const_int("ladder.unlock_spend_per_sec", unlock_spend_per_sec)
	ring_radius = _get_const_float("ladder.ring_radius", ring_radius)
	ring_thickness = _get_const_float("ladder.ring_thickness", ring_thickness)
	add_to_group("ladder")
	collision_layer = 0
	collision_mask = 3
	cs = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height + 2.0)
	cs.shape = shape
	add_child(cs)
	poly = Polygon2D.new()
	poly.color = unlocked_color
	poly.z_index = 3
	poly.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5),
		Vector2(width * 0.5, height * 0.5),
		Vector2(-width * 0.5, height * 0.5)
	])
	poly.visible = false
	add_child(poly)
	ladder_sprite = Sprite2D.new()
	ladder_sprite.texture = _build_ladder_texture(int(round(width)), int(round(height)))
	ladder_sprite.centered = true
	ladder_sprite.z_index = 3
	ladder_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ladder_sprite)
	lock_node = Node2D.new()
	add_child(lock_node)
	lock_sprite = Sprite2D.new()
	lock_sprite.texture = _build_lock_texture(20, 20)
	lock_sprite.centered = true
	lock_sprite.z_index = 5
	lock_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_node.add_child(lock_sprite)
	coin_icon = Sprite2D.new()
	coin_icon.texture = _build_coin_texture(14, 14)
	coin_icon.centered = true
	coin_icon.z_index = 6
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(coin_icon)
	coin_label = Label.new()
	coin_label.text = "100"
	coin_label.modulate = Color(1, 1, 1, 1)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_label.add_theme_font_size_override("font_size", 11)
	coin_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	coin_label.add_theme_constant_override("font_outline_size", 2)
	coin_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
	coin_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_label.custom_minimum_size = Vector2(28, 12)
	coin_label.z_index = 7
	add_child(coin_label)
	var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
	prompt = PromptScript.new()
	prompt.key_text = "E"
	add_child(prompt)
	var RingScript := preload("res://scripts/ui/ProgressCircle.gd")
	ring = RingScript.new()
	add_child(ring)
	ring.radius = ring_radius
	ring.thickness = ring_thickness
	ring.show_label = false
	ring.visible = false
	set_process(true)
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	_update_lock_visual()

func _process(delta):
	var root_chk := get_tree().get_root().get_node_or_null("GameRoot")
	if root_chk and root_chk.get("input_locked") != null and bool(root_chk.get("input_locked")):
		return
	_update_lock_visual()
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var near: bool = false
	if player_ref != null:
		var d := player_ref.global_position.distance_to(global_position)
		near = d <= interact_radius
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if not locked:
		if prompt:
			prompt.visible = false
		_cancel_interact()
		e_was_down = Input.is_key_pressed(KEY_E)
		return
	if prompt:
		prompt.visible = near and target_ok
	if not near or not target_ok:
		_cancel_interact()
		e_was_down = Input.is_key_pressed(KEY_E)
		return
	var e_down: bool = Input.is_key_pressed(KEY_E)
	var just_started: bool = e_down and not e_was_down
	var moving_horiz: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	if just_started and not moving_horiz:
		if opener == null and player_ref != null:
			opener = player_ref
			start_pos = player_ref.global_position
			if ring:
				ring.visible = true
				ring.set_ratio(float(unlock_progress) / 100.0)
		interacting = true
	if interacting:
		if moving_horiz:
			_cancel_interact()
			e_was_down = e_down
			return
		var root_coin := get_tree().get_root().get_node("GameRoot")
		if root_coin and root_coin.has_method("get_run_coins"):
			var cur_coins: int = int(root_coin.call("get_run_coins"))
			if cur_coins <= 0:
				_cancel_interact()
				e_was_down = e_down
				return
		var spend_interval: float = 1.0
		var root_zero := get_tree().get_root().get_node_or_null("GameRoot")
		if root_zero and root_zero.has_method("is_zero_interact") and bool(root_zero.call("is_zero_interact")):
			spend_interval = 0.5
		coin_timer += delta
		if coin_timer >= spend_interval:
			coin_timer = 0.0
			var need: int = max(unlock_cost - unlock_progress, 0)
			var spend_req: int = min(unlock_spend_per_sec, need)
			var root := get_tree().get_root().get_node("GameRoot")
			var spent: int = 0
			if root and root.has_method("spend_run_coins"):
				spent = int(root.call("spend_run_coins", spend_req))
			unlock_progress = min(unlock_cost, unlock_progress + spent)
			if ring:
				ring.set_ratio(float(unlock_progress) / 100.0)
			if unlock_progress >= unlock_cost:
				locked = false
				_update_lock_visual()
				_cancel_interact()
				if leads_to_top:
					var level := get_tree().get_root().get_node("GameRoot/Level")
					if level and level.has_method("set_top_layer_locked"):
						level.call("set_top_layer_locked", false)
	e_was_down = e_down

func _update_lock_visual():
	if lock_node:
		lock_node.position = Vector2(0, 0)
		lock_node.visible = locked
	if lock_sprite:
		lock_sprite.visible = locked
	if poly:
		poly.color = locked_color if locked else unlocked_color
	if ladder_sprite:
		ladder_sprite.modulate = Color(0.72, 0.72, 0.72, 1.0) if locked else Color(1, 1, 1, 1.0)
	var remaining: int = max(unlock_cost - unlock_progress, 0)
	if coin_icon:
		coin_icon.visible = locked
		coin_icon.position = Vector2(-10, -32)
	if coin_label:
		coin_label.visible = locked
		coin_label.text = "%d" % remaining
		coin_label.position = Vector2(0, -38)
	var pr: Node2D = null
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		pr = ps[0] as Node2D
	if ring and (opener != null or pr != null):
		var ref := opener if opener != null else pr
		ring.position = to_local(ref.global_position + Vector2(0, -30))
	if prompt and is_instance_valid(prompt) and (opener != null or pr != null):
		var y := _get_prompt_y()
		prompt.set_world_position(Vector2(global_position.x, y))

func _cancel_interact():
	interacting = false
	opener = null
	coin_timer = 0.0
	e_was_down = false
	if ring:
		ring.visible = false

func _get_prompt_y() -> float:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		var p := ps[0] as Node2D
		var hb := p.get_node_or_null("HealthBar")
		if hb and hb.has_method("get_top_y"):
			var hb_top: float = float(hb.call("get_top_y"))
			var bg_half: float = prompt.get_bg_half_height() if prompt else 0.0
			return hb_top - 5.0 - bg_half
		if hb:
			var bh = hb.get("bar_height")
			if bh != null:
				var hb_top2: float = hb.global_position.y - float(bh) * 0.5
				var bg_half2: float = prompt.get_bg_half_height() if prompt else 0.0
				return hb_top2 - 5.0 - bg_half2
		var bg_half3: float = prompt.get_bg_half_height() if prompt else 0.0
		return p.global_position.y - 40.0 - bg_half3
	var bg_half4: float = prompt.get_bg_half_height() if prompt else 0.0
	return global_position.y - 26.0 - bg_half4

func is_interactable() -> bool:
	return locked

func get_interact_radius() -> float:
	return 40.0

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func _on_body_entered(b):
	if b and b.is_in_group("enemies") and b.has_method("set_on_ladder"):
		b.set_on_ladder(true)
	if b and b.is_in_group("player"):
		if b.has_method("set_near_ladder"):
			b.set_near_ladder(not locked)
		if b.has_method("set_current_ladder"):
			b.set_current_ladder(self)

func _on_body_exited(b):
	if b and b.is_in_group("enemies") and b.has_method("set_on_ladder"):
		b.set_on_ladder(false)
	if b and b.is_in_group("player"):
		if b.has_method("set_near_ladder"):
			b.set_near_ladder(false)
		if b.has_method("set_on_ladder"):
			b.set_on_ladder(false)
	if b and b.has_method("set_current_ladder"):
		b.set_current_ladder(null)

func _build_ladder_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var rail := Color(0.5, 0.3, 0.14, 1.0)
	var rung1 := Color(0.76, 0.62, 0.28, 1.0)
	var rung2 := Color(0.63, 0.49, 0.22, 1.0)
	var edge := Color(0.24, 0.14, 0.06, 1.0)
	var left_x: int = 1
	var right_x: int = max(tw - 2, 1)
	for y in range(th):
		for x in range(tw):
			var col := Color(0, 0, 0, 0)
			if x <= left_x or x >= right_x:
				col = rail
			elif y % 8 <= 1:
				col = rung1 if (int(y / 8.0) % 2) == 0 else rung2
			if col.a > 0.0 and (x == 0 or x == tw - 1):
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _build_coin_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var edge := Color(0.12, 0.12, 0.12, 1.0)
	var c1 := Color(1.0, 0.86, 0.24, 1.0)
	var c2 := Color(0.86, 0.66, 0.12, 1.0)
	for y in range(th):
		for x in range(tw):
			var nx: float = (float(x) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
			var ny: float = (float(y) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
			var inside: bool = nx * nx + ny * ny <= 1.0
			if not inside:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := c1 if ((int(x / 2.0) + int(y / 2.0)) % 2) == 0 else c2
			var near_edge: bool = x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if not near_edge:
				var nx_l: float = (float(x - 1) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var nx_r: float = (float(x + 1) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var ny_u: float = (float(y - 1) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				var ny_d: float = (float(y + 1) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				near_edge = nx_l * nx_l + ny * ny > 1.0 or nx_r * nx_r + ny * ny > 1.0 or nx * nx + ny_u * ny_u > 1.0 or nx * nx + ny_d * ny_d > 1.0
			if near_edge:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

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
			var stripe: bool = abs(dx + dy) <= 1.0 and r2 <= ban_outer * ban_outer
			if stripe:
				col = ban
			var body: bool = y >= body_top and y <= body_bottom and x >= body_left and x <= body_right
			var shackle: bool = y >= shackle_top and y <= shackle_bottom and x >= shackle_left and x <= shackle_right and (y <= shackle_top + 1 or y >= shackle_bottom - 1)
			var shackle_sides: bool = y >= shackle_top and y <= shackle_bottom and (x == shackle_left or x == shackle_right) and y >= shackle_top + 1 and y <= shackle_bottom - 1
			if body or shackle or shackle_sides:
				var shade := mid if ((x + y) % 2) == 0 else dark
				if y < int(th / 2.0) and ((x + y) % 3 == 0):
					shade = hi
				col = shade
				if x == body_left or x == body_right or y == body_top or y == body_bottom:
					col = edge
			var keyhole_circle: bool = (x - key_cx) * (x - key_cx) + (y - key_cy) * (y - key_cy) <= 4
			var keyhole_stem: bool = x == key_cx and y >= key_cy + 2 and y <= key_cy + 5
			if keyhole_circle or keyhole_stem:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
