extends Node

class_name UIFont

static var _font: FontFile = null
static var _theme: Theme = null
const DEFAULT_FONT: FontFile = preload("res://data/fonts/LXGWWenKai-Regular.ttf")

static func _get_font() -> FontFile:
	if _font:
		return _font
	_font = DEFAULT_FONT
	return _font

static func _get_theme() -> Theme:
	if _theme:
		return _theme
	var font := _get_font()
	if font == null:
		return null
	var t := Theme.new()
	t.set_default_font(font)
	_theme = t
	return _theme

static func theme() -> Theme:
	return _get_theme()

static func apply_control(control: Control):
	var font := _get_font()
	if font == null:
		return
	control.add_theme_font_override("font", font)
	control.add_theme_font_override("normal_font", font)
	control.add_theme_font_override("bold_font", font)
	control.add_theme_font_override("italics_font", font)
	control.add_theme_font_override("bold_italics_font", font)
	var t := _get_theme()
	if t:
		control.theme = t

static func apply_tree(node: Node):
	if node is Control:
		apply_control(node as Control)
	for c in node.get_children():
		apply_tree(c)
