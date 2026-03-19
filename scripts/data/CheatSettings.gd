extends Node

var start_coins: int = 0
var unlock_all: bool = false
var invincible: bool = false
var zero_interact: bool = false
var blood_moon_time: float = 0.0
var LocalPathsScript := preload("res://scripts/data/LocalPaths.gd")

func load():
	var cf := ConfigFile.new()
	var path := LocalPathsScript.file_path("cheats.cfg")
	var err := cf.load(path)
	if err == OK:
		start_coins = int(cf.get_value("cheat", "start_coins", start_coins))
		unlock_all = bool(cf.get_value("cheat", "unlock_all", unlock_all))
		invincible = bool(cf.get_value("cheat", "invincible", invincible))
		zero_interact = bool(cf.get_value("cheat", "zero_interact", zero_interact))
		blood_moon_time = float(cf.get_value("cheat", "blood_moon_time", blood_moon_time))

func save():
	var cf := ConfigFile.new()
	cf.set_value("cheat", "start_coins", start_coins)
	cf.set_value("cheat", "unlock_all", unlock_all)
	cf.set_value("cheat", "invincible", invincible)
	cf.set_value("cheat", "zero_interact", zero_interact)
	cf.set_value("cheat", "blood_moon_time", blood_moon_time)
	cf.save(LocalPathsScript.file_path("cheats.cfg"))
