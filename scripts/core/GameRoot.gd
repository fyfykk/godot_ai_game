extends Node2D

@onready var level = $Level
var player_scene: PackedScene = preload("res://scenes/Player.tscn")
var player
var MetaStoreScript := preload("res://scripts/data/MetaProgressionStore.gd")
var CheatSettingsScript := preload("res://scripts/data/CheatSettings.gd")
var meta_store
@onready var failure_dialog := $UI/FailureDialog
@onready var success_dialog := $UI/SuccessDialog
var game_time: float = 0.0
var max_time: float = 180
var post_interaction_active: bool = false
var post_time: float = 0.0
var post_limit: float = 30.0
var run_ended: bool = false
var run_result: String = "none"
var run_coins: int = 0
var run_collectibles: int = 0
var CollConfigScript := preload("res://scripts/data/CollectiblesConfig.gd")
var CollStoreScript := preload("res://scripts/data/CollectiblesStore.gd")
var CharConfigScript := preload("res://scripts/data/CharactersConfig.gd")
var UpgConfigScript := preload("res://scripts/data/UpgradeConfig.gd")
var ConstScript := preload("res://scripts/data/GameplayConstants.gd")
var RarityScript := preload("res://scripts/data/Rarity.gd")
var coll_config
var coll_store
var char_config
var upg_config
var gameplay_consts
var equipment_store
var equipment_config
var run_bag: Array[String] = []
const BAG_GRID_W_DEFAULT: int = 5
const BAG_GRID_H_DEFAULT: int = 4
const BAG_GRID_W_EXPANDED: int = 6
const BAG_GRID_H_EXPANDED: int = 6
const BAG_EXPAND_UNLOCK: String = "bag_expand"
const RUN_TICKET_ID: String = "ticket"
var bag_grid_w: int = BAG_GRID_W_DEFAULT
var bag_grid_h: int = BAG_GRID_H_DEFAULT
var bag_items: Array[Dictionary] = []
var bag_next_uid: int = 1
var bag_icon_cache: Dictionary = {}
var run_collectible_target: int = 0
var run_collectible_drops: int = 0
var run_coin_total: int = 0
const RUN_COIN_CAP: int = 150
var run_coin_cap: int = RUN_COIN_CAP
var base_run_coin_cap: int = RUN_COIN_CAP
var run_collectible_planned: int = 0
var run_coin_reserved: int = 0
var chest_loot_initialized: bool = false
var fail_keep_id: String = ""
var run_level_index: int = 0
var run_seed: int = 0
var input_locked: bool = false
var run_note_drops: Dictionary = {}
var cheat_settings
var cheat_invincible: bool = false
var cheat_zero_interact: bool = false
var cheat_start_coins: int = 0
var cheat_blood_moon_time: float = 0.0

func _ready():
	meta_store = MetaStoreScript.new()
	meta_store.load()
	cheat_settings = CheatSettingsScript.new()
	cheat_settings.load()
	cheat_invincible = bool(cheat_settings.invincible)
	cheat_zero_interact = bool(cheat_settings.zero_interact)
	cheat_start_coins = int(cheat_settings.start_coins)
	cheat_blood_moon_time = float(cheat_settings.blood_moon_time)
	coll_config = CollConfigScript.new()
	coll_config.load_csv()
	coll_store = CollStoreScript.new()
	coll_store.load()
	char_config = CharConfigScript.new()
	char_config.load_csv()
	upg_config = UpgConfigScript.new()
	upg_config.load_csv()
	gameplay_consts = ConstScript.new()
	gameplay_consts.load_csv()
	equipment_store = get_tree().get_root().get_node_or_null("EquipmentStore")
	equipment_config = get_tree().get_root().get_node_or_null("EquipmentConfig")
	max_time = get_const_float("core.run_max_time", max_time)
	if cheat_blood_moon_time > 0.0:
		max_time = cheat_blood_moon_time
	post_limit = get_const_float("core.post_interaction_time", post_limit)
	base_run_coin_cap = get_const_int("core.run_coin_cap", RUN_COIN_CAP)
	run_coin_cap = base_run_coin_cap
	run_coins = cheat_start_coins
	if failure_dialog:
		failure_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if failure_dialog.has_method("get_ok_button"):
			var okb = failure_dialog.get_ok_button()
			if okb:
				okb.disabled = false
		if failure_dialog.has_method("set"):
			failure_dialog.borderless = true
		failure_dialog.size = Vector2(480, 420)
	if success_dialog:
		success_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if success_dialog.has_method("get_ok_button"):
			var okb2 = success_dialog.get_ok_button()
			if okb2:
				okb2.disabled = false
		if success_dialog.has_method("set"):
			success_dialog.borderless = true
		success_dialog.size = Vector2(480, 420)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var seed_min: int = get_const_int("core.run_seed_min", 1)
	var seed_max: int = get_const_int("core.run_seed_max", 2147483000)
	run_seed = rng.randi_range(seed_min, seed_max)
	var coll_min: int = get_const_int("core.run_collectible_target_min", 3)
	var coll_max: int = get_const_int("core.run_collectible_target_max", 6)
	run_collectible_target = rng.randi_range(coll_min, coll_max)
	run_note_drops = {}
	var run_mode: String = "game"
	var level_seed: int = 0
	var editor_new: bool = false
	var use_custom_map_index: int = -1
	var editor_custom_index: int = -1
	if get_tree().has_meta("run_mode"):
		run_mode = String(get_tree().get_meta("run_mode"))
		get_tree().remove_meta("run_mode")
	if get_tree().has_meta("level_seed"):
		level_seed = int(get_tree().get_meta("level_seed"))
		get_tree().remove_meta("level_seed")
	if get_tree().has_meta("editor_new"):
		editor_new = bool(get_tree().get_meta("editor_new"))
		get_tree().remove_meta("editor_new")
	if get_tree().has_meta("use_custom_map_index"):
		use_custom_map_index = int(get_tree().get_meta("use_custom_map_index"))
		get_tree().remove_meta("use_custom_map_index")
	if get_tree().has_meta("editor_custom_index"):
		editor_custom_index = int(get_tree().get_meta("editor_custom_index"))
		get_tree().remove_meta("editor_custom_index")
	if get_tree().has_meta("level_index"):
		run_level_index = int(get_tree().get_meta("level_index"))
		get_tree().remove_meta("level_index")
	if run_mode == "editor":
		get_tree().paused = false
		if level and level.has_method("set_editor_custom_index"):
			level.set_editor_custom_index(editor_custom_index)
		if level and level.has_method("set_editor_enabled"):
			level.set_editor_enabled(true)
		if editor_new:
			if level and level.has_method("editor_new_blank"):
				level.editor_new_blank()
		else:
			var loaded := false
			if editor_custom_index >= 0 and level and level.has_method("load_custom_map"):
				level.load_custom_map(editor_custom_index)
				loaded = true
			elif run_level_index > 0 and level and level.has_method("load_base_map"):
				loaded = bool(level.load_base_map(run_level_index - 1))
			elif level and level.has_method("editor_load_if_exists"):
				level.editor_load_if_exists()
				loaded = true
			if not loaded:
				if level and level.has_method("set_level_seed"):
					level.set_level_seed(level_seed)
				level.generate()
				if run_level_index > 0 and level and level.has_method("save_base_map"):
					level.call("save_base_map", run_level_index - 1)
		var sp := level.get_node_or_null("EnemySpawner")
		if sp and sp.has_method("set_process"):
			sp.set_process(false)
		var ui := get_node_or_null("UI")
		if ui:
			ui.visible = false
			ui.process_mode = Node.PROCESS_MODE_DISABLED
		return
	print("RunMode: %s use_custom_map_index=%d level_index=%d" % [run_mode, use_custom_map_index, run_level_index])
	var map_loaded: bool = false
	if use_custom_map_index >= 0 and level and level.has_method("load_custom_map"):
		map_loaded = bool(level.load_custom_map(use_custom_map_index))
	elif run_level_index > 0 and level and level.has_method("load_base_map"):
		map_loaded = bool(level.load_base_map(run_level_index - 1))
	if not map_loaded:
		if level and level.has_method("set_level_seed"):
			level.set_level_seed(level_seed)
		level.generate()
		if use_custom_map_index < 0 and run_level_index > 0 and level and level.has_method("save_base_map"):
			level.call("save_base_map", run_level_index - 1)
	spawn_player()

func _process(_delta):
	if run_ended:
		return
	game_time = min(game_time + _delta, max_time)
	if post_interaction_active and not run_ended:
		post_time = min(post_time + _delta, post_limit)
		if post_time >= post_limit:
			on_exit()

func spawn_player():
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = level.get_spawn_position()
	if player.has_signal("died"):
		player.connect("died", Callable(self, "_on_player_died"))
	_apply_base_character_stats()
	_apply_start_unlocks()
	_apply_start_effects()

func request_upgrade_choice(p: Node2D) -> bool:
	return _try_show_upgrade_choice(p)

