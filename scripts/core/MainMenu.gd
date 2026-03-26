extends Control

var MetaStoreScript := preload("res://scripts/data/MetaProgressionStore.gd")
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")
var CheatSettingsScript := preload("res://scripts/data/CheatSettings.gd")
var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
var MainMenuGachaScript := preload("res://scripts/core/menu/MainMenuGacha.gd")
var MainMenuHelpScript := preload("res://scripts/core/menu/MainMenuHelp.gd")
var MainMenuLevelDialogsScript := preload("res://scripts/core/menu/MainMenuLevelDialogs.gd")
var MainMenuCheatScript := preload("res://scripts/core/menu/MainMenuCheat.gd")
var meta_store
var cheat_settings
var cheat_p_down: bool = false
var cheat_tilde_down: bool = false
var level_seeds: Array = [91427, 58203, 73691]
var redeem_dialog: ConfirmationDialog
var redeem_input: LineEdit
var coll_config
var coll_store
var gacha_ui
var help_ui
var level_ui
var cheat_ui
var menu_bg: TextureRect
var popup_overlay: ColorRect
var popup_overlay_count: int = 0

func _ready():
	_ensure_audio_output()
	_build_menu_background()
	_build_popup_overlay()
	meta_store = MetaStoreScript.new()
	meta_store.load()
	cheat_settings = CheatSettingsScript.new()
	cheat_settings.load()
	coll_config = CollConfigScript.new()
	coll_config.load_csv()
	coll_store = CollStoreScript.new()
	coll_store.load()
	level_ui = MainMenuLevelDialogsScript.new()
	level_ui.setup(self, meta_store, level_seeds)
	level_ui.build()
	help_ui = MainMenuHelpScript.new()
	help_ui.setup(self)
	help_ui.build()
	gacha_ui = MainMenuGachaScript.new()
	gacha_ui.setup(self, meta_store, coll_config, coll_store, Callable(self, "_rarity_color"), Callable(self, "_build_collectible_icon_texture"))
	gacha_ui.build()
	cheat_ui = MainMenuCheatScript.new()
	cheat_ui.setup(self, cheat_settings, coll_store)
	cheat_ui.build()
	var menu_center := CenterContainer.new()
	menu_center.name = "MenuCenter"
	menu_center.anchors_preset = 15
	menu_center.anchor_left = 0.0
	menu_center.anchor_top = 0.0
	menu_center.anchor_right = 1.0
	menu_center.anchor_bottom = 1.0
	menu_center.offset_left = 0
	menu_center.offset_top = 0
	menu_center.offset_right = 0
	menu_center.offset_bottom = 0
	menu_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(menu_center)
	var menu_box := VBoxContainer.new()
	menu_box.name = "MenuList"
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_box.add_theme_constant_override("separation", 16)
	menu_center.add_child(menu_box)
	var title := $Title
	if title:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if title.get_parent() != menu_box:
			title.get_parent().remove_child(title)
			menu_box.add_child(title)
	var btn := $StartButton
	if btn:
		btn.text = "开始游戏"
		btn.pressed.connect(_on_start_pressed)
		if btn.get_parent() != menu_box:
			btn.get_parent().remove_child(btn)
			menu_box.add_child(btn)
	var equip_btn := $EquipmentButton
	if equip_btn:
		equip_btn.pressed.connect(_on_equipment_pressed)
		if equip_btn.get_parent() != menu_box:
			equip_btn.get_parent().remove_child(equip_btn)
			menu_box.add_child(equip_btn)
	var redeem_btn := Button.new()
	menu_box.add_child(redeem_btn)
	redeem_btn.text = "兑换码"
	redeem_btn.z_index = 10
	redeem_btn.pressed.connect(_on_redeem_pressed)
	var editor := Button.new()
	menu_box.add_child(editor)
	editor.text = "地图编辑"
	editor.z_index = 10
	editor.pressed.connect(_on_editor_pressed)
	var codex := Button.new()
	menu_box.add_child(codex)
	codex.text = "收藏品图鉴"
	codex.z_index = 10
	codex.pressed.connect(_on_codex_pressed)
	var gacha := Button.new()
	menu_box.add_child(gacha)
	gacha.text = "抽奖"
	gacha.z_index = 10
	gacha.pressed.connect(_on_gacha_pressed)
	var save := Button.new()
	menu_box.add_child(save)
	save.text = "显示存档路径"
	save.z_index = 10
	save.pressed.connect(_on_save_path_pressed)
	var clear := Button.new()
	menu_box.add_child(clear)
	clear.text = "清理本地记录"
	clear.z_index = 10
	clear.pressed.connect(_on_clear_collectibles_pressed)
	var help := Button.new()
	menu_box.add_child(help)
	help.text = "帮助"
	help.z_index = 10
	help.pressed.connect(_on_help_pressed)
	UIFontScript.apply_tree(get_tree().get_root())

