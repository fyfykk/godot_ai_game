extends Node2D

@onready var generator = $Generator
@onready var platforms = $Platforms
@onready var ladders = $Ladders
@onready var exit_node = $Exit
@onready var spawner = $EnemySpawner
@export var top_margin: float = 80.0

var spawn_position: Vector2
var exit_position: Vector2
var top_layer_locked: bool = true
var level_seed: int = 0
var editor_enabled: bool = false
var editor_tool: String = "hand"
var editor_grid: float = 8.0
var editor_platform_size: Vector2 = Vector2(160.0, 16.0)
var editor_ladder_height: float = 80.0
var editor_cursor: Polygon2D = null
var editor_ui: CanvasLayer = null
var editor_label: Label = null
var editor_exit_button: Button = null
var editor_exit_dialog: ConfirmationDialog = null
var editor_spawn_marker: Polygon2D = null
var editor_selected_type: String = "none"
var editor_selected_node: Node2D = null
var editor_layer_index: int = 0
var editor_ladder_locked: bool = false
var editor_button_panel: VBoxContainer = null
var editor_custom_index: int = -1
var editor_holding: bool = false
var editor_holding_new: bool = false
var editor_holding_type: String = "none"
var editor_holding_node: Node2D = null
var editor_holding_original_pos: Vector2 = Vector2.ZERO
var editor_holding_original_spawn: Vector2 = Vector2.ZERO
var editor_holding_original_exit: Vector2 = Vector2.ZERO
var editor_holding_original_exit_visible: bool = false
var editor_holding_original_wall: Node2D = null
var editor_holding_original_wall_parent: Node = null
var editor_holding_original_wall_pos: Vector2 = Vector2.ZERO
var editor_holding_original_wall_sprite_pos: Vector2 = Vector2.ZERO
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")

func _get_const_float(key: String, default_val: float) -> float:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_float"):
		return float(root.call("get_const_float", key, default_val))
	return default_val

func _ready():
	top_margin = _get_const_float("level.top_margin", top_margin)
	editor_grid = _get_const_float("level.editor_grid", editor_grid)
	var editor_w: float = _get_const_float("level.editor_platform_width_min", editor_platform_size.x)
	var editor_h: float = _get_const_float("level.editor_platform_height", editor_platform_size.y)
	editor_platform_size = Vector2(editor_w, editor_h)
	editor_ladder_height = _get_const_float("level.editor_ladder_height", editor_ladder_height)
	if generator and generator.has_method("get"):
		if generator.get("layer_height") != null:
			editor_ladder_height = float(generator.layer_height)
		if generator.get("width") != null:
			var w: float = max(float(generator.width) - 160.0, 160.0)
			editor_platform_size = Vector2(w, editor_platform_size.y)
		if generator.get("layers") != null:
			editor_layer_index = clamp(editor_layer_index, 0, int(generator.layers) - 1)
	_init_editor_overlay()

func _process(_delta):
	if not editor_enabled:
		if editor_cursor:
			editor_cursor.visible = false
		if editor_ui:
			editor_ui.visible = false
		if editor_spawn_marker:
			editor_spawn_marker.visible = false
		return
	if editor_ui:
		editor_ui.visible = true
	_update_editor_cursor()
	_update_editor_label()
	_editor_update_holding()
	if editor_spawn_marker:
		var show_spawn: bool = spawn_position.x > -9000.0 and spawn_position.y > -9000.0
		editor_spawn_marker.visible = show_spawn
		if show_spawn:
			editor_spawn_marker.position = spawn_position

func _unhandled_input(event):
	if not editor_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			_editor_toggle_ladder_lock()
		if event.keycode == KEY_0:
			_editor_cancel_hold()
			editor_tool = "hand"
		elif event.keycode == KEY_1:
			_editor_start_new_hold("platform")
		elif event.keycode == KEY_2:
			_editor_start_new_hold("ladder")
		elif event.keycode == KEY_3:
			_editor_start_new_hold("door")
		elif event.keycode == KEY_4:
			_editor_start_new_hold("spawn")
		elif event.keycode == KEY_5:
			_editor_start_new_hold("exit")
		elif event.keycode == KEY_6:
			_editor_start_new_hold("chest")
		elif event.keycode == KEY_7:
			_editor_start_new_hold("special_door")
		elif event.keycode == KEY_F5:
			_editor_save()
		elif event.keycode == KEY_F9:
			_editor_load()
		elif event.keycode == KEY_ESCAPE:
			_editor_cancel_hold()
			get_tree().paused = false
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			_editor_delete_selected()
	if editor_enabled and event is InputEventMouseButton and event.pressed:
		if editor_holding:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_editor_commit_hold()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_editor_cancel_hold()
		elif editor_tool == "hand":
			if event.button_index == MOUSE_BUTTON_LEFT:
				_editor_pick_hold_at(get_global_mouse_position())

func generate():
	if generator and generator.has_method("get") and generator.get("level_seed") != null:
		generator.level_seed = level_seed
	var res = generator.generate()
	spawn_position = res["spawn_position"] + Vector2(0.0, top_margin)
	exit_position = res["exit_position"] + Vector2(0.0, top_margin)
	exit_node.global_position = exit_position
	_add_exit_marker()
	_clear_platforms()
	_clear_ladders()
	for rect in res["platforms"]:
		_add_platform(rect)
	spawner.global_position = spawn_position + Vector2(200.0, -16.0)
	top_layer_locked = true
	_add_border_walls()
	_generate_ladders()
	_partition_rooms_and_place_chests()
	if spawner:
		spawner.global_position = spawn_position + Vector2(200.0, -16.0)

func set_level_seed(v: int):
	level_seed = v

func set_editor_enabled(v: bool):
	editor_enabled = v

func set_editor_custom_index(v: int):
	editor_custom_index = v

func editor_load_if_exists():
	if editor_custom_index >= 0:
		load_custom_map(editor_custom_index)

func editor_new_blank():
	_clear_platforms()
	_clear_ladders()
	_clear_doors()
	_clear_chests()
	spawn_position = Vector2(-9999, -9999)
	exit_position = Vector2(-9999, -9999)
	exit_node.global_position = exit_position
	exit_node.visible = false
	_add_exit_marker()
	if spawner:
		spawner.global_position = spawn_position + Vector2(200.0, -16.0)
	editor_layer_index = 0

func load_custom_map(index: int) -> bool:
	var maps := _load_custom_maps()
	if index < 0 or index >= maps.size():
		return false
	var data = maps[index]
	if data is Dictionary:
		print("CustomMap:load index=%d" % index)
		var chs = data.get("chests")
		var chs_cnt: int = chs.size() if chs is Array else 0
		print("CustomMap:data chests=%d" % chs_cnt)
		_editor_apply_data(data)
		return true
	return false

func get_spawn_position() -> Vector2:
	return spawn_position

func get_run_reward() -> int:
	return 10

func is_exit_reached(p) -> bool:
	if p == null:
		return false
	return p.global_position.distance_to(exit_node.global_position) <= 20.0

func _clear_platforms():
	for c in platforms.get_children():
		c.queue_free()

func _add_platform(rect):
	var body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	var w: float = float(rect["w"])
	var h: float = float(rect["h"])
	shape.size = Vector2(w, h)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	body.collision_layer = 4
	var poly := Polygon2D.new()
	poly.color = Color(0.6, 0.6, 0.6, 1.0)
	poly.z_index = 1
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)
	])
	poly.visible = false
	body.add_child(poly)
	var ground_sprite := Sprite2D.new()
	ground_sprite.texture = _build_ground_texture(int(round(w)), int(round(h)))
	ground_sprite.centered = true
	ground_sprite.z_index = 1
	ground_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(ground_sprite)
	var wall_w: float = 8.0
	var wall_h: float = 48.0
	var left_shape := RectangleShape2D.new()
	left_shape.size = Vector2(wall_w, wall_h)
	var left_cs := CollisionShape2D.new()
	left_cs.shape = left_shape
	left_cs.position = Vector2(-hw, -hh - wall_h * 0.5)
	body.add_child(left_cs)
	var right_shape := RectangleShape2D.new()
	right_shape.size = Vector2(wall_w, wall_h)
	var right_cs := CollisionShape2D.new()
	right_cs.shape = right_shape
	right_cs.position = Vector2(hw, -hh - wall_h * 0.5)
	body.add_child(right_cs)
	platforms.add_child(body)
	var x: float = float(rect["x"])
	var y: float = float(rect["y"])
	body.global_position = Vector2(x + w * 0.5, y + top_margin)

