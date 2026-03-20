extends AttackModule

var damage: int = 10
var interval: float = 4.2
var cooldown: float = 0.0
var vfx_life: float = 1.0
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
	damage = _get_const_int("attack.roar_damage", damage)
	interval = _get_const_float("attack.roar_interval", interval)

func update(delta: float, owner: Node2D):
	if not enabled or owner == null:
		return
	cooldown = max(cooldown - delta, 0.0)
	if cooldown > 0.0:
		return
	if not _is_roar_ready(owner):
		return
	_perform_attack(owner)
	cooldown = interval

func _perform_attack(owner: Node2D):
	_spawn_vfx(owner)
	var delay: float = vfx_life
	var tree: SceneTree = owner.get_tree()
	if tree:
		var timer: SceneTreeTimer = tree.create_timer(delay)
		timer.timeout.connect(_on_roar_timeout.bind(owner))
	else:
		_on_roar_timeout(owner)

func _spawn_vfx(owner: Node2D):
	if not _is_roar_ready(owner):
		return
	var Circle: Script = preload("res://scripts/effects/RoarMagicCircle.gd")
	var fx: Node2D = Circle.new() as Node2D
	var layer_h: float = 80.0
	var root := owner.get_tree().get_root()
	if root and root.has_node("GameRoot/Level/Generator"):
		var gen := root.get_node("GameRoot/Level/Generator")
		if gen and gen.has_method("get") and gen.get("layer_height") != null:
			layer_h = float(gen.layer_height)
	fx.set("max_radius", layer_h * 0.5)
	fx.set("life", vfx_life)
	fx.set("thickness", 4.0)
	if not owner.has_method("get_roar_origin"):
		return
	var head: Node2D = null
	if owner.has_method("get_roar_head"):
		head = owner.call("get_roar_head") as Node2D
	if head and head.is_inside_tree():
		head.add_child(fx)
		fx.position = Vector2(0, 14)
		fx.z_index = -100
	else:
		owner.get_tree().get_root().add_child(fx)
		var origin: Vector2 = owner.call("get_roar_origin") as Vector2
		fx.global_position = origin

func upgrade(params: Dictionary):
	if params == null:
		return
	if params.has("damage"):
		damage = int(params["damage"])
	if params.has("interval"):
		interval = float(params["interval"])

func _on_roar_timeout(owner: Node2D):
	if owner == null:
		return
	var enemies := owner.get_tree().get_nodes_in_group("enemies")
	for n in enemies:
		if n and n.has_method("take_damage"):
			n.call("take_damage", damage)
	if owner.has_method("trigger_screen_shake"):
		owner.call("trigger_screen_shake", 12.0, 0.28)

func _is_roar_ready(owner: Node2D) -> bool:
	if owner.has_method("is_roar_head_ready"):
		return bool(owner.call("is_roar_head_ready"))
	return false

func get_display_name() -> String:
	return "龙咆哮"

func get_display_stats() -> Dictionary:
	return {"伤害": damage, "冷却": interval, "范围": "全屏"}
