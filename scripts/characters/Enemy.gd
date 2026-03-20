extends CharacterBody2D

@export var speed: float = 120.0
@export var hp: int = 5
@export var max_hp: int = 5
@export var damage: int = 1
@export var attack_cooldown: float = 0.8
@export var attack_range_x: float = 24.0
@export var attack_range_y: float = 14.0
@export var ladder_speed: float = 100.0
@export var base_tint: Color = Color(1, 1, 1, 1)
@export var use_global_stats: bool = true
@export var death_duration: float = 0.45
@export var enemy_kind: String = "jiangshi"

var target: Node2D = null
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_timer: float = 0.0
var hitbox: Area2D
var hitbox_shape: CollisionShape2D
var facing: int = 1
var range_vis: Polygon2D
var on_ladder: bool = false
var allow_ladder_enter: bool = false
var target_ladder: Node2D = null
var current_ladder: Node2D = null
var is_boss: bool = false
var enemy_sprite: Sprite2D = null
var sprite_outline: Sprite2D = null
var collider_w: float = 16.0
var collider_h: float = 24.0
var boss_visual_scale: float = 1.4
var base_color: Color = Color(1, 1, 1, 1)
var walk_anim_time: float = 0.0
var attack_anim_time: float = 0.0
var attack_anim_duration: float = 0.22
var walk_anim_speed: float = 7.0
var hit_flash_time: float = 0.0
var hit_flash_duration: float = 0.12
var is_dying: bool = false
var death_time: float = 0.0
var death_anim_time: float = 0.0
var death_anim_fps: float = 12.0
var death_frame_start: int = 5
var death_frame_count: int = 2
var FirePillarFxScript := preload("res://scripts/effects/FirePillarFX.gd")
var CrowFlyFxScript := preload("res://scripts/effects/CrowFlyFX.gd")

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
	add_to_group("enemies")
	enemy_sprite = get_node_or_null("EnemySprite") as Sprite2D
	if enemy_sprite:
		enemy_sprite.texture = _build_enemy_sheet(enemy_kind, 16, 24)
		enemy_sprite.hframes = 7
		enemy_sprite.vframes = 1
		enemy_sprite.frame = 0
		enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if use_global_stats:
		speed = _get_const_float("enemy.base_speed", speed)
		max_hp = _get_const_int("enemy.base_hp", max_hp)
		hp = _get_const_int("enemy.base_hp", hp)
		damage = _get_const_int("enemy.base_damage", damage)
		attack_cooldown = _get_const_float("enemy.attack_cooldown", attack_cooldown)
		attack_range_x = _get_const_float("enemy.attack_range_x", attack_range_x)
		attack_range_y = _get_const_float("enemy.attack_range_y", attack_range_y)
		ladder_speed = _get_const_float("enemy.ladder_speed", ladder_speed)
		collider_w = _get_const_float("enemy.collider_width", collider_w)
		collider_h = _get_const_float("enemy.collider_height", collider_h)
	boss_visual_scale = _get_const_float("boss.visual_scale", boss_visual_scale)
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape == null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(collider_w, collider_h)
		cs.shape = rect
	# layers: enemy on 2; collides with player(1) and platforms(4)
	collision_layer = 2
	collision_mask = 4
	_init_hitbox()
	# enemy health bar color
	var hb: Node2D = $HealthBar
	if hb and hb.has_method("set"):
		hb.set("fill_color", Color(1.0, 0.2, 0.2, 1.0))
		hb.set("back_color", Color(0, 0, 0, 0.6))
	# boss visual tweak
	if is_boss:
		var poly: Polygon2D = $Poly
		if enemy_sprite:
			enemy_sprite.modulate = Color(0.9, 0.15, 0.15, 1.0)
			enemy_sprite.scale = Vector2(boss_visual_scale, boss_visual_scale)
			base_color = enemy_sprite.modulate
		elif poly:
			poly.color = Color(0.9, 0.15, 0.15, 1.0)
			poly.scale = Vector2(boss_visual_scale, boss_visual_scale)
			base_color = poly.color
		add_to_group("boss")
	else:
		base_color = base_tint
		if enemy_sprite:
			enemy_sprite.modulate = base_color
		else:
			var poly2: Polygon2D = $Poly
			if poly2:
				poly2.color = base_color
	_refresh_visual_alignment()
	_add_outline()
	_sync_visual_facing()

