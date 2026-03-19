extends CharacterBody2D
signal died

@export var speed: float = 180.0
@export var jump_velocity: float = -500.0
var attack_modules: Array = []

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_hp: int = 50
var hp: int = 50
var invul_timer: float = 1.2
var invul_on_hit: float = 0.2
@onready var poly: Polygon2D = $Poly
@onready var player_sprite: Sprite2D = $PlayerSprite
@export var ladder_speed: float = 120.0
var on_ladder: bool = false
var current_ladder: Node2D = null
var near_ladder: bool = false
var sprite_outline: Sprite2D = null
var interact_target: Node2D = null
var e_was_down: bool = false
var walk_anim_time: float = 0.0
var walk_anim_speed: float = 9.0
var gun_sprite: Sprite2D = null
var sword_sprites: Array = []
var orb_sprite: Sprite2D = null
var orb_phase: float = 0.0
var sword_phase: float = 0.0
var sword_slash_time: float = 0.0
var sword_slash_duration: float = 0.18
var sword_slash_dir: float = 1.0
var gun_aim_dir: Vector2 = Vector2.RIGHT
var gun_aim_time: float = 0.0
var gun_aim_duration: float = 0.12
var gun_aim_lock: bool = false

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
	add_to_group("player")
	speed = _get_const_float("player.base_speed", speed)
	max_hp = _get_const_int("player.base_hp", max_hp)
	hp = max_hp
	ladder_speed = _get_const_float("player.ladder_speed", ladder_speed)
	invul_timer = _get_const_float("player.invul_initial", invul_timer)
	invul_on_hit = _get_const_float("player.invul_on_hit", invul_on_hit)
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 24)
		cs.shape = rect
	# layers: player on 1; collides with enemy(2) and platforms(4)
	collision_layer = 1
	collision_mask = 12
	if player_sprite:
		player_sprite.texture = _build_player_sprite_sheet()
		player_sprite.hframes = 4
		player_sprite.vframes = 1
		player_sprite.frame = 0
		player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_attack_visuals()
	_init_attacks()
	_setup_camera_view()
	_refresh_visual_alignment()
	_refresh_attack_visuals()
	_add_outline()

func _physics_process(delta):
	invul_timer = max(invul_timer - delta, 0.0)
	if invul_timer <= 0.0:
		_set_visual_color(Color(1, 1, 1, 1))
	_update_attacks(delta)
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.get("input_locked") != null and bool(root.get("input_locked")):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir: float = 0.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if player_sprite and abs(dir) > 0.0:
		player_sprite.flip_h = dir < 0.0
		if sprite_outline:
			sprite_outline.flip_h = player_sprite.flip_h
	if not on_ladder and near_ladder:
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			set_on_ladder(true)
	if on_ladder and not near_ladder:
		set_on_ladder(false)
	_update_interact_target()
	var e_down: bool = Input.is_key_pressed(KEY_E)
	var e_just: bool = e_down and not e_was_down
	if e_just:
		if interact_target != null and interact_target.has_method("try_interact"):
			interact_target.try_interact(self)
	e_was_down = e_down
	if on_ladder:
		velocity.x = dir * speed * 0.5
		var vdir := 0.0
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			vdir -= 1.0
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			vdir += 1.0
		velocity.y = vdir * ladder_speed
	else:
		velocity.x = dir * speed
		if not is_on_floor():
			velocity.y += gravity * delta
	_update_walk_anim(delta, dir)
	_update_attack_visuals(delta, dir)
	# disable jump
	move_and_slide()
	_update_camera_view()
	if on_ladder and current_ladder != null:
		var h = current_ladder.get("height")
		if h != null:
			var half_h: float = float(h) * 0.5
			var cy: float = current_ladder.global_position.y
			var min_y: float = cy - half_h
			var max_y: float = cy + half_h
			var char_half_h: float = 12.0
			var cs: CollisionShape2D = $CollisionShape2D
			if cs and cs.shape and cs.shape is RectangleShape2D:
				char_half_h = (cs.shape as RectangleShape2D).size.y * 0.5
			var ny: float = clamp(global_position.y, min_y - char_half_h, max_y - char_half_h)
			global_position.y = ny
			var bottom_y: float = global_position.y + char_half_h
			var going_up: bool = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or velocity.y < 0.0
			if going_up and bottom_y <= min_y + 0.1:
				set_on_ladder(false)