func _build_menu_background():
	menu_bg = TextureRect.new()
	menu_bg.name = "MenuBackground"
	menu_bg.anchor_left = 0.0
	menu_bg.anchor_top = 0.0
	menu_bg.anchor_right = 1.0
	menu_bg.anchor_bottom = 1.0
	menu_bg.offset_left = 0
	menu_bg.offset_top = 0
	menu_bg.offset_right = 0
	menu_bg.offset_bottom = 0
	menu_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_bg.stretch_mode = TextureRect.STRETCH_SCALE
	menu_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	menu_bg.z_index = -10
	add_child(menu_bg)
	move_child(menu_bg, 0)
	_update_menu_background_texture()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_menu_background_texture()

func _update_menu_background_texture():
	if menu_bg == null:
		return
	var size := get_viewport_rect().size
	menu_bg.texture = _build_menu_bg_texture(size, 91427)

func _build_menu_bg_texture(size: Vector2, seed: int) -> Texture2D:
	var w := int(clamp(size.x, 960.0, 1600.0))
	var h := int(clamp(size.y, 540.0, 900.0))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top := Color(0.06, 0.08, 0.12, 1.0)
	var mid := Color(0.08, 0.12, 0.18, 1.0)
	var bot := Color(0.12, 0.16, 0.22, 1.0)
	for y in range(h):
		var t := float(y) / float(max(h - 1, 1))
		var col := top.lerp(mid, min(t * 1.2, 1.0)).lerp(bot, t * t)
		for x in range(w):
			img.set_pixel(x, y, col)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in range(int(w * h * 0.006)):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, int(h * 0.55))
		var a := rng.randf_range(0.08, 0.2)
		var c := Color(0.7, 0.85, 1.0, a)
		img.set_pixel(x, y, c)
	_draw_mountain_layer(img, int(h * 0.72), int(h * 0.06), Color(0.07, 0.09, 0.12, 1.0), seed + 13)
	_draw_mountain_layer(img, int(h * 0.8), int(h * 0.08), Color(0.05, 0.07, 0.1, 1.0), seed + 29)
	_draw_mountain_layer(img, int(h * 0.88), int(h * 0.1), Color(0.04, 0.05, 0.08, 1.0), seed + 41)
	return ImageTexture.create_from_image(img)

func _draw_mountain_layer(img: Image, base_y: int, amp: int, col: Color, seed: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var w := img.get_width()
	var h := img.get_height()
	var cur := float(base_y)
	for x in range(w):
		cur += rng.randf_range(-float(amp) * 0.18, float(amp) * 0.18)
		cur = clamp(cur, float(base_y - amp), float(base_y + amp))
		for y in range(int(cur), h):
			img.set_pixel(x, y, col)

func _build_popup_overlay():
	popup_overlay = ColorRect.new()
	popup_overlay.color = Color(0, 0, 0, 0.65)
	popup_overlay.visible = false
	popup_overlay.z_index = 200
	popup_overlay.anchor_left = 0.0
	popup_overlay.anchor_top = 0.0
	popup_overlay.anchor_right = 1.0
	popup_overlay.anchor_bottom = 1.0
	popup_overlay.offset_left = 0
	popup_overlay.offset_top = 0
	popup_overlay.offset_right = 0
	popup_overlay.offset_bottom = 0
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup_overlay)

