extends Node

class_name CharactersConfig

var records: Dictionary = {}

func load_csv(path: String = "res://data/characters.csv"):
	records.clear()
	var packed_path := _derive_packed_path(path, "res://data/packed/characters.json")
	if _load_from_csv(path):
		_write_packed(packed_path)
		return
	if _load_from_json(packed_path):
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
		if cols.size() < 7:
			continue
		var role := cols[0]
		var rec: Dictionary = {
			"role": role,
			"max_hp": int(cols[1]),
			"damage": int(cols[2]),
			"bullet_damage": int(cols[3]),
			"melee_damage": int(cols[4]),
			"magic_damage": int(cols[5]),
			"speed": float(cols[6])
		}
		records[role] = rec
	f.close()
	return records.size() > 0

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
				var role := String(rec.get("role", ""))
				records[role] = rec
	return records.size() > 0

func _write_packed(path: String):
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("data/packed")
	var arr: Array = []
	for k in records.keys():
		var rec: Dictionary = records[k]
		arr.append(rec)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(arr))
		f.close()

func _derive_packed_path(csv_path: String, fallback: String) -> String:
	var base := csv_path.get_file().get_basename()
	if base != "":
		return "res://data/packed/%s.json" % base
	return fallback

func get_record(role: String) -> Dictionary:
	return records.get(role, {})

func get_value(role: String, key: String, default_val = null):
	var rec: Dictionary = get_record(role)
	if rec.has(key):
		return rec[key]
	return default_val
