extends RefCounted

var CodexScript := preload("res://scripts/core/Codex.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")
var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
var EquipConfigScript := preload("res://scripts/data/EquipmentConfig.gd")

var owner
var meta_store
var coll_config
var coll_store
var rarity_color_cb: Callable
var build_collectible_icon_cb: Callable

var gacha_overlay: ColorRect
var gacha_panel: PanelContainer
var gacha_bg: ColorRect
var gacha_card: PanelContainer
var gacha_close_button: Button
var gacha_draw_button: Button
var gacha_draw_ten_button: Button
var gacha_ticket_label: Label
var gacha_ticket_icon: TextureRect
var gacha_ticket_help_button: Button
var gacha_pity_label: Label
var gacha_result_label: Label
var gacha_prize_icon: TextureRect
var gacha_results_grid: GridContainer
var gacha_results_items: Array = []
var gacha_animating: bool = false
var gacha_anim_tween
var gacha_codex_helper
var gacha_rng: RandomNumberGenerator

const GACHA_DRAGON_ID: String = "EQ004"
const GACHA_PITY_MAX: int = 50
const GACHA_PITY_START: int = 40
const GACHA_BASE_RATE: float = 0.005
const GACHA_RAMP: Array = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.98]
const GACHA_EPIC_RATE: float = 0.2

func setup(owner_node, meta_store_ref, coll_config_ref, coll_store_ref, rarity_color_callable: Callable, build_collectible_icon_callable: Callable):
	owner = owner_node
	meta_store = meta_store_ref
	coll_config = coll_config_ref
	coll_store = coll_store_ref
	rarity_color_cb = rarity_color_callable
	build_collectible_icon_cb = build_collectible_icon_callable
	gacha_codex_helper = CodexScript.new()
	gacha_rng = RandomNumberGenerator.new()
	gacha_rng.randomize()

