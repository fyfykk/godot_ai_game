extends "res://scripts/characters/Enemy.gd"

const BOSS_COLLIDER_SIZE: Vector2 = Vector2(20.0, 30.0)

func _ready():
	is_boss = true
	super._ready()
	if enemy_sprite:
		enemy_sprite.texture = _build_sadako_sheet(20, 30)
		enemy_sprite.hframes = 5
		enemy_sprite.vframes = 1
		enemy_sprite.frame = 0
		enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		enemy_sprite.modulate = Color(0.95, 0.95, 0.98, 1.0)
		enemy_sprite.z_index = 20
		base_color = enemy_sprite.modulate
		if sprite_outline:
			sprite_outline.z_index = max(enemy_sprite.z_index - 1, 0)
	attack_anim_duration = 0.32
	walk_anim_speed = 5.0
	var cs: CollisionShape2D = $CollisionShape2D
	if cs:
		if cs.shape == null or not (cs.shape is RectangleShape2D):
			cs.shape = RectangleShape2D.new()
		var rect := cs.shape as RectangleShape2D
		rect.size = BOSS_COLLIDER_SIZE
	_refresh_visual_alignment()
	if has_method("set"):
		if get("speed") != null:
			set("speed", 130.0)

func _build_sadako_sheet(w: int, h: int) -> Texture2D:
	var frames: int = 5
	var img := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(frames):
		_draw_sadako_frame(img, i * w, 0, i)
	return ImageTexture.create_from_image(img)

func _draw_sadako_frame(img: Image, ox: int, oy: int, idx: int):
	var hair := Color(0.05, 0.05, 0.08, 1.0)
	var robe := Color(0.82, 0.82, 0.86, 1.0)
	var robe2 := Color(0.72, 0.72, 0.78, 1.0)
	var skin := Color(0.86, 0.88, 0.92, 1.0)
	var shadow := Color(0.12, 0.12, 0.14, 1.0)
	var leg_lx: int = 8
	var leg_rx: int = 12
	var arm_lx: int = 6
	var arm_rx: int = 13
	var drift_y: int = 0
	var hair_y: int = 12
	if idx == 1:
		leg_lx = 7
		leg_rx = 13
		arm_lx = 7
		arm_rx = 12
	elif idx == 2:
		leg_lx = 9
		leg_rx = 11
		arm_lx = 6
		arm_rx = 13
	elif idx == 3:
		drift_y = -1
		arm_lx = 4
		arm_rx = 13
	elif idx == 4:
		drift_y = -1
		arm_lx = 5
		arm_rx = 13
	_rect(img, ox + 6, oy + 2 + drift_y, 8, 2, skin)
	_rect(img, ox + 5, oy + 8 + drift_y, 10, 12, robe)
	_rect(img, ox + 6, oy + 9 + drift_y, 8, 10, robe2)
	_rect(img, ox + arm_lx, oy + 10 + drift_y, 3, 6, robe2)
	_rect(img, ox + arm_rx, oy + 10 + drift_y, 3, 6, robe2)
	_rect(img, ox + leg_lx, oy + 20 + drift_y, 2, 6, robe2)
	_rect(img, ox + leg_rx, oy + 20 + drift_y, 2, 6, robe2)
	_rect(img, ox + 6, oy + 0 + drift_y, 8, 2, hair)
	_rect(img, ox + 5, oy + 2 + drift_y, 10, 2, hair)
	_rect(img, ox + 4, oy + 4 + drift_y, 12, 8, hair)
	_rect(img, ox + 5, oy + 12 + drift_y, 10, 3, hair)
	_rect(img, ox + 6, oy + hair_y + drift_y, 8, 4, hair)
	_rect(img, ox + 7, oy + hair_y + 4 + drift_y, 6, 2, hair)
	_rect(img, ox + 8, oy + hair_y + 6 + drift_y, 4, 1, hair)
	_rect(img, ox + 7, oy + 12 + drift_y, 1, 4, hair)
	_rect(img, ox + 9, oy + 13 + drift_y, 1, 3, hair)
	_rect(img, ox + 11, oy + 12 + drift_y, 1, 4, hair)
	if idx == 3:
		_rect(img, ox + 12, oy + 4 + drift_y, 3, 4, robe2)
		_rect(img, ox + 14, oy + 2 + drift_y, 4, 4, robe2)
		_rect(img, ox + 16, oy + 6 + drift_y, 3, 3, robe2)
	elif idx == 4:
		_rect(img, ox + 12, oy + 10 + drift_y, 4, 5, robe2)
		_rect(img, ox + 15, oy + 14 + drift_y, 4, 4, robe2)
		_rect(img, ox + 16, oy + 18 + drift_y, 3, 2, robe2)
	_rect(img, ox + 7, oy + 6 + drift_y, 6, 2, shadow)

func _update_anim(delta: float):
	if enemy_sprite == null:
		return
	if attack_anim_time > 0.0:
		attack_anim_time = max(attack_anim_time - delta, 0.0)
		enemy_sprite.frame = 3 if attack_anim_time > attack_anim_duration * 0.5 else 4
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
		return
	var moving: bool = abs(velocity.x) > 1.0
	if not moving:
		walk_anim_time = 0.0
		enemy_sprite.frame = 0
		if sprite_outline:
			sprite_outline.frame = enemy_sprite.frame
		return
	walk_anim_time += delta * walk_anim_speed
	var step: int = int(floor(walk_anim_time)) % 2
	enemy_sprite.frame = 1 + step
	if sprite_outline:
		sprite_outline.frame = enemy_sprite.frame