func _try_show_upgrade_choice(p: Node2D = null) -> bool:
	var ui := get_node_or_null("UI")
	if ui == null:
		return false
	var target: Node2D = p if p != null else player
	if target == null:
		return false
	if ui.has_method("show_upgrade_choices"):
		return bool(ui.call("show_upgrade_choices", target))
	return false

func on_exit():
	if run_ended:
		return
	_close_active_puzzles()
	run_ended = true
	run_result = "success"
	meta_store.add_currency(level.get_run_reward())
	meta_store.save()
	if success_dialog:
		var counts: Dictionary = {}
		for id in run_bag:
			if not counts.has(id):
				counts[id] = 0
			counts[id] = int(counts[id]) + 1
		if not counts.has(RUN_TICKET_ID):
			counts[RUN_TICKET_ID] = 0
		counts[RUN_TICKET_ID] = int(counts[RUN_TICKET_ID]) + 1
		var txt := "到达出口，胜利！\n本局获得的收藏品："
		success_dialog.dialog_text = ""
		_update_collectible_dialog(success_dialog, counts, "", txt)
		success_dialog.popup_centered()
		get_tree().paused = true
		success_dialog.confirmed.connect(_on_success_confirmed)

func _on_player_died():
	if run_ended:
		return
	_close_active_puzzles()
	run_ended = true
	run_result = "fail"
	post_interaction_active = false
	if failure_dialog:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		fail_keep_id = ""
		if run_bag.size() > 0:
			var idx := rng.randi_range(0, run_bag.size() - 1)
			fail_keep_id = String(run_bag[idx])
		var counts: Dictionary = {}
		for id in run_bag:
			if not counts.has(id):
				counts[id] = 0
			counts[id] = int(counts[id]) + 1
		var txt := "你失败了\n本局获得的收藏品："
		failure_dialog.dialog_text = ""
		_update_collectible_dialog(failure_dialog, counts, fail_keep_id, txt)
		get_tree().paused = true
		failure_dialog.popup_centered()
		failure_dialog.confirmed.connect(_on_fail_confirmed)

func _on_fail_confirmed():
	if fail_keep_id != "":
		var rec: Dictionary = coll_config.get_item(fail_keep_id) if coll_config else {}
		var unlock := String(rec.get("unlock", "none"))
		if unlock != BAG_EXPAND_UNLOCK:
			coll_store.add(fail_keep_id)
		fail_keep_id = ""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_success_confirmed():
	for id in run_bag:
		coll_store.add(String(id))
	run_bag.clear()
	if run_level_index > 0:
		meta_store.unlock_level(run_level_index + 1)
	meta_store.add_gacha_tickets(1)
	meta_store.save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _close_active_puzzles():
	for p in get_tree().get_nodes_in_group("puzzle"):
		if p and p.has_method("close_forced"):
			p.call("close_forced")
		elif p:
			p.queue_free()

func get_game_time() -> float:
	return game_time

func get_max_time() -> float:
	return max_time

func set_input_locked(v: bool):
	input_locked = v

func is_input_locked() -> bool:
	return input_locked
func is_cheat_invincible() -> bool:
	return cheat_invincible
func is_zero_interact() -> bool:
	return cheat_zero_interact
func is_post_interaction_active() -> bool:
	return post_interaction_active
func get_post_time() -> float:
	return post_time
func get_post_limit() -> float:
	return post_limit
func add_run_coins(v: int):
	run_coins += int(v)
func spend_run_coins(v: int) -> int:
	var need: int = max(int(v), 0)
	var spent: int = min(run_coins, need)
	run_coins -= spent
	return spent
func add_collectible(v: int, p: Node2D) -> bool:
	if p == null:
		return false
	var ui := get_node("UI")
	if ui and ui.has_method("is_choice_active") and bool(ui.call("is_choice_active")):
		return false
	if ui and ui.has_method("show_collectible_choices"):
		var opts: Array = _random_choices_with_probs(0.04, 0.15, 3)
		ui.call("show_collectible_choices", p, opts)
		return true
	return false

func add_boss_collectible(p: Node2D) -> bool:
	if p == null:
		return false
	var ui := get_node("UI")
	if ui and ui.has_method("is_choice_active") and bool(ui.call("is_choice_active")):
		return false
	if ui and ui.has_method("show_collectible_choices"):
		var opts: Array = _random_choices_with_red_prob(0.2, 3)
		ui.call("show_collectible_choices", p, opts)
		return true
	return false
func get_run_coins() -> int:
	return run_coins
func get_collectibles_count() -> int:
	return int(coll_store.get_total())

func get_run_bag_count() -> int:
	return int(run_bag.size())

func apply_collectible_selection(id: String, p: Node2D) -> bool:
	if id == null or id == "":
		return false
	if is_collectible_capped(id):
		return false
	if not try_add_collectible_to_bag(String(id)):
		var drop_pos := Vector2.ZERO
		if p and p is Node2D:
			drop_pos = (p as Node2D).global_position
		else:
			drop_pos = get_player_global_position()
		_spawn_collectible_pickup(String(id), drop_pos)
		return true
	run_collectible_drops += 1
	var rec: Dictionary = coll_config.get_item(id)
	if rec == null or rec.size() == 0:
		return true
	return true

func add_collectible_direct(id: String) -> bool:
	if id == null or id == "":
		return false
	if is_collectible_capped(id):
		return false
	if not try_add_collectible_to_bag(String(id)):
		return false
	run_collectible_drops += 1
	if id.begins_with("W"):
		run_note_drops[id] = true
	var rec: Dictionary = coll_config.get_item(id)
	if rec != null and rec.size() > 0:
		var unlock := String(rec.get("unlock", "none"))
	return true

func get_bag_grid_size() -> Vector2i:
	return Vector2i(bag_grid_w, bag_grid_h)

func get_bag_items() -> Array:
	return bag_items.duplicate(true)

func get_collectible_size(id: String) -> Vector2i:
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	var w: int = int(rec.get("w", 1))
	var h: int = int(rec.get("h", 1))
	return Vector2i(max(1, w), max(1, h))

func _get_item_size(item: Dictionary, rot_override: int = -1) -> Vector2i:
	var rot: int = int(item.get("rot", 0)) if rot_override < 0 else rot_override
	var w: int = int(item.get("w", 1))
	var h: int = int(item.get("h", 1))
	if rot % 2 == 1:
		return Vector2i(h, w)
	return Vector2i(w, h)

func _is_space_free(x: int, y: int, w: int, h: int, ignore_uid: int = -1) -> bool:
	if x < 0 or y < 0 or x + w > bag_grid_w or y + h > bag_grid_h:
		return false
	for it in bag_items:
		var uid: int = int(it.get("uid", -1))
		if ignore_uid >= 0 and uid == ignore_uid:
			continue
		var pos_x: int = int(it.get("x", 0))
		var pos_y: int = int(it.get("y", 0))
		var sz := _get_item_size(it)
		var iw: int = int(sz.x)
		var ih: int = int(sz.y)
		if x < pos_x + iw and x + w > pos_x and y < pos_y + ih and y + h > pos_y:
			return false
	return true

func _find_space_for_size(w: int, h: int) -> Vector2i:
	for y in range(bag_grid_h - h + 1):
		for x in range(bag_grid_w - w + 1):
			if _is_space_free(x, y, w, h):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func try_add_collectible_to_bag(id: String) -> bool:
	var sz := get_collectible_size(id)
	var pos := _find_space_for_size(sz.x, sz.y)
	var rot := 0
	if pos.x < 0 and sz.x != sz.y:
		pos = _find_space_for_size(sz.y, sz.x)
		if pos.x >= 0:
			rot = 1
	if pos.x < 0:
		return false
	var item := {
		"uid": bag_next_uid,
		"id": id,
		"x": int(pos.x),
		"y": int(pos.y),
		"w": int(sz.x),
		"h": int(sz.y),
		"rot": rot
	}
	bag_next_uid += 1
	bag_items.append(item)
	run_bag.append(id)
	return true

func move_bag_item(uid: int, x: int, y: int, rot: int) -> bool:
	for it in bag_items:
		if int(it.get("uid", -1)) == uid:
			var sz := _get_item_size(it, rot)
			if not _is_space_free(x, y, int(sz.x), int(sz.y), uid):
				return false
			it["x"] = x
			it["y"] = y
			it["rot"] = rot
			return true
	return false

func auto_pack_bag():
	var items := bag_items.duplicate(true)
	items.sort_custom(Callable(self, "_bag_sort"))
	bag_items.clear()
	for it in items:
		var base_w: int = int(it.get("w", 1))
		var base_h: int = int(it.get("h", 1))
		var pos := _find_space_for_size(base_w, base_h)
		var rot := 0
		if pos.x < 0 and base_w != base_h:
			pos = _find_space_for_size(base_h, base_w)
			if pos.x >= 0:
				rot = 1
		if pos.x < 0:
			pos = Vector2i(0, 0)
		var new_it: Dictionary = it.duplicate(true)
		new_it["x"] = int(pos.x)
		new_it["y"] = int(pos.y)
		new_it["rot"] = rot
		bag_items.append(new_it)

