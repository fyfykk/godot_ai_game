extends Control

var RarityScript := preload("res://scripts/data/Rarity.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")
var bg_rect: ColorRect = null
var codex_scroller: ScrollContainer = null
var codex_grid: GridContainer = null

class GridIcon:
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
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0.06, 0.07, 0.1, 1.0)
	bg_rect.anchor_left = 0.0
	bg_rect.anchor_top = 0.0
	bg_rect.anchor_right = 0.0
	bg_rect.anchor_bottom = 0.0
	bg_rect.offset_left = 0
	bg_rect.offset_top = 0
	bg_rect.offset_right = 0
	bg_rect.offset_bottom = 0
	bg_rect.z_index = -10
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)
	move_child(bg_rect, 0)
	_update_bg_size()
	var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
	var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
	var config := CollConfigScript.new()
	config.load_csv()
	var store := CollStoreScript.new()
	store.load()
	var back := Button.new()
	add_child(back)
	var in_game := get_tree().get_root().has_node("GameRoot")
	back.text = "返回游戏" if in_game else "返回主菜单"
	back.position = Vector2(40, 40)
	back.pressed.connect(_on_back_pressed)
	var sc := ScrollContainer.new()
	add_child(sc)
	codex_scroller = sc
	sc.custom_minimum_size = Vector2(1200, 560)
	var grid := GridContainer.new()
	codex_grid = grid
	grid.columns = 3
	grid.custom_minimum_size = Vector2(1160, 540)
	sc.add_child(grid)
	var list: Array[Dictionary] = config.items.duplicate()
	list.sort_custom(Callable(self, "_codex_cmp"))
	for rec_i in list:
		var rec: Dictionary = rec_i
		var rar_key: String = String(rec["rarity"])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(360, 140)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.1)
		style.border_color = RarityScript.color(rar_key)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		card.add_theme_stylebox_override("panel", style)
		var hb := HBoxContainer.new()
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hb.add_theme_constant_override("separation", 12)
		card.add_child(hb)
		var icon: Control = _make_icon(rec)
		icon.custom_minimum_size = Vector2(80, 80)
		hb.add_child(icon)
		var right := VBoxContainer.new()
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right.add_theme_constant_override("separation", 4)
		var name_label: Label = Label.new()
		name_label.text = "%s（%s）" % [String(rec["name"]), RarityScript.name(rar_key)]
		right.add_child(name_label)
		var id: String = String(rec["id"])
		var cnt: int = int(store.get_count(id))
		var cnt_box := HBoxContainer.new()
		var unlock_key: String = String(rec["unlock"])
		if unlock_key != "none":
			var dot := Label.new()
			dot.text = "■" if cnt >= 1 else "□"
			dot.modulate = RarityScript.color(String(rec["rarity"]))
			cnt_box.add_child(dot)
		else:
			var cap: int = 5
			if String(rec["rarity"]) == "white":
				cap = 1
			for i in range(cap):
				var dot := Label.new()
				dot.text = "■" if i < cnt else "□"
				dot.modulate = RarityScript.color(String(rec["rarity"]))
				cnt_box.add_child(dot)
		right.add_child(cnt_box)
		var eff := Label.new()
		eff.text = _effect_text(id, rec, cnt)
		right.add_child(eff)
		hb.add_child(right)
		grid.add_child(card)
	_update_bg_size()
	UIFontScript.apply_tree(self)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_bg_size()

func _update_bg_size():
	if bg_rect == null:
		return
	var vp := get_viewport_rect().size
	bg_rect.position = Vector2.ZERO
	bg_rect.size = vp
	if codex_scroller:
		var target_w: float = codex_scroller.custom_minimum_size.x
		var target_h: float = codex_scroller.custom_minimum_size.y
		codex_scroller.anchor_left = 0.5
		codex_scroller.anchor_right = 0.5
		codex_scroller.anchor_top = 0.0
		codex_scroller.anchor_bottom = 0.0
		codex_scroller.offset_left = -target_w * 0.5
		codex_scroller.offset_right = target_w * 0.5
		codex_scroller.offset_top = 100.0
		codex_scroller.offset_bottom = 100.0 + target_h
		if codex_grid:
			var inner_left: float = max(0.0, (codex_scroller.size.x - codex_grid.custom_minimum_size.x) * 0.5)
			codex_grid.position = Vector2(inner_left, 0.0)

