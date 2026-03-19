extends Area2D

@export var heal_ratio: float = 0.5
var prompt

func _ready():
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	cs.shape = shape
	add_child(cs)
	var sprite := Sprite2D.new()
	sprite.texture = _build_medkit_texture(16, 16)
	sprite.centered = true
	sprite.z_index = 100
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
	prompt = PromptScript.new()
	prompt.key_text = "E"
	add_child(prompt)
	collision_layer = 0
	collision_mask = 1
	add_to_group("medkit")
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	set_process(true)

func _on_body_entered(b):
	if b and b.is_in_group("player"):
		pass

func _on_body_exited(b):
	if b and b.is_in_group("player"):
		pass

func try_interact(p: Node2D):
	if p and p.has_method("heal_half"):
		p.call("heal_half", heal_ratio)
	queue_free()

func _process(_delta):
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
	return true

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func _build_medkit_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var base1 := Color(1.0, 1.0, 1.0, 1.0)
	var base2 := Color(0.9, 0.9, 0.95, 1.0)
	var edge := Color(0.15, 0.15, 0.18, 1.0)
	var cross := Color(0.95, 0.2, 0.2, 1.0)
	for y in range(th):
		for x in range(tw):
			var col := base1 if ((x / 2 + y / 2) % 2) == 0 else base2
			if x == 0 or y == 0 or x == tw - 1 or y == th - 1:
				col = edge
			if (x >= tw / 2 - 1 and x <= tw / 2 + 1 and y >= 3 and y <= th - 4) or (y >= th / 2 - 1 and y <= th / 2 + 1 and x >= 3 and x <= tw - 4):
				col = cross
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
