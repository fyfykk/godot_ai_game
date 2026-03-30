extends Node

class_name UpgradeConfig

var items: Array[Dictionary] = []
var by_id: Dictionary = {}

func load_csv(path: String = "res://data/upgrades.csv"):
	items.clear()
	by_id.clear()
	var packed_path := _derive_packed_path(path, "res://data/packed/upgrades.json")
	if _load_from_csv(path):
		_write_packed(packed_path)
		return
	if _load_from_json(packed_path):
		if _is_upgrade_packed_legacy():
			items.clear()
			by_id.clear()
		return

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
		if cols.size() < 8:
			continue
		var id := cols[0]
		var rec: Dictionary = {
			"id": id,
			"name": cols[1],
			"target": cols[2],
			"prop": cols[3],
			"delta": float(cols[4]),
			"weight": float(cols[5]),
			"rarity": cols[6],
			"unlock": cols[7]
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
				if not rec.has("weight"):
					rec["weight"] = 1.0
				if not rec.has("rarity"):
					rec["rarity"] = "blue"
				if not rec.has("unlock"):
					rec["unlock"] = "none"
				items.append(rec)
				by_id[id] = rec
	return items.size() > 0

func _is_upgrade_packed_legacy() -> bool:
	for rec_i in items:
		if rec_i is Dictionary:
			var rec: Dictionary = rec_i
			if rec.has("limit_type") or rec.has("limit_value"):
				return true
			if not rec.has("weight") or not rec.has("rarity") or not rec.has("unlock"):
				return true
	return false

func _write_packed(path: String):
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("data/packed")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(items))
		f.close()

func _derive_packed_path(csv_path: String, fallback: String) -> String:
	var base := csv_path.get_file().get_basename()
	if base != "":
		return "res://data/packed/%s.json" % base
	return fallback

func get_item(id: String) -> Dictionary:
	return by_id.get(id, {})

func get_value(id: String, key: String, default_val = null):
	var rec: Dictionary = get_item(id)
	if rec.has(key):
		return rec[key]
	return default_val