func _physics_process(delta):
	if is_dying:
		_update_death(delta)
		return
	if on_ladder:
		if target:
			var dy_l: float = abs(target.global_position.y - global_position.y)
			var want_up: bool = target.global_position.y < global_position.y - 1.0
			var want_down: bool = target.global_position.y > global_position.y + 1.0
			var at_top: bool = false
			var at_bottom: bool = false
			if current_ladder != null:
				var h_b = current_ladder.get("height")
				if h_b != null:
					var half_h_b: float = float(h_b) * 0.5
					var cy_b: float = current_ladder.global_position.y
					var min_y_b: float = cy_b - half_h_b
					var max_y_b: float = cy_b + half_h_b
					var char_half_h: float = 12.0
					var ecs: CollisionShape2D = $CollisionShape2D
					if ecs and ecs.shape and ecs.shape is RectangleShape2D:
						char_half_h = (ecs.shape as RectangleShape2D).size.y * 0.5
					at_top = (global_position.y + char_half_h) <= min_y_b + 0.1
					at_bottom = (global_position.y + char_half_h) >= max_y_b - 0.1
			if want_up and at_top:
				if current_ladder != null:
					var h1 = current_ladder.get("height")
					if h1 != null:
						var half_h1: float = float(h1) * 0.5
						var cy1: float = current_ladder.global_position.y
						var min_y1: float = cy1 - half_h1
						var char_half_h1: float = 12.0
						var ecs1: CollisionShape2D = $CollisionShape2D
						if ecs1 and ecs1.shape and ecs1.shape is RectangleShape2D:
							char_half_h1 = (ecs1.shape as RectangleShape2D).size.y * 0.5
						global_position.y = min_y1 - char_half_h1
				set_on_ladder(false)
			elif want_down and at_bottom:
				if current_ladder != null:
					var h2 = current_ladder.get("height")
					if h2 != null:
						var half_h2: float = float(h2) * 0.5
						var cy2: float = current_ladder.global_position.y
						var max_y2: float = cy2 + half_h2
						var char_half_h2: float = 12.0
						var ecs2b: CollisionShape2D = $CollisionShape2D
						if ecs2b and ecs2b.shape and ecs2b.shape is RectangleShape2D:
							char_half_h2 = (ecs2b.shape as RectangleShape2D).size.y * 0.5
						global_position.y = max_y2 - char_half_h2
				set_on_ladder(false)
			elif dy_l > 4.0:
				var dir_y: float = sign(target.global_position.y - global_position.y)
				velocity.y = dir_y * ladder_speed
				velocity.x = 0.0
			else:
				var dirx_l: float = sign(target.global_position.x - global_position.x)
				velocity.x = dirx_l * speed
				set_on_ladder(false)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
	if hit_flash_time > 0.0:
		hit_flash_time = max(hit_flash_time - delta, 0.0)
		if hit_flash_time <= 0.0:
			_set_visual_color(base_color)
	attack_timer = max(attack_timer - delta, 0.0)
	update_target()
	if target:
		var dy: float = abs(target.global_position.y - global_position.y)
		var dx: float = abs(target.global_position.x - global_position.x)
		var seeking: bool = false
		var in_range: bool = (dy <= attack_range_y and dx <= attack_range_x)
		if in_range:
			var min_sep: float = 12.0
			if dx < min_sep:
				var push_dir: float = sign(global_position.x - target.global_position.x)
				velocity.x = push_dir * speed * 0.4
				facing = int(sign(push_dir)) if push_dir != 0 else facing
			else:
				velocity.x = 0.0
		else:
			if dy > 8.0 and not on_ladder:
				var lad := target_ladder
				if lad == null or not is_instance_valid(lad) or not _ladder_reachable_from_current(lad, target) or not _ladder_moves_towards_target(lad, target):
					lad = _pick_ladder_for(target)
					target_ladder = lad
				if lad:
					var dirx: float = sign(lad.global_position.x - global_position.x)
					velocity.x = dirx * speed
					facing = int(sign(dirx)) if dirx != 0 else facing
					var near_x: bool = false
					var lw = lad.get("width")
					if lw != null:
						near_x = abs(lad.global_position.x - global_position.x) <= float(lw) * 0.5 + 2.0
					else:
						near_x = abs(lad.global_position.x - global_position.x) <= 6.0
					if _ladder_reachable_from_current(lad, target) and (_is_inside_ladder(lad) or near_x):
						allow_ladder_enter = true
						set_on_ladder(true)
						set_current_ladder(lad)
					seeking = true
		if not seeking:
			var dir: float = sign(target.global_position.x - global_position.x)
			if not on_ladder and not in_range:
				velocity.x = dir * speed
			facing = int(sign(dir)) if dir != 0 else facing
		if not on_ladder and dy <= 8.0:
			target_ladder = null
		_update_hitbox()
		var block_door: Node2D = _get_blocking_door_between(target)
		if in_range and attack_timer <= 0.0:
			if block_door != null:
				attack_door(block_door)
			else:
				attack(target)
			attack_timer = attack_cooldown
		else:
			var dt: Node2D = _find_closed_door_in_range() as Node2D
			if dt != null and attack_timer <= 0.0:
				attack_door(dt)
				attack_timer = attack_cooldown
	else:
		velocity.x = 0.0
	_sync_visual_facing()
	_update_anim(delta)
	move_and_slide()
	if on_ladder and current_ladder != null:
		var h = current_ladder.get("height")
		if h != null:
			var half_h: float = float(h) * 0.5
			var cy: float = current_ladder.global_position.y
			var min_y: float = cy - half_h
			var max_y: float = cy + half_h
			var char_half_h: float = 12.0
			var ecs: CollisionShape2D = $CollisionShape2D
			if ecs and ecs.shape and ecs.shape is RectangleShape2D:
				char_half_h = (ecs.shape as RectangleShape2D).size.y * 0.5
			var ny: float = clamp(global_position.y, min_y - char_half_h, max_y - char_half_h)
			var at_top: bool = (ny + char_half_h) <= min_y + 0.1
			var at_bottom: bool = (ny + char_half_h) >= max_y - 0.1
			global_position.y = ny
			if target:
				var half: float = half_h
				var cy_t: float = cy
				if target.global_position.y < cy_t - half:
					if at_top:
						set_on_ladder(false)
						target_ladder = null
				elif target.global_position.y > cy_t + half:
					if at_bottom:
						set_on_ladder(false)
						target_ladder = null

