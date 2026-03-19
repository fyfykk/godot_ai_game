extends "res://scripts/items/Chest.gd"

@export var note_drop_chance: float = 0.5

func _ready():
	super._ready()
	chest_type = "single"
	if chest_sprite:
		chest_sprite.texture = _build_once_chest_texture(20, 12)

func _finish_open():
	opening = false
	if ring:
		ring.visible = false
	_drop_items_once()
	opened = true
	queue_free()

func _build_once_chest_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var wood1 := Color(0.9, 0.85, 0.2, 1.0)
	var wood2 := Color(0.8, 0.7, 0.16, 1.0)
	var edge := Color(0.2, 0.16, 0.05, 1.0)
	var mark := Color(0.2, 0.1, 0.02, 1.0)
	for y in range(th):
		for x in range(tw):
			var col := wood1 if ((x / 3 + y / 2) % 2) == 0 else wood2
			if x == 0 or x == tw - 1 or y == 0 or y == th - 1:
				col = edge
			if y == th / 2:
				col = edge
			img.set_pixel(x, y, col)
	var cx: int = tw / 2
	var cy: int = th / 2
	for dx in range(-1, 2):
		var px := cx + dx
		if px >= 0 and px < tw and cy >= 0 and cy < th:
			img.set_pixel(px, cy, mark)
		var py := cy + dx
		if cx >= 0 and cx < tw and py >= 0 and py < th:
			img.set_pixel(cx, py, mark)
	return ImageTexture.create_from_image(img)

func _drop_items_once():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var count := rng.randi_range(1, 3)
	var root := get_tree().get_root().get_node("GameRoot")
	var need_collectible: bool = false
	if root and root.has_method("has_available_collectible_choice"):
		need_collectible = bool(root.call("has_available_collectible_choice"))
	var collect_idx: int = -1
	if need_collectible:
		if count == 1:
			collect_idx = 0
		else:
			collect_idx = rng.randi_range(0, count - 1)
	for i in range(count):
		if i == collect_idx and need_collectible:
			_spawn_collectible_choice(i)
		else:
			_spawn_upgrade(i)

func _spawn_collectible_id(id: String, idx: int):
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "collectible_id"
	item.collectible_id = id
	item.amount = 1
	get_parent().add_child(item)
	_place_drop(item, idx)

func _spawn_upgrade(idx: int):
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "upgrade_choice"
	item.amount = 1
	get_parent().add_child(item)
	_place_drop(item, idx)

func _spawn_collectible_choice(idx: int):
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "collectible_note"
	item.amount = 1
	get_parent().add_child(item)
	_place_drop(item, idx)

func _place_drop(item: Area2D, idx: int):
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var base_x: float = global_position.x
	var side: float = -1.0 if (idx % 2) == 0 else 1.0
	var off: float = rng.randf_range(28.0, 64.0)
	var px_pre: float = base_x + side * off
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	var clamped := _clamp_drop_position(px_pre, item_half)
	item.global_position = clamped
	item.z_index = 30