func _clear_ladders():
	for c in ladders.get_children():
		c.queue_free()

func _generate_ladders():
	var LadderScript := preload("res://scripts/world/Ladder.gd")
	var lay: int = int(generator.layers)
	var w: float = float(generator.width)
	var lh: float = float(generator.layer_height)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(1, lay):
		var ladder := LadderScript.new()
		ladder.width = 12.0
		var y_bottom: float = float(i) * lh
		var y_top: float = float(i - 1) * lh
		ladder.height = abs(y_bottom - y_top)
		if i == 1:
			ladder.locked = true
			ladder.leads_to_top = true
		ladders.add_child(ladder)
		var min_x: float = w * 0.2
		var max_x: float = w * 0.8
		var x: float = rng.randf_range(min_x, max_x)
		var platform_half_h: float = 8.0
		var center_y: float = (y_bottom + y_top) * 0.5 - platform_half_h + top_margin
		ladder.global_position = Vector2(x, center_y)

func _add_border_walls():
	var borders: Node2D = null
	if has_node("Borders"):
		borders = get_node("Borders") as Node2D
		for c in borders.get_children():
			c.queue_free()
	else:
		borders = Node2D.new()
		borders.name = "Borders"
		add_child(borders)
	var w: float = float(generator.width)
	var lh: float = float(generator.layer_height)
	var lay: int = int(generator.layers)
	# 扫描所有平台，确定上下边界（平台顶面）
	var min_top: float = INF
	var max_top: float = -INF
	for p in platforms.get_children():
		if p and p is Node2D:
			var pw: float = _get_platform_width(p as Node2D)
			var ph: float = _get_platform_height(p as Node2D)
			if pw > 0.0 and ph > 0.0:
				var top_y: float = (p as Node2D).global_position.y - ph * 0.5
				min_top = min(min_top, top_y)
				max_top = max(max_top, top_y)
	if min_top == INF or max_top == -INF:
		return
	var y_top_top: float = min_top - lh
	var y_bottom_top: float = max_top
	var center_y: float = (y_bottom_top + y_top_top) * 0.5
	var total_h: float = abs(y_top_top - y_bottom_top)
	var left_x: float = 80.0
	var right_x: float = w - 80.0
	var wall_w: float = 12.0
	var half_w: float = wall_w * 0.5
	var half_h: float = total_h * 0.5
	var color := Color(0.35, 0.35, 0.5, 1.0)
	var left := Polygon2D.new()
	left.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h)
	])
	left.color = color
	left.z_index = 0
	left.global_position = Vector2(left_x, center_y)
	left.add_to_group("wall")
	left.visible = false
	borders.add_child(left)
	var left_sprite := Sprite2D.new()
	left_sprite.texture = _build_wall_texture(int(round(wall_w)), int(round(total_h)), true)
	left_sprite.centered = true
	left_sprite.z_index = 0
	left_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	left_sprite.global_position = Vector2(left_x, center_y)
	borders.add_child(left_sprite)
	var right := Polygon2D.new()
	right.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h)
	])
	right.color = color
	right.z_index = 0
	right.global_position = Vector2(right_x, center_y)
	right.add_to_group("wall")
	right.visible = false
	borders.add_child(right)
	var right_sprite := Sprite2D.new()
	right_sprite.texture = _build_wall_texture(int(round(wall_w)), int(round(total_h)), true)
	right_sprite.centered = true
	right_sprite.z_index = 0
	right_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right_sprite.global_position = Vector2(right_x, center_y)
	borders.add_child(right_sprite)

func _add_exit_marker():
	var old_marker := exit_node.get_node_or_null("ExitMarker")
	if old_marker:
		old_marker.queue_free()
	var exit_sprite := Sprite2D.new()
	exit_sprite.name = "ExitMarker"
	exit_sprite.texture = _build_exit_texture(24, 32)
	exit_sprite.centered = false
	exit_sprite.position = Vector2(-12, -32)
	exit_sprite.z_index = 5
	exit_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_node.add_child(exit_sprite)

func _init_editor_overlay():
	editor_cursor = Polygon2D.new()
	editor_cursor.z_index = 20
	editor_cursor.visible = false
	add_child(editor_cursor)
	editor_ui = CanvasLayer.new()
	add_child(editor_ui)
	editor_label = Label.new()
	editor_label.position = Vector2(8, 8)
	editor_label.add_theme_font_size_override("font_size", 12)
	editor_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	editor_label.add_theme_constant_override("font_outline_size", 2)
	editor_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
	editor_ui.add_child(editor_label)
	editor_exit_button = Button.new()
	editor_exit_button.text = "退出编辑"
	editor_exit_button.custom_minimum_size = Vector2(110, 32)
	editor_exit_button.anchor_left = 1.0
	editor_exit_button.anchor_top = 0.0
	editor_exit_button.anchor_right = 1.0
	editor_exit_button.anchor_bottom = 0.0
	editor_exit_button.position = Vector2(-120, 8)
	editor_exit_button.pressed.connect(_on_editor_exit_pressed)
	editor_ui.add_child(editor_exit_button)
	editor_button_panel = VBoxContainer.new()
	editor_button_panel.anchor_left = 1.0
	editor_button_panel.anchor_right = 1.0
	editor_button_panel.anchor_top = 0.0
	editor_button_panel.anchor_bottom = 0.0
	editor_button_panel.position = Vector2(-130, 48)
	editor_button_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	editor_button_panel.add_theme_constant_override("separation", 6)
	editor_ui.add_child(editor_button_panel)
	var btn_hand := Button.new()
	btn_hand.text = "空手(0)"
	btn_hand.custom_minimum_size = Vector2(110, 28)
	btn_hand.pressed.connect(_editor_on_tool_button.bind("hand"))
	editor_button_panel.add_child(btn_hand)
	var btn_platform := Button.new()
	btn_platform.text = "平台(1)"
	btn_platform.custom_minimum_size = Vector2(110, 28)
	btn_platform.pressed.connect(_editor_on_tool_button.bind("platform"))
	editor_button_panel.add_child(btn_platform)
	var btn_ladder := Button.new()
	btn_ladder.text = "梯子(2)"
	btn_ladder.custom_minimum_size = Vector2(110, 28)
	btn_ladder.pressed.connect(_editor_on_tool_button.bind("ladder"))
	editor_button_panel.add_child(btn_ladder)
	var btn_door := Button.new()
	btn_door.text = "门(3)"
	btn_door.custom_minimum_size = Vector2(110, 28)
	btn_door.pressed.connect(_editor_on_tool_button.bind("door"))
	editor_button_panel.add_child(btn_door)
	var btn_spawn := Button.new()
	btn_spawn.text = "出生(4)"
	btn_spawn.custom_minimum_size = Vector2(110, 28)
	btn_spawn.pressed.connect(_editor_on_tool_button.bind("spawn"))
	editor_button_panel.add_child(btn_spawn)
	var btn_exit := Button.new()
	btn_exit.text = "出口(5)"
	btn_exit.custom_minimum_size = Vector2(110, 28)
	btn_exit.pressed.connect(_editor_on_tool_button.bind("exit"))
	editor_button_panel.add_child(btn_exit)
	var btn_special := Button.new()
	btn_special.text = "特殊门(7)"
	btn_special.custom_minimum_size = Vector2(110, 28)
	btn_special.pressed.connect(_editor_on_tool_button.bind("special_door"))
	editor_button_panel.add_child(btn_special)
	var btn_chest := Button.new()
	btn_chest.text = "普通宝箱(6)"
	btn_chest.custom_minimum_size = Vector2(110, 28)
	btn_chest.pressed.connect(_editor_on_tool_button.bind("chest"))
	editor_button_panel.add_child(btn_chest)
	var btn_chest_once := Button.new()
	btn_chest_once.text = "一次宝箱(8)"
	btn_chest_once.custom_minimum_size = Vector2(110, 28)
	btn_chest_once.pressed.connect(_editor_on_tool_button.bind("chest_once"))
	editor_button_panel.add_child(btn_chest_once)
	var btn_lock := Button.new()
	btn_lock.text = "梯子锁定(L)"
	btn_lock.custom_minimum_size = Vector2(110, 28)
	btn_lock.pressed.connect(_editor_on_lock_button)
	editor_button_panel.add_child(btn_lock)
	var btn_save := Button.new()
	btn_save.text = "保存(F5)"
	btn_save.custom_minimum_size = Vector2(110, 28)
	btn_save.pressed.connect(_editor_on_save_button)
	editor_button_panel.add_child(btn_save)
	var btn_load := Button.new()
	btn_load.text = "加载(F9)"
	btn_load.custom_minimum_size = Vector2(110, 28)
	btn_load.pressed.connect(_editor_on_load_button)
	editor_button_panel.add_child(btn_load)
	var btn_delete := Button.new()
	btn_delete.text = "删除(Del)"
	btn_delete.custom_minimum_size = Vector2(110, 28)
	btn_delete.pressed.connect(_editor_on_delete_button)
	editor_button_panel.add_child(btn_delete)
	var btn_cancel := Button.new()
	btn_cancel.text = "取消(右键/ESC)"
	btn_cancel.custom_minimum_size = Vector2(110, 28)
	btn_cancel.pressed.connect(_editor_on_cancel_button)
	editor_button_panel.add_child(btn_cancel)
	editor_exit_dialog = ConfirmationDialog.new()
	editor_exit_dialog.title = "退出编辑"
	editor_exit_dialog.dialog_text = "要保存当前关卡吗？"
	editor_exit_dialog.ok_button_text = "保存并退出"
	editor_exit_dialog.cancel_button_text = "不保存"
	editor_exit_dialog.confirmed.connect(_on_editor_exit_save)
	editor_exit_dialog.canceled.connect(_on_editor_exit_discard)
	editor_ui.add_child(editor_exit_dialog)
	editor_spawn_marker = Polygon2D.new()
	editor_spawn_marker.z_index = 18
	editor_spawn_marker.color = Color(0.3, 0.9, 0.45, 0.7)
	editor_spawn_marker.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6),
		Vector2(6, 6), Vector2(-6, 6)
	])
	editor_spawn_marker.visible = false
	add_child(editor_spawn_marker)

