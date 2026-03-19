extends Button

var drag_payload: Dictionary = {}
var preview_texture: Texture2D = null

func _get_drag_data(_pos):
	if drag_payload.is_empty():
		return null
	var preview = TextureRect.new()
	preview.texture = preview_texture
	preview.custom_minimum_size = Vector2(80, 80)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return drag_payload