func _bag_sort(a: Dictionary, b: Dictionary) -> bool:
	var aw: int = int(a.get("w", 1))
	var ah: int = int(a.get("h", 1))
	var bw: int = int(b.get("w", 1))
	var bh: int = int(b.get("h", 1))
	return aw * ah > bw * bh

func drop_bag_item(uid: int, pos: Vector2) -> bool:
	for i in range(bag_items.size()):
		var it: Dictionary = bag_items[i]
		if int(it.get("uid", -1)) == uid:
			var id: String = String(it.get("id", ""))
			bag_items.remove_at(i)
			for j in range(run_bag.size()):
				if String(run_bag[j]) == id:
					run_bag.remove_at(j)
					break
			_spawn_collectible_pickup(id, pos)
			return true
	return false

func get_player_global_position() -> Vector2:
	if player and player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO

func get_random_password_note_id() -> String:
	var ids := ["W001", "W002", "W003", "W004"]
	var avail := []
	for id in ids:
		if not is_collectible_capped(id):
			avail.append(id)
	if avail.size() == 0:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return String(avail[rng.randi_range(0, avail.size() - 1)])

func get_best_collectible_drop() -> String:
	if coll_config == null:
		return ""
	var by_rarity := {"red": [], "epic": [], "blue": []}
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		if rec == null:
			continue
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		if is_collectible_capped(id):
			continue
		var rar := String(rec.get("rarity", "blue"))
		if rar == "white":
			continue
		if not by_rarity.has(rar):
			continue
		by_rarity[rar].append(id)
	var order := ["red", "epic", "blue"]
	for r in order:
		var arr: Array = by_rarity.get(r, [])
		if arr.size() > 0:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			return String(arr[rng.randi_range(0, arr.size() - 1)])
	return ""

func has_available_collectible_choice() -> bool:
	if coll_config == null:
		return false
	return _get_available_collectible_ids(true).size() > 0

func _get_available_collectible_ids(include_white: bool) -> Array:
	if coll_config == null:
		return []
	var res := []
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		if rec == null:
			continue
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		var target := String(rec.get("target", "none"))
		if target != "none" and not _has_equipped_target(target):
			continue
		var rar := String(rec.get("rarity", "blue"))
		if not include_white and rar == "white":
			continue
		if not is_collectible_capped(id):
			res.append(id)
	return res

func get_collectible_choices_with_note_prob(note_prob: float = 0.5) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var base: Array = _random_choices_with_probs(0.04, 0.15, 3)
	var note_id: String = get_random_password_note_id()
	var non_white := _get_available_collectible_ids(false)
	var should_include: bool = false
	if note_id != "" and rng.randf() < note_prob:
		should_include = true
	if note_id != "" and non_white.size() == 0:
		should_include = true
	if should_include:
		if base.size() == 0:
			base.append(note_id)
		else:
			var idx := rng.randi_range(0, base.size() - 1)
			base[idx] = note_id
	var pool := _get_available_collectible_ids(false)
	while base.size() < 3 and pool.size() > 0:
		var j := rng.randi_range(0, pool.size() - 1)
		base.append(pool[j])
		pool.remove_at(j)
	while base.size() < 3 and base.size() > 0:
		base.append(base[rng.randi_range(0, base.size() - 1)])
	return base

func add_collectible_with_note(p: Node2D, note_prob: float = 0.5) -> bool:
	if p == null:
		return false
	var ui := get_node("UI")
	if ui and ui.has_method("is_choice_active") and bool(ui.call("is_choice_active")):
		return false
	if ui and ui.has_method("show_collectible_choices"):
		var opts: Array = get_collectible_choices_with_note_prob(note_prob)
		ui.call("show_collectible_choices", p, opts)
		return true
	return false

func _get_collectible_cap(id: String) -> int:
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	if rec == null or rec.size() == 0:
		return 5
	var unlock := String(rec.get("unlock", "none"))
	if unlock != "none":
		return 1
	var rar := String(rec.get("rarity", "blue"))
	if rar == "white":
		return 1
	return 5

func _get_run_bag_count_for(id: String) -> int:
	var cnt: int = 0
	for v in run_bag:
		if String(v) == id:
			cnt += 1
	return cnt

func is_collectible_capped(id: String) -> bool:
	if coll_store == null:
		return false
	var base: int = int(coll_store.get_count(id))
	var extra: int = _get_run_bag_count_for(id)
	return base + extra >= _get_collectible_cap(id)

func _apply_collectible_effect(p: Node2D, target: String, typ: String, val: float):
	if p == null:
		return
	if target != "none" and not _has_equipped_target(target):
		return
	var mods = p.get("attack_modules")
	if mods == null:
		return
	for m in mods:
		if m == null or not m.has_method("get_display_name"):
			continue
		var name: String = m.get_display_name()
		var ok := (target == "bullet" and name == "子弹攻击") or (target == "melee" and name == "近战攻击") or (target == "magic" and name == "范围魔法") or (target == "roar" and name == "龙咆哮")
		if not ok:
			continue
		if typ == "damage":
			var cur = m.get("damage")
			if cur != null:
				m.upgrade({"damage": int(cur) + int(val)})
		elif typ == "interval":
			var cur_i = m.get("interval")
			if cur_i != null:
				m.upgrade({"interval": max(float(cur_i) + float(val), 0.1)})
		elif typ == "range":
			var cur_r = m.get("range")
			if cur_r != null:
				m.upgrade({"range": float(cur_r) + float(val)})
		elif typ == "radius":
			var cur_rd = m.get("radius")
			if cur_rd != null:
				m.upgrade({"radius": float(cur_rd) + float(val)})

func get_collectible_name(id: String) -> String:
	if id == RUN_TICKET_ID:
		return "抽奖券"
	var rec: Dictionary = coll_config.get_item(id)
	if rec == null or rec.size() == 0:
		return id
	return String(rec["name"])

func get_collectible_rarity(id: String) -> String:
	if id == RUN_TICKET_ID:
		return "blue"
	var rec: Dictionary = coll_config.get_item(id)
	if rec == null or rec.size() == 0:
		return ""
	return String(rec["rarity"])

func get_collectible_icon_texture(id: String, w: int, h: int) -> Texture2D:
	if id == "":
		return null
	if id == RUN_TICKET_ID:
		return _build_ticket_icon_texture(w, h)
	var key := "%s_%d_%d" % [id, w, h]
	if bag_icon_cache.has(key):
		return bag_icon_cache[key]
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	var icon_key := String(rec.get("icon", ""))
	var rar := String(rec.get("rarity", ""))
	var gw: int = int(rec.get("w", 1))
	var gh: int = int(rec.get("h", 1))
	var tex := _build_collectible_icon(icon_key, rar, w, h, gw, gh)
	bag_icon_cache[key] = tex
	return tex

func _build_ticket_icon_texture(w: int, h: int) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var base := Color(0.25, 0.55, 1.0, 1.0)
	var dark := Color(0.12, 0.28, 0.6, 1.0)
	var light := Color(0.7, 0.88, 1.0, 1.0)
	for y in range(th):
		for x in range(tw):
			var border := x == 0 or y == 0 or x == tw - 1 or y == th - 1
			if border:
				img.set_pixel(x, y, dark)
			else:
				img.set_pixel(x, y, base)
	var cut_r: float = min(tw, th) * 0.18
	var cy: float = th * 0.5
	var left_cx: float = 0.0
	var right_cx: float = float(tw - 1)
	for y in range(th):
		for x in range(tw):
			var dl: float = sqrt((float(x) - left_cx) * (float(x) - left_cx) + (float(y) - cy) * (float(y) - cy))
			var dr: float = sqrt((float(x) - right_cx) * (float(x) - right_cx) + (float(y) - cy) * (float(y) - cy))
			if dl < cut_r or dr < cut_r:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var stripe_h: int = max(2, int(round(th * 0.2)))
	var stripe_y: int = int(round(th * 0.2))
	for y in range(stripe_h):
		for x in range(2, tw - 2):
			var py := stripe_y + y
			if py >= 0 and py < th:
				img.set_pixel(x, py, light)
	return ImageTexture.create_from_image(img)

func get_collectible_icon_texture_filled(id: String, w: int, h: int) -> Texture2D:
	if id == "":
		return null
	var key := "%s_%d_%d_filled" % [id, w, h]
	if bag_icon_cache.has(key):
		return bag_icon_cache[key]
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	var icon_key := String(rec.get("icon", ""))
	var rar := String(rec.get("rarity", ""))
	var gw: int = int(rec.get("w", 1))
	var gh: int = int(rec.get("h", 1))
	var tex := _build_collectible_icon(icon_key, rar, w, h, gw, gh, 0.0, true)
	bag_icon_cache[key] = tex
	return tex