func update_target():
	if target == null or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node2D

func attack(n):
	attack_anim_time = attack_anim_duration
	_spawn_attack_fx(n)
	if _player_in_hitbox():
		if n and n.has_method("take_damage"):
			n.take_damage(damage)
func attack_door(d):
	attack_anim_time = attack_anim_duration
	_spawn_attack_fx(d)
	if d and d.has_method("take_damage"):
		d.take_damage(damage)

func _get_body_half_h() -> float:
	var cs: CollisionShape2D = $CollisionShape2D
	if cs and cs.shape and cs.shape is RectangleShape2D:
		return (cs.shape as RectangleShape2D).size.y * 0.5
	return 12.0

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

func _refresh_visual_alignment():
	var body_half_h: float = _get_body_half_h()
	var hb: Node2D = get_node_or_null("HealthBar") as Node2D
	if enemy_sprite and enemy_sprite.texture:
		var bounds: Vector2 = _get_texture_opaque_bounds_y(enemy_sprite.texture)
		var tex_h: float = max(enemy_sprite.texture.get_size().y, 1.0)
		var bottom_from_center: float = (bounds.y + 1.0 - tex_h * 0.5) * enemy_sprite.scale.y
		var top_from_center: float = (bounds.x - tex_h * 0.5) * enemy_sprite.scale.y
		enemy_sprite.position.y = body_half_h - bottom_from_center
		if hb and hb.has_method("set"):
			hb.set("offset", Vector2(0.0, enemy_sprite.position.y + top_from_center - 10.0))
		if sprite_outline:
			sprite_outline.position = enemy_sprite.position
			sprite_outline.scale = enemy_sprite.scale * Vector2(1.08, 1.08)
		return
	var poly: Polygon2D = $Poly
	if poly == null or poly.polygon.size() == 0:
		return
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

func take_damage(d: int):
	if is_dying:
		return
	hp -= d
	_set_visual_color(Color(1, 0.8, 0.4, 1))
	hit_flash_time = hit_flash_duration
	if hp <= 0:
		if is_boss:
			_drop_boss_loot()
		else:
			_try_drop_medkit()
		_start_death()

func set_on_ladder(v: bool):
	if v:
		if not allow_ladder_enter:
			return
		on_ladder = true
		collision_mask = 0
	else:
		on_ladder = false
		collision_mask = 4
		allow_ladder_enter = false

func set_current_ladder(l):
	current_ladder = l as Node2D

func _try_drop_medkit():
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p := players[0] as Node2D
	var need := false
	if p and p.has_method("get") and p.get("hp") != null and p.get("max_hp") != null:
		var chp: int = int(p.get("hp"))
		var mhp: int = int(p.get("max_hp"))
		need = chp < int(float(mhp) * 0.5)
	if not need:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() <= 0.1:
		var Medkit := preload("res://scripts/items/Medkit.gd")
		var mk: Area2D = Medkit.new()
		get_parent().call_deferred("add_child", mk)
		var top_y: float = _current_floor_top()
		var ITEM_HALF: float = 8.0
		mk.global_position = Vector2(global_position.x, top_y - ITEM_HALF)
		mk.z_index = 100

func _drop_boss_loot():
	var Pickup := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = Pickup.new()
	item.set("kind", "collectible_boss")
	get_parent().call_deferred("add_child", item)
	var top_y: float = _current_floor_top()
	var item_half: float = 8.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	item.global_position = Vector2(global_position.x, top_y - item_half)
	item.z_index = 110

func _init_hitbox():
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1
	hitbox_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(attack_range_x, attack_range_y)
	hitbox_shape.shape = shape
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)
	# visible range overlay
	range_vis = Polygon2D.new()
	range_vis.color = Color(1, 0, 0, 0.2)
	range_vis.z_index = 9
	range_vis.visible = false
	add_child(range_vis)
	_update_hitbox()

func _update_hitbox():
	if hitbox_shape and hitbox_shape.shape:
		var hw: float = attack_range_x * 0.5
		hitbox_shape.position = Vector2(hw if facing >= 0 else -hw, 0.0)
		# update visible polygon to match hitbox
		var hh: float = attack_range_y * 0.5
		var sx: float = 0.0 if facing >= 0 else -attack_range_x
		range_vis.polygon = PackedVector2Array([
			Vector2(sx, -hh),
			Vector2(sx + attack_range_x, -hh),
			Vector2(sx + attack_range_x, hh),
			Vector2(sx, hh)
		])

func _player_in_hitbox() -> bool:
	if hitbox:
		var bodies := hitbox.get_overlapping_bodies()
		for b in bodies:
			if b and b.is_in_group("player"):
				return true
	return false

