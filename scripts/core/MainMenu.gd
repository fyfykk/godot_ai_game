extends Control

var MetaStoreScript := preload("res://scripts/data/MetaProgressionStore.gd")
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")
var CheatSettingsScript := preload("res://scripts/data/CheatSettings.gd")
var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
var meta_store
var cheat_settings
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
var cheat_p_down: bool = false
var cheat_tilde_down: bool = false
var level_seeds: Array = [91427, 58203, 73691]
var level_overlay: ColorRect
var level_panel: PanelContainer
var level_buttons: Array = []
var level_list_container: VBoxContainer
var level_title_label: Label
var level_close_button: Button
var editor_overlay: ColorRect
var editor_panel: PanelContainer
var editor_level_overlay: ColorRect
var editor_level_panel: PanelContainer
var editor_level_buttons: Array = []
var editor_level_list_container: VBoxContainer
var editor_level_title_label: Label
var editor_level_close_button: Button
var help_overlay: ColorRect
var help_panel: PanelContainer
var help_close_button: Button

func _ready():
	meta_store = MetaStoreScript.new()
	meta_store.load()
	cheat_settings = CheatSettingsScript.new()
	cheat_settings.load()
	var btn := $StartButton
	if btn:
		btn.text = "开始游戏"
		btn.position = Vector2(480, 300)
		btn.pressed.connect(_on_start_pressed)
	_build_level_dialog()
	_build_editor_dialog()
	_build_editor_level_dialog()
	_build_help_dialog()
	_build_cheat_panel()
	var editor := Button.new()
	add_child(editor)
	editor.text = "地图编辑"
	editor.position = Vector2(480, 360)
	editor.z_index = 10
	editor.pressed.connect(_on_editor_pressed)
	var codex := Button.new()
	add_child(codex)
	codex.text = "收藏品图鉴"
	codex.position = Vector2(480, 400)
	codex.z_index = 10
	codex.pressed.connect(_on_codex_pressed)
	var save := Button.new()
	add_child(save)
	save.text = "显示存档路径"
	save.position = Vector2(480, 440)
	save.z_index = 10
	save.pressed.connect(_on_save_path_pressed)
	var clear := Button.new()
	add_child(clear)
	clear.text = "清理收藏品记录"
	clear.position = Vector2(480, 480)
	clear.z_index = 10
	clear.pressed.connect(_on_clear_collectibles_pressed)
	var help := Button.new()
	add_child(help)
	help.text = "帮助"
	help.position = Vector2(480, 520)
	help.z_index = 10
	help.pressed.connect(_on_help_pressed)
	UIFontScript.apply_tree(get_tree().get_root())

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_P:
			cheat_p_down = event.pressed
		if event.keycode == KEY_QUOTELEFT:
			cheat_tilde_down = event.pressed
		if event.pressed and not event.echo and cheat_p_down and cheat_tilde_down:
			_toggle_cheat_panel()

func _on_start_pressed():
	_refresh_level_buttons()
	_show_level_dialog()

func _on_level_pressed(level_num: int):
	var seed: int = 0
	var base_count: int = level_seeds.size()
	if level_num > 0 and level_num <= base_count:
		seed = int(level_seeds[level_num - 1])
	get_tree().set_meta("run_mode", "game")
	get_tree().set_meta("level_seed", seed)
	get_tree().set_meta("level_index", level_num)
	if level_num > base_count:
		get_tree().set_meta("use_custom_map_index", level_num - base_count - 1)
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

func _on_editor_pressed():
	_show_editor_dialog()

func _on_editor_existing_pressed():
	_hide_editor_dialog()
	_refresh_editor_level_buttons()
	_show_editor_level_dialog()

func _on_editor_new_pressed():
	get_tree().set_meta("run_mode", "editor")
	get_tree().set_meta("editor_new", true)
	get_tree().set_meta("editor_custom_index", -1)
	_hide_editor_dialog()
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

func _on_help_pressed():
	_show_help_dialog()