func _on_back_pressed():
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root:
		get_tree().paused = false
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")



func _effect_text(id: String, rec: Dictionary, cnt: int) -> String:
	if id.begins_with("W"):
		if cnt <= 0:
			return "密码纸条：未获得"
		if id == "W001":
			return "密码纸条：第1位=7"
		if id == "W002":
			return "密码纸条：第2位=3"
		if id == "W003":
			return "密码纸条：第3位=5"
		if id == "W004":
			return "密码纸条：第4位=5"
	var unlock_key := String(rec["unlock"])
	if unlock_key != "none":
		if unlock_key == "attack_melee":
			return "开局解锁近战攻击"
		if unlock_key == "attack_magic":
			return "开局解锁范围魔法"
		if unlock_key == "attack_roar":
			return "开局解锁龙咆哮"
		if unlock_key == "bag_expand":
			return "背包扩展至6×6"
		return "开局解锁攻击"
	var target := String(rec["target"])
	var typ := String(rec["type"])
	var val := 0.0
	if cnt <= 1:
		val = float(rec["v1"])
	elif cnt == 2:
		val = float(rec["v2"])
	elif cnt == 3:
		val = float(rec["v3"])
	elif cnt == 4:
		val = float(rec["v4"])
	else:
		val = float(rec["v5"])
	if target == "bullet" and typ == "damage":
		return "子弹伤害 %+d" % int(val)
	if target == "bullet" and typ == "interval":
		return "子弹冷却 %+0.2f" % float(val)
	if target == "bullet" and typ == "range":
		return "子弹范围 %+0.1f" % float(val)
	if target == "melee" and typ == "damage":
		return "近战伤害 %+d" % int(val)
	if target == "melee" and typ == "interval":
		return "近战冷却 %+0.2f" % float(val)
	if target == "melee" and typ == "range":
		return "近战范围 %+0.1f" % float(val)
	if target == "magic" and typ == "damage":
		return "魔法伤害 %+d" % int(val)
	if target == "magic" and typ == "interval":
		return "魔法冷却 %+0.2f" % float(val)
	if target == "magic" and typ == "radius":
		return "魔法范围 %+0.1f" % float(val)
	if target == "roar" and typ == "damage":
		return "龙咆哮伤害 %+d" % int(val)
	if target == "roar" and typ == "interval":
		return "龙咆哮冷却 %+0.2f" % float(val)
	return ""

func _make_icon(rec: Dictionary) -> Control:
	var gw: int = int(rec.get("w", 1))
	var gh: int = int(rec.get("h", 1))
	var tex := _build_collectible_icon_plain(String(rec.get("icon", "")), String(rec.get("rarity", "")), 64, 64)
	var frame_col: Color = RarityScript.color(String(rec.get("rarity", "")))
	var box := GridIcon.new()
	box.custom_minimum_size = Vector2(80, 80)
	box.set_icon(tex, gw, gh, frame_col)
	return box

func _build_collectible_icon_plain(icon_key: String, rarity: String, w: int, h: int) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base: Color = RarityScript.color(rarity)
	var logical: int = 16
	var art_cell: int = int(floor(min(float(tw), float(th)) / float(logical)))
	if art_cell < 1:
		art_cell = 1
	var art_w: int = logical * art_cell
	var art_h: int = logical * art_cell
	var ax: int = int((tw - art_w) * 0.5)
	var ay: int = int((th - art_h) * 0.5)
	_draw_icon_art(img, icon_key, ax, ay, art_cell, base)
	return ImageTexture.create_from_image(img)


