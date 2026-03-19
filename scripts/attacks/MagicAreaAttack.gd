extends AttackModule

var damage: int = 1
var interval: float = 2.5
var radius: float = 80.0
var cooldown: float = 0.0
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
	damage = _get_const_int("attack.magic_damage", damage)
	interval = _get_const_float("attack.magic_interval", interval)
	radius = _get_const_float("attack.magic_radius", radius)

func update(delta: float, owner: Node2D):
	if not enabled or owner == null:
		return
	cooldown = max(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	_damage_area(owner)
	cooldown = interval

func _damage_area(owner: Node2D):
	var space: PhysicsDirectSpaceState2D = owner.get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, owner.global_position)
	params.collision_mask = 2
	var res: Array = space.intersect_shape(params, 64)
	for r in res:
		var n: Node = r.get("collider")
		if n and n.is_in_group("enemies") and n.has_method("take_damage") and n is Node2D:
			n.call("take_damage", damage)
	_spawn_vfx(owner)

func upgrade(params: Dictionary):
	if params == null:
		return
	if params.has("damage"):
		damage = int(params["damage"])
	if params.has("interval"):
		interval = float(params["interval"])
	if params.has("radius"):
		radius = float(params["radius"])

func get_display_name() -> String:
	return "范围魔法"

func get_display_stats() -> Dictionary:
	return {"伤害": damage, "冷却": interval, "半径": radius}

func _spawn_vfx(owner: Node2D):
	var Talisman: Script = preload("res://scripts/effects/TalismanBurst.gd")
	var fx: Node2D = Talisman.new() as Node2D
	owner.get_tree().get_root().add_child(fx)
	var origin := owner.global_position
	if owner.has_method("get_magic_origin"):
		origin = owner.call("get_magic_origin")
	fx.global_position = origin
	fx.radius = radius
	fx.count = 18