func _update_editor_label():
	if editor_label == null:
		return
	var sel := "无"
	if editor_selected_type != "none":
		sel = editor_selected_type
	var lock_txt := "锁" if editor_ladder_locked else "开"
	editor_label.text = "编辑模式 | 选中:%s | 梯子锁定:%s" % [sel, lock_txt]

func _editor_on_tool_button(t: String):
	if t == "hand":
		_editor_cancel_hold()
		editor_tool = "hand"
		return
	_editor_start_new_hold(t)

func _editor_on_lock_button():
	_editor_toggle_ladder_lock()

func _editor_on_save_button():
	_editor_save()

func _editor_on_load_button():
	_editor_load()

func _editor_on_delete_button():
	_editor_delete_selected()

func _editor_on_cancel_button():
	_editor_cancel_hold()

func _update_editor_cursor():
	if editor_cursor == null:
		return
	editor_cursor.visible = true
	var w: float = 12.0
	var h: float = 12.0
	var col: Color = Color(0.6, 0.6, 0.6, 0.7)
	var tool := editor_holding_type if editor_holding else editor_tool
	if tool == "hand":
		w = 10.0
		h = 10.0
		col = Color(0.4, 0.8, 1.0, 0.6)
	elif tool == "platform":
		w = editor_platform_size.x
		h = editor_platform_size.y
		col = Color(0.55, 0.55, 0.6, 0.6)
	elif tool == "ladder":
		w = 12.0
		h = editor_ladder_height
		col = Color(0.85, 0.8, 0.3, 0.6)
	elif tool == "door":
		w = 10.0
		h = 36.0
		col = Color(0.65, 0.45, 0.25, 0.6)
	elif tool == "special_door":
		w = 10.0
		h = 36.0
		col = Color(0.85, 0.25, 0.25, 0.6)
	elif tool == "spawn":
		w = 12.0
		h = 12.0
		col = Color(0.3, 0.9, 0.45, 0.7)
	elif tool == "exit":
		w = 12.0
		h = 12.0
		col = Color(0.3, 0.9, 0.85, 0.7)
	elif tool == "chest":
		w = 16.0
		h = 12.0
		col = Color(0.85, 0.6, 0.2, 0.7)
	elif tool == "chest_once":
		w = 16.0
		h = 12.0
		col = Color(0.9, 0.85, 0.2, 0.7)
	var pos := get_global_mouse_position()
	editor_cursor.position = pos
	editor_cursor.color = col
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	editor_cursor.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)
	])

func _editor_start_new_hold(t: String):
	_editor_cancel_hold()
	editor_tool = t
	editor_selected_type = t
	if t == "platform":
		var layer_idx := _editor_get_platform_target_layer(get_global_mouse_position().y)
		var node := _editor_create_platform_at_layer(layer_idx)
		if node:
			_editor_begin_hold(t, node, true)
	elif t == "ladder":
		var LadderScript := preload("res://scripts/world/Ladder.gd")
		var ladder := LadderScript.new()
		ladder.width = 12.0
		ladder.height = _editor_get_layer_height()
		ladder.locked = editor_ladder_locked
		ladders.add_child(ladder)
		_editor_begin_hold(t, ladder, true)
	elif t == "door":
		var DoorScript := preload("res://scripts/world/Door.gd")
		var door = DoorScript.new()
		add_child(door)
		var pos := _editor_get_snapped_mouse()
		var lh := _editor_get_layer_height()
		var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
		var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
		if plat != null:
			_editor_apply_door_wall(door, plat, lh)
		_editor_begin_hold(t, door, true)
	elif t == "special_door":
		var SpecialDoorScript := preload("res://scripts/world/SpecialDoor.gd")
		var sdoor = SpecialDoorScript.new()
		add_child(sdoor)
		var pos2 := _editor_get_snapped_mouse()
		var lh2 := _editor_get_layer_height()
		var layer_idx2: int = _editor_get_layer_index_from_y(pos2.y, lh2)
		var plat2 := _editor_get_platform_at(layer_idx2, pos2.x, lh2)
		if plat2 != null:
			_editor_apply_door_wall(sdoor, plat2, lh2)
		_editor_begin_hold(t, sdoor, true)
	elif t == "spawn":
		_editor_begin_hold(t, null, true)
	elif t == "exit":
		_editor_begin_hold(t, null, true)
	elif t == "chest":
		var ChestScript := preload("res://scripts/items/Chest.gd")
		var chest := ChestScript.new()
		add_child(chest)
		_editor_begin_hold(t, chest, true)
	elif t == "chest_once":
		var ChestOnceScript := preload("res://scripts/items/ChestOnce.gd")
		var chest2 := ChestOnceScript.new()
		add_child(chest2)
		_editor_begin_hold(t, chest2, true)

func _editor_pick_hold_at(pos: Vector2):
	if editor_holding:
		return
	if _editor_select_at(pos):
		_editor_begin_hold(editor_selected_type, editor_selected_node, false)

func _editor_begin_hold(t: String, node: Node2D, is_new: bool):
	editor_holding = true
	editor_holding_new = is_new
	editor_holding_type = t
	editor_holding_node = node
	editor_selected_type = t
	editor_tool = t
	if node != null:
		editor_holding_original_pos = node.global_position
	if t == "spawn":
		editor_holding_original_spawn = spawn_position
	if t == "exit":
		editor_holding_original_exit = exit_position
		editor_holding_original_exit_visible = exit_node.visible
	if t == "ladder" and node != null:
		if node.has_method("get"):
			var lk = node.get("locked")
			if lk != null:
				editor_ladder_locked = bool(lk)

func _editor_update_holding():
	if not editor_holding:
		return
	var pos := _editor_get_snapped_mouse()
	if editor_holding_type == "platform":
		var lh := _editor_get_layer_height()
		var layer_idx := _editor_get_platform_target_layer(pos.y)
		var center_x := _editor_get_level_center_x()
		var center_y := float(layer_idx) * lh + top_margin
		if editor_holding_node:
			editor_holding_node.global_position = Vector2(center_x, center_y)
	elif editor_holding_type == "ladder":
		if editor_holding_node:
			editor_holding_node.global_position = pos
	elif editor_holding_type == "door" or editor_holding_type == "special_door":
		if editor_holding_node:
			_editor_move_door_with_wall(editor_holding_node, pos)
	elif editor_holding_type == "chest" or editor_holding_type == "chest_once":
		if editor_holding_node:
			editor_holding_node.global_position = pos
	elif editor_holding_type == "spawn":
		spawn_position = pos
	elif editor_holding_type == "exit":
		exit_position = pos
		exit_node.global_position = exit_position
		exit_node.visible = true
		_add_exit_marker()