func _add_outline():
	if enemy_sprite and enemy_sprite.texture:
		sprite_outline = Sprite2D.new()
		sprite_outline.texture = enemy_sprite.texture
		sprite_outline.centered = enemy_sprite.centered
		sprite_outline.offset = enemy_sprite.offset
		sprite_outline.region_enabled = enemy_sprite.region_enabled
		sprite_outline.region_rect = enemy_sprite.region_rect
		sprite_outline.hframes = enemy_sprite.hframes
		sprite_outline.vframes = enemy_sprite.vframes
		sprite_outline.frame = enemy_sprite.frame
		sprite_outline.frame_coords = enemy_sprite.frame_coords
		sprite_outline.modulate = Color(0, 0, 0, 0.85)
		sprite_outline.z_index = max(enemy_sprite.z_index - 1, 0)
		sprite_outline.scale = enemy_sprite.scale * Vector2(1.08, 1.08)
		sprite_outline.position = enemy_sprite.position
		sprite_outline.flip_h = enemy_sprite.flip_h
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
	if enemy_sprite:
		enemy_sprite.modulate = c
	var poly: Polygon2D = $Poly
	if poly:
		poly.color = c

func _sync_visual_facing():
	if enemy_sprite:
		enemy_sprite.flip_h = facing < 0
	if sprite_outline:
		sprite_outline.flip_h = facing < 0

func _spawn_attack_fx(target_node: Node2D):
	if enemy_kind == "demon":
		var fx = FirePillarFxScript.new()
		get_parent().add_child(fx)
		var target_pos: Vector2 = global_position
		if target_node != null and is_instance_valid(target_node):
			target_pos = target_node.global_position
		var top_y: float = _floor_top_at(target_pos)
		fx.global_position = Vector2(target_pos.x, top_y - 11.0)
	elif enemy_kind == "vampire":
		var fx2 = CrowFlyFxScript.new()
		var target_pos2: Vector2 = global_position
		if target_node != null and is_instance_valid(target_node):
			target_pos2 = target_node.global_position
		fx2.use_path = true
		fx2.end_position = target_pos2 + Vector2(0.0, -10.0)
		fx2.speed = 420.0
		fx2.global_position = Vector2(global_position.x + float(facing) * 6.0, global_position.y - 12.0)
		get_parent().add_child(fx2)

func _start_death():
	is_dying = true
	death_time = max(death_duration, 0.05)
	death_anim_time = 0.0
	hp = 0
	velocity = Vector2.ZERO
	attack_timer = 0.0
	on_ladder = false
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	if range_vis:
		range_vis.visible = false
	var hb: Node2D = get_node_or_null("HealthBar") as Node2D
	if hb:
		hb.visible = false
	if sprite_outline:
		sprite_outline.visible = false
	if enemy_sprite:
		enemy_sprite.frame = death_frame_start
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
	var poly: Polygon2D = $Poly
	if poly:
		poly.visible = false

func _update_death(delta: float):
	death_time = max(death_time - delta, 0.0)
	death_anim_time += delta
	if enemy_sprite:
		var idx: int = death_frame_start + min(int(floor(death_anim_time * death_anim_fps)), death_frame_count - 1)
		enemy_sprite.frame = idx
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
	if death_time <= 0.0:
		queue_free()

func _find_closed_door_in_range():
	var doors: Array = get_tree().get_nodes_in_group("door")
	var best: Node2D = null
	var best_d: float = INF
	for d in doors:
		if d and d is Node2D:
			var is_special_locked: bool = false
			var sl = d.get("special_locked")
			if sl != null:
				is_special_locked = bool(sl)
			if is_special_locked:
				continue
			var is_open: bool = false
			var ov = d.get("open")
			if ov != null:
				is_open = bool(ov)
			if not is_open:
				var dx: float = abs((d as Node2D).global_position.x - global_position.x)
				var dy: float = abs((d as Node2D).global_position.y - global_position.y)
				var dy_limit: float = attack_range_y + _get_body_half_h()
				if dy <= dy_limit and dx <= attack_range_x:
					if dx < best_d:
						best_d = dx
						best = d as Node2D
	return best

func _get_blocking_door_between(target_node: Node2D) -> Node2D:
	if target_node == null:
		return null
	var doors: Array = get_tree().get_nodes_in_group("door")
	if doors.size() == 0:
		return null
	var ax: float = global_position.x
	var bx: float = target_node.global_position.x
	var min_x: float = min(ax, bx)
	var max_x: float = max(ax, bx)
	for d in doors:
		if d and d is Node2D:
			var is_open: bool = false
			var ov = d.get("open")
			if ov != null:
				is_open = bool(ov)
			if is_open:
				continue
			var dx: float = (d as Node2D).global_position.x
			if dx < min_x or dx > max_x:
				continue
			var dh: float = 36.0
			var dhv = d.get("door_h")
			if dhv != null:
				dh = float(dhv)
			if abs(global_position.y - (d as Node2D).global_position.y) > dh:
				continue
			if abs(target_node.global_position.y - (d as Node2D).global_position.y) > dh:
				continue
			return d as Node2D
	return null

func _get_ladders() -> Array:
	return get_tree().get_nodes_in_group("ladder")

func _ladder_covers_y(lad: Node2D, y: float, margin: float = 2.0) -> bool:
	if lad == null:
		return false
	var h = lad.get("height")
	if h == null:
		return false
	var half: float = float(h) * 0.5 + margin
	var cy: float = lad.global_position.y
	return y >= cy - half and y <= cy + half

func _is_inside_ladder(lad: Node2D) -> bool:
	if lad == null:
		return false
	var w = lad.get("width")
	var h = lad.get("height")
	if w == null or h == null:
		return false
	var half_w: float = float(w) * 0.5
	var half_h: float = float(h) * 0.5
	var c: Vector2 = lad.global_position
	var dx: float = abs(global_position.x - c.x)
	var dy: float = abs(global_position.y - c.y)
	return dx <= half_w and dy <= half_h

