extends Area2D
class_name Bullet

@export var speed: float = 380.0
@export var damage: int = 1
@export var lifetime: float = 1.2
@export var dir: Vector2 = Vector2.RIGHT
var target: Node2D = null
var bullet_texture: Texture2D = preload("res://assets/vfx/fx_bullet_proj.png")
var muzzle_texture: Texture2D = preload("res://assets/vfx/fx_bullet_muzzle.png")
var hit_texture: Texture2D = preload("res://assets/vfx/fx_bullet_hit.png")
var sprite: Sprite2D = null
var base_lifetime: float = 0.0
static var pool: Array = []
static var burst_pool: Array = []

func _ready():
	if sprite != null:
		return
	base_lifetime = lifetime
	var cs: CollisionShape2D = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	cs.shape = shape
	add_child(cs)
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.texture = bullet_texture
	sprite.z_index = 210
	add_child(sprite)
	collision_layer = 8
	collision_mask = 2
	connect("body_entered", Callable(self, "_on_body_entered"))

static func fetch(scene: PackedScene) -> Bullet:
	while pool.size() > 0 and not is_instance_valid(pool[pool.size() - 1]):
		pool.remove_at(pool.size() - 1)
	var b: Bullet = null
	if pool.size() > 0:
		b = pool.pop_back()
	else:
		b = scene.instantiate()
	return b

func reset(pos: Vector2, d: int, t: Node2D, aim: Vector2):
	if base_lifetime <= 0.0:
		base_lifetime = lifetime
	global_position = pos
	damage = d
	target = t
	dir = aim
	lifetime = base_lifetime
	visible = true
	monitoring = true
	monitorable = true
	collision_layer = 8
	collision_mask = 2
	set_physics_process(true)
	_spawn_burst(muzzle_texture, 0.08, Vector2(1.0, 1.0), Vector2(1.6, 1.6), Color(1, 1, 1, 0.95))

func _physics_process(delta):
	if target != null and is_instance_valid(target):
		if _is_target_alive(target):
			dir = (target.global_position - global_position).normalized()
		else:
			target = null
	global_position += dir.normalized() * speed * delta
	if sprite:
		sprite.rotation = dir.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		_recycle()

func _is_target_alive(t: Node2D) -> bool:
	var dying: bool = false
	if t.has_method("get"):
		var raw_dying = t.get("is_dying")
		if raw_dying is bool:
			dying = raw_dying
	if dying:
		return false
	var hp_val: int = 1
	if t.has_method("get"):
		var raw_hp = t.get("hp")
		if raw_hp is int:
			hp_val = raw_hp
	if hp_val <= 0:
		return false
	return true

func _on_body_entered(b):
	if b and b.has_method("take_damage"):
		b.take_damage(damage)
	_spawn_burst(hit_texture, 0.12, Vector2(0.8, 0.8), Vector2(1.7, 1.7), Color(1, 1, 1, 0.95))
	_recycle()

func _spawn_burst(tex: Texture2D, life: float, from_scale: Vector2, to_scale: Vector2, tint: Color):
	if tex == null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var n := _get_burst_node()
	n.global_position = global_position
	n.z_index = 230
	if not n.is_inside_tree():
		tree.get_root().add_child(n)
	var s: Sprite2D = n.get_meta("sprite") as Sprite2D
	s.texture = tex
	s.modulate = tint
	s.scale = from_scale
	if n.has_meta("tween"):
		var old_tw = n.get_meta("tween")
		if old_tw and old_tw is Tween:
			old_tw.kill()
	var tw := n.create_tween()
	tw.parallel().tween_property(s, "scale", to_scale, life)
	tw.parallel().tween_property(s, "modulate:a", 0.0, life)
	tw.tween_callback(Callable(self, "_recycle_burst").bind(n))
	n.set_meta("tween", tw)

func _get_burst_node() -> Node2D:
	while burst_pool.size() > 0 and not is_instance_valid(burst_pool[burst_pool.size() - 1]):
		burst_pool.remove_at(burst_pool.size() - 1)
	if burst_pool.size() > 0:
		return burst_pool.pop_back()
	var n := Node2D.new()
	var s := Sprite2D.new()
	s.centered = true
	n.add_child(s)
	n.set_meta("sprite", s)
	return n

func _recycle_burst(n: Node2D):
	if n == null:
		return
	if n.has_meta("tween"):
		var old_tw = n.get_meta("tween")
		if old_tw and old_tw is Tween:
			old_tw.kill()
	n.set_meta("tween", null)
	if n.get_parent():
		n.get_parent().remove_child(n)
	burst_pool.append(n)

func _recycle():
	target = null
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	visible = false
	set_physics_process(false)
	call_deferred("_finalize_recycle")

func _finalize_recycle():
	var p := get_parent()
	if p:
		p.remove_child(self)
	pool.append(self)