func _init_attacks():
	attack_modules.clear()
	var BulletAttack := preload("res://scripts/attacks/BulletAttack.gd")
	var mod = BulletAttack.new()
	mod.setup(self)
	attack_modules.append(mod)

func _update_attacks(delta: float):
	for m in attack_modules:
		if m:
			m.update(delta, self)

func _update_interact_target():
	var candidates := []
	candidates.append_array(get_tree().get_nodes_in_group("chest"))
	candidates.append_array(get_tree().get_nodes_in_group("medkit"))
	candidates.append_array(get_tree().get_nodes_in_group("exit"))
	candidates.append_array(get_tree().get_nodes_in_group("door"))
	candidates.append_array(get_tree().get_nodes_in_group("ladder"))
	candidates.append_array(get_tree().get_nodes_in_group("pickup"))
	var best: Node2D = null
	var best_d: float = 1e18
	var best_x: float = 0.0
	for c in candidates:
		if c and c is Node2D:
			if c.has_method("is_interactable") and not bool(c.call("is_interactable")):
				continue
			var pos: Vector2 = (c as Node2D).global_position
			if c.has_method("get_interact_position"):
				pos = c.call("get_interact_position", global_position)
			var r: float = 28.0
			if c.has_method("get_interact_radius"):
				r = float(c.call("get_interact_radius"))
			var dx: float = pos.x - global_position.x
			var dy: float = pos.y - global_position.y
			var d := dx * dx + dy * dy
			if d > r * r:
				continue
			if d < best_d - 0.0001:
				best_d = d
				best = c
				best_x = pos.x
			elif abs(d - best_d) <= 0.0001:
				if pos.x < best_x:
					best = c
					best_x = pos.x
	interact_target = best

func is_interact_target(n: Node) -> bool:
	return interact_target == n

func apply_pickup(kind: String, amount: int) -> bool:
	if kind.begins_with("collectible_id:"):
		var cid := kind.replace("collectible_id:", "")
		var root0 := get_tree().get_root().get_node("GameRoot")
		if root0 and root0.has_method("add_collectible_direct"):
			return bool(root0.call("add_collectible_direct", cid))
		return false
	if kind == "bullet_damage":
		_var_show_choice()
		return true
	if kind == "bullet_interval":
		_var_show_choice()
		return true
	if kind == "coin":
		var root := get_tree().get_root().get_node("GameRoot")
		if root and root.has_method("add_run_coins"):
			root.add_run_coins(int(amount))
		return true
	if kind == "collectible":
		var root := get_tree().get_root().get_node("GameRoot")
		if root and root.has_method("add_collectible"):
			root.add_collectible(int(amount), self)
		return true
	if kind == "collectible_note":
		var rootn := get_tree().get_root().get_node("GameRoot")
		if rootn and rootn.has_method("add_collectible_with_note"):
			rootn.call("add_collectible_with_note", self, 0.5)
		return true
	if kind == "upgrade_choice":
		_var_show_choice()
		return true
	if kind == "collectible_boss":
		var root2 := get_tree().get_root().get_node("GameRoot")
		if root2 and root2.has_method("add_boss_collectible"):
			root2.add_boss_collectible(self)
		return true
	if kind == "attack_melee":
		_var_show_choice()
		return true
	if kind == "attack_magic":
		_var_show_choice()
		return true
	if kind == "melee_damage" or kind == "melee_interval" or kind == "melee_range":
		_var_show_choice()
		return true
	if kind == "magic_damage" or kind == "magic_interval" or kind == "magic_radius":
		_var_show_choice()
		return true
	return true
