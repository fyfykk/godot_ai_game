extends Control

const BACKPACK_SLOTS := 10
const SLOT_PANEL_SIZE := 120
const SLOT_CELL_HEIGHT := 152
const ICON_SIZE := 84
const NAME_FONT_SIZE := 12
const TYPE_FONT_SIZE := 11
const BAR_HEIGHT := 22
const BAR_TEXT_COLOR := Color(0.98, 0.9, 0.6, 1.0)
const BAR_BG_COLOR := Color(0.18, 0.18, 0.18, 1.0)
const DragButtonScript = preload("res://scripts/ui/EquipmentDragButton.gd")
const SlotButtonScript = preload("res://scripts/ui/EquipmentSlotButton.gd")

@onready var slot_panels = [
	$VBoxContainer/HBoxContainer/EquippedSlots/Slot1,
	$VBoxContainer/HBoxContainer/EquippedSlots/Slot2,
	$VBoxContainer/HBoxContainer/EquippedSlots/Slot3
]
@onready var backpack_grid_container = $VBoxContainer/BackpackGrid
@onready var equipment_store = get_node("/root/EquipmentStore")
@onready var equipment_config = get_node("/root/EquipmentConfig")

func _ready():
	populate_ui()

func populate_ui():
	for slot in slot_panels:
		for child in slot.get_children():
			child.queue_free()
		slot.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_CELL_HEIGHT)
	for child in backpack_grid_container.get_children():
		child.queue_free()

	var equipped_items = equipment_store.equipped_items
	for i in range(slot_panels.size()):
		var item_id = equipped_items[i] if i < equipped_items.size() else ""
		var slot_type := _get_slot_type(i)
		var cell = _build_item_cell(item_id, slot_type, true, i)
		slot_panels[i].add_child(cell)

	var backpack_items = equipment_store.backpack_items
	for i in range(BACKPACK_SLOTS):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_CELL_HEIGHT)
		panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
		backpack_grid_container.add_child(panel)
		if i < backpack_items.size():
			var item_id = backpack_items[i]
			var slot_type = _get_item_slot_type(item_id)
			var cell = _build_item_cell(item_id, slot_type, false)
			panel.add_child(cell)
		else:
			var empty_cell = _build_empty_cell()
			panel.add_child(empty_cell)

func _build_item_cell(item_id: String, slot_type: String, is_equipped: bool, slot_index: int = -1) -> Control:
	var cell = VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	cell.add_theme_constant_override("separation", 6)
	var icon_panel = Panel.new()
	icon_panel.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_PANEL_SIZE)
	_apply_slot_panel_style(icon_panel, slot_type)
	cell.add_child(icon_panel)
	var btn: Button = null
	if is_equipped:
		btn = _build_slot_button(item_id, slot_index, slot_type)
	else:
		btn = _build_backpack_button(item_id, slot_type)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_panel.add_child(btn)
	var name_label = Label.new()
	var name_bar = _build_name_bar(_get_item_name(item_id))
	cell.add_child(name_bar)
	return cell

func _build_empty_cell() -> Control:
	var cell = VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	cell.add_theme_constant_override("separation", 6)
	var icon_panel = Panel.new()
	icon_panel.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_PANEL_SIZE)
	_apply_slot_panel_style(icon_panel, "")
	cell.add_child(icon_panel)
	var name_label = Label.new()
	var name_bar = _build_name_bar("")
	cell.add_child(name_bar)
	return cell

func _build_slot_button(item_id: String, slot_index: int, slot_type: String) -> Button:
	var btn: Button = SlotButtonScript.new()
	btn.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_PANEL_SIZE)
	btn.text = ""
	_apply_button_style(btn, false, slot_type)
	btn.slot_index = slot_index
	btn.editor = self
	var slot_label := _get_type_label(slot_type)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 0
	box.offset_top = 0
	box.offset_right = 0
	box.offset_bottom = 0
	btn.add_child(box)
	var type_label = Label.new()
	type_label.text = slot_label
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", TYPE_FONT_SIZE)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(type_label)
	if item_id == "":
		var empty_label = Label.new()
		empty_label.text = "空"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(empty_label)
		btn.disabled = true
		return btn
	var item_data = equipment_config.get_equipment_by_id(item_id)
	var icon_path = String(item_data.get("icon", ""))
	var attack_id = String(item_data.get("attack_id", ""))
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var equip_tex = equipment_config.build_equipment_icon(attack_id, ICON_SIZE)
	if equip_tex:
		icon.texture = equip_tex
	elif icon_path != "":
		var tex = load(icon_path)
		if tex:
			icon.texture = tex
	box.add_child(icon)
	return btn