func _build_level_dialog():
	var root := get_tree().get_root()
	level_overlay = ColorRect.new()
	root.call_deferred("add_child", level_overlay)
	level_overlay.color = Color(0, 0, 0, 0.8)
	level_overlay.visible = false
	level_overlay.z_index = 200
	if level_overlay is Control:
		(level_overlay as Control).anchor_left = 0.0
		(level_overlay as Control).anchor_top = 0.0
		(level_overlay as Control).anchor_right = 1.0
		(level_overlay as Control).anchor_bottom = 1.0
		(level_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	level_panel = PanelContainer.new()
	root.call_deferred("add_child", level_panel)
	level_panel.visible = false
	level_panel.z_index = 210
	if level_panel is Control:
		(level_panel as Control).anchor_left = 0.0
		(level_panel as Control).anchor_top = 0.0
		(level_panel as Control).anchor_right = 1.0
		(level_panel as Control).anchor_bottom = 1.0
		(level_panel as Control).offset_left = 0
		(level_panel as Control).offset_top = 0
		(level_panel as Control).offset_right = 0
		(level_panel as Control).offset_bottom = 0
		(level_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	level_panel.add_child(center_box)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(400, 360)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.add_child(list_panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	list_panel.add_child(vb)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "关卡选择"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	level_title_label = title
	level_list_container = vb
	level_buttons.clear()
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(_hide_level_dialog)
	vb.add_child(close_btn)
	level_close_button = close_btn
	_refresh_level_buttons()
	UIFontScript.apply_tree(level_overlay)
	UIFontScript.apply_tree(level_panel)

func _build_help_dialog():
	var root := get_tree().get_root()
	help_overlay = ColorRect.new()
	root.call_deferred("add_child", help_overlay)
	help_overlay.color = Color(0, 0, 0, 0.8)
	help_overlay.visible = false
	help_overlay.z_index = 260
	if help_overlay is Control:
		(help_overlay as Control).anchor_left = 0.0
		(help_overlay as Control).anchor_top = 0.0
		(help_overlay as Control).anchor_right = 1.0
		(help_overlay as Control).anchor_bottom = 1.0
		(help_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	help_panel = PanelContainer.new()
	root.call_deferred("add_child", help_panel)
	help_panel.visible = false
	help_panel.z_index = 270
	if help_panel is Control:
		(help_panel as Control).anchor_left = 0.0
		(help_panel as Control).anchor_top = 0.0
		(help_panel as Control).anchor_right = 1.0
		(help_panel as Control).anchor_bottom = 1.0
		(help_panel as Control).offset_left = 0
		(help_panel as Control).offset_top = 0
		(help_panel as Control).offset_right = 0
		(help_panel as Control).offset_bottom = 0
		(help_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	help_panel.add_child(center_box)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(660, 560)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.add_child(list_panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	list_panel.add_child(vb)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "帮助"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var section_ctrl := Label.new()
	section_ctrl.text = "控制"
	section_ctrl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(section_ctrl)
	var ctrl_info := Label.new()
	ctrl_info.text = "A/D 或 ←/→：移动\nW/S 或 ↑/↓：爬梯\nB：背包    R：旋转背包物品\n1/2/3：快速选择    ESC：暂停"
	ctrl_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(ctrl_info)
	var section_inter := Label.new()
	section_inter.text = "交互"
	section_inter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(section_inter)
	var inter_info := Label.new()
	inter_info.text = "E：与门/宝箱/梯子/出口交互，多数交互需要长按等待进度完成"
	inter_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(inter_info)
	var section_item := Label.new()
	section_item.text = "物品说明"
	section_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(section_item)
	var item_box := VBoxContainer.new()
	item_box.add_theme_constant_override("separation", 6)
	vb.add_child(item_box)
	_add_help_item_row(item_box, "coin", "金币：拾取后立即增加本局金币")
	_add_help_item_row(item_box, "upgrade", "强化：拾取后弹出三选一强化")
	_add_help_item_row(item_box, "collectible", "收藏品：进入背包，胜利后结算入库")
	_add_help_item_row(item_box, "note", "纸条：密码线索，解锁密码宝箱")
	var section_env := Label.new()
	section_env.text = "场景交互"
	section_env.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(section_env)
	var env_box := VBoxContainer.new()
	env_box.add_theme_constant_override("separation", 6)
	vb.add_child(env_box)
	_add_help_item_row(env_box, "door", "门：R 开关门；门损坏时靠近门体长按 E 修理，等待进度完成")
	_add_help_item_row(env_box, "chest", "普通宝箱：长按 E 开箱，等待进度完成")
	_add_help_item_row(env_box, "chest_once", "单次宝箱：只可开启一次，长按 E 开箱")
	_add_help_item_row(env_box, "chest_password", "密码宝箱：按 E 交互后输入 4 位密码")
	_add_help_item_row(env_box, "ladder_locked", "锁定梯子：长按 E 花费金币解锁，等待进度完成")
	_add_help_item_row(env_box, "exit", "出口：长按 E 撤离，等待进度完成")
	var section_play := Label.new()
	section_play.text = "玩法"
	section_play.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(section_play)
	var play_info := Label.new()
	play_info.text = "角色自动攻击，探索开箱获取强化与收藏品；找到出口撤离结算。"
	play_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(play_info)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(_hide_help_dialog)
	vb.add_child(close_btn)
	help_close_button = close_btn
	UIFontScript.apply_tree(help_overlay)
	UIFontScript.apply_tree(help_panel)

func _add_help_item_row(parent: VBoxContainer, kind: String, text: String):
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.texture = _build_help_icon(kind, 18, 18)
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var lb := Label.new()
	lb.text = text
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lb)

func _build_help_icon(kind: String, w: int, h: int) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var edge := Color(0.12, 0.12, 0.12, 1.0)
	var c1 := Color(0.4, 0.6, 1.0, 1.0)
	var c2 := Color(0.3, 0.5, 0.86, 1.0)
	if kind == "coin":
		c1 = Color(1.0, 0.86, 0.24, 1.0)
		c2 = Color(0.86, 0.66, 0.12, 1.0)
	elif kind == "collectible":
		c1 = Color(0.74, 0.43, 1.0, 1.0)
		c2 = Color(0.56, 0.3, 0.82, 1.0)
	elif kind == "upgrade":
		c1 = Color(0.4, 0.9, 0.5, 1.0)
		c2 = Color(0.2, 0.7, 0.35, 1.0)
	elif kind == "note":
		c1 = Color(0.9, 0.85, 0.76, 1.0)
		c2 = Color(0.82, 0.78, 0.7, 1.0)
	for y in range(th):
		for x in range(tw):
			var inside: bool = true
			if kind == "coin":
				var nx: float = (float(x) - float(tw) * 0.5 + 0.5) / (float(tw) * 0.5)
				var ny: float = (float(y) - float(th) * 0.5 + 0.5) / (float(th) * 0.5)
				inside = nx * nx + ny * ny <= 1.0
			if kind == "collectible":
				inside = abs(float(x - tw / 2)) + abs(float(y - th / 2)) <= float(min(tw, th) / 2)
			if kind == "door":
				inside = x >= 5 and x <= 12 and y >= 3 and y <= 15
			if kind == "chest":
				inside = y >= 7 and y <= 15 and x >= 3 and x <= 14
			if kind == "chest_once":
				inside = y >= 7 and y <= 15 and x >= 3 and x <= 14
			if kind == "chest_password":
				inside = y >= 7 and y <= 15 and x >= 3 and x <= 14
			if kind == "ladder_locked":
				inside = (x == 5 or x == 12) and y >= 3 and y <= 15
				if y in [5, 8, 11, 14] and x >= 6 and x <= 11:
					inside = true
				if x >= 8 and x <= 10 and y >= 11 and y <= 13:
					inside = true
			if kind == "exit":
				var left: int = 4 + max(0, 6 - y)
				var right: int = 13 - max(0, 6 - y)
				inside = y >= 4 and y <= 15 and x >= left and x <= right
			if not inside:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := c1 if ((x / 2 + y / 2) % 2) == 0 else c2
			var near_edge: bool = x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if kind == "door":
				c1 = Color(0.55, 0.32, 0.16, 1.0)
				c2 = Color(0.45, 0.25, 0.12, 1.0)
				col = c1 if ((x + y) % 2) == 0 else c2
				if x == 11 and y == 9:
					col = Color(0.9, 0.78, 0.25, 1.0)
			if kind == "chest":
				c1 = Color(0.7, 0.48, 0.2, 1.0)
				c2 = Color(0.55, 0.35, 0.14, 1.0)
				col = c1 if ((x + y) % 2) == 0 else c2
				if x in [8, 9] and y == 10:
					col = Color(0.9, 0.78, 0.25, 1.0)
			if kind == "chest_once":
				c1 = Color(0.9, 0.85, 0.2, 1.0)
				c2 = Color(0.8, 0.7, 0.16, 1.0)
				col = c1 if ((x + y) % 2) == 0 else c2
				if x in [8, 9] and y == 10:
					col = Color(0.9, 0.78, 0.25, 1.0)
			if kind == "chest_password":
				c1 = Color(0.2, 0.55, 0.75, 1.0)
				c2 = Color(0.12, 0.42, 0.62, 1.0)
				col = c1 if ((x + y) % 2) == 0 else c2
				if x in [8, 9] and y in [10, 11]:
					col = Color(0.85, 0.9, 1.0, 1.0)
			if kind == "ladder_locked":
				if x >= 8 and x <= 10 and y >= 11 and y <= 13:
					col = Color(0.9, 0.78, 0.25, 1.0)
				else:
					col = Color(0.6, 0.5, 0.35, 1.0)
			if kind == "exit":
				c1 = Color(0.2, 0.85, 0.4, 1.0)
				c2 = Color(0.15, 0.7, 0.32, 1.0)
				col = c1 if ((x + y) % 2) == 0 else c2
			if near_edge:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _exit_tree():
	if level_overlay and level_overlay.is_inside_tree():
		level_overlay.queue_free()
	if level_panel and level_panel.is_inside_tree():
		level_panel.queue_free()
	if editor_overlay and editor_overlay.is_inside_tree():
		editor_overlay.queue_free()
	if editor_panel and editor_panel.is_inside_tree():
		editor_panel.queue_free()
	if editor_level_overlay and editor_level_overlay.is_inside_tree():
		editor_level_overlay.queue_free()
	if editor_level_panel and editor_level_panel.is_inside_tree():
		editor_level_panel.queue_free()
	if help_overlay and help_overlay.is_inside_tree():
		help_overlay.queue_free()
	if help_panel and help_panel.is_inside_tree():
		help_panel.queue_free()
	if cheat_overlay and cheat_overlay.is_inside_tree():
		cheat_overlay.queue_free()
	if cheat_panel and cheat_panel.is_inside_tree():
		cheat_panel.queue_free()

func _show_level_dialog():
	if level_overlay:
		level_overlay.visible = true
	if level_panel:
		level_panel.visible = true

func _hide_level_dialog():
	if level_overlay:
		level_overlay.visible = false
	if level_panel:
		level_panel.visible = false

func _show_help_dialog():
	if help_overlay:
		help_overlay.visible = true
	if help_panel:
		help_panel.visible = true

func _hide_help_dialog():
	if help_overlay:
		help_overlay.visible = false
	if help_panel:
		help_panel.visible = false

func _build_cheat_panel():
	var root := get_tree().get_root()
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
	cheat_close_button.pressed.connect(_hide_cheat_panel)
	btn_row.add_child(cheat_close_button)

func _toggle_cheat_panel():
	if cheat_panel == null or cheat_overlay == null:
		return
	if cheat_open:
		_hide_cheat_panel()
	else:
		_show_cheat_panel()

func _show_cheat_panel():
	cheat_open = true
	if cheat_overlay:
		cheat_overlay.visible = true
	if cheat_panel:
		cheat_panel.visible = true

func _hide_cheat_panel():
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

func _refresh_level_buttons():
	_rebuild_level_buttons()
	var unlocked: int = int(meta_store.max_level_unlocked) if meta_store != null else level_seeds.size()
	var base_count: int = level_seeds.size()
	for i in range(level_buttons.size()):
		var level_num: int = i + 1
		var b: Button = level_buttons[i]
		if level_num <= base_count:
			if level_num <= unlocked:
				b.disabled = false
				b.text = "关卡 %d" % level_num
			else:
				b.disabled = true
				b.text = "关卡 %d（未解锁）" % level_num
		else:
			b.disabled = false
			b.text = "关卡 %d" % level_num

func _rebuild_level_buttons():
	if level_list_container == null:
		return
	for c in level_list_container.get_children():
		if c != level_title_label and c != level_close_button:
			c.queue_free()
	level_buttons.clear()
	var total: int = level_seeds.size() + _get_custom_count()
	for i in range(total):
		var level_num: int = i + 1
		var b := Button.new()
		b.custom_minimum_size = Vector2(280, 44)
		b.pressed.connect(_on_level_pressed.bind(level_num))
		level_buttons.append(b)
		level_list_container.add_child(b)
	if level_close_button:
		level_list_container.move_child(level_close_button, level_list_container.get_child_count() - 1)

func _build_editor_dialog():
	var root := get_tree().get_root()
	editor_overlay = ColorRect.new()
	root.call_deferred("add_child", editor_overlay)
	editor_overlay.color = Color(0, 0, 0, 0.8)
	editor_overlay.visible = false
	editor_overlay.z_index = 220
	if editor_overlay is Control:
		(editor_overlay as Control).anchor_left = 0.0
		(editor_overlay as Control).anchor_top = 0.0
		(editor_overlay as Control).anchor_right = 1.0
		(editor_overlay as Control).anchor_bottom = 1.0
		(editor_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	editor_panel = PanelContainer.new()
	root.call_deferred("add_child", editor_panel)
	editor_panel.visible = false
	editor_panel.z_index = 230
	if editor_panel is Control:
		(editor_panel as Control).anchor_left = 0.0
		(editor_panel as Control).anchor_top = 0.0
		(editor_panel as Control).anchor_right = 1.0
		(editor_panel as Control).anchor_bottom = 1.0
		(editor_panel as Control).offset_left = 0
		(editor_panel as Control).offset_top = 0
		(editor_panel as Control).offset_right = 0
		(editor_panel as Control).offset_bottom = 0
		(editor_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	editor_panel.add_child(center_box)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(400, 260)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.add_child(list_panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	list_panel.add_child(vb)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "地图编辑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var btn_existing := Button.new()
	btn_existing.text = "编辑已有关卡"
	btn_existing.custom_minimum_size = Vector2(280, 44)
	btn_existing.pressed.connect(_on_editor_existing_pressed)
	vb.add_child(btn_existing)
	var btn_new := Button.new()
	btn_new.text = "新建关卡"
	btn_new.custom_minimum_size = Vector2(280, 44)
	btn_new.pressed.connect(_on_editor_new_pressed)
	vb.add_child(btn_new)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(_hide_editor_dialog)
	vb.add_child(close_btn)
	UIFontScript.apply_tree(editor_overlay)
	UIFontScript.apply_tree(editor_panel)

func _build_editor_level_dialog():
	var root := get_tree().get_root()
	editor_level_overlay = ColorRect.new()
	root.call_deferred("add_child", editor_level_overlay)
	editor_level_overlay.color = Color(0, 0, 0, 0.8)
	editor_level_overlay.visible = false
	editor_level_overlay.z_index = 240
	if editor_level_overlay is Control:
		(editor_level_overlay as Control).anchor_left = 0.0
		(editor_level_overlay as Control).anchor_top = 0.0
		(editor_level_overlay as Control).anchor_right = 1.0
		(editor_level_overlay as Control).anchor_bottom = 1.0
		(editor_level_overlay as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	editor_level_panel = PanelContainer.new()
	root.call_deferred("add_child", editor_level_panel)
	editor_level_panel.visible = false
	editor_level_panel.z_index = 250
	if editor_level_panel is Control:
		(editor_level_panel as Control).anchor_left = 0.0
		(editor_level_panel as Control).anchor_top = 0.0
		(editor_level_panel as Control).anchor_right = 1.0
		(editor_level_panel as Control).anchor_bottom = 1.0
		(editor_level_panel as Control).offset_left = 0
		(editor_level_panel as Control).offset_top = 0
		(editor_level_panel as Control).offset_right = 0
		(editor_level_panel as Control).offset_bottom = 0
		(editor_level_panel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	editor_level_panel.add_child(center_box)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(400, 360)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_box.add_child(list_panel)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	list_panel.add_child(vb)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "选择要编辑的关卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	editor_level_title_label = title
	editor_level_list_container = vb
	editor_level_buttons.clear()
	var close_btn := Button.new()
	close_btn.text = "返回"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(_hide_editor_level_dialog)
	vb.add_child(close_btn)
	editor_level_close_button = close_btn
	UIFontScript.apply_tree(editor_level_overlay)
	UIFontScript.apply_tree(editor_level_panel)

func _show_editor_dialog():
	if editor_overlay:
		editor_overlay.visible = true
	if editor_panel:
		editor_panel.visible = true

func _hide_editor_dialog():
	if editor_overlay:
		editor_overlay.visible = false
	if editor_panel:
		editor_panel.visible = false

func _show_editor_level_dialog():
	if editor_level_overlay:
		editor_level_overlay.visible = true
	if editor_level_panel:
		editor_level_panel.visible = true

func _hide_editor_level_dialog():
	if editor_level_overlay:
		editor_level_overlay.visible = false
	if editor_level_panel:
		editor_level_panel.visible = false

func _refresh_editor_level_buttons():
	_rebuild_editor_level_buttons()
	var base_count: int = level_seeds.size()
	for i in range(editor_level_buttons.size()):
		var level_num: int = i + 1
		var b: Button = editor_level_buttons[i]
		b.disabled = false
		if level_num <= base_count:
			b.text = "关卡 %d" % level_num
		else:
			b.text = "自定义 %d" % (level_num - base_count)

func _rebuild_editor_level_buttons():
	if editor_level_list_container == null:
		return
	for c in editor_level_list_container.get_children():
		if c != editor_level_title_label and c != editor_level_close_button:
			c.queue_free()
	editor_level_buttons.clear()
	var base_count: int = level_seeds.size()
	var custom_count: int = _get_custom_count()
	var total: int = base_count + custom_count
	for i in range(total):
		var level_num: int = i + 1
		if level_num <= base_count:
			var b := Button.new()
			b.custom_minimum_size = Vector2(280, 44)
			b.text = "关卡 %d" % level_num
			b.pressed.connect(_on_editor_level_pressed.bind(level_num))
			editor_level_buttons.append(b)
			editor_level_list_container.add_child(b)
		else:
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var b2 := Button.new()
			b2.custom_minimum_size = Vector2(210, 44)
			b2.text = "自定义 %d" % (level_num - base_count)
			b2.pressed.connect(_on_editor_level_pressed.bind(level_num))
			editor_level_buttons.append(b2)
			row.add_child(b2)
			var del := Button.new()
			del.custom_minimum_size = Vector2(70, 44)
			del.text = "删除"
			del.pressed.connect(_on_editor_custom_delete.bind(level_num - base_count - 1))
			row.add_child(del)
			editor_level_list_container.add_child(row)
	if editor_level_close_button:
		editor_level_list_container.move_child(editor_level_close_button, editor_level_list_container.get_child_count() - 1)

func _on_editor_level_pressed(level_num: int):
	var seed: int = 0
	var base_count: int = level_seeds.size()
	if level_num > 0 and level_num <= base_count:
		seed = int(level_seeds[level_num - 1])
	get_tree().set_meta("run_mode", "editor")
	get_tree().set_meta("editor_new", false)
	get_tree().set_meta("level_seed", seed)
	get_tree().set_meta("level_index", level_num)
	if level_num > base_count:
		get_tree().set_meta("editor_custom_index", level_num - base_count - 1)
	else:
		get_tree().set_meta("editor_custom_index", -1)
	_hide_editor_level_dialog()
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

func _delete_custom_map():
	var custom_path := LocalPathsScript.file_path("custom_maps.json")
	var legacy_path := LocalPathsScript.file_path("map_editor.json")
	if FileAccess.file_exists(custom_path):
		DirAccess.remove_absolute(custom_path)
	if FileAccess.file_exists(legacy_path):
		DirAccess.remove_absolute(legacy_path)

func _on_editor_custom_delete(idx: int):
	var maps := _load_custom_maps()
	if idx < 0 or idx >= maps.size():
		return
	maps.remove_at(idx)
	_save_custom_maps(maps)
	_refresh_editor_level_buttons()

func _get_custom_count() -> int:
	var maps := _load_custom_maps()
	return maps.size()

func _load_custom_maps() -> Array:
	var custom_path := LocalPathsScript.ensure_text_file("custom_maps.json", "res://data/maps/custom_maps.json", "[]")
	var f := FileAccess.open(custom_path, FileAccess.READ)
	if f:
		var txt := f.get_as_text()
		f.close()
		var data = JSON.parse_string(txt)
		if data is Array:
			return data
	var legacy_path := LocalPathsScript.file_path("map_editor.json")
	var legacy := FileAccess.open(legacy_path, FileAccess.READ)
	if legacy:
		var txt2 := legacy.get_as_text()
		legacy.close()
		var d2 = JSON.parse_string(txt2)
		if d2 is Dictionary:
			var arr: Array = [d2]
			_save_custom_maps(arr)
			return arr
	return []

func _save_custom_maps(arr: Array):
	var txt := JSON.stringify(arr)
	var custom_path := LocalPathsScript.file_path("custom_maps.json")
	var f := FileAccess.open(custom_path, FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()

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
	dlg.popup_centered()
func _on_clear_collectibles_pressed():
	var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
	var store := CollStoreScript.new()
	store.load()
	store.counts = {}
	store.total = 0
	store.save()
	var dlg := AcceptDialog.new()
	dlg.title = "开发者功能"
	dlg.dialog_text = "已清理本地收藏品记录"
	add_child(dlg)
	dlg.popup_centered()

func _build_codex():
	var root := Node.new()
	add_child(root)
	var title := Label.new()
	title.text = "收藏品图鉴"
	title.position = Vector2(100, 120)
	add_child(title)
	var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
	var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
	var config := CollConfigScript.new()
	config.load_csv()
	var store := CollStoreScript.new()
	store.load()
	var vb := VBoxContainer.new()
	vb.position = Vector2(100, 160)
	add_child(vb)
	for rec_i in config.items:
		var rec: Dictionary = rec_i
		var id: String = String(rec["id"])
		var name: String = String(rec["name"])
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
		l.text = "%s（%s） 已获得:%d" % [name, rar, cnt]
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
	var seed := _icon_hash(icon_key)
	var mode := seed % 4
	for y in range(th):
		for x in range(tw):
			var border := x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if border:
				img.set_pixel(x, y, edge)
				continue
			var on := false
			if mode == 0:
				on = ((x + y + seed) % 2) == 0
			elif mode == 1:
				on = ((x / 2 + y) % 2) == 0
			elif mode == 2:
				var cx: int = tw / 2
				var cy: int = th / 2
				on = abs(x - cx) + abs(y - cy) <= int(min(tw, th) / 3)
			else:
				on = x == y or x == (tw - 1 - y)
			img.set_pixel(x, y, c1 if on else c2)
	var mark := base.lightened(0.55)
	var midx: int = tw / 2
	var midy: int = th / 2
	var size: int = int(min(tw, th) / 3)
	if _icon_has(icon_key, "紫"):
		_draw_diamond(img, midx, midy, size, mark)
	if _icon_has(icon_key, "弹"):
		_draw_circle(img, midx, midy, size, mark)
	elif _icon_has(icon_key, "刃"):
		_draw_triangle(img, midx, midy, size, mark)
	elif _icon_has(icon_key, "法"):
		_draw_ring(img, midx, midy, size, mark)
	if _icon_has(icon_key, "拓") or _icon_has(icon_key, "扩"):
		_draw_plus(img, midx, midy, size, mark)
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

func _draw_plus(img: Image, cx: int, cy: int, size: int, col: Color):
	for i in range(-size, size + 1):
		var x := cx + i
		var y := cy
		if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
			img.set_pixel(x, y, col)
	for j in range(-size, size + 1):
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

func _draw_triangle(img: Image, cx: int, cy: int, size: int, col: Color):
	for y in range(size + 1):
		var start_x := cx - y
		var end_x := cx + y
		var yy := cy - size + y
		for x in range(start_x, end_x + 1):
			if x >= 1 and x < img.get_width() - 1 and yy >= 1 and yy < img.get_height() - 1:
				img.set_pixel(x, yy, col)

func _draw_diamond(img: Image, cx: int, cy: int, size: int, col: Color):
	for y in range(-size, size + 1):
		var row: int = size - abs(y)
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