func _var_show_choice():
	var ui := get_tree().get_root().get_node("GameRoot/UI")
	if ui and ui.has_method("show_upgrade_choices"):
		ui.show_upgrade_choices(self)

func apply_upgrade_kind(k: String):
	if k == "bullet_damage":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "子弹攻击":
				var cur = m.get("damage")
				if cur != null:
					m.upgrade({"damage": int(cur) + 1})
				return
	if k == "bullet_interval":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "子弹攻击":
				var cur_i = m.get("interval")
				if cur_i != null:
					m.upgrade({"interval": max(float(cur_i) - 0.1, 0.1)})
				return
	if k == "attack_melee":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "近战攻击":
				return
		var Melee := preload("res://scripts/attacks/MeleeAttack.gd")
		var mod = Melee.new()
		mod.setup(self)
		attack_modules.append(mod)
		var root := get_tree().get_root().get_node("GameRoot")
		if root:
			if root.has_method("apply_base_attack_stats_for_target"):
				root.call("apply_base_attack_stats_for_target", "melee")
			if root.has_method("apply_collectible_effects_for_target"):
				root.call("apply_collectible_effects_for_target", "melee")
		_refresh_attack_visuals()
		return
	if k == "attack_magic":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "范围魔法":
				return
		var Magic := preload("res://scripts/attacks/MagicAreaAttack.gd")
		var mod2 = Magic.new()
		mod2.setup(self)
		attack_modules.append(mod2)
		var root2 := get_tree().get_root().get_node("GameRoot")
		if root2:
			if root2.has_method("apply_base_attack_stats_for_target"):
				root2.call("apply_base_attack_stats_for_target", "magic")
			if root2.has_method("apply_collectible_effects_for_target"):
				root2.call("apply_collectible_effects_for_target", "magic")
		_refresh_attack_visuals()
		return
	if k == "melee_damage":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "近战攻击":
				var cur = m.get("damage")
				if cur != null:
					m.upgrade({"damage": int(cur) + 1})
				return
	if k == "melee_interval":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "近战攻击":
				var cur_i = m.get("interval")
				if cur_i != null:
					m.upgrade({"interval": max(float(cur_i) - 0.1, 0.4)})
				return
	if k == "melee_range":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "近战攻击":
				var cur_r = m.get("range")
				if cur_r != null:
					m.upgrade({"range": float(cur_r) + 4.0})
				return
	if k == "magic_damage":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "范围魔法":
				var cur = m.get("damage")
				if cur != null:
					m.upgrade({"damage": int(cur) + 1})
				return
	if k == "magic_interval":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "范围魔法":
				var cur_i = m.get("interval")
				if cur_i != null:
					m.upgrade({"interval": max(float(cur_i) - 0.1, 0.5)})
				return
	if k == "magic_radius":
		for m in attack_modules:
			if m and m.has_method("get_display_name") and m.get_display_name() == "范围魔法":
				var cur_r = m.get("radius")
				if cur_r != null:
					m.upgrade({"radius": float(cur_r) + 8.0})
				return

func has_attack(name: String) -> bool:
	for m in attack_modules:
		if m and m.has_method("get_display_name") and m.get_display_name() == name:
			return true
	return false
func set_on_ladder(v: bool):
	on_ladder = v
	if v:
		collision_mask = 0
	else:
		collision_mask = 12

func set_current_ladder(l):
	current_ladder = l as Node2D

func set_near_ladder(v: bool):
	near_ladder = v

func take_damage(d: int):
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	var cheat_invincible := root and root.has_method("is_cheat_invincible") and bool(root.call("is_cheat_invincible"))
	if invul_timer > 0.0:
		return
	hp -= d
	_set_visual_color(Color(1, 1, 0.2, 1))
	invul_timer = invul_on_hit
	if hp <= 0:
		if cheat_invincible:
			hp = max_hp
			return
		emit_signal("died")
		queue_free()