func build():
	var root: Node = owner.get_tree().get_root()
	gacha_overlay = ColorRect.new()
	root.call_deferred("add_child", gacha_overlay)
	gacha_overlay.color = Color(0, 0, 0, 0.85)
	gacha_overlay.visible = false
	gacha_overlay.z_index = 300
	if gacha_overlay is Control:
		(gacha_overlay as Control).anchor_left = 0.0
		(gacha_overlay as Control).anchor_top = 0.0
		(gacha_overlay as Control).anchor_right = 1.0
		(gacha_overlay as Control).anchor_bottom = 1.0
		(gacha_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	gacha_panel = PanelContainer.new()
	root.call_deferred("add_child", gacha_panel)
	gacha_panel.visible = false
	gacha_panel.z_index = 310
	if gacha_panel is Control:
		(gacha_panel as Control).anchor_left = 0.0
		(gacha_panel as Control).anchor_top = 0.0
		(gacha_panel as Control).anchor_right = 1.0
		(gacha_panel as Control).anchor_bottom = 1.0
		(gacha_panel as Control).offset_left = 0
		(gacha_panel as Control).offset_top = 0
		(gacha_panel as Control).offset_right = 0
		(gacha_panel as Control).offset_bottom = 0
		(gacha_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	gacha_bg = ColorRect.new()
	gacha_bg.color = Color(0.06, 0.08, 0.12, 0.96)
	if gacha_bg is Control:
		(gacha_bg as Control).anchor_left = 0.0
		(gacha_bg as Control).anchor_top = 0.0
		(gacha_bg as Control).anchor_right = 1.0
		(gacha_bg as Control).anchor_bottom = 1.0
	gacha_panel.add_child(gacha_bg)
	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.anchor_left = 0.0
	center_box.anchor_top = 0.0
	center_box.anchor_right = 1.0
	center_box.anchor_bottom = 1.0
	center_box.offset_left = 0
	center_box.offset_top = 0
	center_box.offset_right = 0
	center_box.offset_bottom = 0
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gacha_panel.add_child(center_box)
	gacha_card = PanelContainer.new()
	gacha_card.custom_minimum_size = Vector2(760, 560)
	gacha_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gacha_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.add_child(gacha_card)
	var card_box := VBoxContainer.new()
	card_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_box.add_theme_constant_override("separation", 18)
	gacha_card.add_child(card_box)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 20)
	card_box.add_child(header_row)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 6)
	header_row.add_child(title_box)
	var title := Label.new()
	title.text = "龙咆哮祈愿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_box.add_child(title)
	var stats_box := VBoxContainer.new()
	stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_box.alignment = BoxContainer.ALIGNMENT_END
	header_row.add_child(stats_box)
	var ticket_row := HBoxContainer.new()
	ticket_row.alignment = BoxContainer.ALIGNMENT_END
	ticket_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ticket_row.add_theme_constant_override("separation", 6)
	stats_box.add_child(ticket_row)
	gacha_ticket_icon = TextureRect.new()
	gacha_ticket_icon.custom_minimum_size = Vector2(24, 24)
	gacha_ticket_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gacha_ticket_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ticket_row.add_child(gacha_ticket_icon)
	gacha_ticket_label = Label.new()
	gacha_ticket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ticket_row.add_child(gacha_ticket_label)
	gacha_ticket_help_button = Button.new()
	gacha_ticket_help_button.text = "?"
	gacha_ticket_help_button.custom_minimum_size = Vector2(22, 22)
	gacha_ticket_help_button.pressed.connect(_on_gacha_ticket_help_pressed)
	ticket_row.add_child(gacha_ticket_help_button)
	gacha_pity_label = Label.new()
	gacha_pity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_box.add_child(gacha_pity_label)
	var prize_row := HBoxContainer.new()
	prize_row.add_theme_constant_override("separation", 12)
	card_box.add_child(prize_row)
	gacha_prize_icon = TextureRect.new()
	gacha_prize_icon.custom_minimum_size = Vector2(88, 88)
	gacha_prize_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gacha_prize_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prize_row.add_child(gacha_prize_icon)
	var prize_text_box := VBoxContainer.new()
	prize_text_box.add_theme_constant_override("separation", 4)
	prize_row.add_child(prize_text_box)
	var prize_title := Label.new()
	prize_title.text = "大奖"
	prize_text_box.add_child(prize_title)
	var prize_name := Label.new()
	prize_name.text = "龙咆哮"
	prize_text_box.add_child(prize_name)
	gacha_result_label = Label.new()
	gacha_result_label.text = ""
	gacha_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gacha_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_box.add_child(gacha_result_label)
	gacha_results_grid = GridContainer.new()
	gacha_results_grid.columns = 5
	gacha_results_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_results_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gacha_results_grid.add_theme_constant_override("h_separation", 8)
	gacha_results_grid.add_theme_constant_override("v_separation", 8)
	card_box.add_child(gacha_results_grid)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	card_box.add_child(btn_row)
	gacha_draw_button = Button.new()
	gacha_draw_button.text = "抽一次"
	gacha_draw_button.custom_minimum_size = Vector2(220, 52)
	gacha_draw_button.pressed.connect(_on_gacha_draw_pressed)
	btn_row.add_child(gacha_draw_button)
	gacha_draw_ten_button = Button.new()
	gacha_draw_ten_button.text = "十连抽"
	gacha_draw_ten_button.custom_minimum_size = Vector2(220, 52)
	gacha_draw_ten_button.pressed.connect(_on_gacha_draw_ten_pressed)
	btn_row.add_child(gacha_draw_ten_button)
	gacha_close_button = Button.new()
	gacha_close_button.text = "关闭"
	gacha_close_button.custom_minimum_size = Vector2(180, 52)
	gacha_close_button.pressed.connect(hide)
	btn_row.add_child(gacha_close_button)
	gacha_prize_icon.texture = _get_dragon_icon(96)
	if gacha_ticket_icon:
		gacha_ticket_icon.texture = _build_gacha_ticket_icon(24)
	update_labels()
	UIFontScript.apply_tree(gacha_overlay)
	UIFontScript.apply_tree(gacha_panel)

func show():
	update_labels()
	if gacha_result_label:
		gacha_result_label.text = ""
	_clear_gacha_results()
	if gacha_overlay:
		gacha_overlay.visible = true
	if gacha_panel:
		gacha_panel.visible = true

func hide():
	if gacha_anim_tween:
		gacha_anim_tween.kill()
		gacha_anim_tween = null
	gacha_animating = false
	if gacha_draw_button:
		gacha_draw_button.disabled = false
	if gacha_overlay:
		gacha_overlay.visible = false
	if gacha_panel:
		gacha_panel.visible = false

func cleanup():
	if gacha_overlay and gacha_overlay.is_inside_tree():
		gacha_overlay.queue_free()
	if gacha_panel and gacha_panel.is_inside_tree():
		gacha_panel.queue_free()

