extends Area2D

@export var prompt_offset: Vector2 = Vector2(0, -20)
@export var ring_offset: Vector2 = Vector2(0, -28)

var opened: bool = false
var prompt
var chest_sprite: Sprite2D
var ui_active: bool = false
var chest_type: String = "password"
var password_code: String = "7355"
var collider_w: float = 20.0
var collider_h: float = 12.0
var explode_damage: int = 20
var explode_tex: Texture2D = preload("res://assets/vfx/fx_bullet_hit.png")

func _get_const_float(key: String, default_val: float) -> float:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_float"):
		return float(root.call("get_const_float", key, default_val))
	return default_val

func _get_const_string(key: String, default_val: String) -> String:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_string"):
		return String(root.call("get_const_string", key, default_val))
	return default_val

func _ready():
	password_code = _get_const_string("password_chest.code", password_code)
	collider_w = _get_const_float("password_chest.collider_width", collider_w)
	collider_h = _get_const_float("password_chest.collider_height", collider_h)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(collider_w, collider_h)
	cs.shape = shape
	add_child(cs)
	var poly := Polygon2D.new()
	poly.color = Color(0.2, 0.6, 0.8, 1.0)
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
	collision_layer = 8
	collision_mask = 1

func _process(delta):
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt:
		prompt.visible = target_ok and not opened
	if prompt and prompt.visible:
		var prompt_y: float = _get_prompt_y()
		prompt.set_world_position(Vector2(global_position.x, prompt_y))

func is_interactable() -> bool:
	return not opened

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func try_interact(_p):
	if opened or ui_active:
		return
	ui_active = true
	var PromptScript := preload("res://scripts/ui/PasswordPrompt.gd")
	var ui = PromptScript.new()
	get_tree().get_root().add_child(ui)
	if ui is CanvasItem:
		(ui as CanvasItem).z_index = 10000
		(ui as CanvasItem).z_as_relative = false
	if ui.has_method("open"):
		ui.open()
	ui.submitted.connect(_on_password_submitted.bind(ui))
	ui.tree_exited.connect(_on_ui_closed)

func _on_password_submitted(code: String, ui):
	if code == password_code:
		_drop_reward()
		opened = true
		if ui and ui.is_inside_tree():
			ui.queue_free()
		queue_free()
	else:
		_explode_wrong_password(ui)

func _on_ui_closed():
	ui_active = false

func _explode_wrong_password(ui):
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p := players[0]
		if p and p.has_method("take_damage"):
			p.call("take_damage", explode_damage)
	_spawn_explosion_vfx()
	opened = true
	if ui and ui.has_method("close_forced"):
		ui.call("close_forced")
	elif ui and ui.is_inside_tree():
		ui.queue_free()
	queue_free()

func _spawn_explosion_vfx():
	var Ring: Script = preload("res://scripts/effects/PulseRing.gd")
	var fx: Node2D = Ring.new() as Node2D
	get_tree().get_root().add_child(fx)
	fx.global_position = global_position
	fx.radius = 48.0
	fx.thickness = 6.0
	fx.color = Color(1.0, 0.55, 0.2, 0.85)
	_spawn_burst(explode_tex, 0.18, Vector2(0.8, 0.8), Vector2(2.2, 2.2), Color(1.0, 0.7, 0.3, 0.95))
	_spawn_burst(explode_tex, 0.22, Vector2(0.6, 0.6), Vector2(1.8, 1.8), Color(1.0, 0.35, 0.2, 0.8))

func _spawn_burst(tex: Texture2D, life: float, from_scale: Vector2, to_scale: Vector2, tint: Color):
	if tex == null:
		return
	var n := Node2D.new()
	n.global_position = global_position
	n.z_index = 230
	get_tree().get_root().add_child(n)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.modulate = tint
	s.scale = from_scale
	n.add_child(s)
	var tw := n.create_tween()
	tw.parallel().tween_property(s, "scale", to_scale, life)
	tw.parallel().tween_property(s, "modulate:a", 0.0, life)
	tw.tween_callback(n.queue_free)

func _drop_reward():
	var root := get_tree().get_root().get_node("GameRoot")
	var collectible_id: String = ""
	if root and root.has_method("get_best_collectible_drop"):
		collectible_id = String(root.call("get_best_collectible_drop"))
	if collectible_id != "":
		_spawn_collectible_choice()
	else:
		_spawn_upgrade()

func _spawn_collectible_id(id: String):
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "collectible_id"
	item.collectible_id = id
	item.amount = 1
	get_parent().add_child(item)
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	item.global_position = _clamp_drop_position(global_position.x, item_half)
	item.z_index = 30

func _spawn_collectible_choice():
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "collectible"
	item.amount = 1
	get_parent().add_child(item)
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	item.global_position = _clamp_drop_position(global_position.x, item_half)
	item.z_index = 30

func _spawn_upgrade():
	var root_upg := get_tree().get_root().get_node("GameRoot")
	var opts: Array = []
	if root_upg and root_upg.has_method("get_weighted_upgrade_choices"):
		opts = root_upg.call("get_weighted_upgrade_choices", null, 1)
	if opts.size() == 0:
		opts = ["bullet_damage"]
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = String(opts[0])
	item.amount = 1
	get_parent().add_child(item)
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	item.global_position = _clamp_drop_position(global_position.x, item_half)
	item.z_index = 30

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
	var rx: float = clamp(px_pre, min_x, max_x)
	var half_h: float = max(1.0, item_half)
	var ry: float = (y_top - half_h) if used_platform else global_position.y
	return Vector2(rx, ry)

func _build_chest_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var wood1 := Color(0.2, 0.55, 0.75, 1.0)
	var wood2 := Color(0.12, 0.42, 0.62, 1.0)
	var edge := Color(0.06, 0.2, 0.32, 1.0)
	var metal := Color(0.85, 0.9, 1.0, 1.0)
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