func _draw_icon_art(img: Image, icon_key: String, ox: int, oy: int, s: int, rarity_col: Color):
	var key := icon_key.to_lower()
	var kind := _icon_kind(key)
	var badge := _icon_badge(key)
	var metal := Color(0.68, 0.7, 0.72, 1.0)
	var dark := Color(0.2, 0.22, 0.25, 1.0)
	var wood := Color(0.55, 0.32, 0.16, 1.0)
	var gold := Color(0.9, 0.78, 0.25, 1.0)
	var blue := Color(0.25, 0.65, 0.95, 1.0)
	var purple := Color(0.6, 0.35, 0.8, 1.0)
	var red := Color(0.9, 0.25, 0.22, 1.0)
	var paper := Color(0.9, 0.85, 0.76, 1.0)
	var ink := Color(0.35, 0.3, 0.25, 1.0)
	if kind == "crest_warrior":
		_draw_rect_px(img, ox, oy, s, 4, 3, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 6, dark)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 8, gold)
		_draw_rect_px(img, ox, oy, s, 6, 11, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 7, 12, 2, 2, red)
	elif kind == "crest_mage":
		_draw_rect_px(img, ox, oy, s, 4, 3, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 6, dark)
		_draw_ring_px(img, ox, oy, s, 8, 7, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 4, 1, 6, blue)
		_draw_rect_px(img, ox, oy, s, 7, 12, 2, 2, purple)
	elif kind == "purple_mag":
		_draw_rect_px(img, ox, oy, s, 4, 4, 6, 9, purple)
		_draw_rect_px(img, ox, oy, s, 4, 3, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 13, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 9, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 6, 2, 2, 1, purple.lightened(0.2))
	elif kind == "purple_blade":
		_draw_rect_px(img, ox, oy, s, 7, 2, 2, 8, purple)
		_draw_rect_px(img, ox, oy, s, 6, 1, 4, 1, purple)
		_draw_rect_px(img, ox, oy, s, 5, 10, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
		_draw_rect_px(img, ox, oy, s, 8, 4, 1, 1, purple.lightened(0.25))
	elif kind == "purple_seal":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, purple)
		_draw_ring_px(img, ox, oy, s, 8, 8, 4, blue)
		_draw_rect_px(img, ox, oy, s, 6, 8, 4, 1, blue)
		_draw_rect_px(img, ox, oy, s, 8, 6, 1, 4, blue)
	elif kind == "metronome":
		_draw_rect_px(img, ox, oy, s, 6, 3, 4, 9, wood)
		_draw_rect_px(img, ox, oy, s, 5, 2, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 6, metal)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 9, 6, 1, 1, gold)
	elif kind == "hourglass":
		_draw_rect_px(img, ox, oy, s, 5, 3, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 6, 4, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 6, 2, 4, dark)
	elif kind == "hourglass_mage":
		_draw_rect_px(img, ox, oy, s, 5, 3, 6, 1, blue)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, blue)
		_draw_rect_px(img, ox, oy, s, 6, 4, 4, 2, blue)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 2, blue)
		_draw_rect_px(img, ox, oy, s, 7, 6, 2, 4, purple)
	elif kind == "seal":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, paper)
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 11, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 8, ink)
		_draw_rect_px(img, ox, oy, s, 11, 4, 1, 8, ink)
		_draw_ring_px(img, ox, oy, s, 8, 8, 3, red)
	elif kind == "bag_core":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 5, 6, 6, dark)
		_draw_rect_px(img, ox, oy, s, 6, 6, 4, 4, blue)
		_draw_rect_px(img, ox, oy, s, 7, 7, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 3, 4, 1, gold)
	elif kind == "roar":
		_draw_ring_px(img, ox, oy, s, 8, 8, 6, gold)
		_draw_ring_px(img, ox, oy, s, 8, 8, 4, dark)
		_draw_ring_px(img, ox, oy, s, 8, 8, 3, gold)
		_draw_rect_px(img, ox, oy, s, 6, 5, 1, 1, red)
		_draw_rect_px(img, ox, oy, s, 9, 5, 1, 1, red)
		_draw_rect_px(img, ox, oy, s, 7, 7, 2, 1, red)
		_draw_rect_px(img, ox, oy, s, 5, 10, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 4, 11, 8, 1, dark)
	elif kind == "blade":
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 5, 4, 5, metal)
		_draw_rect_px(img, ox, oy, s, 7, 10, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 14, 4, 1, dark)
	elif kind == "mag":
		_draw_rect_px(img, ox, oy, s, 4, 4, 6, 9, metal)
		_draw_rect_px(img, ox, oy, s, 4, 3, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 13, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 9, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 5, 2, 1, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 2, 1, 1, gold)
		_draw_rect_px(img, ox, oy, s, 9, 2, 1, 1, gold)
	elif kind == "scope":
		_draw_ring_px(img, ox, oy, s, 8, 8, 5, blue)
		_draw_rect_px(img, ox, oy, s, 8, 3, 1, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 10, 1, 3, blue)
		_draw_rect_px(img, ox, oy, s, 3, 8, 3, 1, blue)
		_draw_rect_px(img, ox, oy, s, 10, 8, 3, 1, blue)
	elif kind == "bolt":
		_draw_rect_px(img, ox, oy, s, 9, 2, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 8, 6, 2, 3, gold)
		_draw_rect_px(img, ox, oy, s, 6, 9, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 2, gold)
	elif kind == "orb":
		_draw_ring_px(img, ox, oy, s, 8, 8, 5, purple)
		_draw_ring_px(img, ox, oy, s, 8, 8, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 8, 1, 1, blue)
	elif kind == "spear":
		_draw_rect_px(img, ox, oy, s, 7, 1, 2, 10, metal)
		_draw_rect_px(img, ox, oy, s, 6, 0, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
	elif kind == "gun":
		_draw_rect_px(img, ox, oy, s, 3, 7, 8, 3, metal)
		_draw_rect_px(img, ox, oy, s, 1, 8, 2, 3, wood)
		_draw_rect_px(img, ox, oy, s, 10, 6, 5, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 10, 2, 3, wood)
		_draw_rect_px(img, ox, oy, s, 8, 9, 2, 4, dark)
		_draw_rect_px(img, ox, oy, s, 3, 6, 3, 1, dark)
	elif kind == "sword":
		_draw_rect_px(img, ox, oy, s, 7, 2, 2, 8, metal)
		_draw_rect_px(img, ox, oy, s, 6, 1, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 5, 10, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
	elif kind == "staff":
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 9, wood)
		_draw_ring_px(img, ox, oy, s, 8, 3, 2, blue)
		_draw_rect_px(img, ox, oy, s, 6, 12, 4, 2, dark)
	elif kind == "note":
		_draw_rect_px(img, ox, oy, s, 3, 2, 10, 12, paper)
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 6, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 8, 6, 1, ink)
		_draw_rect_px(img, ox, oy, s, 3, 2, 10, 1, dark)
		_draw_rect_px(img, ox, oy, s, 3, 13, 10, 1, dark)
		_draw_rect_px(img, ox, oy, s, 3, 2, 1, 12, dark)
		_draw_rect_px(img, ox, oy, s, 12, 2, 1, 12, dark)
	if badge != "":
		var bx: int = 10
		var by: int = 1
		var bcol := rarity_col.lightened(0.2)
		if badge == "range":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 5, bcol)
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 5, 1, bcol)
			_draw_ring_px(img, ox, oy, s, bx + 2, by + 2, 2, bcol)
		elif badge == "speed":
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 4, 1, bcol)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 1, 2, 1, bcol)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 3, 2, 1, bcol)
		elif badge == "damage":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 5, red)
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 5, 1, red)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 1, 1, 1, red)
			_draw_rect_px(img, ox, oy, s, bx + 3, by + 3, 1, 1, red)
		elif badge == "radius":
			_draw_ring_px(img, ox, oy, s, bx + 2, by + 2, 2, purple)
		elif badge == "bolt":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 1, gold)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 1, 2, 1, gold)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 2, 1, 2, gold)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 4, 2, 1, gold)
		elif badge == "red":
			_draw_diamond_px(img, ox, oy, s, bx + 2, by + 2, 2, red)

