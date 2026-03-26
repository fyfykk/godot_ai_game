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
	t.set_default_font_size(16)
	var text := Color(0.94, 0.96, 1.0, 1.0)
	var text_muted := Color(0.72, 0.76, 0.84, 1.0)
	var bg := Color(0.08, 0.09, 0.12, 0.92)
	var panel := Color(0.12, 0.13, 0.18, 0.95)
	var border := Color(0.25, 0.28, 0.35, 0.95)
	var accent := Color(0.35, 0.75, 1.0, 1.0)
	var accent_dark := Color(0.2, 0.4, 0.75, 1.0)
	var shadow := Color(0, 0, 0, 0.45)
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = panel
	panel_box.border_color = border
	panel_box.set_border_width_all(2)
	panel_box.set_corner_radius_all(10)
	panel_box.shadow_color = shadow
	panel_box.shadow_size = 6
	panel_box.shadow_offset = Vector2(0, 3)
	t.set_stylebox("panel", "Panel", panel_box)
	t.set_stylebox("panel", "PopupPanel", panel_box)
	t.set_stylebox("panel", "AcceptDialog", panel_box)
	t.set_stylebox("panel", "ConfirmationDialog", panel_box)
	var button_normal := StyleBoxFlat.new()
	button_normal.bg_color = bg
	button_normal.border_color = border
	button_normal.set_border_width_all(2)
	button_normal.set_corner_radius_all(8)
	var button_hover := StyleBoxFlat.new()
	button_hover.bg_color = Color(bg.r + 0.05, bg.g + 0.05, bg.b + 0.06, bg.a)
	button_hover.border_color = accent
	button_hover.set_border_width_all(2)
	button_hover.set_corner_radius_all(8)
	var button_pressed := StyleBoxFlat.new()
	button_pressed.bg_color = Color(bg.r - 0.02, bg.g - 0.02, bg.b - 0.02, bg.a)
	button_pressed.border_color = accent_dark
	button_pressed.set_border_width_all(2)
	button_pressed.set_corner_radius_all(8)
	var button_disabled := StyleBoxFlat.new()
	button_disabled.bg_color = Color(bg.r, bg.g, bg.b, 0.45)
	button_disabled.border_color = Color(border.r, border.g, border.b, 0.45)
	button_disabled.set_border_width_all(2)
	button_disabled.set_corner_radius_all(8)
	var button_focus := StyleBoxFlat.new()
	button_focus.bg_color = Color(bg.r, bg.g, bg.b, 0.2)
	button_focus.border_color = accent
	button_focus.set_border_width_all(2)
	button_focus.set_corner_radius_all(8)
	t.set_stylebox("normal", "Button", button_normal)
	t.set_stylebox("hover", "Button", button_hover)
	t.set_stylebox("pressed", "Button", button_pressed)
	t.set_stylebox("disabled", "Button", button_disabled)
	t.set_stylebox("focus", "Button", button_focus)
	t.set_color("font_color", "Button", text)
	t.set_color("font_hover_color", "Button", text)
	t.set_color("font_pressed_color", "Button", text)
	t.set_color("font_disabled_color", "Button", text_muted)
	var line_normal := StyleBoxFlat.new()
	line_normal.bg_color = bg
	line_normal.border_color = border
	line_normal.set_border_width_all(2)
	line_normal.set_corner_radius_all(6)
	var line_focus := StyleBoxFlat.new()
	line_focus.bg_color = bg
	line_focus.border_color = accent
	line_focus.set_border_width_all(2)
	line_focus.set_corner_radius_all(6)
	t.set_stylebox("normal", "LineEdit", line_normal)
	t.set_stylebox("focus", "LineEdit", line_focus)
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_uneditable_color", "LineEdit", text_muted)
	t.set_color("selection_color", "LineEdit", Color(accent.r, accent.g, accent.b, 0.35))
	t.set_color("caret_color", "LineEdit", text)
	t.set_color("font_color", "Label", text)
	t.set_color("font_outline_color", "Label", Color(0.05, 0.05, 0.08, 0.9))
	t.set_constant("outline_size", "Label", 1)
	t.set_color("font_color", "RichTextLabel", text)
	t.set_color("font_outline_color", "RichTextLabel", Color(0.05, 0.05, 0.08, 0.9))
	t.set_constant("outline_size", "RichTextLabel", 1)
	t.set_color("font_color", "Window", text)
	t.set_color("title_color", "Window", text)
	t.set_color("title_outline_color", "Window", Color(0.05, 0.05, 0.08, 0.9))
	t.set_color("title_button_color", "Window", text)
	t.set_color("title_button_hover_color", "Window", accent)
	t.set_color("title_button_pressed_color", "Window", accent_dark)
	t.set_color("font_color", "OptionButton", text)
	t.set_color("font_hover_color", "OptionButton", text)
	t.set_color("font_pressed_color", "OptionButton", text)
	t.set_color("font_disabled_color", "OptionButton", text_muted)
	t.set_stylebox("normal", "OptionButton", button_normal)
	t.set_stylebox("hover", "OptionButton", button_hover)
	t.set_stylebox("pressed", "OptionButton", button_pressed)
	t.set_stylebox("disabled", "OptionButton", button_disabled)
	t.set_stylebox("focus", "OptionButton", button_focus)
	t.set_color("font_color", "PopupMenu", text)
	t.set_stylebox("panel", "PopupMenu", panel_box)
	t.set_color("font_color", "MenuButton", text)
	t.set_stylebox("normal", "MenuButton", button_normal)
	t.set_stylebox("hover", "MenuButton", button_hover)
	t.set_stylebox("pressed", "MenuButton", button_pressed)
	t.set_stylebox("disabled", "MenuButton", button_disabled)
	t.set_stylebox("focus", "MenuButton", button_focus)
	t.set_color("font_color", "SpinBox", text)
	t.set_stylebox("normal", "SpinBox", line_normal)
	t.set_stylebox("focus", "SpinBox", line_focus)
	t.set_color("font_color", "ProgressBar", text)
	t.set_stylebox("background", "ProgressBar", line_normal)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = accent
	progress_fill.set_corner_radius_all(6)
	t.set_stylebox("fill", "ProgressBar", progress_fill)
	t.set_color("font_color", "CheckBox", text)
	t.set_color("font_color", "CheckButton", text)
	t.set_color("font_color", "TabContainer", text)
	t.set_color("font_color", "Tabs", text)
	t.set_color("font_selected_color", "Tabs", text)
	t.set_color("font_hovered_color", "Tabs", text)
	t.set_color("font_disabled_color", "Tabs", text_muted)
	t.set_color("font_color", "TextureButton", text)
	t.set_color("font_color", "HSlider", text)
	t.set_color("font_color", "VSlider", text)
	t.set_color("font_color", "ItemList", text)
	t.set_color("font_color", "Tree", text)
	t.set_color("font_color", "GraphNode", text)
	t.set_color("font_color", "GraphEdit", text)
	t.set_color("font_color", "TextEdit", text)
	t.set_color("caret_color", "TextEdit", text)
	t.set_color("selection_color", "TextEdit", Color(accent.r, accent.g, accent.b, 0.35))
	t.set_stylebox("normal", "TextEdit", line_normal)
	t.set_stylebox("focus", "TextEdit", line_focus)
	t.set_color("font_color", "Popup", text)
	t.set_color("font_color", "PanelContainer", text)
	t.set_stylebox("panel", "PanelContainer", panel_box)
	t.set_color("font_color", "TooltipLabel", text)
	t.set_stylebox("panel", "TooltipPanel", panel_box)
	t.set_color("font_color", "LinkButton", accent)
	t.set_color("font_hover_color", "LinkButton", Color(accent.r + 0.1, accent.g + 0.1, accent.b + 0.1, 1.0))
	t.set_color("font_pressed_color", "LinkButton", accent_dark)
	t.set_color("font_disabled_color", "LinkButton", text_muted)
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