func _bind_popup_overlay(popup: Window):
	if popup == null:
		return
	if popup.has_signal("visibility_changed"):
		popup.visibility_changed.connect(_on_popup_visibility_changed.bind(popup))

func _on_popup_visibility_changed(popup: Window):
	if popup and popup.visible:
		popup_overlay_count += 1
	else:
		popup_overlay_count = max(popup_overlay_count - 1, 0)
	if popup_overlay:
		popup_overlay.visible = popup_overlay_count > 0

func _ensure_audio_output():
	var devices := AudioServer.get_output_device_list()
	if devices.is_empty():
		return
	var current := String(AudioServer.output_device)
	if current == "" or not devices.has(current):
		if devices.has("Default"):
			AudioServer.output_device = "Default"
		else:
			AudioServer.output_device = String(devices[0])

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_P:
			cheat_p_down = event.pressed
		if event.keycode == KEY_QUOTELEFT:
			cheat_tilde_down = event.pressed
		if event.pressed and not event.echo and cheat_p_down and cheat_tilde_down:
			if cheat_ui:
				cheat_ui.toggle()

func _on_start_pressed():
	if level_ui:
		level_ui.refresh_level_buttons()
		level_ui.show_level_dialog()

func _on_equipment_pressed():
	get_tree().change_scene_to_file("res://scenes/EquipmentEditor.tscn")

func _on_redeem_pressed():
	if redeem_dialog == null:
		_build_redeem_dialog()
	redeem_input.text = ""
	redeem_dialog.popup_centered()
	redeem_input.grab_focus()

func _build_redeem_dialog():
	redeem_dialog = ConfirmationDialog.new()
	redeem_dialog.title = "兑换码"
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(360, 0)
	box.add_theme_constant_override("separation", 8)
	redeem_dialog.add_child(box)
	var label = Label.new()
	label.text = "请输入兑换码"
	box.add_child(label)
	redeem_input = LineEdit.new()
	redeem_input.placeholder_text = "兑换码"
	box.add_child(redeem_input)
	var okb = redeem_dialog.get_ok_button()
	if okb:
		okb.text = "确定"
	var cancelb = redeem_dialog.get_cancel_button()
	if cancelb:
		cancelb.text = "取消"
	redeem_dialog.confirmed.connect(_on_redeem_confirmed)
	add_child(redeem_dialog)
	_bind_popup_overlay(redeem_dialog)

func _on_redeem_confirmed():
	var code := redeem_input.text.strip_edges().to_lower()
	if code == "kfcvme50":
		var store := get_tree().get_root().get_node_or_null("EquipmentStore")
		if store and store.has_method("add_to_backpack") and store.has_method("has_item"):
			var already := bool(store.call("has_item", "EQ004"))
			if already:
				_show_redeem_result("已拥有：龙咆哮")
			else:
				var added := bool(store.call("add_to_backpack", "EQ004"))
				if added:
					_show_redeem_result("获得：龙咆哮")
				else:
					_show_redeem_result("兑换失败")
		else:
			_show_redeem_result("兑换失败")
	elif code == "zhengzhengrishang":
		meta_store.add_gacha_tickets(50)
		meta_store.save()
		_show_redeem_result("获得：抽奖券 x50")
	else:
		_show_redeem_result("兑换码错误")

func _show_redeem_result(msg: String):
	var dlg := AcceptDialog.new()
	dlg.title = "兑换码"
	dlg.dialog_text = msg
	add_child(dlg)
	_bind_popup_overlay(dlg)
	dlg.popup_centered()

