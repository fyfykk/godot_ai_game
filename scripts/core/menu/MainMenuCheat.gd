extends RefCounted

var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")

var owner
var cheat_settings
var coll_store

var cheat_overlay: ColorRect
var cheat_panel: PanelContainer
var cheat_open: bool = false
var cheat_start_spin: SpinBox
var cheat_unlock_check: CheckBox
var cheat_invincible_check: CheckBox
var cheat_zero_interact_check: CheckBox
var cheat_blood_moon_spin: SpinBox
var cheat_apply_button: Button
var cheat_close_button: Button
var cheat_clear_button: Button
var cheat_collectible_scroll: ScrollContainer
var cheat_collectible_list: VBoxContainer
var cheat_collectible_spins: Dictionary = {}

func setup(owner_node, cheat_settings_ref, coll_store_ref):
	owner = owner_node
	cheat_settings = cheat_settings_ref
	coll_store = coll_store_ref

func build():
	var root: Node = owner.get_tree().get_root()
	cheat_overlay = ColorRect.new()
	root.call_deferred("add_child", cheat_overlay)
	cheat_overlay.color = Color(0, 0, 0, 0.7)
	cheat_overlay.visible = false
	cheat_overlay.z_index = 260
	if cheat_overlay is Control:
		(cheat_overlay as Control).anchor_left = 0.0
		(cheat_overlay as Control).anchor_top = 0.0
		(cheat_overlay as Control).anchor_right = 1.0
		(cheat_overlay as Control).anchor_bottom = 1.0
		(cheat_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	cheat_panel = PanelContainer.new()
	root.call_deferred("add_child", cheat_panel)
	cheat_panel.visible = false
	cheat_panel.z_index = 270
	if cheat_panel is Control:
		(cheat_panel as Control).anchor_left = 0.0
		(cheat_panel as Control).anchor_top = 0.0
		(cheat_panel as Control).anchor_right = 1.0
		(cheat_panel as Control).anchor_bottom = 1.0
		(cheat_panel as Control).offset_left = 0
		(cheat_panel as Control).offset_top = 0
		(cheat_panel as Control).offset_right = 0
		(cheat_panel as Control).offset_bottom = 0
		(cheat_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	cheat_panel.add_child(center_box)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(640, 520)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.add_child(list_panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	list_panel.add_child(vb)
	vb.alignment = BoxContainer.ALIGNMENT_BEGIN
	var title := Label.new()
	title.text = "作弊面板"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var row1 := HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(row1)
	var lb1 := Label.new()
	lb1.text = "初始金币"
	lb1.custom_minimum_size = Vector2(160, 32)
	row1.add_child(lb1)
	cheat_start_spin = SpinBox.new()
	cheat_start_spin.min_value = 0
	cheat_start_spin.max_value = 9999
	cheat_start_spin.step = 10
	cheat_start_spin.value = float(cheat_settings.start_coins)
	row1.add_child(cheat_start_spin)
	cheat_unlock_check = CheckBox.new()
	cheat_unlock_check.text = "全部收藏品解锁"
	cheat_unlock_check.button_pressed = cheat_settings.unlock_all
	vb.add_child(cheat_unlock_check)
	cheat_unlock_check.toggled.connect(_on_cheat_unlock_toggled)
	cheat_invincible_check = CheckBox.new()
	cheat_invincible_check.text = "无敌"
	cheat_invincible_check.button_pressed = cheat_settings.invincible
	vb.add_child(cheat_invincible_check)
	cheat_zero_interact_check = CheckBox.new()
	cheat_zero_interact_check.text = "0.5s交互"
	cheat_zero_interact_check.button_pressed = cheat_settings.zero_interact
	vb.add_child(cheat_zero_interact_check)
	var row2 := HBoxContainer.new()
	row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(row2)
	var lb2 := Label.new()
	lb2.text = "血月时长(秒)"
	lb2.custom_minimum_size = Vector2(160, 32)
	row2.add_child(lb2)
	cheat_blood_moon_spin = SpinBox.new()
	cheat_blood_moon_spin.min_value = 0
	cheat_blood_moon_spin.max_value = 999
	cheat_blood_moon_spin.step = 5
	cheat_blood_moon_spin.value = float(cheat_settings.blood_moon_time)
	row2.add_child(cheat_blood_moon_spin)
	var sub_title := Label.new()
	sub_title.text = "收藏品数量"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub_title)
	cheat_collectible_scroll = ScrollContainer.new()
	cheat_collectible_scroll.custom_minimum_size = Vector2(520, 200)
	cheat_collectible_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cheat_collectible_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cheat_collectible_scroll.visible = not cheat_unlock_check.button_pressed
	vb.add_child(cheat_collectible_scroll)
	cheat_collectible_list = VBoxContainer.new()
	cheat_collectible_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cheat_collectible_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cheat_collectible_scroll.add_child(cheat_collectible_list)
	_build_cheat_collectible_list()
	var btn_row := HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(btn_row)
	cheat_apply_button = Button.new()
	cheat_apply_button.text = "应用"
	cheat_apply_button.custom_minimum_size = Vector2(140, 40)
	cheat_apply_button.pressed.connect(_on_cheat_apply_pressed)
	btn_row.add_child(cheat_apply_button)
	cheat_clear_button = Button.new()
	cheat_clear_button.text = "清空收藏品"
	cheat_clear_button.custom_minimum_size = Vector2(160, 40)
	cheat_clear_button.pressed.connect(_on_cheat_clear_collectibles_pressed)
	btn_row.add_child(cheat_clear_button)
	var fill_button := Button.new()
	fill_button.text = "全部设为1"
	fill_button.custom_minimum_size = Vector2(160, 40)
	fill_button.pressed.connect(_on_cheat_fill_collectibles_pressed)
	btn_row.add_child(fill_button)
	cheat_close_button = Button.new()
	cheat_close_button.text = "关闭"
	cheat_close_button.custom_minimum_size = Vector2(140, 40)
	cheat_close_button.pressed.connect(hide)
	btn_row.add_child(cheat_close_button)
	UIFontScript.apply_tree(cheat_overlay)
	UIFontScript.apply_tree(cheat_panel)

func cleanup():
	if cheat_overlay and cheat_overlay.is_inside_tree():
		cheat_overlay.queue_free()
	if cheat_panel and cheat_panel.is_inside_tree():
		cheat_panel.queue_free()

func toggle():
	if cheat_panel == null or cheat_overlay == null:
		return
	if cheat_open:
		hide()
	else:
		show()

func show():
	cheat_open = true
	if cheat_overlay:
		cheat_overlay.visible = true
	if cheat_panel:
		cheat_panel.visible = true

func hide():
	cheat_open = false
	if cheat_overlay:
		cheat_overlay.visible = false
	if cheat_panel:
		cheat_panel.visible = false

func _on_cheat_apply_pressed():
	if cheat_settings == null:
		return
	cheat_settings.start_coins = int(cheat_start_spin.value)
	cheat_settings.unlock_all = cheat_unlock_check.button_pressed
	cheat_settings.invincible = cheat_invincible_check.button_pressed
	cheat_settings.zero_interact = cheat_zero_interact_check.button_pressed
	cheat_settings.blood_moon_time = float(cheat_blood_moon_spin.value)
	cheat_settings.save()
	if cheat_settings.unlock_all:
		_set_collectible_unlock_all(true)
	else:
		_apply_collectible_counts_from_ui()

func _on_cheat_clear_collectibles_pressed():
	_set_collectible_unlock_all(false)
	for k in cheat_collectible_spins.keys():
		var sp: SpinBox = cheat_collectible_spins[k]
		if sp:
			sp.value = 0
	if cheat_unlock_check:
		cheat_unlock_check.button_pressed = false
	if cheat_settings:
		cheat_settings.unlock_all = false
		cheat_settings.save()

func _on_cheat_fill_collectibles_pressed():
	var cfg := CollConfigScript.new()
	cfg.load_csv()
	for k in cheat_collectible_spins.keys():
		var sp: SpinBox = cheat_collectible_spins[k]
		if sp:
			var cap: int = _get_collectible_cap(cfg, String(k))
			sp.value = cap

func _on_cheat_unlock_toggled(v: bool):
	if cheat_collectible_scroll:
		cheat_collectible_scroll.visible = not v

func _set_collectible_unlock_all(enabled: bool):
	var cfg := CollConfigScript.new()
	cfg.load_csv()
	var store := CollStoreScript.new()
	store.load()
	if enabled:
		var counts: Dictionary = {}
		for rec_i in cfg.items:
			var rec: Dictionary = rec_i
			var id := String(rec.get("id", ""))
			if id != "":
				counts[id] = 1
		store.counts = counts
		store.total = counts.size()
	else:
		store.counts = {}
		store.total = 0
	store.save()
	if coll_store:
		coll_store.counts = store.counts.duplicate()
		coll_store.total = int(store.total)

func _build_cheat_collectible_list():
	if cheat_collectible_list == null:
		return
	for c in cheat_collectible_list.get_children():
		c.queue_free()
	cheat_collectible_spins.clear()
	var cfg := CollConfigScript.new()
	cfg.load_csv()
	var store := CollStoreScript.new()
	store.load()
	for rec_i in cfg.items:
		var rec: Dictionary = rec_i
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		var cap: int = _get_collectible_cap(cfg, id)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cheat_collectible_list.add_child(row)
		var lb := Label.new()
		lb.text = "%s %s" % [id, String(rec.get("name", ""))]
		lb.custom_minimum_size = Vector2(300, 28)
		row.add_child(lb)
		var sp := SpinBox.new()
		sp.min_value = 0
		sp.max_value = cap
		sp.step = 1
		sp.value = float(store.get_count(id))
		row.add_child(sp)
		cheat_collectible_spins[id] = sp

func _apply_collectible_counts_from_ui():
	var store := CollStoreScript.new()
	store.load()
	var counts: Dictionary = {}
	var total: int = 0
	for id in cheat_collectible_spins.keys():
		var sp: SpinBox = cheat_collectible_spins[id]
		if sp == null:
			continue
		var v: int = int(sp.value)
		if v > 0:
			counts[id] = v
			total += v
	store.counts = counts
	store.total = total
	store.save()
	if coll_store:
		coll_store.counts = counts.duplicate()
		coll_store.total = total

func _get_collectible_cap(cfg, id: String) -> int:
	if cfg == null:
		return 5
	var rec: Dictionary = cfg.get_item(id)
	if rec == null or rec.size() == 0:
		return 5
	var unlock := String(rec.get("unlock", "none"))
	if unlock != "none":
		return 1
	var rar := String(rec.get("rarity", "blue"))
	if rar == "white":
		return 1
	return 5