func heal_half(ratio: float = 0.5):
	var add_hp: int = int(float(max_hp) * ratio)
	hp = min(hp + add_hp, max_hp)

func _setup_camera_view():
	var cam: Camera2D = $Camera2D
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var layer_h: float = 80.0
	var level := get_tree().get_root().get_node("GameRoot/Level")
	if level and level.has_node("Generator"):
		var gen := level.get_node("Generator")
		if gen and gen.has_method("get") and gen.get("layer_height") != null:
			layer_h = float(gen.layer_height)
	var target_h: float = layer_h * 1.8
	var zoom_y: float = vp.y / max(target_h, 1.0)
	cam.zoom = Vector2(zoom_y, zoom_y)
	cam.position = Vector2(0.0, layer_h * 0.35)

func _update_camera_view():
	var cam: Camera2D = $Camera2D
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var level := get_tree().get_root().get_node("GameRoot/Level")
	var layer_h: float = 80.0
	var layers_cnt: int = 4
	var top_margin: float = 0.0
	var width_w: float = 1024.0
	if level:
		if level.has_method("get_top_margin"):
			top_margin = float(level.call("get_top_margin"))
		if level.has_node("Generator"):
			var gen = level.get_node("Generator")
			if gen and gen.has_method("get"):
				if gen.get("layer_height") != null:
					layer_h = float(gen.layer_height)
				if gen.get("layers") != null:
					layers_cnt = int(gen.layers)
				if gen.get("width") != null:
					width_w = float(gen.width)
	var target_h: float = layer_h * 1.8
	var zoom_y: float = vp.y / max(target_h, 1.0)
	cam.zoom = Vector2(zoom_y, zoom_y)
	var view_h: float = target_h
	var view_w: float = vp.x / zoom_y
	var half_w: float = view_w * 0.5
	var layer_idx: int = int(clamp(floor((global_position.y - top_margin) / layer_h), 0.0, float(layers_cnt - 1)))
	var desired_center_y: float = global_position.y - view_h * (1.0 / 6.0)
	var min_x: float = 80.0
	var max_x: float = width_w - 80.0
	var desired_center_x: float = clamp(global_position.x, min_x + half_w, max_x - half_w)
	cam.position = Vector2(desired_center_x - global_position.x, desired_center_y - global_position.y)

func _refresh_visual_alignment():
	var cs: CollisionShape2D = $CollisionShape2D
	var body_half_h: float = 12.0
	if cs and cs.shape and cs.shape is RectangleShape2D:
		body_half_h = (cs.shape as RectangleShape2D).size.y * 0.5
	var hb: Node2D = $HealthBar
	if player_sprite and player_sprite.texture:
		var bounds: Vector2 = _get_texture_opaque_bounds_y(player_sprite.texture)
		var tex_h: float = max(player_sprite.texture.get_size().y, 1.0)
		var bottom_from_center: float = (bounds.y + 1.0 - tex_h * 0.5) * player_sprite.scale.y
		var top_from_center: float = (bounds.x - tex_h * 0.5) * player_sprite.scale.y
		player_sprite.position.y = body_half_h - bottom_from_center
		if hb and hb.has_method("set"):
			hb.set("offset", Vector2(0.0, player_sprite.position.y + top_from_center - 10.0))
		return
	if poly and poly.polygon.size() > 0:
		var min_y: float = INF
		var max_y: float = -INF
		for p in poly.polygon:
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)
		var bottom_poly: float = max_y * poly.scale.y
		var top_poly: float = min_y * poly.scale.y
		poly.position.y = body_half_h - bottom_poly
		if hb and hb.has_method("set"):
			hb.set("offset", Vector2(0.0, poly.position.y + top_poly - 10.0))

