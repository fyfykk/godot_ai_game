extends Node

class_name GameplayConstants

var values: Dictionary = {}

func load_csv(path: String = "res://data/gameplay_constants.csv"):
	values.clear()
	var packed_path := _derive_packed_path(path, "res://data/packed/gameplay_constants.json")
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
		var cols := line.split(",", false)
		if cols.size() < 3:
			continue
		var cat := cols[0].strip_edges()
		var key := cols[1].strip_edges()
		var val := cols[2].strip_edges()
		if key != "":
			var composite := "%s.%s" % [cat, key]
			values[composite] = val
			if not values.has(key):
				values[key] = val
	f.close()
	return values.size() > 0

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
				var cat := String(rec.get("category", ""))
				var key := String(rec.get("key", ""))
				var val: String = String(rec.get("value", ""))
				if key != "":
					var composite := "%s.%s" % [cat, key]
					values[composite] = val
					if not values.has(key):
						values[key] = val
	return values.size() > 0

func _write_packed(path: String):
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("data/packed")
	var arr: Array = []
	for k in values.keys():
		var ks := String(k)
		var dot := ks.find(".")
		if dot == -1:
			continue
		var cat := ks.substr(0, dot)
		var key := ks.substr(dot + 1)
		var val: String = String(values[k])
		arr.append({"category": cat, "key": key, "value": val})
	var fw := FileAccess.open(path, FileAccess.WRITE)
	if fw:
		fw.store_string(JSON.stringify(arr))
		fw.close()

func _derive_packed_path(csv_path: String, fallback: String) -> String:
	var base := csv_path.get_file().get_basename()
	if base != "":
		return "res://data/packed/%s.json" % base
	return fallback

func get_string(key: String, default_val: String = "") -> String:
	if values.has(key):
		return String(values[key])
	return default_val

func get_float(key: String, default_val: float = 0.0) -> float:
	if values.has(key):
		return float(values[key])
	return float(default_val)

func get_int(key: String, default_val: int = 0) -> int:
	if values.has(key):
		return int(float(values[key]))
	return int(default_val)