func _pick_ladder_for(target: Node2D) -> Node2D:
	var ladders := _get_ladders()
	var best: Node2D = null
	var best_score: float = INF
	for l in ladders:
		if l is Node2D:
			if _ladder_reachable_from_current(l as Node2D, target) and _ladder_moves_towards_target(l as Node2D, target):
				var lx: float = (l as Node2D).global_position.x
				var cx: float = global_position.x
				var px: float = target.global_position.x if target else lx
				var cy: float = (l as Node2D).global_position.y
				var py: float = target.global_position.y if target else cy
				var score: float = abs(cy - py) * 0.7 + abs(lx - px) * 0.2 + abs(lx - cx) * 0.1
				if score < best_score:
					best_score = score
					best = l as Node2D
	if best == null and ladders.size() > 0:
		for l in ladders:
			if l is Node2D:
				var lx2: float = (l as Node2D).global_position.x
				var cx2: float = global_position.x
				var px2: float = target.global_position.x if target else lx2
				var cy2: float = (l as Node2D).global_position.y
				var py2: float = target.global_position.y if target else cy2
				var score2: float = abs(cy2 - py2) * 0.7 + abs(lx2 - px2) * 0.2 + abs(lx2 - cx2) * 0.1
				if score2 < best_score:
					best_score = score2
					best = l as Node2D
	return best

func _ladder_moves_towards_target(lad: Node2D, target: Node2D) -> bool:
	if lad == null or target == null:
		return true
	var cy: float = lad.global_position.y
	var ey: float = global_position.y
	var py: float = target.global_position.y
	if py > ey + 1.0:
		return cy > ey
	if py < ey - 1.0:
		return cy < ey
	return true

func _ladder_reachable_from_current(lad: Node2D, target: Node2D, tol: float = 12.0) -> bool:
	if lad == null:
		return false
	var h = lad.get("height")
	if h == null:
		return false
	var half: float = float(h) * 0.5
	var cy: float = lad.global_position.y
	var top_y: float = cy - half
	var bot_y: float = cy + half
	var ey: float = global_position.y
	var cur_top: float = _current_floor_top()
	if target == null:
		return abs(cur_top - top_y) <= tol or abs(cur_top - bot_y) <= tol
	var py: float = target.global_position.y
	if py < ey - 1.0:
		return abs(cur_top - bot_y) <= tol
	if py > ey + 1.0:
		return abs(cur_top - top_y) <= tol
	return abs(cur_top - top_y) <= tol or abs(cur_top - bot_y) <= tol

func _current_floor_top() -> float:
	var plats := _get_platforms()
	var best_top: float = global_position.y - 8.0
	var best_d: float = INF
	for p in plats:
		if p is Node2D:
			var top := _platform_top(p)
			var d: float = abs(global_position.y - top)
			if d < best_d:
				best_d = d
				best_top = top
	return best_top

func _floor_top_at(pos: Vector2) -> float:
	var plats := _get_platforms()
	var best_top: float = pos.y - 8.0
	var best_d: float = INF
	for p in plats:
		if p is Node2D:
			var top := _platform_top(p)
			var d: float = abs(pos.y - top)
			if d < best_d:
				best_d = d
				best_top = top
	return best_top

func _platform_top(p) -> float:
	if p == null:
		return global_position.y - 8.0
	var y: float = (p as Node2D).global_position.y
	var hh: float = 8.0
	for c in p.get_children():
		if c is CollisionShape2D and c.shape and c.shape is RectangleShape2D:
			hh = (c.shape as RectangleShape2D).size.y * 0.5
			break
	return y - hh

func _get_platforms() -> Array:
	var level := get_parent()
	if level and level.has_node("Platforms"):
		return level.get_node("Platforms").get_children()
	return []

func _build_enemy_sheet(kind: String, w: int, h: int) -> Texture2D:
	if kind == "vampire":
		return _build_fast_sheet(w, h)
	if kind == "demon":
		return _build_brute_sheet(w, h)
	return _build_jiangshi_sheet(w, h)

func _build_jiangshi_sheet(w: int, h: int) -> Texture2D:
	var frames: int = 7
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_jiangshi_frame(img, i * w, 0, i)
	return ImageTexture.create_from_image(img)

