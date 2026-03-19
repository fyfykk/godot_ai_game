extends Area2D

@export var kind: String = "bullet_damage"
@export var amount: int = 1
@export var value: int = 0
@export var collectible_id: String = ""
var prompt
var pickup_shape: CollisionShape2D
var pickup_sprite: Sprite2D

func _ready():
	var cs := CollisionShape2D.new()
	add_child(cs)
	var sprite := Sprite2D.new()
	sprite.z_index = 100
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	pickup_shape = cs
	pickup_sprite = sprite
	if kind == "coin":
		var cshape := CircleShape2D.new()
		cshape.radius = 6.0
		cs.shape = cshape
		sprite.texture = _build_pickup_texture(kind, 14, 14)
	elif kind == "collectible_id":
		var rshape := RectangleShape2D.new()
		rshape.size = Vector2(18, 18)
		cs.shape = rshape
		if collectible_id != "":
			var root := get_tree().get_root().get_node_or_null("GameRoot")
			if root and root.has_method("get_collectible_icon_texture"):
				var tex = root.call("get_collectible_icon_texture", collectible_id, 24, 24)
				if tex:
					sprite.texture = tex
				else:
					sprite.texture = _build_pickup_texture("collectible", 24, 24)
			else:
				sprite.texture = _build_pickup_texture("collectible", 24, 24)
		else:
			sprite.texture = _build_pickup_texture("collectible", 24, 24)
	elif kind == "collectible_boss":
		var rshape2 := RectangleShape2D.new()
		rshape2.size = Vector2(16, 16)
		cs.shape = rshape2
		sprite.texture = _build_pickup_texture("collectible_boss", 16, 16)
	elif kind == "collectible" or kind == "collectible_note":
		var rshape2 := RectangleShape2D.new()
		rshape2.size = Vector2(12, 12)
		cs.shape = rshape2
		sprite.texture = _build_pickup_texture("collectible", 14, 14)
	else:
		var rshape2 := RectangleShape2D.new()
		rshape2.size = Vector2(12, 12)
		cs.shape = rshape2
		sprite.texture = _build_pickup_texture(kind, 14, 14)
	collision_layer = 0
	collision_mask = 1
	connect("body_entered", Callable(self, "_on_body_entered"))
	if kind == "collectible_id" and collectible_id != "":
		var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
		prompt = PromptScript.new()
		prompt.key_text = "E"
		add_child(prompt)
		add_to_group("pickup")
		set_process(true)

func _on_body_entered(b):
	if b and b.is_in_group("player") and b.has_method("apply_pickup"):
		if kind == "collectible_id" and collectible_id != "":
			return
		var amt := amount
		if kind == "coin" and value > 0:
			amt = value
		if kind == "collectible_id" and collectible_id != "":
			if not bool(b.apply_pickup("collectible_id:" + collectible_id, amt)):
				return
		else:
			if not bool(b.apply_pickup(kind, amt)):
				return
		queue_free()

func _process(_delta):
	if kind != "collectible_id" or collectible_id == "":
		return
	var players := get_tree().get_nodes_in_group("player")
	var player_ref: Node2D = null
	if players.size() > 0:
		player_ref = players[0] as Node2D
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt and is_instance_valid(prompt):
		prompt.visible = target_ok
	if prompt and is_instance_valid(prompt) and prompt.visible:
		var prompt_y: float = _get_prompt_y()
		prompt.set_world_position(Vector2(global_position.x, prompt_y))

func get_drop_half_height() -> float:
	if pickup_shape and pickup_shape.shape:
		if pickup_shape.shape is RectangleShape2D:
			var sz := (pickup_shape.shape as RectangleShape2D).size
			return max(1.0, sz.y * 0.5)
		if pickup_shape.shape is CircleShape2D:
			return max(1.0, (pickup_shape.shape as CircleShape2D).radius)
	if pickup_sprite and pickup_sprite.texture:
		return max(1.0, float(pickup_sprite.texture.get_height()) * 0.5)
	return 6.0

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

func is_interactable() -> bool:
	return kind == "collectible_id" and collectible_id != ""

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func get_interact_radius() -> float:
	return 28.0

func try_interact(p: Node2D):
	if kind != "collectible_id" or collectible_id == "":
		return
	if p and p.has_method("apply_pickup"):
		if bool(p.call("apply_pickup", "collectible_id:" + collectible_id, amount)):
			queue_free()

func _build_pickup_texture(k: String, w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var edge := Color(0.12, 0.12, 0.12, 1.0)
	var c1 := Color(0.4, 0.6, 1.0, 1.0)
	var c2 := Color(0.3, 0.5, 0.86, 1.0)
	if k == "coin":
		c1 = Color(1.0, 0.86, 0.24, 1.0)
		c2 = Color(0.86, 0.66, 0.12, 1.0)
	elif k == "collectible" or k == "collectible_id":
		c1 = Color(0.74, 0.43, 1.0, 1.0)
		c2 = Color(0.56, 0.3, 0.82, 1.0)
	elif k == "collectible_boss":
		c1 = Color(1.0, 0.35, 0.2, 1.0)
		c2 = Color(0.86, 0.18, 0.18, 1.0)
	elif k == "upgrade_choice":
		c1 = Color(0.4, 0.9, 0.5, 1.0)
		c2 = Color(0.2, 0.7, 0.35, 1.0)
	for y in range(th):
		for x in range(tw):
			var inside: bool = true
			if k == "coin":
				var nx: float = (float(x) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var ny: float = (float(y) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				inside = nx * nx + ny * ny <= 1.0
			elif k == "collectible" or k == "collectible_id" or k == "collectible_boss":
				inside = abs(float(x - tw / 2)) + abs(float(y - th / 2)) <= float(min(tw, th) / 2)
			if not inside:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := c1 if ((x / 2 + y / 2) % 2) == 0 else c2
			var near_edge: bool = x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if not near_edge and k == "coin":
				var nx_l: float = (float(x - 1) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var nx_r: float = (float(x + 1) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var ny_u: float = (float(y - 1) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				var ny_d: float = (float(y + 1) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				var nx_c: float = (float(x) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var ny_c: float = (float(y) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				near_edge = nx_l * nx_l + ny_c * ny_c > 1.0 or nx_r * nx_r + ny_c * ny_c > 1.0 or nx_c * nx_c + ny_u * ny_u > 1.0 or nx_c * nx_c + ny_d * ny_d > 1.0
			elif not near_edge and (k == "collectible" or k == "collectible_id" or k == "collectible_boss"):
				var md: float = float(min(tw, th) / 2)
				near_edge = abs(float((x - 1) - tw / 2)) + abs(float(y - th / 2)) > md or abs(float((x + 1) - tw / 2)) + abs(float(y - th / 2)) > md or abs(float(x - tw / 2)) + abs(float((y - 1) - th / 2)) > md or abs(float(x - tw / 2)) + abs(float((y + 1) - th / 2)) > md
			if near_edge:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
