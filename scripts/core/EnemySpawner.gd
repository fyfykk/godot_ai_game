extends Node2D

@export var interval: float = 2.0
@export var limit: int = 99
@export var enemy_scene: PackedScene
@export var enemy_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene
var base_interval: float = 2.0

var timer: float = 0.0
var rng := RandomNumberGenerator.new()
var boss_spawned: bool = false
@onready var boss_scene_default: PackedScene = preload("res://scenes/Boss.tscn")
var post_interaction: bool = false
var spawn_pack_min: int = 3
var spawn_pack_max: int = 5
var spawn_x_offset_min: float = -24.0
var spawn_x_offset_max: float = 24.0
var spawn_edge: float = 80.0
var platform_safe_margin: float = 48.0
var platform_narrow_offset: float = 16.0
var spawn_y_offset: float = -12.0
var spawn_player_min_distance: float = 64.0
var spawn_player_push_x: float = 96.0
var post_interval_factor: float = 0.25
var post_interval_min: float = 0.25
var interval_min: float = 0.4

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
	rng.randomize()
	base_interval = interval
	spawn_pack_min = _get_const_int("spawner.spawn_pack_min", spawn_pack_min)
	spawn_pack_max = _get_const_int("spawner.spawn_pack_max", spawn_pack_max)
	spawn_x_offset_min = _get_const_float("spawner.spawn_x_offset_min", spawn_x_offset_min)
	spawn_x_offset_max = _get_const_float("spawner.spawn_x_offset_max", spawn_x_offset_max)
	spawn_edge = _get_const_float("spawner.spawn_x_clamp_min", spawn_edge)
	platform_safe_margin = _get_const_float("spawner.platform_safe_margin", platform_safe_margin)
	platform_narrow_offset = _get_const_float("spawner.platform_narrow_center_offset", platform_narrow_offset)
	spawn_y_offset = _get_const_float("spawner.spawn_y_platform_top_offset", spawn_y_offset)
	spawn_player_min_distance = _get_const_float("spawner.spawn_player_min_distance", spawn_player_min_distance)
	spawn_player_push_x = _get_const_float("spawner.spawn_player_push_x", spawn_player_push_x)
	post_interval_factor = _get_const_float("spawner.post_interaction_interval_factor", post_interval_factor)
	post_interval_min = _get_const_float("spawner.post_interaction_interval_min", post_interval_min)
	interval_min = _get_const_float("spawner.interval_min", interval_min)
	interval = _get_const_float("spawner.interval_base", interval)
	limit = _get_const_int("spawner.limit", limit)