func _draw_jiangshi_frame(img: Image, ox: int, oy: int, idx: int):
	var robe := Color(0.18, 0.22, 0.35, 1.0)
	var robe2 := Color(0.12, 0.16, 0.26, 1.0)
	var trim := Color(0.85, 0.74, 0.38, 1.0)
	var hat := Color(0.05, 0.05, 0.08, 1.0)
	var skin := Color(0.62, 0.82, 0.62, 1.0)
	var talisman := Color(0.92, 0.86, 0.6, 1.0)
	var talisman_ink := Color(0.7, 0.16, 0.16, 1.0)
	var boot := Color(0.08, 0.08, 0.1, 1.0)
	var leg_lx: int = 5
	var leg_rx: int = 9
	var arm_lx: int = 2
	var arm_rx: int = 12
	var lunge_y: int = 0
	if idx == 1:
		leg_lx = 4
		leg_rx = 10
		arm_lx = 3
		arm_rx = 11
	elif idx == 2:
		leg_lx = 6
		leg_rx = 8
		arm_lx = 1
		arm_rx = 13
	elif idx == 3:
		lunge_y = -1
		_rect(img, ox + 6, oy + 1 + lunge_y, 5, 3, hat)
		_rect(img, ox + 6, oy + 4 + lunge_y, 5, 1, hat)
		_rect(img, ox + 7, oy + 4 + lunge_y, 3, 4, skin)
		_rect(img, ox + 8, oy + 3 + lunge_y, 2, 2, talisman)
		_rect(img, ox + 8, oy + 4 + lunge_y, 2, 1, talisman_ink)
		_rect(img, ox + 5, oy + 8 + lunge_y, 8, 8, robe)
		_rect(img, ox + 6, oy + 9 + lunge_y, 6, 6, robe2)
		_rect(img, ox + 5, oy + 8 + lunge_y, 1, 8, trim)
		_rect(img, ox + 12, oy + 8 + lunge_y, 1, 8, trim)
		_rect(img, ox + 7, oy + 8 + lunge_y, 4, 1, trim)
		_rect(img, ox + 10, oy + 6 + lunge_y, 4, 5, robe2)
		_rect(img, ox + 12, oy + 4 + lunge_y, 2, 2, robe2)
		_rect(img, ox + 7, oy + 16 + lunge_y, 2, 5, robe2)
		_rect(img, ox + 9, oy + 16 + lunge_y, 2, 5, robe2)
		_rect(img, ox + 7, oy + 20 + lunge_y, 2, 2, boot)
		_rect(img, ox + 9, oy + 20 + lunge_y, 2, 2, boot)
		return
	elif idx == 4:
		lunge_y = -1
	elif idx >= 5:
		var fall: int = 0 if idx == 5 else 2
		_rect(img, ox + 2, oy + 12 + fall, 12, 6, robe)
		_rect(img, ox + 3, oy + 13 + fall, 10, 4, robe2)
		_rect(img, ox + 4, oy + 10 + fall, 8, 2, hat)
		_rect(img, ox + 6, oy + 8 + fall, 4, 3, skin)
		_rect(img, ox + 6, oy + 9 + fall, 2, 1, talisman_ink)
		_rect(img, ox + 5, oy + 16 + fall, 2, 3, boot)
		_rect(img, ox + 9, oy + 16 + fall, 2, 3, boot)
		return
		_rect(img, ox + 6, oy + 1 + lunge_y, 5, 3, hat)
		_rect(img, ox + 6, oy + 4 + lunge_y, 5, 1, hat)
		_rect(img, ox + 7, oy + 4 + lunge_y, 3, 4, skin)
		_rect(img, ox + 8, oy + 3 + lunge_y, 2, 2, talisman)
		_rect(img, ox + 8, oy + 4 + lunge_y, 2, 1, talisman_ink)
		_rect(img, ox + 5, oy + 8 + lunge_y, 8, 8, robe)
		_rect(img, ox + 6, oy + 9 + lunge_y, 6, 6, robe2)
		_rect(img, ox + 5, oy + 8 + lunge_y, 1, 8, trim)
		_rect(img, ox + 12, oy + 8 + lunge_y, 1, 8, trim)
		_rect(img, ox + 7, oy + 8 + lunge_y, 4, 1, trim)
		_rect(img, ox + 12, oy + 11 + lunge_y, 3, 3, robe2)
		_rect(img, ox + 14, oy + 13 + lunge_y, 1, 1, trim)
		_rect(img, ox + 7, oy + 16 + lunge_y, 2, 5, robe2)
		_rect(img, ox + 9, oy + 16 + lunge_y, 2, 5, robe2)
		_rect(img, ox + 7, oy + 20 + lunge_y, 2, 2, boot)
		_rect(img, ox + 9, oy + 20 + lunge_y, 2, 2, boot)
		return
	_rect(img, ox + 5, oy + 1 + lunge_y, 6, 3, hat)
	_rect(img, ox + 4, oy + 4 + lunge_y, 8, 1, hat)
	_rect(img, ox + 6, oy + 4 + lunge_y, 4, 4, skin)
	_rect(img, ox + 7, oy + 3 + lunge_y, 2, 2, talisman)
	_rect(img, ox + 7, oy + 4 + lunge_y, 2, 1, talisman_ink)
	_rect(img, ox + 3, oy + 8 + lunge_y, 10, 8, robe)
	_rect(img, ox + 4, oy + 9 + lunge_y, 8, 6, robe2)
	_rect(img, ox + 3, oy + 8 + lunge_y, 1, 8, trim)
	_rect(img, ox + 12, oy + 8 + lunge_y, 1, 8, trim)
	_rect(img, ox + 5, oy + 8 + lunge_y, 6, 1, trim)
	_rect(img, ox + arm_lx, oy + 9 + lunge_y, 3, 4, robe2)
	_rect(img, ox + arm_rx, oy + 9 + lunge_y, 3, 4, robe2)
	_rect(img, ox + leg_lx, oy + 16 + lunge_y, 2, 5, robe2)
	_rect(img, ox + leg_rx, oy + 16 + lunge_y, 2, 5, robe2)
	_rect(img, ox + leg_lx, oy + 20 + lunge_y, 2, 2, boot)
	_rect(img, ox + leg_rx, oy + 20 + lunge_y, 2, 2, boot)