func _editor_toggle_ladder_lock():
	editor_ladder_locked = not editor_ladder_locked
	if editor_holding and editor_holding_type == "ladder" and editor_holding_node != null:
		if editor_holding_node.has_method("set"):
			if editor_holding_node.get("locked") != null:
				editor_holding_node.set("locked", editor_ladder_locked)

func _editor_commit_hold():
	if not editor_holding:
		return
	if editor_holding_type == "platform":
		_add_border_walls()
	editor_holding = false
	editor_holding_new = false
	editor_holding_type = "none"
	editor_holding_node = null
	editor_selected_type = "none"
	editor_tool = "hand"

func _editor_cancel_hold():
	if not editor_holding:
		_editor_clear_selection()
		editor_holding = false
		editor_holding_new = false
		editor_holding_type = "none"
		editor_holding_node = null
		editor_tool = "hand"
		return
	if editor_holding_new:
		if (editor_holding_type == "door" or editor_holding_type == "special_door") and editor_holding_node:
			editor_holding_node.queue_free()
		elif editor_holding_type == "platform" and editor_holding_node:
			editor_holding_node.queue_free()
			_add_border_walls()
		elif editor_holding_node:
			editor_holding_node.queue_free()
		elif editor_holding_type == "spawn":
			spawn_position = editor_holding_original_spawn
		elif editor_holding_type == "exit":
			exit_position = editor_holding_original_exit
			exit_node.global_position = exit_position
			exit_node.visible = editor_holding_original_exit_visible
			_add_exit_marker()
	else:
		if editor_holding_node:
			editor_holding_node.global_position = editor_holding_original_pos
		if editor_holding_type == "spawn":
			spawn_position = editor_holding_original_spawn
		if editor_holding_type == "exit":
			exit_position = editor_holding_original_exit
			exit_node.global_position = exit_position
			exit_node.visible = editor_holding_original_exit_visible
			_add_exit_marker()
	editor_holding = false
	editor_holding_new = false
	editor_holding_type = "none"
	editor_holding_node = null
	editor_selected_type = "none"
	editor_selected_node = null
	editor_tool = "hand"

func _editor_get_bound_wall(door: Node2D) -> Node2D:
	if door == null:
		return null
	if door.has_meta("bound_wall"):
		var w = door.get_meta("bound_wall")
		if w != null and is_instance_valid(w):
			return w
	return null

func _editor_get_wall_sprite_for(wall: Node2D) -> Sprite2D:
	if wall == null:
		return null
	if wall.has_meta("wall_sprite"):
		var s: Sprite2D = wall.get_meta("wall_sprite") as Sprite2D
		if s:
			return s
	for c in wall.get_children():
		if c is Sprite2D:
			return c as Sprite2D
	var parent := wall.get_parent()
	if parent == null:
		return null
	var best: Sprite2D = null
	var best_d: float = INF
	for c in parent.get_children():
		if c is Sprite2D:
			var d: float = (c as Sprite2D).position.distance_to(wall.position)
			if d < best_d:
				best_d = d
				best = c as Sprite2D
	if best != null:
		wall.set_meta("wall_sprite", best)
	return best

func _editor_get_wall_height(wall: Polygon2D) -> float:
	var min_y: float = 0.0
	for v in wall.polygon:
		if v.y < min_y:
			min_y = v.y
	return abs(min_y)

func _editor_find_existing_wall(plat: Node2D, local_x: float) -> Polygon2D:
	var best: Polygon2D = null
	var best_d: float = INF
	for c in plat.get_children():
		if c is Polygon2D and c.is_in_group("wall") and is_instance_valid(c):
			var d: float = abs((c as Polygon2D).position.x - local_x)
			if d < 8.0 and d < best_d:
				best_d = d
				best = c as Polygon2D
	return best

func _editor_bind_door_wall(door: Node2D, plat: Node2D, gx: float, lh: float, allow_create: bool):
	return

func _editor_move_door_with_wall(door: Node2D, pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
	if plat == null:
		return
	var top_y: float = _editor_get_platform_top_y(plat)
	door.global_position = Vector2(pos.x, top_y)
	_editor_apply_door_wall(door, plat, lh)

func _editor_apply_door_wall(door: Node2D, plat: Node2D, lh: float):
	if door == null or plat == null:
		return
	var ph: float = _get_platform_height(plat)
	if ph <= 0.0:
		return
	var hh: float = ph * 0.5
	var wall_w: float = 6.0
	var wall_h: float = max(lh - 2.0 * hh - 2.0, 2.0)
	if door.has_method("set_wall_dimensions"):
		door.call("set_wall_dimensions", wall_w, wall_h)

func _editor_ensure_door_wall(door: Node2D):
	return

func _ensure_all_door_walls():
	return

func _editor_create_wall_for_door(plat: Node2D, local_x: float, lh: float, hh: float) -> Node2D:
	var wall_w: float = 6.0
	var wall_h: float = max(lh - 2.0 * hh - 2.0, 2.0)
	var poly := Polygon2D.new()
	poly.color = Color(0.5, 0.5, 0.7, 1.0)
	var wall_hw: float = wall_w * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-wall_hw, -wall_h), Vector2(wall_hw, -wall_h),
		Vector2(wall_hw, 0), Vector2(-wall_hw, 0)
	])
	poly.position = Vector2(local_x, -hh)
	poly.add_to_group("wall")
	poly.visible = false
	var wall_sprite := Sprite2D.new()
	wall_sprite.texture = _build_wall_texture(int(round(wall_w)), int(round(wall_h)), false)
	wall_sprite.centered = true
	wall_sprite.position = poly.position + Vector2(0, -wall_h * 0.5)
	wall_sprite.z_index = 0
	wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plat.add_child(poly)
	plat.add_child(wall_sprite)
	poly.set_meta("wall_sprite", wall_sprite)
	return poly

func _editor_create_platform_at_layer(layer_idx: int) -> Node2D:
	var total_w: float = editor_platform_size.x + 160.0
	if generator and generator.has_method("get") and generator.get("width") != null:
		total_w = float(generator.width)
	var w: float = max(total_w - 160.0, editor_platform_size.x)
	var h: float = editor_platform_size.y
	var x: float = (total_w - w) * 0.5
	var center_y: float = float(layer_idx) * _editor_get_layer_height() + top_margin
	var rect := {"x": x, "y": center_y - top_margin, "w": w, "h": h}
	var before := platforms.get_child_count()
	_add_platform(rect)
	if platforms.get_child_count() > before:
		return platforms.get_child(platforms.get_child_count() - 1) as Node2D
	return null

func _editor_get_next_platform_layer() -> int:
	var max_layer := _editor_get_max_platform_layer_excluding(editor_holding_node if editor_holding_type == "platform" else null)
	if max_layer < 0:
		return 0
	return max_layer + 1

func _editor_get_platform_target_layer(pos_y: float) -> int:
	var lh := _editor_get_layer_height()
	var max_layer := _editor_get_max_platform_layer_excluding(editor_holding_node if editor_holding_type == "platform" else null)
	var target: int = clamp(_editor_get_layer_index_from_y_raw(pos_y, lh), 0, _editor_get_layer_count() - 1)
	if _editor_is_platform_layer_empty(target):
		return target
	var best: int = -1
	var best_d: int = 1000000
	for i in range(_editor_get_layer_count()):
		if _editor_is_platform_layer_empty(i):
			var d: int = abs(i - target)
			if d < best_d:
				best_d = d
				best = i
	if best != -1:
		return best
	return max_layer + 1

func _editor_is_platform_layer_empty(layer_idx: int) -> bool:
	var lh := _editor_get_layer_height()
	var center_x := _editor_get_level_center_x()
	var plat := _editor_get_platform_at(layer_idx, center_x, lh)
	if plat == null:
		return true
	if editor_holding_type == "platform" and editor_holding_node != null and plat == editor_holding_node:
		return true
	return false

func _editor_get_ladder_center_y(ladder_idx: int, gx: float, lh: float) -> float:
	var bottom_plat := _editor_get_platform_at(ladder_idx, gx, lh)
	if bottom_plat != null:
		var top_y: float = _editor_get_platform_top_y(bottom_plat)
		return top_y - lh * 0.5
	return (float(ladder_idx) - 0.5) * lh + top_margin - editor_platform_size.y * 0.5

