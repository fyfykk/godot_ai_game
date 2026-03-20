extends Area2D

@export var speed: float = 380.0
@export var damage: int = 1
@export var lifetime: float = 1.2
@export var dir: Vector2 = Vector2.RIGHT
var target: Node2D = null
var bullet_texture: Texture2D = preload("res://assets/vfx/fx_bullet_proj.png")
var muzzle_texture: Texture2D = preload("res://assets/vfx/fx_bullet_muzzle.png")
var hit_texture: Texture2D = preload("res://assets/vfx/fx_bullet_hit.png")
var sprite: Sprite2D = null

func _ready():
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
		queue_free()

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
	queue_free()

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
