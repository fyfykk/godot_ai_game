extends Button

var slot_index: int = -1
var editor: Node = null

func _can_drop_data(_pos, data):
	if editor == null:
		return false
	if not (data is Dictionary and data.get("from", "") == "backpack"):
		return false
	var item_id := String(data.get("item_id", ""))
	if item_id == "":
		return false
	if editor.has_method("_can_drop_item_to_slot"):
		return bool(editor.call("_can_drop_item_to_slot", item_id, slot_index))
	return true

func _drop_data(_pos, data):
	if editor == null:
		return
	editor.call("_on_drop_item_to_slot", String(data.get("item_id", "")), slot_index)
