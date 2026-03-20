extends CanvasLayer

var label: Label
var ProgressCircle := preload("res://scripts/ui/ProgressCircle.gd")
var MoonProgress := preload("res://scripts/ui/MoonProgress.gd")
var progress_node: Node2D
var evac_node: Node2D
var game_tip: Label
var evac_tip: Label
var pause_button: Button
var pause_panel: PanelContainer
var pause_box: VBoxContainer
var attack_panel: PanelContainer
var attack_list: VBoxContainer
var coins_label: Label
var coll_label: Label
var choice_panel: PanelContainer
var choice_buttons: Array = []
var choice_options: Array = []
var choice_player: Node2D = null
var choice_box: HBoxContainer = null
var rarity_labels: Array = []
var choice_custom_boxes: Array = []
var choice_custom_icons: Array = []
var choice_custom_labels: Array = []
var choice_mode: String = "upgrade"
var choice_hint: Label = null
var RarityScript := preload("res://scripts/data/Rarity.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")

var overlay_rect: ColorRect = null
var overlay_active: bool = false
var mini_map
var bag_button: Button
var bag_panel: PanelContainer
var bag_box: VBoxContainer
var bag_grid_frame: PanelContainer
var bag_grid: Control
var bag_cells: Array = []
var bag_item_nodes: Dictionary = {}
var bag_items_cache: Array = []
var bag_open: bool = false
var bag_cell_size: int = 52
var bag_grid_w: int = 6
var bag_grid_h: int = 6
var bag_drag_uid: int = -1
var bag_drag_offset: Vector2 = Vector2.ZERO
var bag_drag_origin_pos: Vector2 = Vector2.ZERO
var bag_drag_origin_cell: Vector2i = Vector2i(-1, -1)
var bag_drag_origin_rot: int = 0
var bag_drag_rot: int = 0
var bag_sort_button: Button
var bag_close_button: Button
var bag_title: Label
var bag_hint: Label
var bag_drag_label: Label
class ChoiceGridIcon:
	extends Control
	var tex: Texture2D
	var grid_w: int = 1
	var grid_h: int = 1
	var grid_max: int = 4
	var line_col: Color = Color(1, 1, 1, 0.2)
	var frame_col: Color = Color(1, 1, 1, 0.8)
	var fill_col: Color = Color(1, 1, 1, 0.12)
	func _ready():
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _draw():
		var cell: int = int(floor(min(size.x, size.y) / float(grid_max)))
		if cell < 2:
			cell = 2
		var grid_px: Vector2 = Vector2(cell * grid_max, cell * grid_max)
		var origin: Vector2 = (size - grid_px) * 0.5
		for i in range(grid_max + 1):
			var x: float = origin.x + float(i * cell)
			draw_line(Vector2(x, origin.y), Vector2(x, origin.y + grid_px.y), line_col, 1.0)
			var y: float = origin.y + float(i * cell)
			draw_line(Vector2(origin.x, y), Vector2(origin.x + grid_px.x, y), line_col, 1.0)
		if tex:
			var tw: int = int(clamp(grid_w, 1, grid_max))
			var th: int = int(clamp(grid_h, 1, grid_max))
			var rect: Rect2 = Rect2(origin, Vector2(cell * tw, cell * th))
			draw_rect(rect, fill_col, true)
			draw_rect(rect, frame_col, false, 2.0)
			draw_texture_rect(tex, rect, false)
	func set_icon(t: Texture2D, w: int, h: int, rarity_color: Color):
		tex = t
		grid_w = w
		grid_h = h
		frame_col = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.95)
		fill_col = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.12)
		line_col = Color(1, 1, 1, 0.2)
		queue_redraw()