func update_labels():
	if meta_store == null:
		return
	var pool_empty := _is_gacha_pool_empty()
	if gacha_ticket_label:
		gacha_ticket_label.text = "x%d" % int(meta_store.gacha_tickets)
	if gacha_pity_label:
		gacha_pity_label.text = "保底进度：%d/%d" % [int(meta_store.gacha_pity), GACHA_PITY_MAX]
	if gacha_draw_button:
		gacha_draw_button.text = "抽一次"
		gacha_draw_button.disabled = gacha_animating or int(meta_store.gacha_tickets) <= 0 or pool_empty
	if gacha_draw_ten_button:
		gacha_draw_ten_button.text = "十连抽"
		gacha_draw_ten_button.disabled = gacha_animating or int(meta_store.gacha_tickets) < 10 or pool_empty
	if pool_empty and gacha_result_label and not gacha_animating:
		gacha_result_label.text = "奖池已空"

func _on_gacha_ticket_help_pressed():
	var dlg := AcceptDialog.new()
	dlg.title = "抽奖券"
	dlg.dialog_text = "抽奖券通过通关掉落"
	owner.add_child(dlg)
	dlg.popup_centered()

func _on_gacha_draw_pressed():
	if meta_store == null:
		return
	if gacha_animating:
		return
	if _is_gacha_pool_empty():
		if gacha_result_label:
			gacha_result_label.text = "奖池已空"
		update_labels()
		return
	if not meta_store.spend_gacha_tickets(1):
		if gacha_result_label:
			gacha_result_label.text = "抽奖券不足"
		update_labels()
		return
	var result := _perform_single_draw()
	meta_store.save()
	await _play_gacha_reveal([result])
	update_labels()

func _on_gacha_draw_ten_pressed():
	if meta_store == null:
		return
	if gacha_animating:
		return
	if _is_gacha_pool_empty():
		if gacha_result_label:
			gacha_result_label.text = "奖池已空"
		update_labels()
		return
	if int(meta_store.gacha_tickets) < 10:
		if gacha_result_label:
			gacha_result_label.text = "抽奖券不足"
		update_labels()
		return
	var results: Array = []
	for _i in range(10):
		if _is_gacha_pool_empty():
			break
		if not meta_store.spend_gacha_tickets(1):
			break
		results.append(_perform_single_draw())
	meta_store.save()
	await _play_gacha_reveal(results)
	update_labels()

func _is_gacha_pool_empty() -> bool:
	var grand := _get_gacha_grand_candidates()
	if grand.size() > 0:
		return false
	var pool := _get_gacha_collectible_pool()
	return pool.size() == 0

func _is_dragon_available() -> bool:
	var equip_store: Node = owner.get_tree().get_root().get_node_or_null("EquipmentStore")
	if equip_store and equip_store.has_method("has_item"):
		return not bool(equip_store.call("has_item", GACHA_DRAGON_ID))
	return true

func _is_password_note(rec: Dictionary) -> bool:
	var id := String(rec.get("id", ""))
	if id.begins_with("W00"):
		return true
	var name := String(rec.get("name", ""))
	if name.find("密码纸条") >= 0:
		return true
	var icon := String(rec.get("icon", ""))
	if icon == "note":
		return true
	return false

func _ensure_collectible_data():
	if coll_config == null:
		coll_config = CollConfigScript.new()
		coll_config.load_csv()
	if coll_store == null:
		coll_store = CollStoreScript.new()
		coll_store.load()

func _get_gacha_grand_candidates() -> Array:
	_ensure_collectible_data()
	var candidates: Array = []
	if _is_dragon_available():
		candidates.append({"type": "dragon", "id": GACHA_DRAGON_ID})
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		if _is_password_note(rec):
			continue
		var rar := String(rec.get("rarity", ""))
		if rar != "red":
			continue
		var count := int(coll_store.get_count(id))
		if count > 0:
			continue
		candidates.append({"type": "collectible", "id": id})
	return candidates

func _get_gacha_collectible_pool() -> Array:
	_ensure_collectible_data()
	var ids: Array = []
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		if _is_password_note(rec):
			continue
		var rar := String(rec.get("rarity", ""))
		if rar != "blue" and rar != "epic":
			continue
		ids.append(id)
	return ids