func get_collectible_icon_texture_bag(id: String, w: int, h: int, rot: int = 0) -> Texture2D:
	if id == "":
		return null
	var key := "%s_%d_%d_bag_%d" % [id, w, h, rot]
	if bag_icon_cache.has(key):
		return bag_icon_cache[key]
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	var icon_key := String(rec.get("icon", ""))
	var rar := String(rec.get("rarity", ""))
	var gw: int = int(rec.get("w", 1))
	var gh: int = int(rec.get("h", 1))
	var build_w: int = w
	var build_h: int = h
	if rot % 2 == 1:
		build_w = h
		build_h = w
	var tex := _build_collectible_icon(icon_key, rar, build_w, build_h, gw, gh, 0.0, true, "codex", true)
	if tex and rot % 2 == 1:
		var img: Image = tex.get_image()
		if img:
			img.rotate_90(CLOCKWISE)
			if img.get_width() != w or img.get_height() != h:
				img.resize(w, h, Image.INTERPOLATE_NEAREST)
			tex = ImageTexture.create_from_image(img)
	bag_icon_cache[key] = tex
	return tex

func get_collectible_art_texture_bag(id: String, w: int, h: int, rot: int = 0) -> Texture2D:
	if id == "":
		return null
	var key := "%s_%d_%d_art_%d" % [id, w, h, rot]
	if bag_icon_cache.has(key):
		return bag_icon_cache[key]
	var rec: Dictionary = coll_config.get_item(id) if coll_config else {}
	var icon_key := String(rec.get("icon", ""))
	var rar := String(rec.get("rarity", ""))
	var build_w: int = w
	var build_h: int = h
	if rot % 2 == 1:
		build_w = h
		build_h = w
	var tex := _build_collectible_art(icon_key, rar, build_w, build_h, true)
	if tex and rot % 2 == 1:
		var img: Image = tex.get_image()
		if img:
			img.rotate_90(CLOCKWISE)
			if img.get_width() != w or img.get_height() != h:
				img.resize(w, h, Image.INTERPOLATE_NEAREST)
			tex = ImageTexture.create_from_image(img)
	bag_icon_cache[key] = tex
	return tex

func _build_collectible_icon(icon_key: String, rarity: String, w: int, h: int, grid_w: int, grid_h: int, pad_ratio: float = 0.08, fill_art: bool = false, bg_style: String = "grid", bg_full: bool = false) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base: Color = RarityScript.color(rarity) if RarityScript else Color(0.6, 0.6, 0.6, 1.0)
	var bg1 := base.darkened(0.45)
	var bg2 := base.darkened(0.25)
	var line := base.lightened(0.1)
	var edge := Color(0.05, 0.05, 0.07, 1.0)
	var gw: int = int(max(1, grid_w))
	var gh: int = int(max(1, grid_h))
	var pad: int = 0
	if pad_ratio > 0.0:
		pad = max(2, int(min(tw, th) * pad_ratio))
	var cell: int = int(floor(min(float(tw - pad * 2) / float(gw), float(th - pad * 2) / float(gh))))
	if cell < 2:
		cell = 2
	var grid_px_w: int = cell * gw
	var grid_px_h: int = cell * gh
	var gx0: int = int((tw - grid_px_w) / 2)
	var gy0: int = int((th - grid_px_h) / 2)
	if bg_style == "codex":
		if bg_full:
			_draw_flat_background(img, 0, 0, tw, th, Color(0, 0, 0, 0.1), base, 2)
		else:
			_draw_flat_background(img, gx0, gy0, grid_px_w, grid_px_h, Color(0, 0, 0, 0.1), base, 2)
	else:
		_draw_grid_background(img, gx0, gy0, gw, gh, cell, bg1, bg2, line, edge)
	var logical: int = 16
	var art_w: int = grid_px_w if fill_art else int(floor(min(float(grid_px_w), float(grid_px_h)) / float(logical))) * logical
	var art_h: int = grid_px_h if fill_art else art_w
	if art_w < 1:
		art_w = logical
	if art_h < 1:
		art_h = logical
	var ax: int = gx0 + int((grid_px_w - art_w) / 2)
	var ay: int = gy0 + int((grid_px_h - art_h) / 2)
	var art_img := Image.create(logical, logical, false, Image.FORMAT_RGBA8)
	art_img.fill(Color(0, 0, 0, 0))
	_draw_icon_art(art_img, icon_key, 0, 0, 1, base)
	if art_w != logical or art_h != logical:
		art_img.resize(art_w, art_h, Image.INTERPOLATE_NEAREST)
	img.blit_rect(art_img, Rect2i(0, 0, art_img.get_width(), art_img.get_height()), Vector2i(ax, ay))
	return ImageTexture.create_from_image(img)

func _draw_flat_background(img: Image, x0: int, y0: int, w: int, h: int, fill: Color, border: Color, bw: int):
	_fill_rect(img, x0, y0, w, h, fill)
	var t: int = max(1, bw)
	for i in range(t):
		_stroke_rect(img, x0 + i, y0 + i, w - i * 2, h - i * 2, border)

func _build_collectible_art(icon_key: String, rarity: String, w: int, h: int, fill_art: bool = false) -> Texture2D:
	var tw: int = max(1, w)
	var th: int = max(1, h)
	var img := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base: Color = RarityScript.color(rarity) if RarityScript else Color(0.6, 0.6, 0.6, 1.0)
	var logical: int = 16
	var art_w: int = tw if fill_art else min(tw, th)
	var art_h: int = th if fill_art else min(tw, th)
	var ax: int = int((tw - art_w) / 2)
	var ay: int = int((th - art_h) / 2)
	var art_img := Image.create(logical, logical, false, Image.FORMAT_RGBA8)
	art_img.fill(Color(0, 0, 0, 0))
	_draw_icon_art(art_img, icon_key, 0, 0, 1, base)
	if art_w != logical or art_h != logical:
		art_img.resize(art_w, art_h, Image.INTERPOLATE_NEAREST)
	img.blit_rect(art_img, Rect2i(0, 0, art_img.get_width(), art_img.get_height()), Vector2i(ax, ay))
	return ImageTexture.create_from_image(img)

func _draw_grid_background(img: Image, x0: int, y0: int, gw: int, gh: int, cell: int, c1: Color, c2: Color, line: Color, edge: Color):
	for gy in range(gh):
		for gx in range(gw):
			var px := x0 + gx * cell
			var py := y0 + gy * cell
			var fill := c1 if ((gx + gy) % 2) == 0 else c2
			_fill_rect(img, px, py, cell, cell, fill)
			_stroke_rect(img, px, py, cell, cell, line)
	_stroke_rect(img, x0, y0, gw * cell, gh * cell, edge)