func _build_fast_sheet(w: int, h: int) -> Texture2D:
	var frames: int = 7
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_fast_frame(img, i * w, 0, i)
	return ImageTexture.create_from_image(img)

func _draw_fast_frame(img: Image, ox: int, oy: int, idx: int):
	var cloak := Color(0.12, 0.02, 0.05, 1.0)
	var lining := Color(0.5, 0.05, 0.1, 1.0)
	var trim := Color(0.85, 0.75, 0.35, 1.0)
	var vest := Color(0.2, 0.02, 0.03, 1.0)
	var belt := Color(0.4, 0.2, 0.05, 1.0)
	var skin := Color(0.9, 0.82, 0.8, 1.0)
	var hair := Color(0.06, 0.03, 0.05, 1.0)
	var fang := Color(0.96, 0.96, 0.98, 1.0)
	var eye := Color(0.9, 0.1, 0.2, 1.0)
	var boot := Color(0.05, 0.05, 0.06, 1.0)
	var leg_lx: int = 5
	var leg_rx: int = 9
	var lean_x: int = 0
	var bat_wing: int = 0
	var atk: bool = idx == 3 or idx == 4
	if idx == 1:
		leg_lx = 4
		leg_rx = 10
		lean_x = 1
		bat_wing = 1
	elif idx == 2:
		leg_lx = 6
		leg_rx = 8
		lean_x = 1
		bat_wing = -1
	elif idx == 3:
		lean_x = 2
		bat_wing = 1
	elif idx == 4:
		lean_x = 2
		bat_wing = -1
	elif idx >= 5:
		var fall: int = 0 if idx == 5 else 2
		_rect(img, ox + 2, oy + 13 + fall, 12, 6, cloak)
		_rect(img, ox + 3, oy + 14 + fall, 10, 4, lining)
		_rect(img, ox + 4, oy + 13 + fall, 8, 1, trim)
		_rect(img, ox + 5, oy + 11 + fall, 6, 2, hair)
		_rect(img, ox + 6, oy + 10 + fall, 4, 2, skin)
		_rect(img, ox + 6, oy + 11 + fall, 1, 1, eye)
		_rect(img, ox + 9, oy + 11 + fall, 1, 1, eye)
		_rect(img, ox + 7, oy + 12 + fall, 2, 1, fang)
		_rect(img, ox + 5, oy + 16 + fall, 6, 2, vest)
		_rect(img, ox + 6, oy + 18 + fall, 4, 1, belt)
		_rect(img, ox + 2, oy + 15 + fall, 2, 3, cloak)
		_rect(img, ox + 12, oy + 15 + fall, 2, 3, cloak)
		_rect(img, ox + 3, oy + 15 + fall, 2, 2, trim)
		_rect(img, ox + 11, oy + 15 + fall, 2, 2, trim)
		return
	var head_x := ox + 6 + lean_x
	var head_y := oy + 4
	_rect(img, head_x - 1, head_y - 1, 6, 2, hair)
	_rect(img, head_x, head_y, 4, 3, skin)
	_rect(img, head_x, head_y + 1, 1, 1, eye)
	_rect(img, head_x + 3, head_y + 1, 1, 1, eye)
	_rect(img, head_x + 1, head_y + 2, 2, 1, fang)
	_rect(img, ox + 4 + lean_x, oy + 7, 8, 2, trim)
	_rect(img, ox + 4 + lean_x, oy + 9, 8, 7, lining)
	_rect(img, ox + 5 + lean_x, oy + 10, 6, 2, vest)
	_rect(img, ox + 5 + lean_x, oy + 12, 6, 1, belt)
	_rect(img, ox + 3 + lean_x, oy + 8, 10, 10, cloak)
	_rect(img, ox + 2 + lean_x, oy + 9, 12, 9, cloak)
	_rect(img, ox + leg_lx + lean_x, oy + 16, 2, 5, cloak)
	_rect(img, ox + leg_rx + lean_x, oy + 16, 2, 5, cloak)
	_rect(img, ox + leg_lx + lean_x, oy + 21, 2, 2, boot)
	_rect(img, ox + leg_rx + lean_x, oy + 21, 2, 2, boot)
	if atk:
		_rect(img, ox + 1 + lean_x, oy + 7 + bat_wing, 4, 6, cloak)
		_rect(img, ox + 12 + lean_x, oy + 7 - bat_wing, 4, 6, cloak)
		_rect(img, ox + 2 + lean_x, oy + 8 + bat_wing, 2, 4, trim)
		_rect(img, ox + 13 + lean_x, oy + 8 - bat_wing, 2, 4, trim)
	else:
		_rect(img, ox + 1 + lean_x, oy + 9 + bat_wing, 3, 4, cloak)
		_rect(img, ox + 12 + lean_x, oy + 9 - bat_wing, 3, 4, cloak)
		_rect(img, ox + 2 + lean_x, oy + 10 + bat_wing, 1, 3, trim)
		_rect(img, ox + 13 + lean_x, oy + 10 - bat_wing, 1, 3, trim)

func _build_brute_sheet(w: int, h: int) -> Texture2D:
	var frames: int = 7
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_brute_frame(img, i * w, 0, i)
	return ImageTexture.create_from_image(img)

