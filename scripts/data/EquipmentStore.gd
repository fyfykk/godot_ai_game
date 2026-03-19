extends Node

const SAVE_PATH = "user://equipment.cfg"
const SLOT_TYPES := ["ranged", "melee", "range"]

var equipped_items: Array[String] = []
var backpack_items: Array[String] = []
@onready var equipment_config = get_node("/root/EquipmentConfig")

func _ready():
	load_store()

func get_default_equipped_items() -> Array[String]:
	return ["EQ001", "EQ002", "EQ003"]

func equip_item(item_id: String, slot_index: int):
	if slot_index < 0 or slot_index >= equipped_items.size():
		return
	if not backpack_items.has(item_id):
		return
	if not _can_equip_item_to_slot(item_id, slot_index):
		return
	var old_item_id = equipped_items[slot_index]
	if old_item_id != "":
		backpack_items.append(old_item_id)
	equipped_items[slot_index] = item_id
	backpack_items.erase(item_id)
	_normalize_state()
	save_store()

func save_store():
	var config = ConfigFile.new()
	config.set_value("equipment", "equipped", equipped_items)
	config.set_value("equipment", "backpack", backpack_items)
	config.save(SAVE_PATH)

func load_store():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		equipped_items = get_default_equipped_items()
		backpack_items = []
		save_store()
	else:
		equipped_items = config.get_value("equipment", "equipped", get_default_equipped_items())
		backpack_items = config.get_value("equipment", "backpack", [])
	_normalize_state()
	_ensure_start_items()
	save_store()

func clear_local():
	equipped_items = get_default_equipped_items()
	backpack_items = []
	_normalize_state()
	save_store()

func _ensure_start_items():
	var start_items := ["EQ003"]
	for item_id in start_items:
		if not has_item(item_id):
			backpack_items.append(item_id)
	_normalize_state()

func _normalize_state():
	var defaults = get_default_equipped_items()
	if equipped_items.size() != defaults.size():
		equipped_items = defaults.duplicate()
	var seen := {}
	for i in range(equipped_items.size()):
		var id := equipped_items[i]
		if id == "" or seen.has(id):
			equipped_items = defaults.duplicate()
			break
		seen[id] = true
	for i in range(equipped_items.size()):
		var id2 := equipped_items[i]
		if not _can_equip_item_to_slot(id2, i):
			if id2 != "" and not backpack_items.has(id2):
				backpack_items.append(id2)
			equipped_items[i] = defaults[i]
	seen = {}
	for id in equipped_items:
		seen[id] = true
	var filtered_backpack: Array[String] = []
	for id in backpack_items:
		if id != "" and not seen.has(id):
			if not filtered_backpack.has(id):
				filtered_backpack.append(id)
	backpack_items = filtered_backpack

func has_item(item_id: String) -> bool:
	if item_id == "":
		return false
	if equipped_items.has(item_id):
		return true
	return backpack_items.has(item_id)

func add_to_backpack(item_id: String) -> bool:
	if item_id == "":
		return false
	if has_item(item_id):
		return false
	backpack_items.append(item_id)
	_normalize_state()
	save_store()
	return true

func _can_equip_item_to_slot(item_id: String, slot_index: int) -> bool:
	var slot_type := _get_slot_type(slot_index)
	if slot_type == "":
		return false
	var rec: Dictionary = equipment_config.get_equipment_by_id(item_id) if equipment_config else {}
	var item_slot := String(rec.get("slot_type", ""))
	if item_slot == "":
		var attack_id := String(rec.get("attack_id", ""))
		item_slot = _map_attack_to_slot_type(attack_id)
	return item_slot == slot_type

func _get_slot_type(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOT_TYPES.size():
		return ""
	return SLOT_TYPES[slot_index]

func _map_attack_to_slot_type(attack_id: String) -> String:
	if attack_id == "bullet":
		return "ranged"
	if attack_id == "melee":
		return "melee"
	if attack_id == "magic" or attack_id == "roar":
		return "range"
	return ""