func _build_backpack_button(item_id: String, slot_type: String) -> Button:
	var btn: Button = DragButtonScript.new()
	btn.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, SLOT_PANEL_SIZE)
	var item_data = equipment_config.get_equipment_by_id(item_id)
	var icon_path = String(item_data.get("icon", ""))
	var attack_id = String(item_data.get("attack_id", ""))
	var item_slot := String(item_data.get("slot_type", ""))
	if item_slot == "":
		item_slot = _map_attack_to_slot_type(attack_id)
	var slot_label := _get_type_label(item_slot)
	btn.text = ""
	_apply_button_style(btn, false, slot_type)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 0
	box.offset_top = 0
	box.offset_right = 0
	box.offset_bottom = 0
	btn.add_child(box)
	var type_label = Label.new()
	type_label.text = slot_label
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", TYPE_FONT_SIZE)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(type_label)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var equip_tex = equipment_config.build_equipment_icon(attack_id, ICON_SIZE)
	if equip_tex:
		icon.texture = equip_tex
	elif icon_path != "":
		var tex = load(icon_path)
		if tex:
			icon.texture = tex
	box.add_child(icon)
	btn.drag_payload = {"from": "backpack", "item_id": item_id}
	btn.preview_texture = icon.texture
	return btn

func _apply_slot_panel_style(panel: Panel, slot_type: String):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1)
	style.set_border_width_all(2)
	style.border_color = _get_type_border_color(slot_type)
	panel.add_theme_stylebox_override("panel", style)

func _apply_button_style(btn: Button, highlight: bool, slot_type: String):
	var base := _get_type_border_color(slot_type)
	var border = Color(1, 0.9, 0.4, 1) if highlight else base
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.12, 0.12, 1)
	normal.set_border_width_all(2)
	normal.border_color = border
	var hover = normal.duplicate()
	hover.bg_color = Color(0.18, 0.18, 0.18, 1)
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.08, 0.08, 0.08, 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)

func _get_item_slot_type(item_id: String) -> String:
	var rec: Dictionary = equipment_config.get_equipment_by_id(item_id)
	var item_slot := String(rec.get("slot_type", ""))
	if item_slot == "":
		var attack_id := String(rec.get("attack_id", ""))
		item_slot = _map_attack_to_slot_type(attack_id)
	return item_slot

func _get_item_name(item_id: String) -> String:
	if item_id == "":
		return ""
	var item_data = equipment_config.get_equipment_by_id(item_id)
	return String(item_data.get("name", item_id))

func _build_name_bar(text: String) -> Control:
	var bar = PanelContainer.new()
	bar.custom_minimum_size = Vector2(SLOT_PANEL_SIZE, BAR_HEIGHT)
	var style = StyleBoxFlat.new()
	style.bg_color = BAR_BG_COLOR
	bar.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	label.add_theme_color_override("font_color", BAR_TEXT_COLOR)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(label)
	return bar

func _get_type_border_color(slot_type: String) -> Color:
	if slot_type == "ranged":
		return Color(0.35, 0.75, 1.0, 1.0)
	if slot_type == "melee":
		return Color(0.95, 0.35, 0.35, 1.0)
	if slot_type == "range":
		return Color(0.75, 0.55, 1.0, 1.0)
	return Color(0.7, 0.7, 0.7, 1)

func _on_drop_item_to_slot(item_id: String, slot_index: int):
	if item_id == "":
		return
	if not _can_drop_item_to_slot(item_id, slot_index):
		return
	equipment_store.equip_item(item_id, slot_index)
	populate_ui()

func _can_drop_item_to_slot(item_id: String, slot_index: int) -> bool:
	var slot_type := _get_slot_type(slot_index)
	if slot_type == "":
		return false
	var rec: Dictionary = equipment_config.get_equipment_by_id(item_id)
	var item_slot := String(rec.get("slot_type", ""))
	if item_slot == "":
		var attack_id := String(rec.get("attack_id", ""))
		item_slot = _map_attack_to_slot_type(attack_id)
	return item_slot == slot_type

func _get_slot_type(slot_index: int) -> String:
	var types := ["ranged", "melee", "range"]
	if slot_index < 0 or slot_index >= types.size():
		return ""
	return types[slot_index]

func _map_attack_to_slot_type(attack_id: String) -> String:
	if attack_id == "bullet":
		return "ranged"
	if attack_id == "melee":
		return "melee"
	if attack_id == "magic" or attack_id == "roar":
		return "range"
	return ""

func _get_type_label(slot_type: String) -> String:
	if slot_type == "ranged":
		return "远程"
	if slot_type == "melee":
		return "近战"
	if slot_type == "range":
		return "范围"
	return ""

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
