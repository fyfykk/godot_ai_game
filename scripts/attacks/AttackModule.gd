extends RefCounted
class_name AttackModule

var enabled: bool = true

func setup(_owner: Node2D):
	pass

func update(_delta: float, _owner: Node2D):
	pass

func upgrade(_params: Dictionary):
	pass

func get_display_name() -> String:
	return ""

func get_display_stats() -> Dictionary:
	return {}
