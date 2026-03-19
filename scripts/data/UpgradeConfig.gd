extends Node

class_name UpgradeConfig

var items: Array[Dictionary] = []
var by_id: Dictionary = {}

func load_csv(path: String = "res://data/upgrades.csv"):
	items.clear()
	by_id.clear()
	var packed_path := "res://data/packed/upgrades.json"
	if _load_from_json(packed_path):
		return
	if _load_from_csv(path):
		_write_packed(packed_path)

func _load_from_csv(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var _header := f.get_line()
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var cols := line.split(",")
		if cols.size() < 10:
			continue
		var id := cols[0]
		var rec: Dictionary = {
			"id": id,
			"name": cols[1],
			"target": cols[2],
			"prop": cols[3],
			"delta": float(cols[4]),
			"limit_type": cols[5],
			"limit_value": float(cols[6]),
			"weight": float(cols[7]),
			"rarity": cols[8],
			"unlock": cols[9]
		}
		items.append(rec)
		by_id[id] = rec
	f.close()
	return items.size() > 0

func _load_from_json(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data is Array:
		for rec_i in data:
			if rec_i is Dictionary:
				var rec: Dictionary = rec_i
				var id := String(rec.get("id", ""))
				items.append(rec)
				by_id[id] = rec
	return items.size() > 0

func _write_packed(path: String):
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("data/packed")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(items))
		f.close()

func get_item(id: String) -> Dictionary:
	return by_id.get(id, {})

func get_value(id: String, key: String, default_val = null):
	var rec: Dictionary = get_item(id)
	if rec.has(key):
		return rec[key]
	return default_val