func _perform_single_draw() -> Dictionary:
	var pity: int = int(meta_store.gacha_pity)
	var draw_index: int = pity + 1
	var grand_candidates := _get_gacha_grand_candidates()
	var has_grand := grand_candidates.size() > 0
	var roll_grand := false
	if has_grand:
		if draw_index >= GACHA_PITY_MAX:
			roll_grand = true
		else:
			var chance := _get_grand_chance(draw_index)
			roll_grand = gacha_rng.randf() < chance
	if roll_grand:
		meta_store.gacha_pity = 0
		var pick_idx := gacha_rng.randi_range(0, grand_candidates.size() - 1)
		var pick: Dictionary = grand_candidates[pick_idx]
		var typ := String(pick.get("type", ""))
		var pid := String(pick.get("id", ""))
		if typ == "dragon":
			return _grant_dragon_reward()
		if pid != "":
			return _grant_collectible_by_id(pid)
		return {"text": "获得失败", "type": "none", "id": ""}
	if has_grand:
		meta_store.gacha_pity = pity + 1
	else:
		meta_store.gacha_pity = 0
	var cid := _grant_random_collectible()
	if cid != "":
		return _build_collectible_result(cid)
	return {"text": "奖池已空", "type": "none", "id": ""}

func _get_grand_chance(draw_index: int) -> float:
	if draw_index >= GACHA_PITY_MAX:
		return 1.0
	if draw_index < GACHA_PITY_START:
		return GACHA_BASE_RATE
	var idx: int = draw_index - GACHA_PITY_START
	if idx >= 0 and idx < GACHA_RAMP.size():
		return float(GACHA_RAMP[idx])
	return 0.9

func _grant_dragon_reward() -> Dictionary:
	var equip_store: Node = owner.get_tree().get_root().get_node_or_null("EquipmentStore")
	if equip_store and equip_store.has_method("has_item") and equip_store.has_method("add_to_backpack"):
		var already := bool(equip_store.call("has_item", GACHA_DRAGON_ID))
		if already:
			var cid := _grant_random_collectible()
			if cid != "":
				return {"text": "已拥有：龙咆哮，转为收藏品：%s" % _get_collectible_name(cid), "type": "collectible", "id": cid}
			return {"text": "已拥有：龙咆哮", "type": "dragon", "id": GACHA_DRAGON_ID}
		var added := bool(equip_store.call("add_to_backpack", GACHA_DRAGON_ID))
		if added:
			return {"text": "获得：龙咆哮", "type": "dragon", "id": GACHA_DRAGON_ID}
		var cid2 := _grant_random_collectible()
		if cid2 != "":
			return {"text": "获得失败，转为收藏品：%s" % _get_collectible_name(cid2), "type": "collectible", "id": cid2}
		return {"text": "获得失败", "type": "none", "id": ""}
	var cid3 := _grant_random_collectible()
	if cid3 != "":
		return {"text": "获得失败，转为收藏品：%s" % _get_collectible_name(cid3), "type": "collectible", "id": cid3}
	return {"text": "获得失败", "type": "none", "id": ""}

func _grant_random_collectible() -> String:
	_ensure_collectible_data()
	var blue_ids: Array = []
	var epic_ids: Array = []
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		if _is_password_note(rec):
			continue
		var rar := String(rec.get("rarity", ""))
		if rar == "blue":
			blue_ids.append(id)
		elif rar == "epic":
			epic_ids.append(id)
	if blue_ids.size() == 0 and epic_ids.size() == 0:
		return ""
	var pick_epic := gacha_rng.randf() < GACHA_EPIC_RATE
	var pool: Array = []
	if pick_epic and epic_ids.size() > 0:
		pool = epic_ids
	elif blue_ids.size() > 0:
		pool = blue_ids
	else:
		pool = epic_ids
	var idx := gacha_rng.randi_range(0, pool.size() - 1)
	var cid := String(pool[idx])
	coll_store.add(cid)
	return cid

func _grant_collectible_by_id(cid: String) -> Dictionary:
	_ensure_collectible_data()
	coll_store.add(cid)
	return _build_collectible_result(cid)

func _build_collectible_result(cid: String) -> Dictionary:
	return {"text": "获得收藏品：%s" % _get_collectible_name(cid), "type": "collectible", "id": cid}

func _get_collectible_name(id: String) -> String:
	if coll_config == null:
		return id
	var rec: Dictionary = coll_config.get_item(id)
	var name: String = String(rec.get("name", ""))
	if name == "":
		return id
	return name