func _process(delta):
	timer += delta
	var eff_interval: float = _effective_interval()
	if timer >= eff_interval:
		timer = 0.0
		var cur: int = get_tree().get_nodes_in_group("enemies").size()
		var scenes := _get_spawn_scenes()
		if cur < limit and scenes.size() > 0:
			var root := get_tree().get_root().get_node("GameRoot")
			var ratio: float = 0.0
			if root and root.has_method("get_game_time") and root.has_method("get_max_time"):
				ratio = float(clamp(float(root.get_game_time()) / float(root.get_max_time()), 0.0, 1.0))
			var pack: int = _effective_pack_size(ratio)
			var can_spawn: int = max(limit - cur, 0)
			var count: int = min(pack, can_spawn)
			var base_pos: Vector2 = _pick_spawn_pos(false)
			var first_idx: int = 0
			var second_idx: int = 0
			if count >= 2 and scenes.size() >= 2:
				first_idx = rng.randi_range(0, scenes.size() - 1)
				second_idx = rng.randi_range(0, scenes.size() - 1)
				if second_idx == first_idx:
					second_idx = (second_idx + 1) % scenes.size()
			for i in range(count):
				var scene_to_use: PackedScene = scenes[0]
				if scenes.size() == 1:
					scene_to_use = scenes[0]
				elif count >= 2 and scenes.size() >= 2:
					if i == 0:
						scene_to_use = scenes[first_idx]
					elif i == 1:
						scene_to_use = scenes[second_idx]
					else:
						scene_to_use = scenes[rng.randi_range(0, scenes.size() - 1)]
				else:
					scene_to_use = scenes[rng.randi_range(0, scenes.size() - 1)]
				var e = scene_to_use.instantiate()
				get_parent().add_child(e)
				var off: Vector2 = Vector2(rng.randf_range(spawn_x_offset_min, spawn_x_offset_max), 0.0)
				var new_pos: Vector2 = base_pos + off
				var level = get_parent()
				var min_x: float = spawn_edge
				var max_x: float = 100000.0
				if level and level.has_node("Generator"):
					var gen = level.get_node("Generator")
					if gen and gen.has_method("get") and gen.get("width") != null:
						max_x = float(gen.width) - spawn_edge
				new_pos.x = clamp(new_pos.x, min_x, max_x)
				e.global_position = new_pos
				var root_cfg := get_tree().get_root().get_node("GameRoot")
				var use_globals: bool = true
				if e and e.has_method("get") and e.get("use_global_stats") != null:
					use_globals = bool(e.get("use_global_stats"))
				if use_globals and root_cfg and root_cfg.has_method("get_character_value") and e.has_method("set"):
					var ehp = root_cfg.call("get_character_value", "enemy", "max_hp", e.get("max_hp"))
					var edmg = root_cfg.call("get_character_value", "enemy", "damage", e.get("damage"))
					var espd = root_cfg.call("get_character_value", "enemy", "speed", e.get("speed"))
					if ehp != null:
						e.set("max_hp", int(ehp))
						if e.get("hp") != null:
							e.set("hp", int(ehp))
					if edmg != null:
						e.set("damage", int(edmg))
					if espd != null and e.get("speed") != null:
						e.set("speed", float(espd))
				_scale_enemy_stats(e, ratio)
	# boss summon at max time
	var root2 := get_tree().get_root().get_node("GameRoot")
	if not boss_spawned and root2 and root2.has_method("get_game_time") and root2.has_method("get_max_time"):
		var t: float = float(root2.get_game_time())
		var m: float = float(root2.get_max_time())
		if t >= m:
			_spawn_boss()

func _effective_interval() -> float:
	var root := get_tree().get_root().get_node("GameRoot")
	if root and root.has_method("get_game_time") and root.has_method("get_max_time"):
		var t: float = float(root.get_game_time())
		var m: float = float(root.get_max_time())
		var ratio: float = float(clamp(t / m, 0.0, 1.0))
		if post_interaction:
			return max(base_interval * post_interval_factor, post_interval_min)
		return max(base_interval * (1.0 - 0.6 * ratio), interval_min)
	return interval

func _get_spawn_scenes() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for s in enemy_scenes:
		if s:
			scenes.append(s)
	if scenes.size() == 0 and enemy_scene:
		scenes.append(enemy_scene)
	return scenes

func _pick_spawn_pos(nearest_layer_only: bool = false) -> Vector2:
	var level = get_parent()
	var gen = null
	if level and level.has_node("Generator"):
		gen = level.get_node("Generator")
	if gen == null:
		return global_position
	var layers: int = int(gen.layers)
	var lh: float = float(gen.layer_height)
	var w: float = float(gen.width)
	var players := get_tree().get_nodes_in_group("player")
	var player_layer: int = 0
	if players.size() > 0:
		var p := players[0] as Node2D
		var tm: float = 0.0
		if level and level.has_method("get_top_margin"):
			tm = float(level.get_top_margin())
		player_layer = int(clamp(floor((p.global_position.y - tm) / lh), 0.0, float(layers - 1)))
	var layer_idx: int = player_layer
	if not nearest_layer_only:
		var weights := []
		var total: float = 0.0
		for i in range(layers):
			var d: float = abs(float(i - player_layer))
			var wgt: float = 1.0 / (d + 1.0)
			var level_locked: bool = false
			var lvl = get_parent()
			if lvl and lvl.has_method("is_top_layer_locked"):
				level_locked = bool(lvl.call("is_top_layer_locked"))
			if level_locked and i == 0:
				wgt = 0.0
			weights.append(wgt)
			total += wgt
		var pick: float = rng.randf() * total
		var acc: float = 0.0
		for i in range(layers):
			acc += float(weights[i])
			if pick <= acc:
				layer_idx = i
				break
	if nearest_layer_only:
		var lvl2 = get_parent()
		if lvl2 and lvl2.has_method("is_top_layer_locked") and bool(lvl2.call("is_top_layer_locked")) and layer_idx == 0 and layers > 1:
			layer_idx = 1
	var pos: Vector2 = Vector2(0.0, 0.0)
	var min_x: float = spawn_edge
	var max_x: float = w - spawn_edge
	var y_top: float = float(layer_idx) * lh - 16.0
	var used_platform_bounds: bool = false
	# try clamp to actual platform width bounds
	if level and level.has_method("_get_platform_body_for_layer") and level.has_method("_get_platform_width") and level.has_method("_get_platform_height"):
		var plat = level.call("_get_platform_body_for_layer", int(layer_idx))
		if plat and plat is Node2D:
			var pw: float = float(level.call("_get_platform_width", plat))
			var ph: float = float(level.call("_get_platform_height", plat))
			if pw > 0.0 and ph > 0.0:
				var cx: float = (plat as Node2D).global_position.x
				var cy: float = (plat as Node2D).global_position.y
				var hw: float = pw * 0.5
				min_x = cx - hw + platform_safe_margin
				max_x = cx + hw - platform_safe_margin
				if max_x <= min_x:
					min_x = cx - platform_narrow_offset
					max_x = cx + platform_narrow_offset
				y_top = cy - ph * 0.5
				used_platform_bounds = true
	var x: float = rng.randf_range(min_x, max_x)
	# set center Y slightly above platform top so feet落在平台上（敌人半高约12）
	pos = Vector2(x, y_top + spawn_y_offset)
	var y_off: float = 0.0
	if level and level.has_method("get_top_margin"):
		y_off = float(level.get_top_margin())
	# 如果使用了平台的全局坐标，已经包含top_margin，不再重复加
	if not used_platform_bounds:
		pos.y += y_off
	if players.size() > 0:
		var p := players[0] as Node2D
		if p and p.global_position.distance_to(pos) < spawn_player_min_distance:
			pos.x = clamp(pos.x + spawn_player_push_x, min_x, max_x)
	return pos

