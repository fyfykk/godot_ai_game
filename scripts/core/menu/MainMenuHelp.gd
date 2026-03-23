extends RefCounted

var UIFontScript := preload("res://scripts/ui/UIFont.gd")

var owner
var help_overlay: ColorRect
var help_panel: PanelContainer
var help_close_button: Button

func setup(owner_node):
	owner = owner_node

func build():
	var root: Node = owner.get_tree().get_root()
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
	close_btn.pressed.connect(hide)
	vb.add_child(close_btn)
	help_close_button = close_btn
	UIFontScript.apply_tree(help_overlay)
	UIFontScript.apply_tree(help_panel)

func show():
	if help_overlay:
		help_overlay.visible = true
	if help_panel:
		help_panel.visible = true

func hide():
	if help_overlay:
		help_overlay.visible = false
	if help_panel:
		help_panel.visible = false

func cleanup():
	if help_overlay and help_overlay.is_inside_tree():
		help_overlay.queue_free()
	if help_panel and help_panel.is_inside_tree():
		help_panel.queue_free()

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
				inside = abs(float(x - tw * 0.5)) + abs(float(y - th * 0.5)) <= float(min(tw, th) * 0.5)
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
			var col := c1 if ((int(floor(float(x) * 0.5)) + int(floor(float(y) * 0.5))) % 2) == 0 else c2
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