func _get_collectible_rarity(id: String) -> String:
	if coll_config == null:
		return "white"
	var rec: Dictionary = coll_config.get_item(id)
	return String(rec.get("rarity", "white"))

func _get_collectible_icon_key(id: String) -> String:
	if coll_config == null:
		return id
	var rec: Dictionary = coll_config.get_item(id)
	return String(rec.get("icon", id))

func _get_collectible_grid_size(id: String) -> Vector2i:
	if coll_config == null:
		return Vector2i(1, 1)
	var rec: Dictionary = coll_config.get_item(id)
	return Vector2i(int(rec.get("w", 1)), int(rec.get("h", 1)))

func _get_dragon_icon(size: int = 128) -> Texture2D:
	var equip_cfg = owner.get_tree().get_root().get_node_or_null("EquipmentConfig")
	if equip_cfg and equip_cfg.has_method("build_equipment_icon"):
		var tex: Texture2D = equip_cfg.call("build_equipment_icon", "roar", size) as Texture2D
		if tex:
			return tex
	var tmp := EquipConfigScript.new()
	return tmp.build_equipment_icon("roar", size)

func _build_ticket_icon(w: int, h: int) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var base := Color(0.25, 0.55, 1.0, 1.0)
	var dark := Color(0.12, 0.28, 0.6, 1.0)
	var light := Color(0.7, 0.88, 1.0, 1.0)
	for y in range(th):
		for x in range(tw):
			var border := x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if border:
				img.set_pixel(x, y, dark)
			else:
				img.set_pixel(x, y, base)
	var cut_r: float = min(tw, th) * 0.22
	var cy: float = th * 0.5
	var left_cx: float = 0.0
	var right_cx: float = float(tw - 1)
	for y in range(th):
		for x in range(tw):
			var dl: float = sqrt((float(x) - left_cx) * (float(x) - left_cx) + (float(y) - cy) * (float(y) - cy))
			var dr: float = sqrt((float(x) - right_cx) * (float(x) - right_cx) + (float(y) - cy) * (float(y) - cy))
			if dl < cut_r or dr < cut_r:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var stripe_h: int = max(2, int(round(th * 0.22)))
	var stripe_y: int = int(round(th * 0.2))
	for y in range(stripe_h):
		for x in range(2, tw - 2):
			var py := stripe_y + y
			if py >= 0 and py < th:
				img.set_pixel(x, py, light)
	return ImageTexture.create_from_image(img)

func _build_gacha_mystery_icon(size: int = 128) -> Texture2D:
	var tw: int = max(1, size)
	var th: int = max(1, size)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var bg := Color(0.12, 0.14, 0.2, 1.0)
	var edge := Color(0.08, 0.1, 0.16, 1.0)
	var glow := Color(0.4, 0.7, 1.0, 1.0)
	for y in range(th):
		for x in range(tw):
			var border := x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if border:
				img.set_pixel(x, y, edge)
			else:
				img.set_pixel(x, y, bg)
	var cx: float = tw * 0.5
	var cy: float = th * 0.45
	var r: float = min(tw, th) * 0.18
	for y in range(th):
		for x in range(tw):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d < r:
				img.set_pixel(x, y, glow)
			elif d < r + 2.0:
				img.set_pixel(x, y, Color(0.7, 0.9, 1.0, 1.0))
	var stem_w: int = int(max(4, tw * 0.08))
	var stem_h: int = int(max(8, th * 0.12))
	var stem_x: int = int(cx - stem_w * 0.5)
	var stem_y: int = int(cy + r * 0.6)
	for y in range(stem_h):
		for x in range(stem_w):
			var px := stem_x + x
			var py := stem_y + y
			if px >= 0 and py >= 0 and px < tw and py < th:
				img.set_pixel(px, py, glow)
	var dot_r: int = int(max(2, tw * 0.03))
	var dot_y: int = int(cy + r * 1.6)
	for y in range(-dot_r, dot_r + 1):
		for x in range(-dot_r, dot_r + 1):
			if x * x + y * y <= dot_r * dot_r:
				var px2 := int(cx) + x
				var py2 := dot_y + y
				if px2 >= 0 and py2 >= 0 and px2 < tw and py2 < th:
					img.set_pixel(px2, py2, glow)
	return ImageTexture.create_from_image(img)

func _build_gacha_ticket_icon(size: int) -> Texture2D:
	return _build_ticket_icon(size, size)

