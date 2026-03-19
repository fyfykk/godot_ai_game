extends Node

class_name Rarity

static func normalize(r: String) -> String:
	var s := r.to_lower()
	if s == "蓝" or s == "blue":
		return "blue"
	if s == "紫" or s == "epic" or s == "purple":
		return "epic"
	if s == "红" or s == "red":
		return "red"
	if s == "白" or s == "white":
		return "white"
	if s == "金" or s == "gold" or s == "legendary":
		return "gold"
	return s

static func color(r: String) -> Color:
	var n := normalize(r)
	if n == "blue":
		return Color(0.3, 0.5, 1.0, 1.0)
	if n == "epic":
		return Color(0.6, 0.3, 0.8, 1.0)
	if n == "gold":
		return Color(1.0, 0.8, 0.2, 1.0)
	if n == "red":
		return Color(1.0, 0.2, 0.2, 1.0)
	if n == "white":
		return Color(0.95, 0.95, 0.95, 1.0)
	return Color(1, 1, 1, 1)

static func name(r: String) -> String:
	var n := normalize(r)
	if n == "blue":
		return "蓝"
	if n == "epic":
		return "紫"
	if n == "gold":
		return "金"
	if n == "red":
		return "红"
	if n == "white":
		return "白"
	return r
