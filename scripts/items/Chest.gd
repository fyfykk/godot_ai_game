extends Area2D

@export var opening_time: float = 5.0
@export var prompt_offset: Vector2 = Vector2(0, -20)
@export var ring_offset: Vector2 = Vector2(0, -28)

var opening: bool = false
var progress: float = 0.0
var opener: Node2D = null
var start_pos: Vector2 = Vector2.ZERO
var opened: bool = false
var open_count: int = 0
var drop_plan: Array = []

var prompt
var ring: Node2D
var chest_sprite: Sprite2D
var chest_type: String = "normal"
var max_opens: int = 3
var interact_cancel_move: float = 2.0
var ring_radius: float = 16.0
var ring_thickness: float = 4.0
var drop_count_min: int = 1
var drop_count_max: int = 3
var coin_drop_min: int = 10
var coin_drop_max: int = 50
var drop_offset_min: float = 28.0
var drop_offset_max: float = 64.0

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
	opening_time = _get_const_float("chest.open_time", opening_time)
	max_opens = _get_const_int("chest.max_opens", max_opens)
	interact_cancel_move = _get_const_float("chest.interact_cancel_move", interact_cancel_move)
	ring_radius = _get_const_float("chest.ring_radius", ring_radius)
	ring_thickness = _get_const_float("chest.ring_thickness", ring_thickness)
	drop_count_min = _get_const_int("chest.drop_count_min", drop_count_min)
	drop_count_max = _get_const_int("chest.drop_count_max", drop_count_max)
	coin_drop_min = _get_const_int("chest.coin_drop_min", coin_drop_min)
	coin_drop_max = _get_const_int("chest.coin_drop_max", coin_drop_max)
	drop_offset_min = _get_const_float("chest.drop_offset_min", drop_offset_min)
	drop_offset_max = _get_const_float("chest.drop_offset_max", drop_offset_max)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 12)
	cs.shape = shape
	add_child(cs)
	var poly := Polygon2D.new()
	poly.color = Color(0.8, 0.6, 0.2, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-10, -6), Vector2(10, -6), Vector2(10, 6), Vector2(-10, 6)])
	poly.visible = false
	add_child(poly)
	chest_sprite = Sprite2D.new()
	chest_sprite.texture = _build_chest_texture(20, 12)
	chest_sprite.centered = true
	chest_sprite.z_index = 1
	chest_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(chest_sprite)
	var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
	prompt = PromptScript.new()
	prompt.key_text = "E"
	add_child(prompt)
	add_to_group("chest")
	var RingScript := preload("res://scripts/ui/ProgressCircle.gd")
	ring = RingScript.new()
	add_child(ring)
	ring.radius = ring_radius
	ring.thickness = ring_thickness
	ring.show_label = false
	ring.position = ring_offset + Vector2(0, 6)
	ring.visible = false
	collision_layer = 8
	collision_mask = 1
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	pass

func _process(delta):
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt and is_instance_valid(prompt):
		prompt.visible = target_ok
	if prompt and is_instance_valid(prompt) and prompt.visible:
		var prompt_y: float = _get_prompt_y()
		prompt.set_world_position(Vector2(global_position.x, prompt_y))
	if opening and opener != null and is_instance_valid(opener):
		var cur_pos := opener.global_position
		if cur_pos.distance_to(start_pos) > interact_cancel_move:
			_cancel_open()
			return
		progress += delta
		var r: float = clamp(progress / opening_time, 0.0, 1.0)
		if ring:
			ring.set_ratio(r)
		if progress >= opening_time:
			_finish_open()

func _on_body_entered(b):
	if opened:
		return
	if b and b.is_in_group("player"):
		pass

func _on_body_exited(b):
	if b and b.is_in_group("player"):
		_cancel_open()

func try_interact(p):
	if opened:
		return
	if not opening:
		opening = true
		progress = 0.0
		opener = p
		start_pos = p.global_position
		if ring:
			ring.visible = true
			ring.set_ratio(0.0)
			var lh := _get_layer_height()
			ring.position = Vector2(0, -lh * 0.5)

func _cancel_open():
	opening = false
	progress = 0.0
	opener = null
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
	return not opened

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func _preplan_loot():
	var root := get_tree().get_root().get_node("GameRoot")
	if root and root.has_method("register_chest_plan"):
		drop_plan = root.call("register_chest_plan")
	else:
		drop_plan = []
func set_drop_plan(p):
	drop_plan = p

func _finish_open():
	opening = false
	if ring:
		ring.visible = false
	_drop_items_once()
	open_count += 1
	if open_count >= max_opens:
		opened = true
		queue_free()

func _drop_items_once():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var items := []
	if drop_plan.size() > open_count:
		items = drop_plan[open_count]
	else:
		var root := get_tree().get_root().get_node("GameRoot")
		if root and root.has_method("ensure_chest_loot_initialized"):
			root.call("ensure_chest_loot_initialized")
			if drop_plan.size() > open_count:
				items = drop_plan[open_count]
			else:
				var count := rng.randi_range(drop_count_min, drop_count_max)
				for i in range(count):
					items.append({"cat": 1, "coin": rng.randi_range(coin_drop_min, coin_drop_max)})
				for i in range(items.size()):
					_spawn_planned_item(items[i], i, opener)
				return
		var count := rng.randi_range(drop_count_min, drop_count_max)
		for i in range(count):
			items.append({"cat": 1, "coin": rng.randi_range(coin_drop_min, coin_drop_max)})
	for i in range(items.size()):
		_spawn_planned_item(items[i], i, opener)

