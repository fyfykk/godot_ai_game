extends AttackModule

var damage: int = 2
var interval: float = 1.2
var range: float = 28.0
var cooldown: float = 0.0
var AttackArcScript: Script = preload("res://scripts/combat/AttackArc.gd")
var SwordWaveScript: Script = preload("res://scripts/effects/SwordWave.gd")
var root_ref = null

func _get_const_float(key: String, default_val: float) -> float:
	if root_ref and root_ref.has_method("get_const_float"):
		return float(root_ref.call("get_const_float", key, default_val))
	return default_val

func _get_const_int(key: String, default_val: int) -> int:
	if root_ref and root_ref.has_method("get_const_int"):
		return int(root_ref.call("get_const_int", key, default_val))
	return default_val

func setup(_owner: Node2D):
	cooldown = 0.0
	root_ref = _owner.get_tree().get_root().get_node_or_null("GameRoot") if _owner else null
	damage = _get_const_int("attack.melee_damage", damage)
	interval = _get_const_float("attack.melee_interval", interval)
	range = _get_const_float("attack.melee_range", range)

func update(delta: float, owner: Node2D):
	if not enabled or owner == null:
		return
	cooldown = max(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var target := _find_target(owner)
	if target:
		target.call("take_damage", damage)
		_spawn_vfx(owner, target)
		cooldown = interval

func _find_target(owner: Node2D) -> Node2D:
	var space: PhysicsDirectSpaceState2D = owner.get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = range
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, owner.global_position)
	params.collision_mask = 2
	var res: Array = space.intersect_shape(params, 16)
	var best: Node2D = null
	var best_d: float = INF
	for r in res:
		var n: Node = r.get("collider")
		if n and n != owner and n.is_in_group("enemies") and n.has_method("take_damage") and n is Node2D:
			var d: float = (n as Node2D).global_position.distance_to(owner.global_position)
			if d < best_d:
				best_d = d
				best = n as Node2D
	return best

func upgrade(params: Dictionary):
	if params == null:
		return
	if params.has("damage"):
		damage = int(params["damage"])
	if params.has("interval"):
		interval = float(params["interval"])
	if params.has("range"):
		range = float(params["range"])

func get_display_name() -> String:
	return "近战攻击"

func get_display_stats() -> Dictionary:
	return {"伤害": damage, "攻速": interval, "范围": range}

func _spawn_vfx(owner: Node2D, target: Node2D):
	var dir: float = sign(target.global_position.x - owner.global_position.x)
	if SwordWaveScript:
		var wave: Node2D = SwordWaveScript.new() as Node2D
		var slash_tex := _build_half_moon_texture(92, 48)
		owner.get_tree().get_root().add_child(wave)
		var start_pos := owner.global_position + Vector2(-8.0 * dir, -6.0)
		var end_pos := owner.global_position + Vector2(range * 1.35 * dir, -6.0)
		var s0 := Vector2(range * 1.35, range * 0.9)
		var s1 := Vector2(range * 2.7, range * 1.45)
		wave.set("life", 0.26)
		wave.set("color", Color(0.65, 1.0, 1.0, 1.0))
		wave.call("setup", start_pos, end_pos, s0, s1, slash_tex, dir)
	elif AttackArcScript:
		var arc: Node2D = AttackArcScript.new() as Node2D
		var slash_tex2 := _build_half_moon_texture(48, 24)
		arc.set("texture", slash_tex2)
		arc.set("life", 0.2)
		owner.get_tree().get_root().add_child(arc)
		arc.z_index = 200
		arc.set("color", Color(0.55, 0.95, 1.0, 0.9))
		arc.setup(owner.global_position + Vector2(8.0 * dir, -2.0), dir, Vector2(range * 1.0, range * 0.7))
		arc.rotation = -0.3 * dir
	if owner and owner.has_method("play_sword_slash"):
		owner.call("play_sword_slash", dir)

func _build_half_moon_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var core := Color(0.65, 0.98, 1.0, 0.9)
	var edge := Color(0.25, 0.7, 1.0, 0.6)
	var cx: float = float(w) * 0.05
	var cy: float = float(h) * 0.85
	var r: float = float(w) * 1.28
	for y in range(h):
		for x in range(w):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var d: float = sqrt(dx * dx + dy * dy)
			var band: float = abs(d - r * 0.58)
			var t: float = float(x) / max(float(w - 1), 1.0)
			var boost: float = 0.25 + 0.75 * t
			var taper: float = sin(t * PI)
			var thickness: float = 1.2 + taper * 2.2
			if band <= thickness:
				var col := Color(core.r, core.g, core.b, core.a * boost)
				img.set_pixel(x, y, col)
			elif band <= thickness + 2.4:
				var col2 := Color(edge.r, edge.g, edge.b, edge.a * boost)
				img.set_pixel(x, y, col2)
	return ImageTexture.create_from_image(img)