func _icon_kind(key: String) -> String:
	if key.find("note") >= 0:
		return "note"
	if key.find("sword_red") >= 0:
		return "crest_warrior"
	if key.find("magic_red") >= 0:
		return "crest_mage"
	if key.find("roar") >= 0 or key.find("龙吼") >= 0 or key.find("咆哮") >= 0:
		return "roar"
	if key.find("战士之徽") >= 0:
		return "crest_warrior"
	if key.find("法师之徽") >= 0:
		return "crest_mage"
	if key.find("扩容") >= 0 or key.find("背包") >= 0 or key.find("核心") >= 0:
		return "bag_core"
	if key.find("紫封") >= 0:
		if key.find("弹匣") >= 0:
			return "purple_mag"
		if key.find("刃纹") >= 0:
			return "purple_blade"
		if key.find("法印") >= 0:
			return "purple_seal"
	if key.find("节奏刻") >= 0 or key.find("冷却刻") >= 0:
		if key.find("奥术") >= 0 or key.find("法") >= 0:
			return "hourglass_mage"
		if key.find("刃") >= 0:
			return "hourglass"
		return "metronome"
	if key.find("拓展") >= 0 or key.find("扩环") >= 0 or key.find("弹道") >= 0 or key.find("刃域") >= 0 or key.find("法域") >= 0:
		if key.find("法") >= 0:
			return "orb"
		if key.find("刃") >= 0:
			return "spear"
		return "scope"
	if key.find("增幅") >= 0:
		if key.find("刃") >= 0:
			return "blade"
		if key.find("法") >= 0:
			return "seal"
		return "mag"
	if key.find("弹匣") >= 0:
		return "mag"
	if key.find("刃纹") >= 0:
		return "blade"
	if key.find("法印") >= 0:
		return "seal"
	return "mag"

