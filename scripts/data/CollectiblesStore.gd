extends Node

var counts: Dictionary = {}
var total: int = 0
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")

func load():
	var cf := ConfigFile.new()
	var path := LocalPathsScript.file_path("collectibles.cfg")
	var err := cf.load(path)
	if err == OK:
		counts = cf.get_value("coll", "counts", {})
		total = int(cf.get_value("coll", "total", 0))
	else:
		counts = {}
		total = 0

func save():
	var cf := ConfigFile.new()
	cf.set_value("coll", "counts", counts)
	cf.set_value("coll", "total", total)
	cf.save(LocalPathsScript.file_path("collectibles.cfg"))

func add(id: String):
	if not counts.has(id):
		counts[id] = 0
	counts[id] = int(counts[id]) + 1
	total += 1
	save()

func get_count(id: String) -> int:
	return int(counts.get(id, 0))

func get_total() -> int:
	return total
