extends Node2D
var prompt
var interacting: bool = false
var interact_time: float = 0.0
var player_ref: Node2D = null
var required_time: float = 5.0
var ring
var opener: Node2D = null
var start_pos: Vector2 = Vector2.ZERO
var interact_radius: float = 28.0
var select_radius: float = 40.0
var ring_radius: float = 16.0
var ring_thickness: float = 4.0
var cancel_move_distance: float = 2.0
var const_inited: bool = false

func _get_const_float(key: String, default_val: float) -> float:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_float"):
		return float(root.call("get_const_float", key, default_val))
	return default_val
func _ready():
	set_process(true)
	var PromptScript := preload("res://scripts/ui/PromptWidget.gd")
	prompt = PromptScript.new()
	prompt.key_text = "E"
	add_child(prompt)
	var RingScript := preload("res://scripts/ui/ProgressCircle.gd")
	ring = RingScript.new()
	add_child(ring)
	ring.radius = 16.0
	ring.radius = ring_radius
	ring.thickness = ring_thickness
	ring.show_label = false
	ring.position = Vector2(0, -30)
	ring.visible = false
	add_to_group("exit")
	_refresh_consts()
	call_deferred("_refresh_consts")

func _refresh_consts():
	required_time = _get_const_float("exit.interact_time", required_time)
	interact_radius = _get_const_float("exit.interact_radius", interact_radius)
	select_radius = _get_const_float("exit.interact_select_radius", select_radius)
	ring_radius = _get_const_float("exit.ring_radius", ring_radius)
	ring_thickness = _get_const_float("exit.ring_thickness", ring_thickness)
	cancel_move_distance = _get_const_float("exit.cancel_move_distance", cancel_move_distance)
	if ring:
		ring.radius = ring_radius
		ring.thickness = ring_thickness
	const_inited = true
func _process(delta):
	var root_chk := get_tree().get_root().get_node_or_null("GameRoot")
	if root_chk and root_chk.get("input_locked") != null and bool(root_chk.get("input_locked")):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0] as Node2D
	else:
		player_ref = null
	var near: bool = false
	if player_ref != null:
		var d := player_ref.global_position.distance_to(global_position)
		near = d <= interact_radius
	var target_ok: bool = false
	if player_ref != null and player_ref.has_method("is_interact_target"):
		target_ok = bool(player_ref.call("is_interact_target", self))
	if prompt and is_instance_valid(prompt):
		prompt.visible = near and target_ok
	if near and target_ok and prompt and is_instance_valid(prompt):
		var prompt_y: float = _get_prompt_y()
		prompt.set_world_position(Vector2(global_position.x, prompt_y))
	if not near or not target_ok:
		interacting = false
		interact_time = 0.0
		_cancel_interact()
		return
	var holding: bool = Input.is_key_pressed(KEY_E)
	if holding:
		interacting = true
		if opener == null and player_ref != null:
			opener = player_ref
			start_pos = player_ref.global_position
			if ring:
				ring.visible = true
				ring.set_ratio(0.0)
	if interacting:
		if opener != null and is_instance_valid(opener):
			var cur_pos := opener.global_position
			if cur_pos.distance_to(start_pos) > cancel_move_distance:
				_cancel_interact()
				return
		interact_time += delta
		var r: float = clamp(interact_time / required_time, 0.0, 1.0)
		if ring:
			ring.set_ratio(r)
	if interacting and interact_time >= required_time:
		var root := get_tree().get_root().get_node("GameRoot")
		if root and root.has_method("start_post_interaction"):
			root.call("start_post_interaction")
		if prompt:
			prompt.visible = false
		_cancel_interact()
		set_process(false)
func try_interact(_p: Node2D):
	interacting = true
	opener = _p
	start_pos = _p.global_position
	interact_time = 0.0
	if ring:
		ring.visible = true
		ring.set_ratio(0.0)
func _cancel_interact():
	interacting = false
	interact_time = 0.0
	opener = null
	if ring:
		ring.visible = false

func _get_prompt_y() -> float:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		var p := ps[0] as Node2D
		var hb := p.get_node_or_null("HealthBar")
		if hb and hb.has_method("get_top_y"):
			var hb_top: float = float(hb.call("get_top_y"))
			var bg_half: float = prompt.get_bg_half_height() if prompt else 0.0
			return hb_top - 5.0 - bg_half
		if hb:
			var bh = hb.get("bar_height")
			if bh != null:
				var hb_top2: float = hb.global_position.y - float(bh) * 0.5
				var bg_half2: float = prompt.get_bg_half_height() if prompt else 0.0
				return hb_top2 - 5.0 - bg_half2
		var bg_half3: float = prompt.get_bg_half_height() if prompt else 0.0
		return p.global_position.y - 40.0 - bg_half3
	var bg_half4: float = prompt.get_bg_half_height() if prompt else 0.0
	return global_position.y - 26.0 - bg_half4

func is_interactable() -> bool:
	return true

func get_interact_position(_p: Vector2 = Vector2.ZERO) -> Vector2:
	return global_position

func get_interact_radius() -> float:
	return select_radius