func _editor_get_snapped_mouse() -> Vector2:
	var pos := get_global_mouse_position()
	var gx: float = pos.x
	if editor_grid > 0.0:
		gx = round(pos.x / editor_grid) * editor_grid
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	var tool := editor_holding_type if editor_holding else editor_tool
	if tool == "platform":
		var center_x: float = _editor_get_level_center_x()
		var next_layer: int = _editor_get_platform_target_layer(pos.y)
		var center_y: float = float(next_layer) * lh + top_margin
		return Vector2(center_x, center_y)
	if tool == "ladder":
		var ladder_idx: int = _editor_get_ladder_index_from_y(pos.y, lh)
		var center_y: float = _editor_get_ladder_center_y(ladder_idx, gx, lh)
		return Vector2(gx, center_y)
	if tool == "door" or tool == "special_door":
		var plat := _editor_get_platform_at(layer_idx, gx, lh)
		if plat != null:
			var top_y: float = _editor_get_platform_top_y(plat)
			return Vector2(gx, top_y)
	if tool == "spawn":
		var plat2 := _editor_get_platform_at(layer_idx, gx, lh)
		if plat2 != null:
			var top_y2: float = _editor_get_platform_top_y(plat2)
			return Vector2(gx, top_y2 - 24.0)
	if tool == "chest" or tool == "chest_once":
		var plat3 := _editor_get_platform_at(layer_idx, gx, lh)
		if plat3 != null:
			var top_y3: float = _editor_get_platform_top_y(plat3)
			return Vector2(gx, top_y3 - 6.0)
	if tool == "exit":
		var center_y2: float = float(layer_idx) * lh + top_margin - 8.0
		return Vector2(gx, center_y2)
	var center_y3: float = float(layer_idx) * lh + top_margin
	return Vector2(gx, center_y3)

func _editor_place():
	var pos := _editor_get_snapped_mouse()
	if editor_tool == "platform":
		_editor_place_platform(pos)
	elif editor_tool == "ladder":
		_editor_place_ladder(pos)
	elif editor_tool == "door":
		_editor_place_door(pos)
	elif editor_tool == "special_door":
		_editor_place_special_door(pos)
	elif editor_tool == "spawn":
		_editor_place_spawn(pos)
	elif editor_tool == "exit":
		_editor_place_exit(pos)

func _editor_erase():
	var pos := _editor_get_snapped_mouse()
	if editor_tool == "platform":
		_editor_erase_platform(pos)
	elif editor_tool == "ladder":
		_editor_erase_ladder(pos)
	elif editor_tool == "door":
		_editor_erase_door(pos)
	elif editor_tool == "special_door":
		_editor_erase_door(pos)