func _icon_badge(key: String) -> String:
	if key.find("range") >= 0:
		return "range"
	if key.find("speed") >= 0 or key.find("interval") >= 0:
		return "speed"
	if key.find("dmg") >= 0 or key.find("damage") >= 0:
		return "damage"
	if key.find("radius") >= 0:
		return "radius"
	if key.find("red") >= 0:
		return "red"
	if key == "bolt":
		return "bolt"
	return ""


func _draw_rect_px(img: Image, ox: int, oy: int, s: int, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			_plot_px(img, ox + (x + xx) * s, oy + (y + yy) * s, s, col)

func _draw_ring_px(img: Image, ox: int, oy: int, s: int, cx: int, cy: int, r: int, col: Color):
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			var d := dx * dx + dy * dy
			if d <= r * r and d >= (r - 1) * (r - 1):
				_plot_px(img, ox + x * s, oy + y * s, s, col)

func _draw_diamond_px(img: Image, ox: int, oy: int, s: int, cx: int, cy: int, r: int, col: Color):
	for y in range(-r, r + 1):
		var row: int = r - abs(y)
		for x in range(-row, row + 1):
			_plot_px(img, ox + (cx + x) * s, oy + (cy + y) * s, s, col)

func _plot_px(img: Image, x: int, y: int, s: int, col: Color):
	for yy in range(s):
		for xx in range(s):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)

func _codex_cmp(a: Dictionary, b: Dictionary) -> bool:
	var order_rarity := {"red": 0, "epic": 1, "blue": 2, "white": 3}
	var order_target := {"bullet": 0, "melee": 1, "magic": 2}
	var order_type := {"damage": 0, "interval": 1, "range": 2, "radius": 3}
	var ar: String = RarityScript.normalize(String(a["rarity"]))
	var br: String = RarityScript.normalize(String(b["rarity"]))
	var at: String = String(a["target"])
	var bt: String = String(b["target"])
	var ap: String = String(a["type"])
	var bp: String = String(b["type"])
	var rcmp := int(order_rarity.get(ar, 9)) - int(order_rarity.get(br, 9))
	if rcmp != 0:
		return rcmp < 0
	var tcmp := int(order_target.get(at, 9)) - int(order_target.get(bt, 9))
	if tcmp != 0:
		return tcmp < 0
	var pcmp := int(order_type.get(ap, 9)) - int(order_type.get(bp, 9))
	if pcmp != 0:
		return pcmp < 0
	return String(a["id"]) < String(b["id"])
