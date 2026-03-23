extends AttackModule

var damage: int = 1
var interval: float = 0.8
var attack_range: float = 150.0
var cooldown: float = 0.0

var bullet_scene: PackedScene = preload("res://scenes/Bullet.tscn")
var bullet_script: Script = preload("res://scripts/combat/Bullet.gd")
var root_ref = null
var query_shape: CircleShape2D = null
var query_params: PhysicsShapeQueryParameters2D = null

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
	damage = _get_const_int("attack.bullet_damage", damage)
	interval = _get_const_float("attack.bullet_interval", interval)
	attack_range = _get_const_float("attack.bullet_range", attack_range)
	if query_shape == null:
		query_shape = CircleShape2D.new()
	if query_params == null:
		query_params = PhysicsShapeQueryParameters2D.new()
		query_params.shape = query_shape
		query_params.collision_mask = 2

func update(delta: float, owner: Node2D):
	if not enabled or owner == null:
		return
	cooldown = max(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	var target := _find_target(owner)
	if target:
		_perform_attack(owner, target)
		cooldown = interval

func _find_target(owner: Node2D) -> Node2D:
	var space: PhysicsDirectSpaceState2D = owner.get_world_2d().direct_space_state
	if query_shape == null or query_params == null:
		query_shape = CircleShape2D.new()
		query_params = PhysicsShapeQueryParameters2D.new()
		query_params.shape = query_shape
		query_params.collision_mask = 2
	query_shape.radius = attack_range
	query_params.transform = Transform2D(0.0, owner.global_position)
	var res: Array = space.intersect_shape(query_params, 32)
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

func _perform_attack(owner: Node2D, target: Node2D):
	if bullet_scene:
		var b: Node = bullet_script.call("fetch", bullet_scene)
		var root := owner.get_tree().get_root()
		if b.get_parent() == null:
			root.add_child(b)
		elif b.get_parent() != root:
			b.reparent(root)
		var muzzle_pos: Vector2 = owner.global_position
		if owner and owner.has_method("get_muzzle_position"):
			muzzle_pos = owner.call("get_muzzle_position")
		var aim_dir: Vector2 = (target.global_position - muzzle_pos).normalized()
		if b and b.has_method("reset"):
			b.call("reset", muzzle_pos, damage, target, aim_dir)
		if owner and owner.has_method("set_gun_aim"):
			owner.call("set_gun_aim", aim_dir)

func upgrade(params: Dictionary):
	if params == null:
		return
	if params.has("damage"):
		damage = int(params["damage"])
	if params.has("interval"):
		interval = float(params["interval"])
	if params.has("range"):
		attack_range = float(params["range"])
func get_display_name() -> String:
	return "子弹攻击"
func get_display_stats() -> Dictionary:
	return {"伤害": damage, "攻速": interval, "范围": attack_range}