func _editor_place_platform(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = editor_layer_index
	_editor_clear_platform_layer(layer_idx, lh)
	var total_w: float = editor_platform_size.x + 160.0
	if generator and generator.has_method("get") and generator.get("width") != null:
		total_w = float(generator.width)
	var w: float = max(total_w - 160.0, editor_platform_size.x)
	var h: float = editor_platform_size.y
	var x: float = (total_w - w) * 0.5
	var center_y: float = float(layer_idx) * lh + top_margin
	var rect := {"x": x, "y": center_y - top_margin, "w": w, "h": h}
	_add_platform(rect)
	_add_border_walls()

func _editor_place_ladder(pos: Vector2):
	var lh := _editor_get_layer_height()
	var ladder_idx: int = _editor_get_ladder_index_from_y(pos.y, lh)
	var top_layer: int = ladder_idx - 1
	var bottom_layer: int = ladder_idx
	var gx: float = pos.x
	var top_plat := _editor_get_platform_at(top_layer, gx, lh)
	var bottom_plat := _editor_get_platform_at(bottom_layer, gx, lh)
	if top_plat == null or bottom_plat == null:
		return
	var LadderScript := preload("res://scripts/world/Ladder.gd")
	var ladder := LadderScript.new()
	ladder.width = 12.0
	ladder.height = lh
	ladder.locked = editor_ladder_locked
	ladders.add_child(ladder)
	var center_y: float = _editor_get_ladder_center_y(ladder_idx, gx, lh)
	ladder.global_position = Vector2(gx, center_y)

func _editor_place_door(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
	if plat == null:
		return
	var top_y: float = _editor_get_platform_top_y(plat)
	var DoorScript := preload("res://scripts/world/Door.gd")
	var door = DoorScript.new()
	add_child(door)
	door.global_position = Vector2(pos.x, top_y)
	_editor_apply_door_wall(door, plat, lh)

func _editor_place_special_door(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
	if plat == null:
		return
	var top_y: float = _editor_get_platform_top_y(plat)
	var SpecialDoorScript := preload("res://scripts/world/SpecialDoor.gd")
	var door = SpecialDoorScript.new()
	add_child(door)
	door.global_position = Vector2(pos.x, top_y)
	_editor_apply_door_wall(door, plat, lh)

func _editor_place_spawn(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
	if plat == null:
		return
	var top_y: float = _editor_get_platform_top_y(plat)
	spawn_position = Vector2(pos.x, top_y - 24.0)
	if spawner:
		spawner.global_position = spawn_position + Vector2(200.0, -16.0)

func _editor_place_exit(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	exit_position = Vector2(pos.x, float(layer_idx) * lh + top_margin - 8.0)
	exit_node.global_position = exit_position
	exit_node.visible = true
	_add_exit_marker()

func _editor_erase_platform(pos: Vector2):
	var lh := _editor_get_layer_height()
	var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
	_editor_clear_platform_layer(layer_idx, lh)
	_add_border_walls()

func _editor_erase_ladder(pos: Vector2):
	var best: Node2D = null
	var best_d: float = 1e18
	for l in ladders.get_children():
		if l and l is Node2D:
			var d: float = (l as Node2D).global_position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = l as Node2D
	if best != null and best_d <= 40.0:
		best.queue_free()

func _editor_erase_door(pos: Vector2):
	var best: Node2D = null
	var best_d: float = 1e18
	for d in get_tree().get_nodes_in_group("door"):
		if d and d is Node2D:
			var dist: float = (d as Node2D).global_position.distance_to(pos)
			if dist < best_d:
				best_d = dist
				best = d as Node2D
	if best != null and best_d <= 32.0:
		best.queue_free()

func _editor_adjust_layer(delta: int):
	editor_layer_index = clamp(editor_layer_index + delta, 0, _editor_get_layer_count() - 1)

func _editor_move_selected_platform(delta: int):
	if editor_selected_node == null:
		return
	var lh := _editor_get_layer_height()
	var cur_idx: int = _editor_get_layer_index_from_y(editor_selected_node.global_position.y, lh)
	var next_idx: int = clamp(cur_idx + delta, 0, _editor_get_layer_count() - 1)
	if next_idx == cur_idx:
		return
	if _editor_get_platform_at(next_idx, editor_selected_node.global_position.x, lh) != null:
		return
	editor_selected_node.global_position = Vector2(editor_selected_node.global_position.x, float(next_idx) * lh + top_margin)
	editor_layer_index = next_idx
	_add_border_walls()

func _editor_select_at(pos: Vector2) -> bool:
	var best_d: float = INF
	editor_selected_type = "none"
	editor_selected_node = null
	for p in platforms.get_children():
		if p and p is Node2D:
			var pw: float = _get_platform_width(p as Node2D)
			var ph: float = _get_platform_height(p as Node2D)
			if pw <= 0.0 or ph <= 0.0:
				continue
			var cx: float = (p as Node2D).global_position.x
			var cy: float = (p as Node2D).global_position.y
			var margin: float = 8.0
			if pos.x >= cx - pw * 0.5 - margin and pos.x <= cx + pw * 0.5 + margin and pos.y >= cy - ph * 0.5 - margin and pos.y <= cy + ph * 0.5 + margin:
				var dp: float = (p as Node2D).global_position.distance_to(pos)
				if dp < best_d:
					best_d = dp
					editor_selected_type = "platform"
					editor_selected_node = p as Node2D
	for l in ladders.get_children():
		if l and l is Node2D:
			var dl: float = (l as Node2D).global_position.distance_to(pos)
			if dl <= 40.0 and dl < best_d:
				best_d = dl
				editor_selected_type = "ladder"
				editor_selected_node = l as Node2D
	for d in get_tree().get_nodes_in_group("door"):
		if d and d is Node2D:
			var dd: float = (d as Node2D).global_position.distance_to(pos)
			if dd <= 40.0 and dd < best_d:
				best_d = dd
				var specv = d.get("special")
				editor_selected_type = "special_door" if specv != null and bool(specv) else "door"
				editor_selected_node = d as Node2D
	for c in get_tree().get_nodes_in_group("chest"):
		if c and c is Node2D:
			var dc: float = (c as Node2D).global_position.distance_to(pos)
			if dc <= 40.0 and dc < best_d:
				best_d = dc
				var ctype := "chest"
				if c.get("chest_type") != null and String(c.get("chest_type")) == "single":
					ctype = "chest_once"
				editor_selected_type = ctype
				editor_selected_node = c as Node2D
	if exit_node and exit_node.visible:
		var d_exit: float = exit_node.global_position.distance_to(pos)
		if d_exit <= 18.0 and d_exit < best_d:
			best_d = d_exit
			editor_selected_type = "exit"
	if spawn_position.distance_to(pos) <= 18.0 and spawn_position.distance_to(pos) < best_d:
		best_d = spawn_position.distance_to(pos)
		editor_selected_type = "spawn"
	if editor_selected_type == "platform" and editor_selected_node != null:
		var lh := _editor_get_layer_height()
		editor_layer_index = _editor_get_layer_index_from_y(editor_selected_node.global_position.y, lh)
	return editor_selected_type != "none"

func _editor_try_move_selected(pos: Vector2) -> bool:
	if editor_selected_type == "none":
		return false
	if editor_selected_type == "platform":
		return false
	var lh := _editor_get_layer_height()
	if editor_selected_type == "ladder" and editor_selected_node != null:
		var ladder_idx: int = _editor_get_ladder_index_from_y(pos.y, lh)
		var gx: float = pos.x
		var top_plat := _editor_get_platform_at(ladder_idx - 1, gx, lh)
		var bottom_plat := _editor_get_platform_at(ladder_idx, gx, lh)
		if top_plat == null or bottom_plat == null:
			return false
		var center_y: float = (float(ladder_idx) - 0.5) * lh + top_margin - editor_platform_size.y * 0.5
		editor_selected_node.global_position = Vector2(gx, center_y)
		return true
	if (editor_selected_type == "door" or editor_selected_type == "special_door") and editor_selected_node != null:
		var layer_idx: int = _editor_get_layer_index_from_y(pos.y, lh)
		var plat := _editor_get_platform_at(layer_idx, pos.x, lh)
		if plat == null:
			return false
		var top_y: float = _editor_get_platform_top_y(plat)
		editor_selected_node.global_position = Vector2(pos.x, top_y)
		_editor_apply_door_wall(editor_selected_node, plat, lh)
		return true
	if (editor_selected_type == "chest" or editor_selected_type == "chest_once") and editor_selected_node != null:
		var layer_idx2: int = _editor_get_layer_index_from_y(pos.y, lh)
		var plat2 := _editor_get_platform_at(layer_idx2, pos.x, lh)
		if plat2 == null:
			return false
		var top_y2: float = _editor_get_platform_top_y(plat2)
		editor_selected_node.global_position = Vector2(pos.x, top_y2 - 6.0)
		return true
	if editor_selected_type == "spawn":
		var layer_idx3: int = _editor_get_layer_index_from_y(pos.y, lh)
		var plat3 := _editor_get_platform_at(layer_idx3, pos.x, lh)
		if plat3 == null:
			return false
		var top_y3: float = _editor_get_platform_top_y(plat3)
		spawn_position = Vector2(pos.x, top_y3 - 24.0)
		if spawner:
			spawner.global_position = spawn_position + Vector2(200.0, -16.0)
		return true
	if editor_selected_type == "exit":
		var layer_idx4: int = _editor_get_layer_index_from_y(pos.y, lh)
		exit_position = Vector2(pos.x, float(layer_idx4) * lh + top_margin - 8.0)
		exit_node.global_position = exit_position
		exit_node.visible = true
		_add_exit_marker()
		return true
	return false

func _editor_delete_selected():
	if editor_selected_type == "none":
		return
	if editor_selected_type == "platform" and editor_selected_node != null:
		editor_selected_node.queue_free()
		_add_border_walls()
	elif editor_selected_type == "ladder" and editor_selected_node != null:
		editor_selected_node.queue_free()
	elif (editor_selected_type == "door" or editor_selected_type == "special_door") and editor_selected_node != null:
		editor_selected_node.queue_free()
	elif (editor_selected_type == "chest" or editor_selected_type == "chest_once") and editor_selected_node != null:
		editor_selected_node.queue_free()
	elif editor_selected_type == "spawn":
		spawn_position = Vector2(-9999, -9999)
		if spawner:
			spawner.global_position = spawn_position + Vector2(200.0, -16.0)
		if editor_spawn_marker:
			editor_spawn_marker.visible = false
	elif editor_selected_type == "exit":
		exit_position = Vector2(-9999, -9999)
		exit_node.global_position = exit_position
		exit_node.visible = false
	_editor_clear_selection()
	if editor_holding:
		editor_holding = false
		editor_holding_new = false
		editor_holding_type = "none"
		editor_holding_node = null
		editor_tool = "hand"

func _editor_clear_selection():
	editor_selected_type = "none"
	editor_selected_node = null

func _on_editor_exit_pressed():
	if editor_exit_dialog:
		editor_exit_dialog.popup_centered()

func _on_editor_exit_save():
	if editor_holding:
		_editor_commit_hold()
	_editor_save()
	editor_enabled = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")

func _on_editor_exit_discard():
	if editor_holding:
		_editor_cancel_hold()
	editor_enabled = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")

func _editor_get_layer_height() -> float:
	if generator and generator.has_method("get") and generator.get("layer_height") != null:
		return float(generator.layer_height)
	return editor_ladder_height

func _editor_get_layer_count() -> int:
	if generator and generator.has_method("get") and generator.get("layers") != null:
		var base: int = int(generator.layers)
		return max(base, _editor_get_max_platform_layer() + 2)
	return 4

func _editor_get_max_platform_layer() -> int:
	var lh := _editor_get_layer_height()
	var best: int = -1
	for p in platforms.get_children():
		if p and p is Node2D:
			var idx: int = _editor_get_layer_index_from_y_raw((p as Node2D).global_position.y, lh)
			if idx > best:
				best = idx
	return best

func _editor_get_max_platform_layer_excluding(exclude: Node2D) -> int:
	var lh := _editor_get_layer_height()
	var best: int = -1
	for p in platforms.get_children():
		if p and p is Node2D:
			if exclude != null and p == exclude:
				continue
			var idx: int = _editor_get_layer_index_from_y_raw((p as Node2D).global_position.y, lh)
			if idx > best:
				best = idx
	return best

func _editor_get_level_width() -> float:
	if generator and generator.has_method("get") and generator.get("width") != null:
		return float(generator.width)
	return editor_platform_size.x + 160.0

func _editor_get_level_center_x() -> float:
	return _editor_get_level_width() * 0.5

func _editor_get_layer_index_from_y(y: float, lh: float) -> int:
	var idx: int = int(round((y - top_margin) / lh))
	return clamp(idx, 0, _editor_get_layer_count() - 1)

func _editor_get_layer_index_from_y_raw(y: float, lh: float) -> int:
	return int(round((y - top_margin) / lh))

func _editor_get_ladder_index_from_y(y: float, lh: float) -> int:
	var idx: int = int(round((y - top_margin) / lh + 0.5))
	return clamp(idx, 1, _editor_get_layer_count() - 1)

func _editor_get_platform_at(layer_idx: int, x: float, lh: float) -> Node2D:
	var target_y: float = float(layer_idx) * lh + top_margin
	var best: Node2D = null
	var best_d: float = INF
	for p in platforms.get_children():
		if p and p is Node2D:
			var pw: float = _get_platform_width(p as Node2D)
			var ph: float = _get_platform_height(p as Node2D)
			if pw <= 0.0 or ph <= 0.0:
				continue
			var cy: float = (p as Node2D).global_position.y
			var d: float = abs(cy - target_y)
			if d > lh * 0.25:
				continue
			var cx: float = (p as Node2D).global_position.x
			if x < cx - pw * 0.5 or x > cx + pw * 0.5:
				continue
			if d < best_d:
				best_d = d
				best = p as Node2D
	return best

func _editor_get_platform_top_y(plat: Node2D) -> float:
	var ph: float = _get_platform_height(plat)
	return plat.global_position.y - ph * 0.5

func _editor_clear_platform_layer(layer_idx: int, lh: float):
	var target_y: float = float(layer_idx) * lh + top_margin
	var to_remove: Array = []
	for p in platforms.get_children():
		if p and p is Node2D:
			var ph: float = _get_platform_height(p as Node2D)
			if ph <= 0.0:
				continue
			var d: float = abs((p as Node2D).global_position.y - target_y)
			if d <= lh * 0.25:
				to_remove.append(p)
	for p in to_remove:
		p.queue_free()

func _editor_collect_data() -> Dictionary:
	var plats: Array = []
	for p in platforms.get_children():
		if p and p is Node2D:
			var pw: float = _get_platform_width(p as Node2D)
			var ph: float = _get_platform_height(p as Node2D)
			if pw <= 0.0 or ph <= 0.0:
				continue
			var center := (p as Node2D).global_position
			plats.append({"x": center.x - pw * 0.5, "y": center.y - top_margin, "w": pw, "h": ph})
	var ladd: Array = []
	for l in ladders.get_children():
		if l and l is Node2D:
			var lh = l.get("height")
			var lw = l.get("width")
			var locked = l.get("locked")
			var leads = l.get("leads_to_top")
			ladd.append({
				"x": (l as Node2D).global_position.x,
				"y": (l as Node2D).global_position.y,
				"w": float(lw) if lw != null else 12.0,
				"h": float(lh) if lh != null else editor_ladder_height,
				"locked": bool(locked) if locked != null else false,
				"leads": bool(leads) if leads != null else false
			})
	var doors: Array = []
	for d in get_tree().get_nodes_in_group("door"):
		if d and d is Node2D:
			var hpv = d.get("hp")
			var maxv = d.get("max_hp")
			var openv = d.get("open")
			var specialv = d.get("special")
			var lockedv = d.get("special_locked")
			doors.append({
				"x": (d as Node2D).global_position.x,
				"y": (d as Node2D).global_position.y,
				"hp": int(hpv) if hpv != null else 100,
				"max_hp": int(maxv) if maxv != null else 300,
				"open": bool(openv) if openv != null else true,
				"special": bool(specialv) if specialv != null else false,
				"locked": bool(lockedv) if lockedv != null else false
			})
	var chests: Array = []
	for c in get_tree().get_nodes_in_group("chest"):
		if c and c is Node2D:
			if c.get("chest_type") != null and String(c.get("chest_type")) == "password":
				continue
			var ctype := "normal"
			if c.get("chest_type") != null:
				ctype = String(c.get("chest_type"))
			chests.append({
				"x": (c as Node2D).global_position.x,
				"y": (c as Node2D).global_position.y,
				"type": ctype
			})
	return {
		"spawn": {"x": spawn_position.x, "y": spawn_position.y},
		"exit": {"x": exit_position.x, "y": exit_position.y},
		"platforms": plats,
		"ladders": ladd,
		"doors": doors,
		"chests": chests
	}

func _editor_save():
	var data := _editor_collect_data()
	if editor_custom_index < 0:
		var root := get_tree().get_root().get_node_or_null("GameRoot")
		if root and root.get("run_level_index") != null:
			var idx: int = int(root.get("run_level_index"))
			if idx >= 1 and idx <= 3:
				save_base_map(idx - 1)
				return
	var maps := _load_custom_maps()
	if editor_custom_index >= 0 and editor_custom_index < maps.size():
		maps[editor_custom_index] = data
	else:
		maps.append(data)
		editor_custom_index = maps.size() - 1
	_save_custom_maps(maps)

func _editor_load():
	if editor_custom_index >= 0:
		load_custom_map(editor_custom_index)

func _editor_apply_data(data: Dictionary):
	_clear_platforms()
	_clear_ladders()
	_clear_doors()
	_clear_chests()
	var plats = data.get("platforms")
	if plats != null:
		for r in plats:
			if r is Dictionary:
				_add_platform(r)
	var ladd = data.get("ladders")
	if ladd != null:
		var LadderScript := preload("res://scripts/world/Ladder.gd")
		for l in ladd:
			if l is Dictionary:
				var ladder := LadderScript.new()
				ladder.width = float(l.get("w", 12.0))
				ladder.height = float(l.get("h", editor_ladder_height))
				ladder.locked = bool(l.get("locked", false))
				ladder.leads_to_top = bool(l.get("leads", false))
				ladders.add_child(ladder)
				ladder.global_position = Vector2(float(l.get("x", 0.0)), float(l.get("y", 0.0)))
	var doors = data.get("doors")
	if doors != null:
		for d in doors:
			if d is Dictionary:
				var is_special: bool = bool(d.get("special", false))
				var DoorScript := preload("res://scripts/world/Door.gd") if not is_special else preload("res://scripts/world/SpecialDoor.gd")
				var door = DoorScript.new()
				add_child(door)
				door.global_position = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
				door.max_hp = int(d.get("max_hp", 300))
				door.hp = int(d.get("hp", 100))
				var locked_flag: bool = bool(d.get("locked", true))
				if is_special and door.has_method("set_special_locked"):
					door.set_special_locked(locked_flag)
				if not (is_special and locked_flag):
					door.set_open(bool(d.get("open", true)))
				var lh := _editor_get_layer_height()
				var layer_idx: int = _editor_get_layer_index_from_y(door.global_position.y, lh)
				var plat := _editor_get_platform_at(layer_idx, door.global_position.x, lh)
				_editor_apply_door_wall(door, plat, lh)
	var chests = data.get("chests")
	if chests != null:
		for c in chests:
			if c is Dictionary:
				var ctype: String = String(c.get("type", "normal"))
				var chest
				if ctype == "single":
					var ChestOnceScript := preload("res://scripts/items/ChestOnce.gd")
					chest = ChestOnceScript.new()
				else:
					var ChestScript := preload("res://scripts/items/Chest.gd")
					chest = ChestScript.new()
				add_child(chest)
				chest.global_position = Vector2(float(c.get("x", 0.0)), float(c.get("y", 0.0)))
	var sp = data.get("spawn")
	if sp is Dictionary:
		spawn_position = Vector2(float(sp.get("x", spawn_position.x)), float(sp.get("y", spawn_position.y)))
	var ex = data.get("exit")
	if ex is Dictionary:
		exit_position = Vector2(float(ex.get("x", exit_position.x)), float(ex.get("y", exit_position.y)))
		exit_node.global_position = exit_position
		exit_node.visible = true
	_add_exit_marker()
	if not editor_enabled:
		var root := get_tree().get_root().get_node("GameRoot")
		if root and root.has_method("init_chest_loot"):
			if root.has_method("reset_chest_loot_initialized"):
				root.call("reset_chest_loot_initialized")
			var normal_chests := []
			for c2 in get_tree().get_nodes_in_group("chest"):
				if c2 and c2.get("chest_type") != null and String(c2.get("chest_type")) == "normal":
					normal_chests.append(c2)
			root.init_chest_loot(normal_chests)
	_add_border_walls()
	if spawner:
		spawner.global_position = spawn_position + Vector2(200.0, -16.0)
	_maybe_spawn_password_chest()

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

func _load_base_maps() -> Array:
	var base_path := LocalPathsScript.ensure_text_file("base_maps.json", "res://data/maps/base_maps.json", "[]")
	var f := FileAccess.open(base_path, FileAccess.READ)
	if f:
		var txt := f.get_as_text()
		f.close()
		var data = JSON.parse_string(txt)
		if data is Array:
			return data
	return []

func _save_base_maps(arr: Array):
	var txt := JSON.stringify(arr)
	var base_path := LocalPathsScript.file_path("base_maps.json")
	var f := FileAccess.open(base_path, FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()

func load_base_map(index: int) -> bool:
	var maps := _load_base_maps()
	if index < 0 or index >= maps.size():
		return false
	var data = maps[index]
	if data is Dictionary:
		_editor_apply_data(data)
		return true
	return false

func save_base_map(index: int):
	if index < 0:
		return
	var data := _editor_collect_data()
	var maps := _load_base_maps()
	while maps.size() <= index:
		maps.append({})
	maps[index] = data
	_save_base_maps(maps)

func _clear_doors():
	for d in get_tree().get_nodes_in_group("door"):
		if d and d is Node:
			d.queue_free()
func _clear_chests():
	for c in get_tree().get_nodes_in_group("chest"):
		if c and c is Node:
			c.queue_free()
func _partition_rooms_and_place_chests():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lay: int = int(generator.layers)
	var lh: float = float(generator.layer_height)
	# 允许层：底部三层（1-3层）
	var allowed_layers := []
	for i in range(max(lay - 3, 0), lay):
		allowed_layers.append(i)
	# 梯子X坐标（用于避让）
	var ladder_xs: Array = []
	for l in ladders.get_children():
		if l and l is Node2D:
			ladder_xs.append((l as Node2D).global_position.x)
	# 遍历每层进行分房与放置
	for layer_idx in allowed_layers:
		var plat := _get_platform_body_for_layer(layer_idx)
		if plat == null:
			continue
		var w := _get_platform_width(plat)
		var h := _get_platform_height(plat)
		if w <= 0.0 or h <= 0.0:
			continue
		var hw: float = w * 0.5
		var hh: float = h * 0.5
		var min_x: float = plat.global_position.x - hw + 24.0
		var max_x: float = plat.global_position.x + hw - 24.0
		if max_x - min_x < 200.0:
			continue
		var room_count: int = rng.randi_range(2, 3)
		var boundaries: Array = []
		var tries: int = 0
		while boundaries.size() < room_count - 1 and tries < 200:
			tries += 1
			var bx: float = rng.randf_range(min_x + 64.0, max_x - 64.0)
			var near_ladder: bool = false
			for lx in ladder_xs:
				if abs(lx - bx) < 24.0:
					near_ladder = true
					break
			if near_ladder:
				continue
			var ok_dist: bool = true
			for ex in boundaries:
				if abs(float(ex) - bx) < 160.0:
					ok_dist = false
					break
			if ok_dist:
				_boundaries_insert_sorted(boundaries, bx)
		# 生成房间区间
		var rooms := []
		var start_x: float = min_x
		for b in boundaries:
			rooms.append(Vector2(start_x, float(b)))
			start_x = float(b)
		rooms.append(Vector2(start_x, max_x))
		for b in boundaries:
			var bx: float = float(b)
			var local_x: float = bx - plat.global_position.x
			var wall_w: float = 6.0
			var wall_h: float = max(lh - 2.0 * hh - 2.0, 2.0)
			var DoorScript := preload("res://scripts/world/Door.gd")
			var door = DoorScript.new()
			plat.add_child(door)
			door.position = Vector2(local_x, -hh)
			if door.has_method("set_wall_dimensions"):
				door.call("set_wall_dimensions", wall_w, wall_h)
		# 每个房间放一个宝箱（避让梯子）
		var ChestScript := preload("res://scripts/items/Chest.gd")
		for r in rooms:
			var rx1: float = float(r.x) + 28.0
			var rx2: float = float(r.y) - 28.0
			if rx2 <= rx1:
				continue
			var placed: bool = false
			for i in range(20):
				var cx: float = rng.randf_range(rx1, rx2)
				var ok: bool = true
				for lx in ladder_xs:
					if abs(lx - cx) < 24.0:
						ok = false
						break
				if ok:
					var chest = ChestScript.new()
					add_child(chest)
					chest.global_position = Vector2(cx, plat.global_position.y - hh - 6.0)
					placed = true
					break
			if not placed:
				var chest = ChestScript.new()
				add_child(chest)
				chest.global_position = Vector2((rx1 + rx2) * 0.5, plat.global_position.y - hh - 6.0)
	var root := get_tree().get_root().get_node("GameRoot")
	if root and root.has_method("init_chest_loot"):
		var chests := []
		for c in get_tree().get_nodes_in_group("chest"):
			if c and c.get("chest_type") != null and String(c.get("chest_type")) == "normal":
				chests.append(c)
		root.init_chest_loot(chests)
	_maybe_spawn_password_chest()

func _maybe_spawn_password_chest():
	if editor_enabled:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() > 0.3:
		return
	var lay: int = int(generator.layers)
	var lh: float = float(generator.layer_height)
	var allowed_layers := []
	for i in range(max(lay - 3, 0), lay):
		allowed_layers.append(i)
	if allowed_layers.size() == 0:
		return
	var ladder_xs: Array = []
	for l in ladders.get_children():
		if l and l is Node2D:
			ladder_xs.append((l as Node2D).global_position.x)
	var PasswordChestScript := preload("res://scripts/items/PasswordChest.gd")
	for _i in range(60):
		var layer_idx: int = int(allowed_layers[rng.randi_range(0, allowed_layers.size() - 1)])
		var plat := _get_platform_body_for_layer(layer_idx)
		if plat == null:
			continue
		var w := _get_platform_width(plat)
		var h := _get_platform_height(plat)
		if w <= 0.0 or h <= 0.0:
			continue
		var hw: float = w * 0.5
		var hh: float = h * 0.5
		var min_x: float = plat.global_position.x - hw + 28.0
		var max_x: float = plat.global_position.x + hw - 28.0
		if max_x <= min_x:
			continue
		var cx: float = rng.randf_range(min_x, max_x)
		var ok: bool = true
		for lx in ladder_xs:
			if abs(lx - cx) < 24.0:
				ok = false
				break
		if not ok:
			continue
		var chest = PasswordChestScript.new()
		add_child(chest)
		chest.global_position = Vector2(cx, plat.global_position.y - hh - 6.0)
		return

func _get_platform_body_for_layer(layer_idx: int) -> Node2D:
	var lh: float = float(generator.layer_height)
	var target_y: float = float(layer_idx) * lh + top_margin
	var best: Node2D = null
	var best_d: float = INF
	for b in platforms.get_children():
		if b and b is Node2D:
			var d: float = abs((b as Node2D).global_position.y - target_y)
			if d < best_d:
				best_d = d
				best = b as Node2D
	return best

func _get_platform_width(plat: Node2D) -> float:
	for c in plat.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape and (c as CollisionShape2D).shape is RectangleShape2D:
			var sz := ((c as CollisionShape2D).shape as RectangleShape2D).size
			if sz.x > 100.0 and sz.y <= 24.0:
				return float(sz.x)
	return 0.0

func _get_platform_height(plat: Node2D) -> float:
	for c in plat.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape and (c as CollisionShape2D).shape is RectangleShape2D:
			var sz := ((c as CollisionShape2D).shape as RectangleShape2D).size
			if sz.x > 100.0 and sz.y <= 24.0:
				return float(sz.y)
	return 0.0

func _boundaries_insert_sorted(arr: Array, v: float):
	var inserted: bool = false
	for i in range(arr.size()):
		if v < float(arr[i]):
			arr.insert(i, v)
			inserted = true
			break
	if not inserted:
		arr.append(v)

func _build_ground_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.43, 0.43, 0.46, 1.0)
	var c2 := Color(0.36, 0.36, 0.39, 1.0)
	var c_top := Color(0.62, 0.62, 0.66, 1.0)
	var c_bot := Color(0.23, 0.23, 0.26, 1.0)
	for y in range(th):
		for x in range(tw):
			var use_alt: bool = ((x / 4 + y / 4) % 2) == 0
			var col := c1 if use_alt else c2
			if y < 2:
				col = c_top
			elif y >= th - 2:
				col = c_bot
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _build_wall_texture(w: int, h: int, border: bool) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.44, 0.44, 0.56, 1.0) if border else Color(0.51, 0.51, 0.66, 1.0)
	var c2 := Color(0.32, 0.32, 0.42, 1.0) if border else Color(0.38, 0.38, 0.5, 1.0)
	var edge := Color(0.22, 0.22, 0.28, 1.0)
	for y in range(th):
		for x in range(tw):
			var stripe: bool = ((y / 4) % 2) == 0
			var col := c1 if stripe else c2
			if x == 0 or x == tw - 1:
				col = edge
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _build_exit_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(w, 1)
	var th: int = max(h, 1)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var dark := Color(0.04, 0.08, 0.06, 0.98)
	var glow := Color(0.2, 0.98, 0.42, 1.0)
	var glow2 := Color(0.7, 1.0, 0.82, 1.0)
	var core := Color(0.85, 1.0, 0.92, 1.0)
	for y in range(th):
		for x in range(tw):
			var col := dark
			var border: bool = x == 0 or x == tw - 1 or y == 0 or y == th - 1
			if border:
				col = glow
			var inner: bool = x > 4 and x < tw - 5 and y > 4 and y < th - 4
			if inner:
				col = glow
				if abs(x - tw / 2) <= 1:
					col = core
				elif ((x + y) % 3) == 0:
					col = glow2
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
func get_top_margin() -> float:
	return top_margin
func is_top_layer_locked() -> bool:
	return top_layer_locked
func set_top_layer_locked(v: bool):
	top_layer_locked = v