func _draw_icon_art(img: Image, icon_key: String, ox: int, oy: int, s: int, rarity_col: Color):
	var key := icon_key.to_lower()
	var kind := _icon_kind(key)
	var badge := _icon_badge(key)
	var metal := Color(0.68, 0.7, 0.72, 1.0)
	var dark := Color(0.2, 0.22, 0.25, 1.0)
	var wood := Color(0.55, 0.32, 0.16, 1.0)
	var gold := Color(0.9, 0.78, 0.25, 1.0)
	var blue := Color(0.25, 0.65, 0.95, 1.0)
	var purple := Color(0.6, 0.35, 0.8, 1.0)
	var red := Color(0.9, 0.25, 0.22, 1.0)
	var paper := Color(0.9, 0.85, 0.76, 1.0)
	var ink := Color(0.35, 0.3, 0.25, 1.0)
	if kind == "crest_warrior":
		_draw_rect_px(img, ox, oy, s, 4, 3, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 6, dark)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 8, gold)
		_draw_rect_px(img, ox, oy, s, 6, 11, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 7, 12, 2, 2, red)
	elif kind == "crest_mage":
		_draw_rect_px(img, ox, oy, s, 4, 3, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 6, dark)
		_draw_ring_px(img, ox, oy, s, 8, 7, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 4, 1, 6, blue)
		_draw_rect_px(img, ox, oy, s, 7, 12, 2, 2, purple)
	elif kind == "purple_mag":
		_draw_rect_px(img, ox, oy, s, 4, 4, 6, 9, purple)
		_draw_rect_px(img, ox, oy, s, 4, 3, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 13, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 9, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 6, 2, 2, 1, purple.lightened(0.2))
	elif kind == "purple_blade":
		_draw_rect_px(img, ox, oy, s, 7, 2, 2, 8, purple)
		_draw_rect_px(img, ox, oy, s, 6, 1, 4, 1, purple)
		_draw_rect_px(img, ox, oy, s, 5, 10, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
		_draw_rect_px(img, ox, oy, s, 8, 4, 1, 1, purple.lightened(0.25))
	elif kind == "purple_seal":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, purple)
		_draw_ring_px(img, ox, oy, s, 8, 8, 4, blue)
		_draw_rect_px(img, ox, oy, s, 6, 8, 4, 1, blue)
		_draw_rect_px(img, ox, oy, s, 8, 6, 1, 4, blue)
	elif kind == "metronome":
		_draw_rect_px(img, ox, oy, s, 6, 3, 4, 9, wood)
		_draw_rect_px(img, ox, oy, s, 5, 2, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 6, metal)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 9, 6, 1, 1, gold)
	elif kind == "hourglass":
		_draw_rect_px(img, ox, oy, s, 5, 3, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 6, 4, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 6, 2, 4, dark)
	elif kind == "hourglass_mage":
		_draw_rect_px(img, ox, oy, s, 5, 3, 6, 1, blue)
		_draw_rect_px(img, ox, oy, s, 5, 12, 6, 1, blue)
		_draw_rect_px(img, ox, oy, s, 6, 4, 4, 2, blue)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 2, blue)
		_draw_rect_px(img, ox, oy, s, 7, 6, 2, 4, purple)
	elif kind == "seal":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, paper)
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 11, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 8, ink)
		_draw_rect_px(img, ox, oy, s, 11, 4, 1, 8, ink)
		_draw_ring_px(img, ox, oy, s, 8, 8, 3, red)
	elif kind == "bag_core":
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 8, metal)
		_draw_rect_px(img, ox, oy, s, 5, 5, 6, 6, dark)
		_draw_rect_px(img, ox, oy, s, 6, 6, 4, 4, blue)
		_draw_rect_px(img, ox, oy, s, 7, 7, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 6, 3, 4, 1, gold)
	elif kind == "blade":
		_draw_rect_px(img, ox, oy, s, 5, 4, 6, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 5, 4, 5, metal)
		_draw_rect_px(img, ox, oy, s, 7, 10, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 14, 4, 1, dark)
	elif kind == "mag":
		_draw_rect_px(img, ox, oy, s, 4, 4, 6, 9, metal)
		_draw_rect_px(img, ox, oy, s, 4, 3, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 13, 6, 1, dark)
		_draw_rect_px(img, ox, oy, s, 4, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 9, 4, 1, 9, dark)
		_draw_rect_px(img, ox, oy, s, 5, 2, 1, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 2, 1, 1, gold)
		_draw_rect_px(img, ox, oy, s, 9, 2, 1, 1, gold)
	elif kind == "scope":
		_draw_ring_px(img, ox, oy, s, 8, 8, 5, blue)
		_draw_rect_px(img, ox, oy, s, 8, 3, 1, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 10, 1, 3, blue)
		_draw_rect_px(img, ox, oy, s, 3, 8, 3, 1, blue)
		_draw_rect_px(img, ox, oy, s, 10, 8, 3, 1, blue)
	elif kind == "bolt":
		_draw_rect_px(img, ox, oy, s, 9, 2, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 8, 6, 2, 3, gold)
		_draw_rect_px(img, ox, oy, s, 6, 9, 2, 2, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 2, gold)
	elif kind == "orb":
		_draw_ring_px(img, ox, oy, s, 8, 8, 5, purple)
		_draw_ring_px(img, ox, oy, s, 8, 8, 3, blue)
		_draw_rect_px(img, ox, oy, s, 8, 8, 1, 1, blue)
	elif kind == "spear":
		_draw_rect_px(img, ox, oy, s, 7, 1, 2, 10, metal)
		_draw_rect_px(img, ox, oy, s, 6, 0, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 10, 4, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
	elif kind == "gun":
		_draw_rect_px(img, ox, oy, s, 3, 7, 8, 3, metal)
		_draw_rect_px(img, ox, oy, s, 1, 8, 2, 3, wood)
		_draw_rect_px(img, ox, oy, s, 10, 6, 5, 1, metal)
		_draw_rect_px(img, ox, oy, s, 6, 10, 2, 3, wood)
		_draw_rect_px(img, ox, oy, s, 8, 9, 2, 4, dark)
		_draw_rect_px(img, ox, oy, s, 3, 6, 3, 1, dark)
	elif kind == "sword":
		_draw_rect_px(img, ox, oy, s, 7, 2, 2, 8, metal)
		_draw_rect_px(img, ox, oy, s, 6, 1, 4, 1, metal)
		_draw_rect_px(img, ox, oy, s, 5, 10, 6, 1, gold)
		_draw_rect_px(img, ox, oy, s, 7, 11, 2, 4, wood)
		_draw_rect_px(img, ox, oy, s, 6, 15, 4, 1, dark)
	elif kind == "staff":
		_draw_rect_px(img, ox, oy, s, 7, 4, 2, 9, wood)
		_draw_ring_px(img, ox, oy, s, 8, 3, 2, blue)
		_draw_rect_px(img, ox, oy, s, 6, 12, 4, 2, dark)
	elif kind == "note":
		_draw_rect_px(img, ox, oy, s, 3, 2, 10, 12, paper)
		_draw_rect_px(img, ox, oy, s, 4, 4, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 6, 8, 1, ink)
		_draw_rect_px(img, ox, oy, s, 4, 8, 6, 1, ink)
		_draw_rect_px(img, ox, oy, s, 3, 2, 10, 1, dark)
		_draw_rect_px(img, ox, oy, s, 3, 13, 10, 1, dark)
		_draw_rect_px(img, ox, oy, s, 3, 2, 1, 12, dark)
		_draw_rect_px(img, ox, oy, s, 12, 2, 1, 12, dark)
	if badge != "":
		var bx: int = 10
		var by: int = 1
		var bcol := rarity_col.lightened(0.2)
		if badge == "range":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 5, bcol)
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 5, 1, bcol)
			_draw_ring_px(img, ox, oy, s, bx + 2, by + 2, 2, bcol)
		elif badge == "speed":
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 4, 1, bcol)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 1, 2, 1, bcol)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 3, 2, 1, bcol)
		elif badge == "damage":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 5, red)
			_draw_rect_px(img, ox, oy, s, bx, by + 2, 5, 1, red)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 1, 1, 1, red)
			_draw_rect_px(img, ox, oy, s, bx + 3, by + 3, 1, 1, red)
		elif badge == "radius":
			_draw_ring_px(img, ox, oy, s, bx + 2, by + 2, 2, purple)
		elif badge == "bolt":
			_draw_rect_px(img, ox, oy, s, bx + 2, by, 1, 1, gold)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 1, 2, 1, gold)
			_draw_rect_px(img, ox, oy, s, bx + 2, by + 2, 1, 2, gold)
			_draw_rect_px(img, ox, oy, s, bx + 1, by + 4, 2, 1, gold)
		elif badge == "red":
			_draw_diamond_px(img, ox, oy, s, bx + 2, by + 2, 2, red)

func _icon_kind(key: String) -> String:
	if key.find("note") >= 0:
		return "note"
	if key.find("sword_red") >= 0:
		return "crest_warrior"
	if key.find("magic_red") >= 0:
		return "crest_mage"
	if key.find("战士之徽") >= 0:
		return "crest_warrior"
	if key.find("法师之徽") >= 0:
		return "crest_mage"
	if key.find("扩容") >= 0 or key.find("背包") >= 0 or key.find("核心") >= 0:
		return "bag_core"
	if key.find("紫封") >= 0:
		if key.find("弹匣") >= 0:
			return "purple_mag"
		if key.find("刃纹") >= 0:
			return "purple_blade"
		if key.find("法印") >= 0:
			return "purple_seal"
	if key.find("节奏刻") >= 0 or key.find("冷却刻") >= 0:
		if key.find("奥术") >= 0 or key.find("法") >= 0:
			return "hourglass_mage"
		if key.find("刃") >= 0:
			return "hourglass"
		return "metronome"
	if key.find("拓展") >= 0 or key.find("扩环") >= 0 or key.find("弹道") >= 0 or key.find("刃域") >= 0 or key.find("法域") >= 0:
		if key.find("法") >= 0:
			return "orb"
		if key.find("刃") >= 0:
			return "spear"
		return "scope"
	if key.find("增幅") >= 0:
		if key.find("刃") >= 0:
			return "blade"
		if key.find("法") >= 0:
			return "seal"
		return "mag"
	if key.find("弹匣") >= 0:
		return "mag"
	if key.find("刃纹") >= 0:
		return "blade"
	if key.find("法印") >= 0:
		return "seal"
	return "mag"

func _icon_badge(key: String) -> String:
	if key.find("range") >= 0:
		return "range"
	if key.find("speed") >= 0 or key.find("interval") >= 0:
		return "speed"
	if key.find("dmg") >= 0 or key.find("damage") >= 0:
		return "damage"
	if key.find("radius") >= 0:
		return "radius"
	if key.find("red") >= 0:
		return "red"
	if key == "bolt":
		return "bolt"
	return ""

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)

func _stroke_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for xx in range(w):
		var px := x + xx
		var py1 := y
		var py2 := y + h - 1
		if px >= 0 and px < img.get_width():
			if py1 >= 0 and py1 < img.get_height():
				img.set_pixel(px, py1, col)
			if py2 >= 0 and py2 < img.get_height():
				img.set_pixel(px, py2, col)
	for yy in range(h):
		var py := y + yy
		var px1 := x
		var px2 := x + w - 1
		if py >= 0 and py < img.get_height():
			if px1 >= 0 and px1 < img.get_width():
				img.set_pixel(px1, py, col)
			if px2 >= 0 and px2 < img.get_width():
				img.set_pixel(px2, py, col)