func _ready():
	label = Label.new()
	add_child(label)
	label.position = Vector2(8, 8)
	label.text = "HP:-  Enemies 0"
	if label is Control:
		(label as Control).anchor_left = 0.0
		(label as Control).anchor_top = 0.0
		(label as Control).anchor_right = 0.0
		(label as Control).anchor_bottom = 0.0
	label.scale = Vector2(1, 1)
	UIFontScript.apply_tree(self)
	label.z_index = 100
	progress_node = MoonProgress.new()
	add_child(progress_node)
	# center top; actual x set in _process using viewport width
	progress_node.position = Vector2(0, 56)
	progress_node.z_index = 100
	evac_node = ProgressCircle.new()
	add_child(evac_node)
	evac_node.position = Vector2(0, 56)
	evac_node.z_index = 100
	evac_node.fill_color = Color(0.2, 0.6, 1.0, 1.0)
	evac_node.back_color = Color(0, 0, 0, 0.6)
	evac_node.visible = false
	game_tip = Label.new()
	add_child(game_tip)
	game_tip.text = "满条之后会触发血月"
	game_tip.custom_minimum_size = Vector2(240, 20)
	game_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_tip.z_index = 101
	if game_tip is Control:
		(game_tip as Control).anchor_left = 0.0
		(game_tip as Control).anchor_top = 0.0
		(game_tip as Control).anchor_right = 0.0
		(game_tip as Control).anchor_bottom = 0.0
	evac_tip = Label.new()
	add_child(evac_tip)
	evac_tip.text = "倒计时结束后可撤离"
	evac_tip.custom_minimum_size = Vector2(240, 20)
	evac_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evac_tip.visible = false
	evac_tip.z_index = 101
	if evac_tip is Control:
		(evac_tip as Control).anchor_left = 0.0
		(evac_tip as Control).anchor_top = 0.0
		(evac_tip as Control).anchor_right = 0.0
		(evac_tip as Control).anchor_bottom = 0.0
	attack_panel = PanelContainer.new()
	add_child(attack_panel)
	attack_panel.position = Vector2(8, 120)
	if attack_panel is Control:
		(attack_panel as Control).anchor_left = 0.0
		(attack_panel as Control).anchor_top = 0.0
		(attack_panel as Control).anchor_right = 0.0
		(attack_panel as Control).anchor_bottom = 0.0
	attack_panel.z_index = 100
	attack_list = VBoxContainer.new()
	attack_list.size_flags_vertical = Control.SIZE_EXPAND
	attack_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_panel.add_child(attack_list)
	pause_button = Button.new()
	add_child(pause_button)
	pause_button.text = "暂停"
	pause_button.z_index = 1000
	if pause_button is Control:
		(pause_button as Control).anchor_left = 0.0
		(pause_button as Control).anchor_top = 0.0
		(pause_button as Control).anchor_right = 0.0
		(pause_button as Control).anchor_bottom = 0.0
		(pause_button as Node).process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.custom_minimum_size = Vector2(92, 32)
	pause_button.pressed.connect(_on_pause_pressed)
	pause_panel = PanelContainer.new()
	add_child(pause_panel)
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_panel.z_index = 2000
	if pause_panel is Control:
		(pause_panel as Control).anchor_left = 0.0
		(pause_panel as Control).anchor_top = 0.0
		(pause_panel as Control).anchor_right = 0.0
		(pause_panel as Control).anchor_bottom = 0.0
		(pause_panel as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	pause_box = VBoxContainer.new()
	pause_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pause_panel.add_child(pause_box)
	var btn_codex := Button.new()
	btn_codex.text = "收藏品图鉴"
	btn_codex.custom_minimum_size = Vector2(280, 60)
	btn_codex.pressed.connect(_on_pause_codex)
	pause_box.add_child(btn_codex)
	var btn_back := Button.new()
	btn_back.text = "返回主菜单"
	btn_back.custom_minimum_size = Vector2(280, 60)
	btn_back.pressed.connect(_on_pause_mainmenu)
	pause_box.add_child(btn_back)
	overlay_rect = ColorRect.new()
	add_child(overlay_rect)
	overlay_rect.color = Color(0, 0, 0, 0.6)
	overlay_rect.visible = false
	overlay_rect.z_index = 1000
	if overlay_rect is Node:
		(overlay_rect as Node).process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if overlay_rect is Control:
		(overlay_rect as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	move_child(overlay_rect, 0)
	var btn_resume := Button.new()
	btn_resume.text = "继续游戏"
	btn_resume.custom_minimum_size = Vector2(280, 60)
	btn_resume.pressed.connect(_on_pause_resume)
	pause_box.add_child(btn_resume)
	coins_label = Label.new()
	add_child(coins_label)
	coins_label.position = Vector2(8, 40)
	coins_label.text = "金币: 0"
	if coins_label is Control:
		(coins_label as Control).anchor_left = 0.0
		(coins_label as Control).anchor_top = 0.0
		(coins_label as Control).anchor_right = 0.0
		(coins_label as Control).anchor_bottom = 0.0
	coins_label.z_index = 100
	coll_label = Label.new()
	add_child(coll_label)
	coll_label.position = Vector2(8, 62)
	coll_label.text = "收藏品: 0"
	if coll_label is Control:
		(coll_label as Control).anchor_left = 0.0
		(coll_label as Control).anchor_top = 0.0
		(coll_label as Control).anchor_right = 0.0
		(coll_label as Control).anchor_bottom = 0.0
	coll_label.z_index = 100
	bag_button = Button.new()
	add_child(bag_button)
	bag_button.text = "背包(B)"
	bag_button.position = Vector2(8, 86)
	bag_button.z_index = 100
	if bag_button is Control:
		(bag_button as Control).anchor_left = 0.0
		(bag_button as Control).anchor_top = 0.0
		(bag_button as Control).anchor_right = 0.0
		(bag_button as Control).anchor_bottom = 0.0
	bag_button.pressed.connect(_toggle_bag)
	var MiniMapScript := preload("res://scripts/ui/MiniMap.gd")
	mini_map = MiniMapScript.new()
	add_child(mini_map)
	mini_map.z_index = 900
	choice_panel = PanelContainer.new()
	add_child(choice_panel)
	choice_panel.visible = false
	choice_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	choice_panel.z_index = 1000
	if choice_panel is Control:
		(choice_panel as Control).anchor_left = 0.0
		(choice_panel as Control).anchor_top = 0.0
		(choice_panel as Control).anchor_right = 0.0
		(choice_panel as Control).anchor_bottom = 0.0
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	choice_hint = Label.new()
	choice_hint.text = ""
	add_child(choice_hint)
	choice_hint.z_index = 1100
	if choice_hint is Control:
		(choice_hint as Control).anchor_left = 0.0
		(choice_hint as Control).anchor_top = 0.0
		(choice_hint as Control).anchor_right = 0.0
		(choice_hint as Control).anchor_bottom = 0.0
		(choice_hint as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_box = HBoxContainer.new()
	choice_panel.add_child(choice_box)
	choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var card := Button.new()
		card.text = ""
		card.pressed.connect(_on_choice_pressed.bind(i))
		choice_box.add_child(card)
		choice_buttons.append(card)
		var rl := Label.new()
		rl.text = ""
		card.add_child(rl)
		rarity_labels.append(rl)
		if rl is Control:
			(rl as Control).anchor_left = 0.0
			(rl as Control).anchor_top = 0.0
			(rl as Control).anchor_right = 0.0
			(rl as Control).anchor_bottom = 0.0
			(rl as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.anchor_left = 0.0
		vb.anchor_top = 0.0
		vb.anchor_right = 1.0
		vb.anchor_bottom = 1.0
		vb.offset_left = 0.0
		vb.offset_top = 0.0
		vb.offset_right = 0.0
		vb.offset_bottom = 0.0
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.visible = false
		card.add_child(vb)
		choice_custom_boxes.append(vb)
		var icon := ChoiceGridIcon.new()
		icon.custom_minimum_size = Vector2(96, 96)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(icon)
		choice_custom_icons.append(icon)
		var lb := Label.new()
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lb)
		choice_custom_labels.append(lb)
	_build_bag_ui()

func _build_bag_ui():
	bag_panel = PanelContainer.new()
	add_child(bag_panel)
	bag_panel.visible = false
	bag_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	bag_panel.z_index = 1500
	if bag_panel is Control:
		(bag_panel as Control).anchor_left = 0.0
		(bag_panel as Control).anchor_top = 0.0
		(bag_panel as Control).anchor_right = 0.0
		(bag_panel as Control).anchor_bottom = 0.0
		(bag_panel as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	bag_box = VBoxContainer.new()
	bag_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_panel.add_child(bag_box)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	bag_box.add_child(header)
	bag_title = Label.new()
	bag_title.text = "背包"
	header.add_child(bag_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	bag_sort_button = Button.new()
	bag_sort_button.text = "整理"
	bag_sort_button.pressed.connect(_on_bag_sort_pressed)
	header.add_child(bag_sort_button)
	bag_close_button = Button.new()
	bag_close_button.text = "关闭"
	bag_close_button.pressed.connect(_close_bag)
	header.add_child(bag_close_button)
	bag_grid_frame = PanelContainer.new()
	bag_grid_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bag_box.add_child(bag_grid_frame)
	bag_grid = Control.new()
	bag_grid.mouse_filter = Control.MOUSE_FILTER_STOP
	bag_grid.gui_input.connect(_on_bag_grid_input)
	bag_grid_frame.add_child(bag_grid)
	bag_hint = Label.new()
	bag_hint.text = "拖动摆放，R旋转，拖出丢弃"
	bag_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_box.add_child(bag_hint)
	bag_drag_label = Label.new()
	bag_drag_label.text = ""
	bag_drag_label.visible = false
	bag_drag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_drag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_box.add_child(bag_drag_label)
	_sync_bag_grid_size()
	_rebuild_bag_grid()

func _toggle_bag():
	if bag_open:
		_close_bag()
	else:
		_open_bag()

func _open_bag():
	if bag_open:
		return
	if get_tree().paused:
		return
	if choice_panel and choice_panel.visible:
		return
	if pause_panel and pause_panel.visible:
		return
	bag_open = true
	get_tree().paused = true
	if bag_panel:
		bag_panel.visible = true
	if overlay_rect:
		overlay_rect.visible = true
	overlay_active = true
	if pause_button:
		pause_button.visible = false
		pause_button.disabled = true
	_refresh_bag_view()

func _close_bag():
	if not bag_open:
		return
	bag_open = false
	bag_drag_uid = -1
	if bag_drag_label:
		bag_drag_label.text = ""
		bag_drag_label.visible = false
	if bag_panel:
		bag_panel.visible = false
	if overlay_rect:
		overlay_rect.visible = false
	overlay_active = false
	get_tree().paused = false
	if pause_button:
		pause_button.visible = true
		pause_button.disabled = false

func _update_bag_layout(vp: Vector2):
	if not bag_panel:
		return
	var grid_px_w: int = bag_cell_size * bag_grid_w
	var grid_px_h: int = bag_cell_size * bag_grid_h
	var grid_px: int = max(grid_px_w, grid_px_h)
	var panel_w: float = float(grid_px + 20)
	var panel_h: float = float(grid_px + 112)
	bag_panel.position = Vector2(vp.x * 0.5 - panel_w * 0.5, vp.y * 0.5 - panel_h * 0.5)
	bag_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	if bag_box:
		bag_box.custom_minimum_size = Vector2(panel_w, panel_h)
	if bag_grid_frame:
		bag_grid_frame.custom_minimum_size = Vector2(grid_px_w + 20, grid_px_h + 20)
	if bag_grid:
		bag_grid.position = Vector2(10, 10)
		bag_grid.custom_minimum_size = Vector2(grid_px_w, grid_px_h)

func _sync_bag_grid_size():
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_bag_grid_size"):
		var sz = root.call("get_bag_grid_size")
		if sz is Vector2i:
			if int(sz.x) != bag_grid_w or int(sz.y) != bag_grid_h:
				bag_grid_w = int(sz.x)
				bag_grid_h = int(sz.y)

func _rebuild_bag_grid():
	if not bag_grid:
		return
	for c in bag_grid.get_children():
		c.queue_free()
	bag_cells.clear()
	for y in range(bag_grid_h):
		for x in range(bag_grid_w):
			var cell := ColorRect.new()
			cell.color = Color(0, 0, 0, 0.12)
			cell.size = Vector2(bag_cell_size, bag_cell_size)
			cell.position = Vector2(x * bag_cell_size, y * bag_cell_size)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bag_grid.add_child(cell)
			bag_cells.append(cell)
	var grid_px_w: int = bag_cell_size * bag_grid_w
	var grid_px_h: int = bag_cell_size * bag_grid_h
	for i in range(bag_grid_w + 1):
		var vline := ColorRect.new()
		vline.color = Color(1, 1, 1, 0.28)
		vline.position = Vector2(i * bag_cell_size, 0)
		vline.size = Vector2(1, grid_px_h)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bag_grid.add_child(vline)
	for j in range(bag_grid_h + 1):
		var hline := ColorRect.new()
		hline.color = Color(1, 1, 1, 0.28)
		hline.position = Vector2(0, j * bag_cell_size)
		hline.size = Vector2(grid_px_w, 1)
		hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bag_grid.add_child(hline)

func _bag_item_size(it: Dictionary, rot: int) -> Vector2i:
	var w: int = int(it.get("w", 1))
	var h: int = int(it.get("h", 1))
	if rot % 2 == 1:
		return Vector2i(h, w)
	return Vector2i(w, h)

func _get_bag_item_texture(id: String, w: int, h: int, rot: int) -> Texture2D:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root:
		if root.has_method("get_collectible_art_texture_bag"):
			return root.call("get_collectible_art_texture_bag", id, w, h, rot)
		var tex = null
		if root.has_method("get_collectible_icon_texture"):
			tex = root.call("get_collectible_icon_texture", id, w, h)
		return tex
	return null

func _refresh_bag_view():
	for k in bag_item_nodes.keys():
		var n = bag_item_nodes[k]
		if n:
			n.queue_free()
	bag_item_nodes.clear()
	bag_items_cache = []
	if not bag_grid:
		return
	_sync_bag_grid_size()
	_rebuild_bag_grid()
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_bag_items"):
		bag_items_cache = root.call("get_bag_items")
	for it in bag_items_cache:
		var uid: int = int(it.get("uid", -1))
		if uid < 0:
			continue
		var rot: int = int(it.get("rot", 0))
		var sz := _bag_item_size(it, rot)
		var node := Control.new()
		node.position = Vector2(int(it.get("x", 0)) * bag_cell_size, int(it.get("y", 0)) * bag_cell_size)
		node.size = Vector2(sz.x * bag_cell_size, sz.y * bag_cell_size)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var border_col := Color(1, 1, 1, 1)
		if root and root.has_method("get_collectible_rarity"):
			var rar := String(root.call("get_collectible_rarity", String(it.get("id", ""))))
			border_col = RarityScript.color(rar)
		var bg := ColorRect.new()
		bg.name = "bg"
		bg.color = Color(0, 0, 0, 0.1)
		bg.position = Vector2.ZERO
		bg.size = node.size
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(bg)
		var b_top := ColorRect.new()
		b_top.name = "b_top"
		b_top.color = border_col
		b_top.position = Vector2.ZERO
		b_top.size = Vector2(node.size.x, 2)
		b_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(b_top)
		var b_bottom := ColorRect.new()
		b_bottom.name = "b_bottom"
		b_bottom.color = border_col
		b_bottom.position = Vector2(0, node.size.y - 2)
		b_bottom.size = Vector2(node.size.x, 2)
		b_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(b_bottom)
		var b_left := ColorRect.new()
		b_left.name = "b_left"
		b_left.color = border_col
		b_left.position = Vector2.ZERO
		b_left.size = Vector2(2, node.size.y)
		b_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(b_left)
		var b_right := ColorRect.new()
		b_right.name = "b_right"
		b_right.color = border_col
		b_right.position = Vector2(node.size.x - 2, 0)
		b_right.size = Vector2(2, node.size.y)
		b_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(b_right)
		var art := TextureRect.new()
		art.name = "art"
		art.position = Vector2.ZERO
		art.size = node.size
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex := _get_bag_item_texture(String(it.get("id", "")), int(node.size.x), int(node.size.y), rot)
		if tex:
			art.texture = tex
		node.add_child(art)
		bag_grid.add_child(node)
		bag_item_nodes[uid] = node

func _get_bag_item_by_uid(uid: int) -> Dictionary:
	for it in bag_items_cache:
		if int(it.get("uid", -1)) == uid:
			return it
	return {}

func _get_bag_item_at_pos(pos: Vector2) -> int:
	for k in bag_item_nodes.keys():
		var uid: int = int(k)
		var n = bag_item_nodes[k]
		if n and Rect2(n.position, n.size).has_point(pos):
			return uid
	return -1

func _start_bag_drag(uid: int, pos: Vector2):
	if not bag_item_nodes.has(uid):
		return
	var it := _get_bag_item_by_uid(uid)
	if it.size() == 0:
		return
	bag_drag_uid = uid
	bag_drag_origin_pos = bag_item_nodes[uid].position
	bag_drag_origin_cell = Vector2i(int(it.get("x", 0)), int(it.get("y", 0)))
	bag_drag_origin_rot = int(it.get("rot", 0))
	bag_drag_rot = bag_drag_origin_rot
	bag_drag_offset = pos - bag_item_nodes[uid].position
	bag_grid.move_child(bag_item_nodes[uid], bag_grid.get_child_count() - 1)
	if bag_drag_label:
		var root := get_tree().get_root().get_node_or_null("GameRoot")
		var name_txt := String(it.get("id", ""))
		if root and root.has_method("get_collectible_name"):
			name_txt = String(root.call("get_collectible_name", String(it.get("id", ""))))
		bag_drag_label.text = name_txt
		bag_drag_label.visible = name_txt != ""

func _update_bag_drag(pos: Vector2):
	if bag_drag_uid < 0 or not bag_item_nodes.has(bag_drag_uid):
		return
	bag_item_nodes[bag_drag_uid].position = pos - bag_drag_offset

func _apply_drag_size(uid: int, rot: int):
	if not bag_item_nodes.has(uid):
		return
	var it := _get_bag_item_by_uid(uid)
	if it.size() == 0:
		return
	var sz := _bag_item_size(it, rot)
	var node: Control = bag_item_nodes[uid]
	var center: Vector2 = node.position + node.size * 0.5
	var target_size := Vector2(sz.x * bag_cell_size, sz.y * bag_cell_size)
	node.size = target_size
	node.rotation_degrees = 0.0
	node.position = center - node.size * 0.5
	if node.has_method("set_deferred"):
		node.set_deferred("size", node.size)
	var bg := node.get_node_or_null("bg")
	if bg and bg is ColorRect:
		(bg as ColorRect).position = Vector2.ZERO
		(bg as ColorRect).size = node.size
		if bg.has_method("set_deferred"):
			bg.set_deferred("size", node.size)
	var b_top := node.get_node_or_null("b_top")
	if b_top and b_top is ColorRect:
		(b_top as ColorRect).position = Vector2.ZERO
		(b_top as ColorRect).size = Vector2(node.size.x, 2)
	var b_bottom := node.get_node_or_null("b_bottom")
	if b_bottom and b_bottom is ColorRect:
		(b_bottom as ColorRect).position = Vector2(0, node.size.y - 2)
		(b_bottom as ColorRect).size = Vector2(node.size.x, 2)
	var b_left := node.get_node_or_null("b_left")
	if b_left and b_left is ColorRect:
		(b_left as ColorRect).position = Vector2.ZERO
		(b_left as ColorRect).size = Vector2(2, node.size.y)
	var b_right := node.get_node_or_null("b_right")
	if b_right and b_right is ColorRect:
		(b_right as ColorRect).position = Vector2(node.size.x - 2, 0)
		(b_right as ColorRect).size = Vector2(2, node.size.y)
	var art := node.get_node_or_null("art")
	if art and art is TextureRect:
		(art as TextureRect).position = Vector2.ZERO
		(art as TextureRect).size = node.size
		if art.has_method("set_deferred"):
			art.set_deferred("size", node.size)
		var tex := _get_bag_item_texture(String(it.get("id", "")), int(node.size.x), int(node.size.y), rot)
		if tex:
			(art as TextureRect).texture = tex

func _reset_bag_drag(uid: int):
	if not bag_item_nodes.has(uid):
		return
	bag_item_nodes[uid].position = bag_drag_origin_pos
	_apply_drag_size(uid, bag_drag_origin_rot)
	if bag_drag_label:
		bag_drag_label.text = ""
		bag_drag_label.visible = false

func _end_bag_drag(pos: Vector2):
	var uid := bag_drag_uid
	bag_drag_uid = -1
	if bag_drag_label:
		bag_drag_label.text = ""
		bag_drag_label.visible = false
	if uid < 0:
		return
	if not bag_item_nodes.has(uid):
		return
	var node: Control = bag_item_nodes[uid]
	var grid_px_w: int = bag_cell_size * bag_grid_w
	var grid_px_h: int = bag_cell_size * bag_grid_h
	var center: Vector2 = node.position + node.size * 0.5
	var inside := center.x >= 0 and center.y >= 0 and center.x < grid_px_w and center.y < grid_px_h
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if inside and root and root.has_method("move_bag_item"):
		var item_w: int = int(round(node.size.x / float(bag_cell_size)))
		var item_h: int = int(round(node.size.y / float(bag_cell_size)))
		var cell_x: int = int(round(node.position.x / float(bag_cell_size)))
		var cell_y: int = int(round(node.position.y / float(bag_cell_size)))
		cell_x = clamp(cell_x, 0, bag_grid_w - item_w)
		cell_y = clamp(cell_y, 0, bag_grid_h - item_h)
		if bool(root.call("move_bag_item", uid, cell_x, cell_y, bag_drag_rot)):
			_refresh_bag_view()
			return
	if inside:
		_reset_bag_drag(uid)
		return
	if root and root.has_method("drop_bag_item"):
		var drop_pos: Vector2 = Vector2.ZERO
		if root.has_method("get_player_global_position"):
			drop_pos = root.call("get_player_global_position")
		root.call("drop_bag_item", uid, drop_pos)
	_refresh_bag_view()

func _rotate_drag_item():
	if bag_drag_uid < 0:
		return
	bag_drag_rot = 0 if bag_drag_rot == 1 else 1
	_apply_drag_size(bag_drag_uid, bag_drag_rot)

func _on_bag_grid_input(event):
	if not bag_open:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var uid := _get_bag_item_at_pos(event.position)
			if uid >= 0:
				_start_bag_drag(uid, event.position)
		else:
			if bag_drag_uid >= 0:
				_end_bag_drag(event.position)
	elif event is InputEventMouseMotion:
		if bag_drag_uid >= 0:
			_update_bag_drag(event.position)

func _on_bag_sort_pressed():
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("auto_pack_bag"):
		root.call("auto_pack_bag")
	_refresh_bag_view()

func on_bag_grid_changed():
	_refresh_bag_view()

func _process(_delta):
	var players := get_tree().get_nodes_in_group("player")
	var hp_txt := "-"
	if players.size() > 0:
		var p := players[0]
		var v = p.get("hp")
		if v != null:
			hp_txt = "%d" % int(v)
	var enemies := get_tree().get_nodes_in_group("enemies").size()
	label.text = "HP:%s  Enemies %d" % [hp_txt, enemies]
	var root := get_tree().get_root().get_node("GameRoot")
	var vp_size := get_viewport().get_visible_rect().size
	if overlay_rect:
		overlay_rect.position = Vector2.ZERO
		overlay_rect.size = vp_size
	_update_bag_layout(vp_size)
	if progress_node:
		progress_node.position.x = vp_size.x * 0.5
	if game_tip:
		game_tip.position = Vector2(progress_node.position.x - game_tip.custom_minimum_size.x * 0.5, progress_node.position.y - 58)
	if evac_node:
		evac_node.position.x = vp_size.x * 0.5 + 220.0
	if evac_tip:
		evac_tip.position = Vector2(evac_node.position.x - evac_tip.custom_minimum_size.x * 0.5, evac_node.position.y - 58)
	if pause_button:
		pause_button.position = Vector2(vp_size.x - pause_button.custom_minimum_size.x - 12.0, 8.0)
		pause_button.add_theme_font_size_override("font_size", 18)
	_update_pause_layout(vp_size)
	if overlay_rect:
		overlay_rect.custom_minimum_size = vp_size
		overlay_rect.position = Vector2(0, 0)
		overlay_rect.visible = overlay_active and get_tree().paused
		if overlay_rect.visible:
			overlay_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not get_tree().paused and overlay_active:
		overlay_active = false
	if pause_button:
		var allow_pause_btn: bool = not choice_panel.visible
		pause_button.visible = allow_pause_btn and not (get_tree().paused and overlay_active)
		pause_button.disabled = false
	if root and root.has_method("get_game_time") and root.has_method("get_max_time") and progress_node:
		var t: float = float(root.get_game_time())
		var m: float = float(root.get_max_time())
		var ratio: float = clamp(t / m, 0.0, 1.0)
		progress_node.call("set_ratio", ratio)
		progress_node.call("set_seconds", m - t)
	if root and root.has_method("is_post_interaction_active") and root.has_method("get_post_time") and root.has_method("get_post_limit") and evac_node:
		var active: bool = bool(root.is_post_interaction_active())
		evac_node.visible = active
		evac_tip.visible = active
		if active:
			var pt: float = float(root.get_post_time())
			var pl: float = float(root.get_post_limit())
			var pratio: float = clamp(pt / pl, 0.0, 1.0)
			evac_node.call("set_ratio", pratio)
			evac_node.call("set_seconds", pt)
	if root and root.has_method("get_run_coins"):
		var coins := int(root.get_run_coins())
		coins_label.text = "金币: %d" % coins
	if root and root.has_method("get_run_bag_count"):
		var coll := int(root.get_run_bag_count())
		coll_label.text = "收藏品: %d" % coll
	_update_attack_list(players)
	if mini_map:
		if root and root.has_node("Level"):
			var level := root.get_node("Level")
			var p: Node2D = null
			if players.size() > 0:
				p = players[0] as Node2D
			if mini_map and mini_map.has_method("set_context"):
				mini_map.call("set_context", level, p)
		mini_map.position = Vector2(vp_size.x - mini_map.size.x - 10.0, vp_size.y - mini_map.size.y - 10.0)

func show_upgrade_choices(p: Node2D) -> bool:
	if not _can_open_choice():
		return false
	choice_player = p
	choice_mode = "upgrade"
	var root := get_tree().get_root().get_node("GameRoot")
	if root and root.has_method("get_weighted_upgrade_choices"):
		choice_options = root.call("get_weighted_upgrade_choices", p, 3)
	else:
		choice_options = _generate_upgrade_choices()
	for i in range(choice_buttons.size()):
		if i < choice_options.size():
			var name_txt := _choice_name(choice_options[i])
			var r_key := _choice_rarity_key(choice_options[i])
			var root2 := get_tree().get_root().get_node("GameRoot")
			if root2:
				if root2.has_method("get_upgrade_name"):
					name_txt = String(root2.call("get_upgrade_name", choice_options[i]))
				if root2.has_method("get_upgrade_rarity"):
					r_key = String(root2.call("get_upgrade_rarity", choice_options[i]))
			choice_buttons[i].text = "%d) %s" % [i + 1, name_txt]
			choice_buttons[i].icon = null
			if i < choice_custom_boxes.size():
				choice_custom_boxes[i].visible = false
			if i < choice_custom_labels.size():
				choice_custom_labels[i].text = ""
			choice_buttons[i].disabled = false
			choice_buttons[i].visible = true
			rarity_labels[i].text = RarityScript.name(r_key)
			rarity_labels[i].position = Vector2(8, 8)
			rarity_labels[i].visible = true
			choice_buttons[i].modulate = RarityScript.color(r_key)
		else:
			choice_buttons[i].text = ""
			choice_buttons[i].icon = null
			if i < choice_custom_boxes.size():
				choice_custom_boxes[i].visible = false
			if i < choice_custom_labels.size():
				choice_custom_labels[i].text = ""
			choice_buttons[i].disabled = true
			choice_buttons[i].visible = false
			rarity_labels[i].text = ""
			rarity_labels[i].visible = false
	_update_choice_layout()
	choice_hint.text = "按 1/2/3 快速选择"
	choice_hint.visible = true
	choice_panel.visible = true
	if pause_button:
		pause_button.visible = false
		pause_button.disabled = true
	get_tree().paused = true
	return true

func _on_choice_pressed(idx: int):
	if idx >= 0 and idx < choice_options.size():
		if choice_mode == "upgrade":
			if choice_player and choice_player.has_method("apply_upgrade_kind"):
				choice_player.call("apply_upgrade_kind", choice_options[idx])
		elif choice_mode == "collectible":
			var root := get_tree().get_root().get_node("GameRoot")
			if root and root.has_method("apply_collectible_selection"):
				root.apply_collectible_selection(choice_options[idx], choice_player)
	choice_panel.visible = false
	if choice_hint:
		choice_hint.visible = false
	get_tree().paused = false
	if pause_button:
		pause_button.disabled = false
		pause_button.visible = true
	choice_player = null
	choice_options = []
	choice_mode = "upgrade"

func _generate_upgrade_choices() -> Array:
	var pool := []
	if choice_player and choice_player.has_method("has_attack"):
		if choice_player.has_attack("子弹攻击"):
			pool.append_array(["bullet_damage", "bullet_interval"])
		if choice_player.has_attack("近战攻击"):
			pool.append_array(["melee_damage", "melee_interval", "melee_range"])
		else:
			pool.append("attack_melee")
		if choice_player.has_attack("范围魔法"):
			pool.append_array(["magic_damage", "magic_interval", "magic_radius"])
		else:
			pool.append("attack_magic")
	else:
		pool = ["bullet_damage", "bullet_interval", "attack_melee", "attack_magic"]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res := []
	while res.size() < 3 and pool.size() > 0:
		var idx := rng.randi_range(0, pool.size() - 1)
		res.append(pool[idx])
		pool.remove_at(idx)
	return res

func _choice_name(k: String) -> String:
	if k == "bullet_damage":
		return "子弹伤害 +1"
	if k == "bullet_interval":
		return "子弹攻速 +"
	if k == "attack_melee":
		return "解锁近战攻击"
	if k == "attack_magic":
		return "解锁范围魔法"
	if k == "melee_damage":
		return "近战伤害 +1"
	if k == "melee_interval":
		return "近战冷却 -"
	if k == "melee_range":
		return "近战范围 +"
	if k == "magic_damage":
		return "魔法伤害 +1"
	if k == "magic_interval":
		return "魔法冷却 -"
	if k == "magic_radius":
		return "魔法范围 +"
	return k

func show_collectible_choices(p: Node2D, ids: Array):
	choice_player = p
	choice_mode = "collectible"
	choice_options = ids.duplicate()
	var root := get_tree().get_root().get_node("GameRoot")
	for i in range(choice_buttons.size()):
		if i < choice_options.size():
			var name: String = String(choice_options[i])
			var rar: String = ""
			if root:
				if root.has_method("get_collectible_name"):
					name = root.get_collectible_name(choice_options[i])
				if root.has_method("get_collectible_rarity"):
					rar = RarityScript.normalize(root.get_collectible_rarity(choice_options[i]))
			var sz := Vector2i(1, 1)
			if root and root.has_method("get_collectible_size"):
				var res: Vector2i = root.call("get_collectible_size", choice_options[i])
				sz = res
			var tex: Texture2D = null
			if root and root.has_method("get_collectible_art_texture_bag"):
				tex = root.call("get_collectible_art_texture_bag", choice_options[i], 64, 64, 0)
			elif root and root.has_method("get_collectible_icon_texture"):
				tex = root.call("get_collectible_icon_texture", choice_options[i], 64, 64)
			choice_buttons[i].text = ""
			choice_buttons[i].icon = null
			if i < choice_custom_boxes.size():
				choice_custom_boxes[i].visible = true
				choice_custom_boxes[i].z_index = 2
			if i < choice_custom_labels.size():
				choice_custom_labels[i].text = "%d) 收藏品: %s" % [i + 1, name]
			if i < choice_custom_icons.size():
				choice_custom_icons[i].set_icon(tex, int(sz.x), int(sz.y), RarityScript.color(rar))
			choice_buttons[i].disabled = false
			choice_buttons[i].visible = true
			rarity_labels[i].text = RarityScript.name(rar)
			rarity_labels[i].position = Vector2(8, 8)
			rarity_labels[i].visible = true
			choice_buttons[i].modulate = RarityScript.color(rar)
		else:
			choice_buttons[i].text = ""
			choice_buttons[i].icon = null
			if i < choice_custom_boxes.size():
				choice_custom_boxes[i].visible = false
			if i < choice_custom_labels.size():
				choice_custom_labels[i].text = ""
			choice_buttons[i].disabled = true
			choice_buttons[i].visible = false
			rarity_labels[i].text = ""
			rarity_labels[i].visible = false
	_update_choice_layout()
	choice_hint.text = "按 1/2/3 快速选择"
	choice_hint.visible = true
	choice_panel.visible = true
	if pause_button:
		pause_button.visible = false
		pause_button.disabled = true
	get_tree().paused = true

func _choice_rarity_key(k: String) -> String:
	var root := get_tree().get_root().get_node("GameRoot")
	if root and root.has_method("get_upgrade_rarity"):
		return String(root.call("get_upgrade_rarity", k))
	if k == "attack_melee" or k == "attack_magic":
		return "epic"
	return "blue"

func _update_choice_layout():
	var vp := get_viewport().get_visible_rect().size
	var h := vp.y * 0.6
	var w := vp.x * 0.8
	choice_panel.position = Vector2(vp.x * 0.5 - w * 0.5, vp.y * 0.5 - h * 0.5)
	choice_panel.custom_minimum_size = Vector2(w, h)
	# hint on top, centered and larger
	if choice_hint:
		var hint_h: float = min(72.0, h * 0.2)
		choice_hint.custom_minimum_size = Vector2(w, hint_h)
		choice_hint.position = Vector2(vp.x * 0.5 - w * 0.5, choice_panel.position.y - hint_h - 12.0)
		choice_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		choice_hint.add_theme_font_size_override("font_size", 28)
	# option box occupies full panel area
	choice_box.custom_minimum_size = Vector2(w, h)
	choice_box.position = Vector2(0, 0)
	var card_h := h * 0.95
	var card_w := w * 0.28
	for i in range(choice_buttons.size()):
		choice_buttons[i].custom_minimum_size = Vector2(card_w, card_h)
		if i < choice_custom_icons.size():
			var icon_size: float = max(48.0, min(card_w, card_h) * 0.45)
			choice_custom_icons[i].custom_minimum_size = Vector2(icon_size, icon_size)
		rarity_labels[i].scale = Vector2(1.2, 1.2)

func is_choice_active() -> bool:
	return choice_panel != null and choice_panel.visible

func _can_open_choice() -> bool:
	if choice_panel != null and choice_panel.visible:
		return false
	if pause_panel != null and pause_panel.visible:
		return false
	if overlay_active and get_tree().paused:
		return false
	if get_tree().paused:
		return false
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.get("input_locked") != null and bool(root.get("input_locked")):
		return false
	return true

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var root := get_tree().get_root().get_node_or_null("GameRoot")
		if root and root.get("input_locked") != null and bool(root.get("input_locked")):
			return
		if bag_open:
			if event.keycode == KEY_B:
				_close_bag()
				return
			if event.keycode == KEY_R:
				_rotate_drag_item()
				return
		if choice_panel.visible:
			if event.keycode == KEY_1:
				_on_choice_pressed(0)
			elif event.keycode == KEY_2:
				_on_choice_pressed(1)
			elif event.keycode == KEY_3:
				_on_choice_pressed(2)
		else:
			if event.keycode == KEY_B:
				_toggle_bag()
			elif event.keycode == KEY_ESCAPE:
				if pause_button and not pause_button.disabled and not get_tree().paused:
					_on_pause_pressed()

func _update_attack_list(players: Array):
	for c in attack_list.get_children():
		c.queue_free()
	if players.size() == 0:
		return
	var p = players[0]
	var mods = p.get("attack_modules")
	if mods == null:
		return
	for m in mods:
		if m and m.has_method("get_display_name") and m.has_method("get_display_stats"):
			var name: String = m.get_display_name()
			var stats: Dictionary = m.get_display_stats()
			var txt := "%s  " % name
			for k in stats.keys():
				txt += "%s:%s  " % [str(k), str(stats[k])]
			var l := Label.new()
			l.text = txt
			attack_list.add_child(l)
	UIFontScript.apply_tree(attack_list)

func _update_pause_layout(vp: Vector2):
	if not pause_panel:
		return
	var w := vp.x * 0.5
	var h := vp.y * 0.5
	pause_panel.position = Vector2(vp.x * 0.5 - w * 0.5, vp.y * 0.5 - h * 0.5)
	pause_panel.custom_minimum_size = Vector2(w, h)
	if pause_box:
		pause_box.custom_minimum_size = Vector2(w, h)

func _on_pause_pressed():
	if choice_panel and choice_panel.visible:
		return
	get_tree().paused = true
	pause_panel.visible = true
	overlay_active = true
	if pause_button:
		pause_button.visible = false

func _on_pause_codex():
	if pause_panel:
		pause_panel.visible = false
	get_tree().paused = true
	var codex_scene: PackedScene = preload("res://scenes/Codex.tscn")
	var codex = codex_scene.instantiate()
	if codex:
		if codex is Node:
			(codex as Node).process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		add_child(codex)
		codex.z_index = 2100
	overlay_active = true
	if pause_button:
		pause_button.visible = false
	if overlay_rect:
		move_child(overlay_rect, 0)

func _on_pause_mainmenu():
	get_tree().paused = false
	overlay_active = false
	if pause_button:
		pause_button.visible = true
		pause_button.disabled = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_pause_resume():
	pause_panel.visible = false
	get_tree().paused = false
	overlay_active = false
	if pause_button:
		pause_button.visible = true
		pause_button.disabled = false
