extends Node

class_name LevelGenerator

@export var layers: int = 4
@export var layer_height: float = 80.0
@export var width: float = 1024.0
var level_seed: int = 0
var consts = null

func _get_const_int(key: String, default_val: int) -> int:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_int"):
		return int(root.call("get_const_int", key, default_val))
	return default_val

func _get_const_float(key: String, default_val: float) -> float:
	var root := get_tree().get_root().get_node_or_null("GameRoot")
	if root and root.has_method("get_const_float"):
		return float(root.call("get_const_float", key, default_val))
	return default_val

func generate():
	layers = _get_const_int("levelgen.default_layers", layers)
	layer_height = _get_const_float("levelgen.default_layer_height", layer_height)
	width = _get_const_float("levelgen.default_width", width)
	var rand_layers_min: int = _get_const_int("levelgen.random_layers_min", 3)
	var rand_layers_max: int = _get_const_int("levelgen.random_layers_max", 6)
	var rand_width_min: int = _get_const_int("levelgen.random_width_min", 960)
	var rand_width_max: int = _get_const_int("levelgen.random_width_max", 1280)
	if level_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(level_seed)
		layers = rng.randi_range(rand_layers_min, rand_layers_max)
		width = float(rng.randi_range(rand_width_min, rand_width_max))
	var spawn_x: float = _get_const_float("levelgen.spawn_x", 96.0)
	var spawn_y_off: float = _get_const_float("levelgen.spawn_y_offset_from_bottom", -24.0)
	var exit_x_off: float = _get_const_float("levelgen.exit_x_offset_from_right", -96.0)
	var exit_y: float = _get_const_float("levelgen.exit_y", -8.0)
	var platform_h: float = _get_const_float("levelgen.platform_height", 16.0)
	var platform_x: float = _get_const_float("levelgen.platform_x", 80.0)
	var platform_w_off: float = _get_const_float("levelgen.platform_width_offset", 160.0)
	var spawn := Vector2(spawn_x, (layers - 1) * layer_height + spawn_y_off)
	var exit := Vector2(width + exit_x_off, exit_y)
	var platforms := []
	for i in range(layers):
		var y := float(i) * layer_height
		var w := width - platform_w_off
		var x := platform_x
		platforms.append({"x": x, "y": y, "w": w, "h": platform_h})
	return {"spawn_position": spawn, "exit_position": exit, "platforms": platforms}