func _draw_rect_px(img: Image, ox: int, oy: int, s: int, x: int, y: int, w: int, h: int, col: Color):
	for yy in range(h):
		for xx in range(w):
			_plot_px(img, ox + (x + xx) * s, oy + (y + yy) * s, s, col)

func _draw_ring_px(img: Image, ox: int, oy: int, s: int, cx: int, cy: int, r: int, col: Color):
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			var d := dx * dx + dy * dy
			if d <= r * r and d >= (r - 1) * (r - 1):
				_plot_px(img, ox + x * s, oy + y * s, s, col)

func _draw_diamond_px(img: Image, ox: int, oy: int, s: int, cx: int, cy: int, r: int, col: Color):
	for y in range(-r, r + 1):
		var row: int = r - abs(y)
		for x in range(-row, row + 1):
			_plot_px(img, ox + (cx + x) * s, oy + (cy + y) * s, s, col)

func _plot_px(img: Image, x: int, y: int, s: int, col: Color):
	for yy in range(s):
		for xx in range(s):
			var px := x + xx
			var py := y + yy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, col)

func _update_collectible_dialog(dialog: AcceptDialog, counts: Dictionary, keep_id: String, header_text: String = ""):
	if dialog == null:
		return
	var list := dialog.get_node_or_null("CollectibleList")
	if list == null:
		list = VBoxContainer.new()
		list.name = "CollectibleList"
		dialog.add_child(list)
		if list is Control:
			(list as Control).anchor_left = 0.0
			(list as Control).anchor_top = 0.0
			(list as Control).anchor_right = 1.0
			(list as Control).anchor_bottom = 1.0
			(list as Control).offset_left = 24
			(list as Control).offset_top = 36
			(list as Control).offset_right = -24
			(list as Control).offset_bottom = -80
			(list as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			(list as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	if list:
		for c in list.get_children():
			c.queue_free()
		if header_text != "":
			var header := Label.new()
			header.text = header_text
			list.add_child(header)
		for id in counts.keys():
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var tex := get_collectible_icon_texture(String(id), 24, 24)
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(24, 24)
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(icon)
			var name := get_collectible_name(String(id))
			var label := Label.new()
			label.text = "%s x%d" % [name, int(counts[id])]
			row.add_child(label)
			list.add_child(row)
		if keep_id != "":
			var row2: HBoxContainer = HBoxContainer.new()
			row2.add_theme_constant_override("separation", 8)
			var tex2 := get_collectible_icon_texture(keep_id, 24, 24)
			var icon2 := TextureRect.new()
			icon2.texture = tex2
			icon2.custom_minimum_size = Vector2(24, 24)
			icon2.stretch_mode = TextureRect.STRETCH_SCALE
			icon2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row2.add_child(icon2)
			var label2 := Label.new()
			label2.text = "随机保留：%s" % get_collectible_name(keep_id)
			row2.add_child(label2)
			list.add_child(row2)

func _snap_drop_position(pos: Vector2, item_half: float) -> Vector2:
	if level == null:
		return pos
	var tm: float = 0.0
	if level.has_method("get_top_margin"):
		tm = float(level.get_top_margin())
	var lh: float = 80.0
	if level.has_node("Generator"):
		var gen := level.get_node("Generator")
		if gen and gen.get("layer_height") != null:
			lh = float(gen.layer_height)
	var layer_idx: int = int(clamp(round((pos.y - tm) / lh), 0.0, 99.0))
	var min_x: float = pos.x
	var max_x: float = pos.x
	var y_top: float = pos.y
	var used_platform: bool = false
	if level.has_method("_get_platform_body_for_layer") and level.has_method("_get_platform_width") and level.has_method("_get_platform_height"):
		var plat = level.call("_get_platform_body_for_layer", int(layer_idx))
		if plat and plat is Node2D:
			var pw: float = float(level.call("_get_platform_width", plat))
			var ph: float = float(level.call("_get_platform_height", plat))
			if pw > 0.0 and ph > 0.0:
				var cx: float = (plat as Node2D).global_position.x
				var cy: float = (plat as Node2D).global_position.y
				var hw: float = pw * 0.5
				min_x = cx - hw + 24.0
				max_x = cx + hw - 24.0
				y_top = cy - ph * 0.5
				used_platform = true
	var rx: float = clamp(pos.x, min_x, max_x)
	var half_h: float = max(1.0, item_half)
	var ry: float = (y_top - half_h) if used_platform else pos.y
	return Vector2(rx, ry)

func _spawn_collectible_pickup(id: String, pos: Vector2):
	if id == "":
		return
	var PickupScript := preload("res://scripts/items/Pickup.gd")
	var item: Area2D = PickupScript.new()
	item.kind = "collectible_id"
	item.collectible_id = id
	item.amount = 1
	if level:
		level.add_child(item)
	else:
		add_child(item)
	var item_half: float = 6.0
	if item and item.has_method("get_drop_half_height"):
		item_half = float(item.call("get_drop_half_height"))
	item.global_position = _snap_drop_position(pos, item_half)
	item.z_index = 30

func _set_bag_grid_size(w: int, h: int):
	bag_grid_w = max(1, w)
	bag_grid_h = max(1, h)
	var ui := get_node_or_null("UI")
	if ui and ui.has_method("on_bag_grid_changed"):
		ui.call("on_bag_grid_changed")

func _apply_collectible_unlock(id: String, unlock: String, p: Node2D, from_store: bool = false):
	if unlock == BAG_EXPAND_UNLOCK:
		if from_store:
			_set_bag_grid_size(BAG_GRID_W_EXPANDED, BAG_GRID_H_EXPANDED)
		return
	if unlock == "attack_melee" and not _has_equipped_target("melee"):
		return
	if unlock == "attack_magic" and not _has_equipped_target("magic"):
		return
	if unlock == "attack_roar" and not _has_equipped_target("roar"):
		return
	if p and p.has_method("apply_upgrade_kind"):
		p.apply_upgrade_kind(unlock)

func _apply_start_unlocks():
	if player == null:
		return
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		if rec == null:
			continue
		var id := String(rec["id"])
		var unlock := String(rec["unlock"])
		if unlock != "none" and int(coll_store.get_count(id)) > 0:
			_apply_collectible_unlock(id, unlock, player, true)

func _apply_start_effects():
	if player == null:
		return
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		if rec == null:
			continue
		var id := String(rec["id"])
		var unlock := String(rec["unlock"])
		if unlock != "none":
			continue
		var target := String(rec.get("target", "none"))
		var typ := String(rec.get("type", "none"))
		if target == "none" or typ == "none":
			continue
		if not _has_equipped_target(target):
			continue
		var cnt: int = int(coll_store.get_count(id))
		if cnt <= 0:
			continue
		var stage: int = clamp(cnt, 1, 5)
		var key := "v%d" % stage
		var val_f: float = float(rec.get(key, 0.0))
		_apply_collectible_effect(player, target, typ, val_f)

func _apply_base_character_stats():
	if player == null:
		return
	if char_config == null:
		return
	var prec: Dictionary = char_config.get_record("player")
	if prec.size() == 0:
		return
	if player.has_method("set"):
		if player.get("max_hp") != null and prec.has("max_hp"):
			player.set("max_hp", int(prec["max_hp"]))
		if player.get("hp") != null and prec.has("max_hp"):
			player.set("hp", int(prec["max_hp"]))
		if player.get("speed") != null and prec.has("speed"):
			player.set("speed", float(prec["speed"]))
	var mods = player.get("attack_modules")
	if mods != null:
		for m in mods:
			if m == null or not m.has_method("get_display_name"):
				continue
			var name: String = m.get_display_name()
			if name == "子弹攻击" and prec.has("bullet_damage"):
				m.upgrade({"damage": int(prec["bullet_damage"])})
			elif name == "近战攻击" and prec.has("melee_damage"):
				m.upgrade({"damage": int(prec["melee_damage"])})
			elif name == "范围魔法" and prec.has("magic_damage"):
				m.upgrade({"damage": int(prec["magic_damage"])})

func get_character_value(role: String, key: String, default_val = null):
	if char_config == null:
		return default_val
	return char_config.get_value(role, key, default_val)

func get_gameplay_consts():
	return gameplay_consts

func get_const_float(key: String, default_val: float = 0.0) -> float:
	if cheat_zero_interact:
		if key == "chest.open_time" or key == "exit.interact_time" or key == "door.repair_time":
			return 0.5
	if gameplay_consts:
		return gameplay_consts.get_float(key, default_val)
	return default_val

func get_const_int(key: String, default_val: int = 0) -> int:
	if gameplay_consts:
		return gameplay_consts.get_int(key, default_val)
	return default_val

func get_const_string(key: String, default_val: String = "") -> String:
	if gameplay_consts:
		return gameplay_consts.get_string(key, default_val)
	return default_val

func get_upgrade_name(id: String) -> String:
	if upg_config == null:
		return id
	var rec: Dictionary = upg_config.get_item(id)
	if rec == null or rec.size() == 0:
		return id
	return String(rec.get("name", id))

func get_upgrade_rarity(id: String) -> String:
	if upg_config == null:
		return "blue"
	return String(upg_config.get_value(id, "rarity", "blue"))

func _player_has_target(p: Node2D, target: String) -> bool:
	if p == null:
		return false
	if p.has_method("has_attack"):
		var name_map := {"bullet": "子弹攻击", "melee": "近战攻击", "magic": "范围魔法", "roar": "龙咆哮"}
		var n := String(name_map.get(target, ""))
		if n != "" and bool(p.call("has_attack", n)):
			return true
	var mods = p.get("attack_modules")
	if mods == null:
		return false
	for m in mods:
		if m == null or not m.has_method("get_display_name"):
			continue
		var name: String = m.get_display_name()
		if (target == "bullet" and name == "子弹攻击") or (target == "melee" and name == "近战攻击") or (target == "magic" and name == "范围魔法") or (target == "roar" and name == "龙咆哮"):
			return true
	return false

func _player_get_module(p: Node2D, target: String):
	if p == null:
		return null
	var mods = p.get("attack_modules")
	if mods == null:
		return null
	for m in mods:
		if m == null or not m.has_method("get_display_name"):
			continue
		var name: String = m.get_display_name()
		if (target == "bullet" and name == "子弹攻击") or (target == "melee" and name == "近战攻击") or (target == "magic" and name == "范围魔法") or (target == "roar" and name == "龙咆哮"):
			return m
	return null

func apply_base_attack_stats_for_target(target: String):
	if player == null or char_config == null:
		return
	var mod = _player_get_module(player, target)
	if mod == null:
		return
	var prec: Dictionary = char_config.get_record("player")
	if prec.size() == 0:
		return
	if target == "bullet" and prec.has("bullet_damage"):
		mod.upgrade({"damage": int(prec["bullet_damage"])})
	elif target == "melee" and prec.has("melee_damage"):
		mod.upgrade({"damage": int(prec["melee_damage"])})
	elif target == "magic" and prec.has("magic_damage"):
		mod.upgrade({"damage": int(prec["magic_damage"])})

func apply_collectible_effects_for_target(target: String):
	if player == null or coll_config == null or coll_store == null:
		return
	for rec_i in coll_config.items:
		var rec: Dictionary = rec_i
		if rec == null:
			continue
		var unlock := String(rec.get("unlock", "none"))
		if unlock != "none":
			continue
		var t := String(rec.get("target", "none"))
		var typ := String(rec.get("type", "none"))
		if t != target or typ == "none":
			continue
		var id := String(rec.get("id", ""))
		if id == "":
			continue
		var cnt: int = int(coll_store.get_count(id)) + _get_run_bag_count_for(id)
		if cnt <= 0:
			continue
		var stage: int = clamp(cnt, 1, 5)
		var key := "v%d" % stage
		var val_f: float = float(rec.get(key, 0.0))
		_apply_collectible_effect(player, t, typ, val_f)

func _is_upgrade_capped(p: Node2D, id: String) -> bool:
	if upg_config == null or p == null:
		return false
	var rec: Dictionary = upg_config.get_item(id)
	if rec == null or rec.size() == 0:
		return false
	var target := String(rec.get("target", "none"))
	var prop := String(rec.get("prop", "none"))
	var limit_type := String(rec.get("limit_type", "none"))
	var limit_value := float(rec.get("limit_value", 0.0))
	if target == "none" or prop == "none" or limit_type == "none":
		return false
	if not _player_has_target(p, target):
		return true
	var mod = _player_get_module(p, target)
	if mod == null:
		return true
	var cur = mod.get(prop)
	if cur == null:
		return false
	var cur_f: float = float(cur)
	if limit_type == "max":
		return cur_f >= limit_value
	elif limit_type == "min":
		return cur_f <= limit_value
	return false

func get_weighted_upgrade_choices(p: Node2D, n: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var candidates := []
	if upg_config:
		for rec in upg_config.items:
			var id := String(rec.get("id", ""))
			if id == "":
				continue
			var unlock_key := String(rec.get("unlock", "none"))
			var target := String(rec.get("target", "none"))
			if unlock_key != "none":
				var need_unlock: bool = true
				var unlock_target := _unlock_to_target(id, unlock_key)
				if unlock_target != "":
					need_unlock = not _player_has_target(p, unlock_target)
					if need_unlock and _has_equipped_target(unlock_target):
						candidates.append(id)
				continue
			if target != "none" and _player_has_target(p, target):
				if not _is_upgrade_capped(p, id):
					candidates.append(id)
	# weighted choice without replacement
	var res := []
	var pool := candidates.duplicate()
	while res.size() < n and pool.size() > 0:
		var total_w: float = 0.0
		var weights := []
		for id2 in pool:
			var w := float(get_upgrade_weight(id2))
			weights.append(w)
			total_w += w
		var pick := rng.randf() * (total_w if total_w > 0.0 else 1.0)
		var acc: float = 0.0
		var chosen_idx: int = 0
		for i in range(pool.size()):
			acc += float(weights[i])
			if pick <= acc:
				chosen_idx = i
				break
		res.append(pool[chosen_idx])
		pool.remove_at(chosen_idx)
	# fallback if empty
	if res.size() == 0:
		if _player_has_target(p, "bullet") and not _is_upgrade_capped(p, "bullet_damage"):
			res.append("bullet_damage")
		elif _player_has_target(p, "melee") and not _is_upgrade_capped(p, "melee_damage"):
			res.append("melee_damage")
		elif _player_has_target(p, "magic") and not _is_upgrade_capped(p, "magic_damage"):
			res.append("magic_damage")
		elif _player_has_target(p, "roar") and not _is_upgrade_capped(p, "roar_damage"):
			res.append("roar_damage")
	return res

func _unlock_to_target(id: String, unlock_key: String) -> String:
	if unlock_key == "attack_melee" or id == "attack_melee":
		return "melee"
	if unlock_key == "attack_magic" or id == "attack_magic":
		return "magic"
	if unlock_key == "attack_roar" or id == "attack_roar":
		return "roar"
	return ""

func _has_equipped_target(target: String) -> bool:
	if equipment_store == null or equipment_config == null:
		return false
	for item_id in equipment_store.equipped_items:
		var rec: Dictionary = equipment_config.get_equipment_by_id(String(item_id))
		if String(rec.get("attack_id", "")) == target:
			return true
	return false

func get_upgrade_weight(id: String) -> float:
	if upg_config == null:
		return 1.0
	return float(upg_config.get_value(id, "weight", 1.0))

func can_drop_collectible() -> bool:
	return run_collectible_drops < run_collectible_target

func can_drop_coin(amount: int) -> bool:
	return (run_coin_total + int(amount)) <= run_coin_cap

func register_coin_drop(amount: int):
	run_coin_total = min(run_coin_cap, run_coin_total + int(amount))

func register_chest_plan() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var plan := []
	var max_opens: int = get_const_int("chest.max_opens", 3)
	var drop_min: int = get_const_int("chest.drop_count_min", 1)
	var drop_max: int = get_const_int("chest.drop_count_max", 3)
	var coin_min: int = get_const_int("chest.coin_drop_min", 10)
	var coin_max: int = get_const_int("chest.coin_drop_max", 50)
	for open_idx in range(max_opens):
		var count := rng.randi_range(drop_min, drop_max)
		var items := []
		for i in range(count):
			var cat := 1
			var coin_val := rng.randi_range(coin_min, coin_max)
			var remaining_coin := run_coin_cap - run_coin_reserved
			var can_plan_coin := remaining_coin >= coin_val
			var can_plan_coll := run_collectible_planned < run_collectible_target
			var r := rng.randf()
			if can_plan_coll and r < 0.33:
				cat = 3
				run_collectible_planned += 1
			elif can_plan_coin and r < 0.66:
				cat = 2
				run_coin_reserved += coin_val
			else:
				cat = 1
			items.append({"cat": cat, "coin": coin_val})
		plan.append(items)
	return plan

func init_chest_loot(chests: Array):
	if chest_loot_initialized:
		return
	chest_loot_initialized = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var openings_per: int = get_const_int("chest.max_opens", 3)
	print("ChestLoot:init start chests=%d" % chests.size())
	for c0 in chests:
		if c0 and c0 is Node2D:
			var p0 := (c0 as Node2D).global_position
			print("ChestLoot:normal chest at (%.1f, %.1f)" % [p0.x, p0.y])
	var open_counts := []
	for c in chests:
		for i in range(openings_per):
			var drop_min: int = get_const_int("chest.drop_count_min", 1)
			var drop_max: int = get_const_int("chest.drop_count_max", 3)
			open_counts.append(rng.randi_range(drop_min, drop_max))
	var total_items: int = 0
	for v in open_counts:
		total_items += int(v)
	run_collectible_planned = 0
	run_coin_reserved = 0
	var locked_cnt: int = _get_locked_ladder_count()
	var ladder_cost: int = get_const_int("ladder.unlock_cost", 100)
	var ladder_extra: int = get_const_int("core.ladder_unlock_extra", 50)
	var required_coins: int = (locked_cnt * ladder_cost + ladder_extra) if locked_cnt > 0 else 0
	run_coin_cap = max(base_run_coin_cap, required_coins)
	print("ChestLoot:locked=%d required=%d total_items=%d" % [locked_cnt, required_coins, total_items])
	var coll_count: int = min(run_collectible_target, total_items)
	var remaining_slots: int = total_items - coll_count
	var coin_entries := []
	var reserved_sum: int = 0
	var coin_min: int = get_const_int("chest.coin_drop_min", 10)
	var coin_max: int = get_const_int("chest.coin_drop_max", 50)
	var min_coin_slots: int = int(ceil(float(required_coins) / float(coin_max))) if required_coins > 0 else 0
	if remaining_slots < min_coin_slots:
		var need_slots: int = min_coin_slots - remaining_slots
		coll_count = max(coll_count - need_slots, 0)
		remaining_slots = total_items - coll_count
	min_coin_slots = min(min_coin_slots, remaining_slots)
	var coin_slots: int = min_coin_slots
	if required_coins > 0:
		var extra_slots: int = min(2, remaining_slots - min_coin_slots)
		if extra_slots <= 0 and coll_count > 0:
			coll_count = max(coll_count - 1, 0)
			remaining_slots = total_items - coll_count
			extra_slots = min(2, remaining_slots - min_coin_slots)
		coin_slots = min_coin_slots + max(extra_slots, 0)
	var required_remaining: int = required_coins
	for i in range(coin_slots):
		var slots_left: int = coin_slots - i - 1
		var min_allowed: int = max(coin_min, required_remaining - coin_max * slots_left)
		var max_allowed: int = min(coin_max, required_remaining - coin_min * slots_left)
		var cv: int = rng.randi_range(min_allowed, max_allowed)
		coin_entries.append(cv)
		reserved_sum += cv
		required_remaining -= cv
		remaining_slots -= 1
	while remaining_slots > 0:
		var cv := rng.randi_range(coin_min, coin_max)
		var remain := run_coin_cap - reserved_sum
		if remain >= cv:
			coin_entries.append(cv)
			reserved_sum += cv
			remaining_slots -= 1
		else:
			break
	print("ChestLoot:coinsum=%d coin_items=%d coll_items=%d upg_items=%d" % [reserved_sum, coin_entries.size(), coll_count, (total_items - coll_count - coin_entries.size())])
	run_coin_reserved = reserved_sum
	run_collectible_planned = coll_count
	var upg_count: int = total_items - coll_count - coin_entries.size()
	var tokens := []
	for i in range(coll_count):
		tokens.append({"cat": 3, "coin": 0})
	for cv2 in coin_entries:
		tokens.append({"cat": 2, "coin": cv2})
	for i in range(upg_count):
		tokens.append({"cat": 1, "coin": rng.randi_range(10, 50)})
	for i in range(tokens.size()):
		var j := rng.randi_range(i, tokens.size() - 1)
		var tmp = tokens[i]
		tokens[i] = tokens[j]
		tokens[j] = tmp
	var idx: int = 0
	for c in chests:
		var plan := []
		for oi in range(openings_per):
			var cnt: int = int(open_counts[idx])
			var items := []
			for k in range(cnt):
				if tokens.size() > 0:
					items.append(tokens.pop_back())
			plan.append(items)
			idx += 1
		if c and c.has_method("set_drop_plan"):
			c.call("set_drop_plan", plan)

func ensure_chest_loot_initialized():
	if chest_loot_initialized:
		return
	var chests := []
	for c in get_tree().get_nodes_in_group("chest"):
		if c and c.get("chest_type") != null and String(c.get("chest_type")) == "normal":
			chests.append(c)
	if chests.size() > 0:
		for c2 in chests:
			if c2 and c2 is Node2D:
				var p := (c2 as Node2D).global_position
				print("ChestLoot:normal chest at (%.1f, %.1f)" % [p.x, p.y])
		init_chest_loot(chests)

func reset_chest_loot_initialized():
	chest_loot_initialized = false

func _get_locked_ladder_count() -> int:
	var cnt: int = 0
	if level and level.has_node("Ladders"):
		var ladder_root = level.get_node("Ladders")
		for l in ladder_root.get_children():
			if l and l.has_method("get"):
				var locked = l.get("locked")
				var leads = l.get("leads_to_top")
				if (locked != null and bool(locked)) or (leads != null and bool(leads)):
					cnt += 1
	return cnt

func get_required_ladder_coins() -> int:
	var ladder_cost: int = get_const_int("ladder.unlock_cost", 100)
	return _get_locked_ladder_count() * ladder_cost

func _random_choices_with_red_prob(prob: float, n: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var reds := []
	var normals := []
	for rec in coll_config.items:
		var rec_d: Dictionary = rec
		if String(rec_d["unlock"]) != "none":
			var rid: String = String(rec_d["id"])
			if not is_collectible_capped(rid):
				reds.append(rid)
		else:
			var nid: String = String(rec_d["id"])
			var rar0: String = String(rec_d.get("rarity", "blue"))
			if rar0 != "white" and not is_collectible_capped(nid):
				normals.append(nid)
	var res := []
	if rng.randf() < prob and reds.size() > 0:
		var ridx := rng.randi_range(0, reds.size() - 1)
		res.append(reds[ridx])
		reds.remove_at(ridx)
	while res.size() < n and normals.size() > 0:
		var idx := rng.randi_range(0, normals.size() - 1)
		res.append(normals[idx])
		normals.remove_at(idx)
	return res

func _random_normal_choices_with_epic_prob(prob: float, n: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var epics := []
	var blues := []
	for rec in coll_config.items:
		var rec_d: Dictionary = rec
		var unlock_key: String = String(rec_d.get("unlock", "none"))
		if unlock_key != "none":
			continue
		var id: String = String(rec_d["id"])
		if is_collectible_capped(id):
			continue
		var rar: String = String(rec_d.get("rarity", "blue"))
		if rar == "white":
			continue
		if rar == "epic":
			epics.append(id)
		else:
			blues.append(id)
	var res := []
	if rng.randf() < prob and epics.size() > 0:
		var eidx := rng.randi_range(0, epics.size() - 1)
		res.append(epics[eidx])
		epics.remove_at(eidx)
	while res.size() < n and (blues.size() > 0 or epics.size() > 0):
		if blues.size() > 0:
			var bidx := rng.randi_range(0, blues.size() - 1)
			res.append(blues[bidx])
			blues.remove_at(bidx)
		elif epics.size() > 0:
			var eidx2 := rng.randi_range(0, epics.size() - 1)
			res.append(epics[eidx2])
			epics.remove_at(eidx2)
	return res

func _random_choices_with_probs(red_prob: float, epic_prob: float, n: int = 3) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var reds := []
	var epics := []
	var blues := []
	for rec in coll_config.items:
		var rec_d: Dictionary = rec
		var id: String = String(rec_d["id"])
		if is_collectible_capped(id):
			continue
		var unlock_key: String = String(rec_d.get("unlock", "none"))
		var rar: String = String(rec_d.get("rarity", "blue"))
		if rar == "white":
			continue
		if unlock_key != "none":
			reds.append(id)
		elif rar == "epic":
			epics.append(id)
		else:
			blues.append(id)
	var res := []
	for i in range(n):
		var r := rng.randf()
		if r < red_prob and reds.size() > 0:
			var ridx := rng.randi_range(0, reds.size() - 1)
			res.append(reds[ridx])
			reds.remove_at(ridx)
		elif r < (red_prob + epic_prob) and epics.size() > 0:
			var eidx := rng.randi_range(0, epics.size() - 1)
			res.append(epics[eidx])
			epics.remove_at(eidx)
		elif blues.size() > 0:
			var bidx := rng.randi_range(0, blues.size() - 1)
			res.append(blues[bidx])
			blues.remove_at(bidx)
		elif epics.size() > 0:
			var eidx2 := rng.randi_range(0, epics.size() - 1)
			res.append(epics[eidx2])
			epics.remove_at(eidx2)
		elif reds.size() > 0:
			var ridx2 := rng.randi_range(0, reds.size() - 1)
			res.append(reds[ridx2])
			reds.remove_at(ridx2)
	return res

func start_post_interaction():
	if run_ended and run_result == "fail":
		return
	post_interaction_active = true
	post_time = 0.0
	post_limit = 30.0
	var sp := level.get_node("EnemySpawner")
	if sp and sp.has_method("set_post_interaction"):
		sp.call("set_post_interaction", true)