func _get_equipment_record(equip_id: String) -> Dictionary:
	var equip_cfg = owner.get_tree().get_root().get_node_or_null("EquipmentConfig")
	if equip_cfg and equip_cfg.has_method("get_equipment_by_id"):
		return equip_cfg.call("get_equipment_by_id", equip_id)
	var tmp := EquipConfigScript.new()
	tmp.load_equipment_data()
	return tmp.get_equipment_by_id(equip_id)

func _get_equipment_slot_type(equip_id: String) -> String:
	var rec := _get_equipment_record(equip_id)
	var slot_type := String(rec.get("slot_type", ""))
	if slot_type != "":
		return slot_type
	var attack_id := String(rec.get("attack_id", ""))
	if attack_id == "bullet":
		return "ranged"
	if attack_id == "melee":
		return "melee"
	if attack_id == "magic" or attack_id == "roar":
		return "range"
	return ""

func _get_equipment_type_label(slot_type: String) -> String:
	if slot_type == "ranged":
		return "远程"
	if slot_type == "melee":
		return "近战"
	if slot_type == "range":
		return "范围"
	return ""

func _get_equipment_type_border_color(slot_type: String) -> Color:
	if slot_type == "ranged":
		return Color(0.35, 0.75, 1.0, 1.0)
	if slot_type == "melee":
		return Color(0.95, 0.35, 0.35, 1.0)
	if slot_type == "range":
		return Color(0.75, 0.55, 1.0, 1.0)
	return Color(0.7, 0.7, 0.7, 1)

func _build_equipment_display(equip_id: String, size: int) -> Control:
	var rec := _get_equipment_record(equip_id)
	var attack_id := String(rec.get("attack_id", ""))
	var icon_path := String(rec.get("icon", ""))
	var slot_type := _get_equipment_slot_type(equip_id)
	var is_dragon := equip_id == GACHA_DRAGON_ID
	var gold := Color(1.0, 0.86, 0.35, 1.0)
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1)
	style.set_border_width_all(2)
	style.border_color = gold if is_dragon else _get_equipment_type_border_color(slot_type)
	if is_dragon:
		style.shadow_color = Color(gold.r, gold.g, gold.b, 0.6)
		style.shadow_size = 8
		style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var type_label := Label.new()
	type_label.text = _get_equipment_type_label(slot_type)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_dragon:
		type_label.add_theme_color_override("font_color", gold)
		type_label.add_theme_color_override("font_outline_color", Color(gold.r, gold.g, gold.b, 0.85))
		type_label.add_theme_constant_override("outline_size", 3)
	type_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	type_label.offset_left = 0
	type_label.offset_right = 0
	type_label.offset_top = 4
	type_label.offset_bottom = 22
	panel.add_child(type_label)
	var icon := TextureRect.new()
	var icon_size := int(round(size * 0.7))
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_holder := CenterContainer.new()
	icon_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_holder.offset_left = 0
	icon_holder.offset_top = 0
	icon_holder.offset_right = 0
	icon_holder.offset_bottom = 0
	icon_holder.add_child(icon)
	var equip_cfg = owner.get_tree().get_root().get_node_or_null("EquipmentConfig")
	var equip_tex: Texture2D = null
	if equip_cfg and equip_cfg.has_method("build_equipment_icon"):
		equip_tex = equip_cfg.call("build_equipment_icon", attack_id, icon_size)
	else:
		var tmp := EquipConfigScript.new()
		equip_tex = tmp.build_equipment_icon(attack_id, icon_size)
	if equip_tex:
		icon.texture = equip_tex
	elif icon_path != "":
		var tex = load(icon_path)
		if tex:
			icon.texture = tex
	panel.add_child(icon_holder)
	return root

func _build_codex_icon_texture(icon_key: String, rarity: String, size: int) -> Texture2D:
	if gacha_codex_helper and gacha_codex_helper.has_method("_build_collectible_icon_plain"):
		return gacha_codex_helper.call("_build_collectible_icon_plain", icon_key, rarity, size, size)
	return build_collectible_icon_cb.call(icon_key, rarity, size, size)

