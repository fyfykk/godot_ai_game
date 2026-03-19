extends SceneTree

func _init():
	_pack_all()
	quit()

func _pack_all():
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("data/packed")
	_pack_collectibles()
	_pack_upgrades()
	_pack_characters()
	_pack_gameplay_constants()

func _pack_collectibles():
	var f := FileAccess.open("res://data/collectibles.csv", FileAccess.READ)
	if f == null:
		return
	var _header := f.get_line()
	var arr: Array = []
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
			"target": cols[3],
			"type": cols[4],
			"unlock": cols[5],
			"v1": float(cols[6]),
			"v2": float(cols[7]),
			"v3": float(cols[8]),
			"v4": float(cols[9]),
			"v5": float(cols[10]),
			"icon": cols[11],
			"w": w,
			"h": h
		}
		arr.append(rec)
	f.close()
	_write_json("res://data/packed/collectibles.json", arr)

func _pack_upgrades():
	var f := FileAccess.open("res://data/upgrades.csv", FileAccess.READ)
	if f == null:
		return
	var _header := f.get_line()
	var arr: Array = []
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var cols := line.split(",", false)
		if cols.size() < 10:
			continue
		var rec: Dictionary = {
			"id": cols[0],
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
		arr.append(rec)
	f.close()
	_write_json("res://data/packed/upgrades.json", arr)

func _pack_characters():
	var f := FileAccess.open("res://data/characters.csv", FileAccess.READ)
	if f == null:
		return
	var _header := f.get_line()
	var arr: Array = []
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var cols := line.split(",", false)
		if cols.size() < 7:
			continue
		var rec: Dictionary = {
			"role": cols[0],
			"max_hp": int(cols[1]),
			"damage": int(cols[2]),
			"bullet_damage": int(cols[3]),
			"melee_damage": int(cols[4]),
			"magic_damage": int(cols[5]),
			"speed": float(cols[6])
		}
		arr.append(rec)
	f.close()
	_write_json("res://data/packed/characters.json", arr)

func _pack_gameplay_constants():
	var f := FileAccess.open("res://data/gameplay_constants.csv", FileAccess.READ)
	if f == null:
		return
	var _header := f.get_line()
	var arr: Array = []
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
			arr.append({"category": cat, "key": key, "value": val})
	f.close()
	_write_json("res://data/packed/gameplay_constants.json", arr)

func _write_json(path: String, data):
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
