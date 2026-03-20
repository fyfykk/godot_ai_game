extends Node

var currency: int = 0
var upgrades = {"hp": 0, "dmg": 0, "aspd": 0, "range": 0}
var max_level_unlocked: int = 1
var gacha_tickets: int = 0
var gacha_pity: int = 0
var version: String = "v0.1"
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")

func load():
	var cf := ConfigFile.new()
	var path := LocalPathsScript.file_path("progress.cfg")
	var err := cf.load(path)
	if err == OK:
		currency = int(cf.get_value("progress", "currency", 0))
		upgrades = cf.get_value("progress", "upgrades", upgrades)
		max_level_unlocked = int(cf.get_value("progress", "max_level_unlocked", max_level_unlocked))
		gacha_tickets = int(cf.get_value("progress", "gacha_tickets", gacha_tickets))
		gacha_pity = int(cf.get_value("progress", "gacha_pity", gacha_pity))
		version = str(cf.get_value("progress", "version", version))

func save():
	var cf := ConfigFile.new()
	cf.set_value("progress", "currency", currency)
	cf.set_value("progress", "upgrades", upgrades)
	cf.set_value("progress", "max_level_unlocked", max_level_unlocked)
	cf.set_value("progress", "gacha_tickets", gacha_tickets)
	cf.set_value("progress", "gacha_pity", gacha_pity)
	cf.set_value("progress", "version", version)
	cf.save(LocalPathsScript.file_path("progress.cfg"))

func add_currency(v: int):
	currency += v

func add_gacha_tickets(v: int):
	gacha_tickets = max(0, gacha_tickets + int(v))

func spend_gacha_tickets(v: int) -> bool:
	var cost: int = max(0, int(v))
	if gacha_tickets < cost:
		return false
	gacha_tickets -= cost
	return true

func unlock_level(level_num: int):
	max_level_unlocked = max(max_level_unlocked, int(level_num))