func _get_gacha_result_icon_info(result: Dictionary) -> Dictionary:
	var typ := String(result.get("type", "none"))
	var id := String(result.get("id", ""))
	if typ == "dragon":
		return {"name": "龙咆哮", "mode": "equipment", "equip_id": GACHA_DRAGON_ID}
	if typ == "collectible":
		var icon_key := _get_collectible_icon_key(id)
		var rar := _get_collectible_rarity(id)
		var size := _get_collectible_grid_size(id)
		return {"name": _get_collectible_name(id), "mode": "collectible", "icon_key": icon_key, "rarity": rar, "gw": size.x, "gh": size.y}
	return {"name": "空", "mode": "none", "icon_key": "?", "rarity": "white", "gw": 1, "gh": 1}

func _clear_gacha_results():
	if gacha_results_grid == null:
		return
	for c in gacha_results_grid.get_children():
		c.queue_free()
	gacha_results_items.clear()

func _add_gacha_result_cell(tex: Texture2D, name: String, col: Color, gw: int, gh: int):
	if gacha_results_grid == null:
		return
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(130, 120)
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_theme_constant_override("separation", 6)
	var icon: Control = gacha_codex_helper.GridIcon.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.set_icon(tex, gw, gh, col)
	cell.add_child(icon)
	var label := Label.new()
	label.text = name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = col
	cell.add_child(label)
	gacha_results_grid.add_child(cell)
	gacha_results_items.append({"cell": cell, "icon": icon, "label": label})

func _play_gacha_reveal(results: Array):
	if gacha_results_grid == null:
		return
	if gacha_anim_tween:
		gacha_anim_tween.kill()
	gacha_animating = true
	if gacha_draw_button:
		gacha_draw_button.disabled = true
	if gacha_draw_ten_button:
		gacha_draw_ten_button.disabled = true
	if gacha_result_label:
		gacha_result_label.text = "抽奖中..."
	_clear_gacha_results()
	for _i in range(results.size()):
		_add_gacha_result_cell(_build_gacha_mystery_icon(96), "?", Color(0.8, 0.9, 1.0, 0.9), 1, 1)
	for i in range(results.size()):
		var r: Dictionary = results[i]
		var item: Dictionary = gacha_results_items[i]
		var cell: VBoxContainer = item.get("cell")
		var icon: Control = item.get("icon")
		var label: Label = item.get("label")
		var info := _get_gacha_result_icon_info(r)
		var mode := String(info.get("mode", "collectible"))
		var icon_key := String(info.get("icon_key", ""))
		var rar := String(info.get("rarity", "white"))
		var gw := int(info.get("gw", 1))
		var gh := int(info.get("gh", 1))
		var col: Color = Color.WHITE
		col = rarity_color_cb.call(rar) as Color
		if gacha_codex_helper and gacha_codex_helper.RarityScript:
			col = gacha_codex_helper.RarityScript.color(rar)
		if icon:
			icon.scale = Vector2(0.9, 0.9)
			gacha_anim_tween = owner.get_tree().create_tween()
			gacha_anim_tween.tween_property(icon, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			gacha_anim_tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await gacha_anim_tween.finished
		if mode == "equipment":
			var equip_id := String(info.get("equip_id", ""))
			var slot_type := _get_equipment_slot_type(equip_id)
			var is_dragon := equip_id == GACHA_DRAGON_ID
			var gold := Color(1.0, 0.86, 0.35, 1.0)
			col = gold if is_dragon else _get_equipment_type_border_color(slot_type)
			var equip_icon := _build_equipment_display(equip_id, 80)
			if icon and icon.get_parent() == cell:
				cell.remove_child(icon)
				icon.queue_free()
			if cell:
				cell.add_child(equip_icon)
				cell.move_child(equip_icon, 0)
			item["icon"] = equip_icon
		else:
			var tex := _build_codex_icon_texture(icon_key, rar, 64)
			if icon and icon.has_method("set_icon"):
				icon.set_icon(tex, gw, gh, col)
		if label:
			label.text = String(info.get("name", ""))
			label.modulate = col
			if mode == "equipment" and String(info.get("equip_id", "")) == GACHA_DRAGON_ID:
				label.add_theme_color_override("font_color", col)
				label.add_theme_color_override("font_outline_color", Color(col.r, col.g, col.b, 0.85))
				label.add_theme_constant_override("outline_size", 3)
	if gacha_result_label:
		gacha_result_label.text = ""
	gacha_animating = false
	if gacha_draw_button:
		gacha_draw_button.disabled = int(meta_store.gacha_tickets) <= 0 or _is_gacha_pool_empty()
	if gacha_draw_ten_button:
		gacha_draw_ten_button.disabled = int(meta_store.gacha_tickets) < 10 or _is_gacha_pool_empty()