func _on_editor_pressed():
	if level_ui:
		level_ui.show_editor_dialog()

func _on_help_pressed():
	if help_ui:
		help_ui.show()

func _on_gacha_pressed():
	if gacha_ui:
		gacha_ui.show()

func _exit_tree():
	if level_ui:
		level_ui.cleanup()
	if help_ui:
		help_ui.cleanup()
	if gacha_ui:
		gacha_ui.cleanup()
	if cheat_ui:
		cheat_ui.cleanup()

func _on_codex_pressed():
	get_tree().change_scene_to_file("res://scenes/Codex.tscn")
func _on_save_path_pressed():
	var dir: String = LocalPathsScript.root_dir()
	var coll: String = LocalPathsScript.file_path("collectibles.cfg")
	var prog: String = LocalPathsScript.file_path("progress.cfg")
	var dlg := AcceptDialog.new()
	dlg.title = "存档路径"
	dlg.dialog_text = "本地目录:\n%s\n\n收藏品:\n%s\n\n元进度:\n%s" % [dir, coll, prog]
	add_child(dlg)
	_bind_popup_overlay(dlg)
	dlg.popup_centered()
func _on_clear_collectibles_pressed():
	var CollStoreScriptLocal := preload("res://scripts/data/CollectiblesStore.gd")
	var store := CollStoreScriptLocal.new()
	store.load()
	store.counts = {}
	store.total = 0
	store.save()
	if coll_store:
		coll_store.counts = {}
		coll_store.total = 0
	var equip_store := get_tree().get_root().get_node_or_null("EquipmentStore")
	if equip_store and equip_store.has_method("clear_local"):
		equip_store.call("clear_local")
	if gacha_ui:
		gacha_ui.update_labels()
	var dlg := AcceptDialog.new()
	dlg.title = "开发者功能"
	dlg.dialog_text = "已清理本地收藏品与装备记录"
	add_child(dlg)
	_bind_popup_overlay(dlg)
	dlg.popup_centered()

func _build_codex():
	var root := Node.new()
	add_child(root)
	var title := Label.new()
	title.text = "收藏品图鉴"
	title.position = Vector2(100, 120)
	add_child(title)
	var CollConfigScriptLocal := preload("res://scripts/data/CollectiblesConfig.gd")
	var CollStoreScriptLocal := preload("res://scripts/data/CollectiblesStore.gd")
	var config := CollConfigScriptLocal.new()
	config.load_csv()
	var store := CollStoreScriptLocal.new()
	store.load()
	var vb := VBoxContainer.new()
	vb.position = Vector2(100, 160)
	add_child(vb)
	for rec_i in config.items:
		var rec: Dictionary = rec_i
		var id: String = String(rec["id"])
		var item_name: String = String(rec["name"])
		var rar: String = String(rec["rarity"])
		var cnt: int = int(store.get_count(id))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tex := _build_collectible_icon_texture(String(rec.get("icon", "")), rar, 24, 24)
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
		var l := Label.new()
		l.text = "%s（%s） 已获得:%d" % [item_name, rar, cnt]
		l.modulate = _rarity_color(rar)
		row.add_child(l)
		vb.add_child(row)

func _rarity_color(r: String) -> Color:
	if r == "blue":
		return Color(0.3, 0.5, 1.0, 1.0)
	if r == "epic":
		return Color(0.6, 0.3, 0.8, 1.0)
	if r == "red":
		return Color(1.0, 0.2, 0.2, 1.0)
	if r == "white":
		return Color(0.95, 0.95, 0.95, 1.0)
	return Color(1, 1, 1, 1)

