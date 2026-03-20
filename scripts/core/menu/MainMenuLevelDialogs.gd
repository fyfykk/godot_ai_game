extends RefCounted

var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")
var UIFontScript := preload("res://scripts/ui/UIFont.gd")

var owner
var meta_store
var level_seeds: Array = []

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

func setup(owner_node, meta_store_ref, level_seeds_ref: Array):
	owner = owner_node
	meta_store = meta_store_ref
	level_seeds = level_seeds_ref

func build():
	_build_level_dialog()
	_build_editor_dialog()
	_build_editor_level_dialog()

func cleanup():
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

func show_level_dialog():
	if level_overlay:
		level_overlay.visible = true
	if level_panel:
		level_panel.visible = true

func hide_level_dialog():
	if level_overlay:
		level_overlay.visible = false
	if level_panel:
		level_panel.visible = false

func show_editor_dialog():
	if editor_overlay:
		editor_overlay.visible = true
	if editor_panel:
		editor_panel.visible = true

func hide_editor_dialog():
	if editor_overlay:
		editor_overlay.visible = false
	if editor_panel:
		editor_panel.visible = false

func show_editor_level_dialog():
	if editor_level_overlay:
		editor_level_overlay.visible = true
	if editor_level_panel:
		editor_level_panel.visible = true

func hide_editor_level_dialog():
	if editor_level_overlay:
		editor_level_overlay.visible = false
	if editor_level_panel:
		editor_level_panel.visible = false

func refresh_level_buttons():
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

func refresh_editor_level_buttons():
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

func _build_level_dialog():
	var root: Node = owner.get_tree().get_root()
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
	close_btn.pressed.connect(hide_level_dialog)
	vb.add_child(close_btn)
	level_close_button = close_btn
	refresh_level_buttons()
	UIFontScript.apply_tree(level_overlay)
	UIFontScript.apply_tree(level_panel)

func _build_editor_dialog():
	var root: Node = owner.get_tree().get_root()
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
	close_btn.pressed.connect(hide_editor_dialog)
	vb.add_child(close_btn)
	UIFontScript.apply_tree(editor_overlay)
	UIFontScript.apply_tree(editor_panel)

func _build_editor_level_dialog():
	var root: Node = owner.get_tree().get_root()
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
	close_btn.pressed.connect(hide_editor_level_dialog)
	vb.add_child(close_btn)
	editor_level_close_button = close_btn
	UIFontScript.apply_tree(editor_level_overlay)
	UIFontScript.apply_tree(editor_level_panel)

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

func _on_level_pressed(level_num: int):
	var seed: int = 0
	var base_count: int = level_seeds.size()
	if level_num > 0 and level_num <= base_count:
		seed = int(level_seeds[level_num - 1])
	owner.get_tree().set_meta("run_mode", "game")
	owner.get_tree().set_meta("level_seed", seed)
	owner.get_tree().set_meta("level_index", level_num)
	if level_num > base_count:
		owner.get_tree().set_meta("use_custom_map_index", level_num - base_count - 1)
	owner.get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

func _on_editor_existing_pressed():
	hide_editor_dialog()
	refresh_editor_level_buttons()
	show_editor_level_dialog()

func _on_editor_new_pressed():
	owner.get_tree().set_meta("run_mode", "editor")
	owner.get_tree().set_meta("editor_new", true)
	owner.get_tree().set_meta("editor_custom_index", -1)
	hide_editor_dialog()
	owner.get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

func _on_editor_level_pressed(level_num: int):
	var seed: int = 0
	var base_count: int = level_seeds.size()
	if level_num > 0 and level_num <= base_count:
		seed = int(level_seeds[level_num - 1])
	owner.get_tree().set_meta("run_mode", "editor")
	owner.get_tree().set_meta("editor_new", false)
	owner.get_tree().set_meta("level_seed", seed)
	owner.get_tree().set_meta("level_index", level_num)
	if level_num > base_count:
		owner.get_tree().set_meta("editor_custom_index", level_num - base_count - 1)
	else:
		owner.get_tree().set_meta("editor_custom_index", -1)
	hide_editor_level_dialog()
	owner.get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

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
	refresh_editor_level_buttons()

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