func _draw_brute_frame(img: Image, ox: int, oy: int, idx: int):
	var body := Color(0.42, 0.05, 0.06, 1.0)
	var armor := Color(0.1, 0.01, 0.02, 1.0)
	var horn := Color(0.9, 0.82, 0.45, 1.0)
	var eye := Color(1.0, 0.4, 0.2, 1.0)
	var wing := Color(0.08, 0.01, 0.02, 1.0)
	var claw := Color(0.96, 0.96, 0.98, 1.0)
	var glow := Color(0.95, 0.25, 0.12, 1.0)
	var accent := Color(0.78, 0.48, 0.12, 1.0)
	var tail := Color(0.5, 0.06, 0.08, 1.0)
	var leg_lx: int = 5
	var leg_rx: int = 9
	var stomp: int = 0
	var flap: int = 0
	var atk: bool = idx == 3 or idx == 4
	if idx == 1:
		leg_lx = 4
		leg_rx = 10
		stomp = 1
		flap = 1
	elif idx == 2:
		leg_lx = 6
		leg_rx = 8
		stomp = -1
		flap = -1
	elif idx == 3:
		stomp = 0
		flap = 1
	elif idx == 4:
		stomp = 0
		flap = -1
	elif idx >= 5:
		var fall: int = 0 if idx == 5 else 2
		_rect(img, ox + 3, oy + 13 + fall, 10, 7, body)
		_rect(img, ox + 4, oy + 11 + fall, 8, 3, armor)
		_rect(img, ox + 5, oy + 9 + fall, 2, 2, horn)
		_rect(img, ox + 9, oy + 9 + fall, 2, 2, horn)
		_rect(img, ox + 6, oy + 11 + fall, 4, 2, eye)
		_rect(img, ox + 6, oy + 13 + fall, 4, 1, glow)
		_rect(img, ox + 5, oy + 16 + fall, 6, 2, armor)
		_rect(img, ox + 6, oy + 17 + fall, 4, 1, accent)
		_rect(img, ox + 2, oy + 15 + fall, 3, 4, wing)
		_rect(img, ox + 11, oy + 15 + fall, 3, 4, wing)
		_rect(img, ox + 4, oy + 18 + fall, 2, 2, claw)
		_rect(img, ox + 10, oy + 18 + fall, 2, 2, claw)
		_rect(img, ox + 12, oy + 19 + fall, 2, 2, tail)
		return
	var head_x := ox + 6
	var head_y := oy + 4 + stomp
	_rect(img, head_x - 1, head_y, 6, 3, body)
	_rect(img, head_x, head_y - 1, 2, 2, horn)
	_rect(img, head_x + 3, head_y - 1, 2, 2, horn)
	_rect(img, head_x + 1, head_y + 1, 1, 1, eye)
	_rect(img, head_x + 3, head_y + 1, 1, 1, eye)
	_rect(img, head_x + 1, head_y + 2, 3, 1, glow)
	_rect(img, ox + 3, oy + 7 + stomp, 10, 6, armor)
	_rect(img, ox + 4, oy + 8 + stomp, 8, 4, body)
	_rect(img, ox + 5, oy + 9 + stomp, 6, 2, armor)
	_rect(img, ox + 5, oy + 11 + stomp, 6, 1, accent)
	_rect(img, ox + 4, oy + 12 + stomp, 8, 2, body)
	_rect(img, ox + 5, oy + 13 + stomp, 6, 1, armor)
	_rect(img, ox + 6, oy + 14 + stomp, 4, 1, glow)
	_rect(img, ox + leg_lx, oy + 16 + stomp, 2, 6, body)
	_rect(img, ox + leg_rx, oy + 16 + stomp, 2, 6, body)
	_rect(img, ox + leg_lx, oy + 22 + stomp, 2, 2, claw)
	_rect(img, ox + leg_rx, oy + 22 + stomp, 2, 2, claw)
	_rect(img, ox + 12, oy + 18 + stomp, 2, 2, tail)
	if atk:
		_rect(img, ox + 1, oy + 6 + flap, 4, 9, wing)
		_rect(img, ox + 11, oy + 6 - flap, 4, 9, wing)
		_rect(img, ox + 2, oy + 8 + flap, 2, 4, accent)
		_rect(img, ox + 12, oy + 8 - flap, 2, 4, accent)
	else:
		_rect(img, ox + 1, oy + 8 + flap, 3, 6, wing)
		_rect(img, ox + 12, oy + 8 - flap, 3, 6, wing)
		_rect(img, ox + 2, oy + 10 + flap, 1, 3, accent)
		_rect(img, ox + 13, oy + 10 - flap, 1, 3, accent)

func _update_anim(delta: float):
	if enemy_sprite == null:
		return
	if attack_anim_time > 0.0:
		attack_anim_time = max(attack_anim_time - delta, 0.0)
		enemy_sprite.frame = 3 if attack_anim_time > attack_anim_duration * 0.5 else 4
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
		return
	var moving: bool = abs(velocity.x) > 1.0
	if not moving:
		walk_anim_time = 0.0
		enemy_sprite.frame = 0
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
		return
	walk_anim_time += delta * walk_anim_speed
	var step: int = int(floor(walk_anim_time)) % 2
	enemy_sprite.frame = 1 + step
	if sprite_outline:
		sprite_outline.frame = enemy_sprite.frame

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)