func _build_collectible_icon_texture(icon_key: String, rarity: String, w: int, h: int) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var base: Color = _rarity_color(rarity)
	var c1 := base.lightened(0.2)
	var c2 := base.darkened(0.2)
	var edge := Color(0.08, 0.08, 0.1, 1.0)
	var icon_seed := _icon_hash(icon_key)
	var mode := icon_seed % 4
	for y in range(th):
		for x in range(tw):
			var border := x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if border:
				img.set_pixel(x, y, edge)
				continue
			var on := false
			if mode == 0:
				on = ((x + y + icon_seed) % 2) == 0
			elif mode == 1:
				on = ((int(floor(float(x) * 0.5)) + y) % 2) == 0
			elif mode == 2:
				var cx: int = int(floor(float(tw) * 0.5))
				var cy: int = int(floor(float(th) * 0.5))
				on = abs(x - cx) + abs(y - cy) <= int(floor(float(min(tw, th)) / 3.0))
			else:
				on = x == y or x == (tw - 1 - y)
			img.set_pixel(x, y, c1 if on else c2)
	var mark := base.lightened(0.55)
	var midx: int = int(floor(float(tw) * 0.5))
	var midy: int = int(floor(float(th) * 0.5))
	var mark_size: int = int(floor(float(min(tw, th)) / 3.0))
	if _icon_has(icon_key, "紫"):
		_draw_diamond(img, midx, midy, mark_size, mark)
	if _icon_has(icon_key, "弹"):
		_draw_circle(img, midx, midy, mark_size, mark)
	elif _icon_has(icon_key, "刃"):
		_draw_triangle(img, midx, midy, mark_size, mark)
	elif _icon_has(icon_key, "法"):
		_draw_ring(img, midx, midy, mark_size, mark)
	if _icon_has(icon_key, "拓") or _icon_has(icon_key, "扩"):
		_draw_plus(img, midx, midy, mark_size, mark)
	if _icon_has(icon_key, "冷") or _icon_has(icon_key, "速") or _icon_has(icon_key, "节奏"):
		_draw_stripes(img, mark)
	return ImageTexture.create_from_image(img)

func _icon_hash(s: String) -> int:
	var h: int = 17
	for i in range(s.length()):
		h = int(h * 31 + s.unicode_at(i))
	return abs(h)

func _icon_has(s: String, key: String) -> bool:
	return s.find(key) >= 0

func _draw_plus(img: Image, cx: int, cy: int, arm: int, col: Color):
	for i in range(-arm, arm + 1):
		var x := cx + i
		var y := cy
		if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
			img.set_pixel(x, y, col)
	for j in range(-arm, arm + 1):
		var x2 := cx
		var y2 := cy + j
		if x2 >= 1 and x2 < img.get_width() - 1 and y2 >= 1 and y2 < img.get_height() - 1:
			img.set_pixel(x2, y2, col)

func _draw_circle(img: Image, cx: int, cy: int, r: int, col: Color):
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
					img.set_pixel(x, y, col)

func _draw_ring(img: Image, cx: int, cy: int, r: int, col: Color):
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			var d := dx * dx + dy * dy
			if d <= r * r and d >= (r - 1) * (r - 1):
				if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
					img.set_pixel(x, y, col)

func _draw_triangle(img: Image, cx: int, cy: int, tri_size: int, col: Color):
	for y in range(tri_size + 1):
		var start_x := cx - y
		var end_x := cx + y
		var yy := cy - tri_size + y
		for x in range(start_x, end_x + 1):
			if x >= 1 and x < img.get_width() - 1 and yy >= 1 and yy < img.get_height() - 1:
				img.set_pixel(x, yy, col)

func _draw_diamond(img: Image, cx: int, cy: int, diamond_size: int, col: Color):
	for y in range(-diamond_size, diamond_size + 1):
		var row: int = diamond_size - abs(y)
		for x in range(-row, row + 1):
			var px := cx + x
			var py := cy + y
			if px >= 1 and px < img.get_width() - 1 and py >= 1 and py < img.get_height() - 1:
				img.set_pixel(px, py, col)

func _draw_stripes(img: Image, col: Color):
	var w := img.get_width()
	var h := img.get_height()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if (x + y) % 5 == 0:
				img.set_pixel(x, y, col)