func _effective_pack_size(ratio: float) -> int:
	var base: float = float(spawn_pack_min)
	var maxv: float = float(spawn_pack_max)
	var span: float = max(maxv - base, 0.0)
	return int(clamp(base + floor(ratio * span), base, maxv))

func _scale_enemy_stats(e, ratio: float):
	if e == null:
		return
	if e.has_method("set"):
		if e.get("max_hp") != null:
			var base_max: int = int(e.get("max_hp"))
			var mult: float = 1.0 + 2.0 * ratio
			var new_max: int = int(round(float(base_max) * mult))
			e.set("max_hp", new_max)
			if e.get("hp") != null:
				e.set("hp", new_max)
		if e.get("damage") != null:
			var base_dmg: int = int(e.get("damage"))
			var new_dmg: int = int(round(float(base_dmg) * (1.0 + 0.6 * ratio)))
			e.set("damage", max(new_dmg, 1))
		if e.get("speed") != null:
			var base_spd: float = float(e.get("speed"))
			e.set("speed", base_spd * (1.0 + 0.15 * ratio))

func _spawn_boss():
	boss_spawned = true
	var scene_to_use: PackedScene = boss_scene if boss_scene != null else boss_scene_default if boss_scene_default != null else enemy_scene
	if scene_to_use == null:
		return
	var b = scene_to_use.instantiate()
	get_parent().add_child(b)
	var pos: Vector2 = _pick_spawn_pos(true)
	b.global_position = pos
	# mark as boss and scale stats
	if b.has_method("set"):
		if b.get("is_boss") != null:
			b.set("is_boss", true)
		var root_cfg2 := get_tree().get_root().get_node("GameRoot")
		if root_cfg2 and root_cfg2.has_method("get_character_value"):
			var bhp = root_cfg2.call("get_character_value", "boss", "max_hp", b.get("max_hp"))
			var bdmg = root_cfg2.call("get_character_value", "boss", "damage", b.get("damage"))
			if bhp != null and b.get("max_hp") != null:
				b.set("max_hp", int(bhp))
				if b.get("hp") != null:
					b.set("hp", int(bhp))
			if bdmg != null and b.get("damage") != null:
				b.set("damage", int(bdmg))
		if b.get("speed") != null:
			var bspd = null
			if root_cfg2 and root_cfg2.has_method("get_character_value"):
				bspd = root_cfg2.call("get_character_value", "boss", "speed", b.get("speed"))
			b.set("speed", float(bspd if bspd != null else 130.0))
func set_post_interaction(v: bool):
	post_interaction = v
	if v:
		base_interval = interval
