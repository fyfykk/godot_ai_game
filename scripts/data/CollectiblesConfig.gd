extends Node

var items: Array[Dictionary] = []
var by_id: Dictionary = {}

func load_csv(path: String = "res://data/collectibles.csv"):
	items.clear()
	by_id.clear()
	var packed_path := "res://data/packed/collectibles.json"
	if _should_use_packed(path, packed_path):
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
		var cols := line.split(",", false)
		if cols.size() < 12:
			continue
		var w: int = 1
		var h: int = 1
		if cols.size() >= 14:
			w = int(cols[12])
			h = int(cols[13])
		var rec: Dictionary = {
			"id": cols[0],
			"name": cols[1],
			"rarity": cols[2],
			"target": cols[3], # bullet/melee/magic/none
			"type": cols[4],   # damage/interval/range/radius/none
			"unlock": cols[5], # attack_melee/attack_magic/none
			"v1": float(cols[6]),
			"v2": float(cols[7]),
			"v3": float(cols[8]),
			"v4": float(cols[9]),
			"v5": float(cols[10]),
			"icon": cols[11],
			"w": w,
			"h": h
		}
		var unlock_str: String = String(rec["unlock"])
		var rar_str: String = String(rec["rarity"])
		if unlock_str != "none":
			rec["rarity"] = "red"
		elif rar_str == "red":
			rec["rarity"] = "epic"
		_normalize_collectible_size(rec)
		items.append(rec)
		by_id[rec["id"]] = rec
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
				var unlock_str: String = String(rec.get("unlock", "none"))
				var rar_str: String = String(rec.get("rarity", ""))
				if unlock_str != "none":
					rec["rarity"] = "red"
				elif rar_str == "red":
					rec["rarity"] = "epic"
				if not rec.has("w"):
					rec["w"] = 1
				if not rec.has("h"):
					rec["h"] = 1
				_normalize_collectible_size(rec)
				items.append(rec)
				by_id[String(rec.get("id", ""))] = rec
	return items.size() > 0

func _should_use_packed(csv_path: String, packed_path: String) -> bool:
	if not FileAccess.file_exists(packed_path):
		return false
	if not FileAccess.file_exists(csv_path):
		return true
	var csv_mtime: int = int(FileAccess.get_modified_time(csv_path))
	var packed_mtime: int = int(FileAccess.get_modified_time(packed_path))
	return packed_mtime >= csv_mtime

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

func _normalize_collectible_size(rec: Dictionary):
	var rar: String = String(rec.get("rarity", ""))
	var id: String = String(rec.get("id", ""))
	if rar == "red":
		rec["w"] = 4
		rec["h"] = 4
		return
	var min_w: int = 1
	var max_w: int = 4
	var min_h: int = 1
	var max_h: int = 4
	if rar == "epic":
		min_w = 2
		min_h = 2
		max_w = 4
		max_h = 4
	elif rar == "blue":
		min_w = 2
		min_h = 2
		max_w = 3
		max_h = 3
	else:
		min_w = 1
		min_h = 2
		max_w = 3
		max_h = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = _size_hash(id)
	var target_w: int = rng.randi_range(min_w, max_w)
	var target_h: int = rng.randi_range(min_h, max_h)
	if target_w == 4 and target_h == 4:
		target_h = 3
	if target_w * target_h < 3:
		if target_w == 1:
			target_h = 3
		elif target_h == 1:
			target_w = 3
	rec["w"] = clamp(target_w, 1, 4)
	rec["h"] = clamp(target_h, 1, 4)

func _size_hash(s: String) -> int:
	var h: int = 17
	for i in range(s.length()):
		h = int(h * 31 + s.unicode_at(i))
	return abs(h)

func random_choices(n: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var reds := []
	var normals := []
	for rec in items:
		if String(rec["unlock"]) != "none":
			reds.append(String(rec["id"]))
		else:
			normals.append(String(rec["id"]))
	var res := []
	if rng.randf() < 0.01 and reds.size() > 0:
		var ridx := rng.randi_range(0, reds.size() - 1)
		res.append(reds[ridx])
		reds.remove_at(ridx)
	while res.size() < n and normals.size() > 0:
		var idx := rng.randi_range(0, normals.size() - 1)
		res.append(normals[idx])
		normals.remove_at(idx)
	return res