func _spawn_planned_item(entry: Dictionary, idx: int, p: Node2D):
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var cat := int(entry.get("cat", 1))
	var coin_val := int(entry.get("coin", 0))
	if cat == 1:
		var root_upg := get_tree().get_root().get_node("GameRoot")
		var opts: Array = []
		if root_upg and root_upg.has_method("get_weighted_upgrade_choices"):
			opts = root_upg.call("get_weighted_upgrade_choices", p, 1)
		if opts.size() == 0:
			opts = ["bullet_damage"]
		item.kind = String(opts[0])
		item.amount = 1
	elif cat == 2:
		var val := coin_val
		var ok_val := val
		var root2 := get_tree().get_root().get_node("GameRoot")
		if root2 and root2.has_method("can_drop_coin"):
			if not root2.call("can_drop_coin", val):
				cat = 1
			else:
				ok_val = val
				if root2.has_method("register_coin_drop"):
					root2.call("register_coin_drop", ok_val)
		item.kind = "coin"
		item.value = ok_val
	else:
		item.kind = "collectible"
		item.amount = 1
		var root3 := get_tree().get_root().get_node("GameRoot")
		if root3 and root3.has_method("can_drop_collectible"):
			if not root3.call("can_drop_collectible"):
				item.kind = "upgrade_choice"
				item.amount = 1
	get_parent().add_child(item)
	var base_x: float = global_position.x
	var side: float = -1.0 if (idx % 2) == 0 else 1.0
	var off: float = rng.randf_range(drop_offset_min, drop_offset_max)
	var px_pre: float = base_x + side * off
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	var clamped := _clamp_drop_position(px_pre, item_half)
	item.global_position = clamped
	item.z_index = 30

func _get_layer_height() -> float:
	var level := get_parent()
	if level and level.has_node("Generator"):
		var gen := level.get_node("Generator")
		if gen:
			return float(gen.layer_height)
	return 80.0

func _clamp_drop_position(px_pre: float, item_half: float) -> Vector2:
	var level := get_parent()
	var tm: float = 0.0
	if level and level.has_method("get_top_margin"):
		tm = float(level.get_top_margin())
	var lh: float = _get_layer_height()
	var layer_idx: int = int(clamp(round((global_position.y - tm) / lh), 0.0, 99.0))
	var min_x: float = 40.0
	var max_x: float = 100000.0
	var y_top: float = global_position.y
	var used_platform: bool = false
	if level and level.has_method("_get_platform_body_for_layer") and level.has_method("_get_platform_width") and level.has_method("_get_platform_height"):
		var plat = level.call("_get_platform_body_for_layer", int(layer_idx))
		if plat and plat is Node2D:
			var pw: float = float(level.call("_get_platform_width", plat))
			var ph: float = float(level.call("_get_platform_height", plat))
			if pw > 0.0 and ph > 0.0:
				var cx: float = (plat as Node2D).global_position.x
				var cy: float = (plat as Node2D).global_position.y
				var hw: float = pw * 0.5
				min_x = cx - hw + 24.0
				max_x = cx + hw - 24.0
				y_top = cy - ph * 0.5
				used_platform = true
	# room-local clamp around chest to keep in same room
	var ROOM_HALF: float = 96.0
	var room_min: float = clamp(global_position.x - ROOM_HALF, min_x, max_x)
	var room_max: float = clamp(global_position.x + ROOM_HALF, min_x, max_x)
	# do not cross doors: constrain to chest side relative to nearest door in intended direction
	if level:
		var plat2 = level.call("_get_platform_body_for_layer", int(layer_idx))
		if plat2 and plat2 is Node2D:
			var doors: Array = []
			for c in plat2.get_children():
				if c and c is Node2D and (c as Node2D).is_in_group("door"):
					doors.append(c)
			if doors.size() > 0:
				var chest_x: float = global_position.x
				var dir_sign: float = sign(px_pre - chest_x)
				if dir_sign != 0.0:
					var nearest_door_x: float = chest_x
					var found: bool = false
					var best_dist: float = INF
					for d in doors:
						var dx: float = (d as Node2D).global_position.x
						var between: bool = (dir_sign > 0.0 and dx > chest_x and dx <= px_pre) or (dir_sign < 0.0 and dx < chest_x and dx >= px_pre)
						if between:
							var dist: float = abs(dx - chest_x)
							if dist < best_dist:
								best_dist = dist
								nearest_door_x = dx
								found = true
					if found:
						var margin: float = 8.0
						if dir_sign > 0.0:
							room_max = min(room_max, nearest_door_x - margin)
						else:
							room_min = max(room_min, nearest_door_x + margin)
	# clamp and set slightly above platform top so item rests on surface
	var rx: float = clamp(px_pre, room_min, room_max)
	var half_h: float = max(1.0, item_half)
	var ry: float = (y_top - half_h) if used_platform else global_position.y
	return Vector2(rx, ry)

func _build_chest_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var wood1 := Color(0.7, 0.48, 0.2, 1.0)
	var wood2 := Color(0.55, 0.35, 0.14, 1.0)
	var edge := Color(0.24, 0.15, 0.06, 1.0)
	var metal := Color(0.92, 0.82, 0.42, 1.0)
	for y in range(th):
		for x in range(tw):
			var col := wood1 if ((x / 3 + y / 2) % 2) == 0 else wood2
			if x == 0 or x == tw - 1 or y == 0 or y == th - 1:
				col = edge
			if y == th / 2:
				col = edge
			img.set_pixel(x, y, col)
	var lock_x: int = tw / 2
	var lock_y: int = th / 2 + 1
	if lock_x >= 1 and lock_x < tw - 1 and lock_y >= 1 and lock_y < th - 1:
		img.set_pixel(lock_x, lock_y, metal)
		img.set_pixel(lock_x, lock_y - 1, metal)
	return ImageTexture.create_from_image(img)