func _get_texture_opaque_bounds_y(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2(0.0, 0.0)
	var size: Vector2 = tex.get_size()
	var h: int = int(size.y)
	var w: int = int(size.x)
	if h <= 0 or w <= 0:
		return Vector2(0.0, 0.0)
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return Vector2(0.0, float(h - 1))
	var top: int = -1
	var bottom: int = -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.01:
				if top < 0:
					top = y
				bottom = y
	if top < 0:
		return Vector2(0.0, float(h - 1))
	return Vector2(float(top), float(bottom))

func _add_outline():
	if player_sprite and player_sprite.texture:
		sprite_outline = Sprite2D.new()
		sprite_outline.texture = player_sprite.texture
		sprite_outline.centered = player_sprite.centered
		sprite_outline.offset = player_sprite.offset
		sprite_outline.region_enabled = player_sprite.region_enabled
		sprite_outline.region_rect = player_sprite.region_rect
		sprite_outline.hframes = player_sprite.hframes
		sprite_outline.vframes = player_sprite.vframes
		sprite_outline.frame = player_sprite.frame
		sprite_outline.frame_coords = player_sprite.frame_coords
		sprite_outline.modulate = Color(0, 0, 0, 0.85)
		sprite_outline.z_index = max(player_sprite.z_index - 1, 0)
		sprite_outline.scale = player_sprite.scale * Vector2(1.08, 1.08)
		sprite_outline.position = player_sprite.position
		sprite_outline.flip_h = player_sprite.flip_h
		add_child(sprite_outline)
		return
	var poly: Polygon2D = $Poly
	if poly == null:
		return
	var outline := Polygon2D.new()
	outline.polygon = poly.polygon
	outline.color = Color(0, 0, 0, 0.85)
	outline.z_index = max(poly.z_index - 1, 0)
	outline.scale = poly.scale * Vector2(1.08, 1.08)
	outline.position = poly.position
	add_child(outline)

func _set_visual_color(c: Color):
	if player_sprite:
		player_sprite.modulate = c
	if poly:
		poly.color = c

func play_sword_slash(dir: float):
	sword_slash_time = sword_slash_duration
	sword_slash_dir = 1.0 if dir >= 0.0 else -1.0

func set_gun_aim(dir: Vector2):
	if dir.length() <= 0.01:
		return
	gun_aim_dir = dir.normalized()
	gun_aim_time = gun_aim_duration
	gun_aim_lock = true

func get_muzzle_position() -> Vector2:
	if gun_sprite and gun_sprite.visible:
		if gun_aim_time > 0.0:
			return gun_sprite.global_position + gun_aim_dir * 10.0
		var facing_right: bool = true
		if player_sprite:
			facing_right = not player_sprite.flip_h
		var muzzle_offset := Vector2(10.0 if facing_right else -10.0, 0.0)
		return gun_sprite.global_position + muzzle_offset
	return global_position

func get_magic_origin() -> Vector2:
	if orb_sprite and orb_sprite.visible:
		return orb_sprite.global_position
	return global_position

func _find_aim_target() -> Node2D:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 160.0
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 2
	var res: Array = space.intersect_shape(params, 32)
	var best: Node2D = null
	var best_d: float = INF
	for r in res:
		var n: Node = r.get("collider")
		if n and n != self and n.is_in_group("enemies") and n is Node2D:
			var d: float = (n as Node2D).global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = n as Node2D
	return best

func _setup_attack_visuals():
	if gun_sprite == null:
		gun_sprite = Sprite2D.new()
		gun_sprite.texture = _build_gun_texture(18, 7)
		gun_sprite.centered = true
		gun_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gun_sprite.z_index = 12
		add_child(gun_sprite)
	if sword_sprites.size() == 0:
		for i in range(3):
			var s := Sprite2D.new()
			s.texture = _build_sword_texture(6, 16)
			s.centered = true
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.z_index = 9
			add_child(s)
			sword_sprites.append(s)
	if orb_sprite == null:
		orb_sprite = Sprite2D.new()
		orb_sprite.texture = _build_orb_texture(16, 16)
		orb_sprite.centered = true
		orb_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		orb_sprite.z_index = 13
		add_child(orb_sprite)

func _refresh_attack_visuals():
	var has_bullet: bool = has_attack("子弹攻击")
	var has_melee: bool = has_attack("近战攻击")
	var has_magic: bool = has_attack("范围魔法")
	if gun_sprite:
		gun_sprite.visible = has_bullet
	for s in sword_sprites:
		if s:
			s.visible = has_melee
	if orb_sprite:
		orb_sprite.visible = has_magic

func _update_attack_visuals(delta: float, dir: float):
	var facing_right: bool = dir >= 0.0
	if player_sprite:
		facing_right = not player_sprite.flip_h
	if gun_sprite and gun_sprite.visible:
		gun_aim_lock = false
		var target := _find_aim_target()
		if target:
			gun_aim_dir = (target.global_position - gun_sprite.global_position).normalized()
			gun_aim_time = gun_aim_duration
			gun_aim_lock = true
		gun_aim_time = max(gun_aim_time - delta, 0.0)
		var sway := sin(walk_anim_time * 0.8) * 1.0
		var gx: float = 0.0
		var gy: float = sway
		gun_sprite.position = player_sprite.position + Vector2(gx, gy)
		if gun_aim_time > 0.0 or gun_aim_lock:
			gun_sprite.flip_h = false
			gun_sprite.rotation = gun_aim_dir.angle()
		else:
			gun_sprite.flip_h = not facing_right
			gun_sprite.rotation = 0.0
	if sword_sprites.size() > 0 and sword_sprites[0].visible:
		sword_phase += delta * 2.0
		var behind_x: float = -8.0 if facing_right else 8.0
		var base_y: float = 2.0
		var slashing: bool = sword_slash_time > 0.0
		if slashing:
			sword_slash_time = max(sword_slash_time - delta, 0.0)
		for i in range(sword_sprites.size()):
			var s: Sprite2D = sword_sprites[i]
			if s == null:
				continue
			var bob := sin(sword_phase + float(i) * 1.1) * 1.4
			var oy: float = base_y + float(i - 1) * 4.0 + bob
			if slashing:
				var t: float = 1.0 - (sword_slash_time / sword_slash_duration)
				var behind := player_sprite.position + Vector2(-12.0 * sword_slash_dir, -2.0 + float(i) * 2.0)
				var front := player_sprite.position + Vector2(12.0 * sword_slash_dir, -6.0 + float(i) * 2.0)
				var arc_t: float = sin(t * PI * 0.5)
				s.position = behind.lerp(front, arc_t)
				s.rotation = (-1.4 + arc_t * 2.4) * sword_slash_dir
				s.z_index = 14
			else:
				s.position = player_sprite.position + Vector2(behind_x, oy)
				s.rotation = -0.4 if facing_right else 0.4
				s.z_index = 9
			s.flip_h = not facing_right
	if orb_sprite and orb_sprite.visible:
		orb_phase += delta * 2.2
		var ox: float = sin(orb_phase) * 4.0
		var oy: float = -26.0 + cos(orb_phase * 1.2) * 2.0
		orb_sprite.position = player_sprite.position + Vector2(ox, oy)

func _update_walk_anim(delta: float, dir: float):
	if player_sprite == null:
		return
	if on_ladder:
		player_sprite.frame = 0
		if sprite_outline:
			sprite_outline.frame = player_sprite.frame
		return
	var moving: bool = abs(dir) > 0.01
	if not moving:
		walk_anim_time = 0.0
		player_sprite.frame = 0
		if sprite_outline:
			sprite_outline.frame = player_sprite.frame
		return
	walk_anim_time += delta * walk_anim_speed
	var step: int = int(floor(walk_anim_time)) % 3
	player_sprite.frame = 1 + step
	if sprite_outline:
		sprite_outline.frame = player_sprite.frame

func _build_player_sprite_sheet() -> Texture2D:
	var frame_w: int = 16
	var frame_h: int = 24
	var frames: int = 4
	var img := Image.create(frame_w * frames, frame_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_player_frame(img, i * frame_w, 0, i)
	return ImageTexture.create_from_image(img)

func _draw_player_frame(img: Image, ox: int, oy: int, idx: int):
	var outline := Color(0.05, 0.05, 0.08, 1.0)
	var robe := Color(0.78, 0.8, 0.92, 1.0)
	var robe2 := Color(0.65, 0.7, 0.84, 1.0)
	var trim := Color(0.35, 0.38, 0.5, 1.0)
	var sash := Color(0.35, 0.1, 0.1, 1.0)
	var hair := Color(0.1, 0.1, 0.12, 1.0)
	var skin := Color(0.95, 0.84, 0.72, 1.0)
	var boot := Color(0.06, 0.06, 0.08, 1.0)
	var hat := Color(0.88, 0.72, 0.32, 1.0)
	var hat2 := Color(0.7, 0.56, 0.26, 1.0)
	var blade := Color(0.75, 0.82, 0.9, 1.0)
	var hilt := Color(0.55, 0.32, 0.16, 1.0)
	var leg_lx: int = 6
	var leg_rx: int = 9
	var arm_lx: int = 4
	var arm_rx: int = 11
	if idx == 1:
		leg_lx = 5
		leg_rx = 10
		arm_lx = 5
		arm_rx = 10
	elif idx == 3:
		leg_lx = 10
		leg_rx = 5
		arm_lx = 10
		arm_rx = 5
	_rect(img, ox + 7, oy + 0, 2, 1, hat2)
	_rect(img, ox + 6, oy + 1, 4, 1, hat2)
	_rect(img, ox + 5, oy + 2, 6, 1, hat2)
	_rect(img, ox + 4, oy + 3, 8, 1, hat)
	_rect(img, ox + 3, oy + 4, 10, 1, hat)
	_rect(img, ox + 2, oy + 5, 12, 1, hat)
	_rect(img, ox + 1, oy + 6, 14, 1, hat)
	_rect(img, ox + 2, oy + 7, 12, 1, hat)
	_rect(img, ox + 4, oy + 8, 8, 1, hat2)
	_rect(img, ox + 6, oy + 9, 4, 1, hat2)
	_rect(img, ox + 6, oy + 10, 4, 1, hair)
	_rect(img, ox + 6, oy + 12, 4, 2, robe2)
	_rect(img, ox + 5, oy + 14, 6, 5, robe)
	_rect(img, ox + 6, oy + 18, 4, 1, sash)
	_rect(img, ox + arm_lx + 1, oy + 12, 2, 4, robe2)
	_rect(img, ox + arm_rx - 1, oy + 12, 2, 4, robe2)
	_rect(img, ox + leg_lx, oy + 19, 2, 3, Color(0.08, 0.08, 0.1, 1.0))
	_rect(img, ox + leg_rx, oy + 19, 2, 3, Color(0.08, 0.08, 0.1, 1.0))
	_rect(img, ox + 11, oy + 12, 1, 6, blade)
	_rect(img, ox + 11, oy + 12, 2, 1, blade)
	_rect(img, ox + 10, oy + 16, 2, 1, hilt)
	_rect(img, ox + leg_lx, oy + 20, 2, 2, boot)
	_rect(img, ox + leg_rx, oy + 20, 2, 2, boot)

func _build_gun_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var metal := Color(0.08, 0.08, 0.1, 1.0)
	var dark := Color(0.18, 0.2, 0.24, 1.0)
	var barrel := Color(0.06, 0.06, 0.08, 1.0)
	var wood := Color(0.55, 0.32, 0.16, 1.0)
	_rect(img, 1, 3, 15, 2, metal)
	_rect(img, 13, 2, 4, 2, barrel)
	_rect(img, 2, 2, 3, 2, wood)
	_rect(img, 6, 3, 5, 2, wood)
	_rect(img, 11, 5, 2, 2, dark)
	_rect(img, 10, 4, 1, 2, dark)
	_rect(img, 4, 5, 2, 1, dark)
	_rect(img, 6, 5, 2, 2, wood)
	return ImageTexture.create_from_image(img)

func _build_sword_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var metal := Color(0.75, 0.8, 0.9, 1.0)
	var dark := Color(0.2, 0.22, 0.3, 1.0)
	var glow := Color(0.5, 0.9, 1.0, 1.0)
	var wood := Color(0.5, 0.3, 0.16, 1.0)
	_rect(img, 2, 1, 2, 11, metal)
	_rect(img, 2, 2, 1, 9, glow)
	_rect(img, 1, 12, 4, 1, dark)
	_rect(img, 2, 13, 2, 2, wood)
	return ImageTexture.create_from_image(img)

func _build_orb_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.95, 0.82, 0.28, 1.0)
	var gold_dark := Color(0.35, 0.25, 0.12, 1.0)
	var white := Color(0.96, 0.94, 0.88, 1.0)
	var black := Color(0.05, 0.05, 0.08, 1.0)
	var red := Color(0.85, 0.18, 0.18, 1.0)
	var cx: float = w * 0.5 - 0.5
	var cy: float = h * 0.5 - 0.5
	var r: float = min(w, h) * 0.5 - 0.5
	for y in range(h):
		for x in range(w):
			var sx: float = float(x) - cx
			var sy: float = float(y) - cy
			var adx: float = abs(sx)
			var ady: float = abs(sy)
			var maxd: float = max(adx, ady)
			if maxd > r:
				continue
			if adx + ady > r * 1.55:
				continue
			var d: float = sqrt(sx * sx + sy * sy)
			var ang: float = atan2(sy, sx)
			var col := black
			if d >= r * 0.88:
				col = gold_dark
			elif d >= r * 0.78:
				col = gold
			elif d >= r * 0.7:
				col = red
			elif d >= r * 0.62:
				col = black
				var seg := int(floor(((ang + PI) / TAU) * 24.0))
				if seg % 6 == 0:
					col = gold
			elif d >= r * 0.56:
				col = gold
			else:
				var curve: float = sy + sin(sx / max(r, 1.0) * PI) * r * 0.2
				col = white if curve >= 0.0 else black
				var top_dot: float = sqrt(sx * sx + (sy + r * 0.32) * (sy + r * 0.32))
				var bot_dot: float = sqrt(sx * sx + (sy - r * 0.32) * (sy - r * 0.32))
				if top_dot <= r * 0.16:
					col = black
				if bot_dot <= r * 0.16:
					col = white
			img.set_pixel(x, y, col)
	for i in range(8):
		var ang2: float = TAU * float(i) / 8.0 + 0.2
		var px2: int = int(round(cx + cos(ang2) * r * 0.8))
		var py2: int = int(round(cy + sin(ang2) * r * 0.8))
		if px2 >= 0 and py2 >= 0 and px2 < img.get_width() and py2 < img.get_height():
			img.set_pixel(px2, py2, red)
	for i3 in range(8):
		var ang3: float = TAU * float(i3) / 8.0
		var px3: int = int(round(cx + cos(ang3) * r * 0.95))
		var py3: int = int(round(cy + sin(ang3) * r * 0.95))
		if px3 >= 0 and py3 >= 0 and px3 < img.get_width() and py3 < img.get_height():
			img.set_pixel(px3, py3, gold_dark)
	img.set_pixel(int(cx), int(cy), red)
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)

func _outline_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for xx in range(w):
		var px := x + xx
		if px >= 0 and px < img.get_width():
			if y >= 0 and y < img.get_height():
				img.set_pixel(px, y, col)
			var by := y + h - 1
			if by >= 0 and by < img.get_height():
				img.set_pixel(px, by, col)
	for yy in range(h):
		var py := y + yy
		if py >= 0 and py < img.get_height():
			if x >= 0 and x < img.get_width():
				img.set_pixel(x, py, col)
			var bx := x + w - 1
			if bx >= 0 and bx < img.get_width():
				img.set_pixel(bx, py, col)
