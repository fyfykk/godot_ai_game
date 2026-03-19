extends Node2D

@export var size: Vector2 = Vector2(220, 140)
@export var padding: float = 8.0
var level_ref: Node2D = null
var player_ref: Node2D = null
var discovered_chests: Dictionary = {}
var discovered_doors: Dictionary = {}
var discovered_ladders: Dictionary = {}
var discovered_walls: Dictionary = {}

func set_context(level: Node2D, player: Node2D):
	level_ref = level
	player_ref = player

func _process(_delta):
	_update_discovered()
	queue_redraw()

func _draw():
	var bg: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bg, Color(0, 0, 0, 0.35), true)
	var border: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(border, Color(0.9, 0.9, 0.9, 0.6), false, 2.0)
	if level_ref == null:
		return
	var platforms_node: Node = null
	if level_ref.has_node("Platforms"):
		platforms_node = level_ref.get_node("Platforms")
	var min_x: float = 999999.0
	var max_x: float = -999999.0
	var min_y_top: float = 999999.0
	var max_y_top: float = -999999.0
	var plats: Array = []
	if platforms_node:
		for p in platforms_node.get_children():
			if p and p is Node2D:
				var pos: Vector2 = (p as Node2D).global_position
				var pw: float = 0.0
				var ph: float = 0.0
				for c in p.get_children():
					if c is CollisionShape2D and (c as CollisionShape2D).shape and (c as CollisionShape2D).shape is RectangleShape2D:
						var sz := ((c as CollisionShape2D).shape as RectangleShape2D).size
						pw = float(sz.x)
						ph = float(sz.y)
						break
				var hw: float = pw * 0.5
				var hh: float = ph * 0.5
				var left_x: float = pos.x - hw
				var right_x: float = pos.x + hw
				var top_y: float = pos.y - hh
				min_x = min(min_x, left_x)
				max_x = max(max_x, right_x)
				min_y_top = min(min_y_top, top_y)
				max_y_top = max(max_y_top, top_y)
				plats.append({"left": left_x, "right": right_x, "top": top_y, "bottom": top_y + ph})
	if plats.size() == 0:
		return
	# 最高层向上延伸一层层高
	var lh: float = 0.0
	if level_ref and level_ref.has_node("Generator"):
		var gen = level_ref.get_node("Generator")
		if gen and gen.has_method("get") and gen.get("layer_height") != null:
			lh = float(gen.get("layer_height"))
	var min_y_ext: float = min_y_top - lh
	var sx: float = (size.x - padding * 2.0) / max((max_x - min_x), 1.0)
	var sy: float = (size.y - padding * 2.0) / max((max_y_top - min_y_ext), 1.0)
	for rec in plats:
		var lx: float = padding + (float(rec["left"]) - min_x) * sx
		var rx: float = padding + (float(rec["right"]) - min_x) * sx
		var ty: float = padding + (float(rec["top"]) - min_y_ext) * sy
		var by: float = padding + (float(rec["bottom"]) - min_y_ext) * sy
		var rect: Rect2 = Rect2(Vector2(lx, min(ty, by)), Vector2(max(rx - lx, 1.0), max(abs(by - ty), 1.0)))
		draw_rect(rect, Color(0.7, 0.7, 0.7, 0.9), true)
	# discovered ladders
	for id in discovered_ladders.keys():
		var rec_l: Dictionary = discovered_ladders[id]
		var cx: float = padding + (float(rec_l["x"]) - min_x) * sx
		var topy: float = padding + (float(rec_l["top"]) - min_y_ext) * sy
		var boty: float = padding + (float(rec_l["bottom"]) - min_y_ext) * sy
		var lh_m: float = max(abs(boty - topy), 2.0)
		var rect_l: Rect2 = Rect2(Vector2(cx - 1.5, min(topy, boty)), Vector2(3.0, lh_m))
		draw_rect(rect_l, Color(0.6, 0.6, 0.2, 0.9), true)
	# discovered doors
	for id2 in discovered_doors.keys():
		var rec_d: Dictionary = discovered_doors[id2]
		var dx: float = padding + (float(rec_d["x"]) - min_x) * sx
		var topy_d: float = float(rec_d.get("top", 0.0))
		var boty_d: float = float(rec_d.get("bottom", 0.0))
		if boty_d == 0.0 and topy_d == 0.0:
			var dy_fallback: float = padding + (float(rec_d.get("y", 0.0)) - min_y_ext) * sy
			var rect_fallback: Rect2 = Rect2(Vector2(dx - 1.5, dy_fallback - 8.0), Vector2(3.0, 16.0))
			draw_rect(rect_fallback, Color(0.55, 0.35, 0.2, 0.95), true)
		else:
			var ty: float = padding + (topy_d - min_y_ext) * sy
			var by: float = padding + (boty_d - min_y_ext) * sy
			var rect_d: Rect2 = Rect2(Vector2(dx - 1.5, min(ty, by)), Vector2(3.0, max(abs(by - ty), 2.0)))
			draw_rect(rect_d, Color(0.55, 0.35, 0.2, 0.95), true)
	# discovered chests
	for id3 in discovered_chests.keys():
		var rec_c: Dictionary = discovered_chests[id3]
		var cx2: float = padding + (float(rec_c["x"]) - min_x) * sx
		var cy2: float = padding + (float(rec_c["y"]) - min_y_ext) * sy
		var rect_c: Rect2 = Rect2(Vector2(cx2 - 2.0, cy2 - 2.0), Vector2(4.0, 4.0))
		draw_rect(rect_c, Color(0.9, 0.75, 0.2, 1.0), true)
	# discovered walls
	for id4 in discovered_walls.keys():
		var rec_w: Dictionary = discovered_walls[id4]
		if bool(rec_w.get("border", false)):
			continue
		var wx: float = padding + (float(rec_w["x"]) - min_x) * sx
		var wy1: float = padding + (float(rec_w["top"]) - min_y_ext) * sy
		var wy2: float = padding + (float(rec_w["bottom"]) - min_y_ext) * sy
		var h_m: float = max(abs(wy2 - wy1), 2.0)
		var rect_w: Rect2 = Rect2(Vector2(wx - 2.0, min(wy1, wy2)), Vector2(4.0, h_m))
		draw_rect(rect_w, Color(0.5, 0.5, 0.7, 0.95), true)
	# exit
	if level_ref.has_node("Exit"):
		var ep: Vector2 = level_ref.get_node("Exit").global_position
		var ex: float = padding + (ep.x - min_x) * sx
		var ey: float = padding + (ep.y - min_y_ext) * sy
		draw_circle(Vector2(ex, ey), 3.0, Color(0.2, 1.0, 0.2, 1.0))
	# player
	if player_ref:
		var pp: Vector2 = player_ref.global_position
		var px: float = padding + (pp.x - min_x) * sx
		var py: float = padding + (pp.y - min_y_ext) * sy
		draw_circle(Vector2(px, py), 3.0, Color(0.3, 0.8, 1.0, 1.0))
	# borders
	var bx_l: float = padding + (min_x - min_x) * sx
	var bx_r: float = padding + (max_x - min_x) * sx
	draw_rect(Rect2(Vector2(bx_l - 2.0, padding), Vector2(4.0, size.y - padding * 2.0)), Color(0.35, 0.35, 0.5, 0.8), true)
	draw_rect(Rect2(Vector2(bx_r - 2.0, padding), Vector2(4.0, size.y - padding * 2.0)), Color(0.35, 0.35, 0.5, 0.8), true)
func _update_discovered():
	if level_ref == null or player_ref == null:
		return
	var cam: Camera2D = null
	if player_ref.has_node("Camera2D"):
		cam = player_ref.get_node("Camera2D")
	if cam == null:
		return
	var vp: Vector2 = player_ref.get_viewport().get_visible_rect().size
	var zoom: float = float(cam.zoom.y)
	var view_w: float = vp.x / max(zoom, 0.0001)
	var view_h: float = vp.y / max(zoom, 0.0001)
	var center: Vector2 = player_ref.global_position + cam.position
	var left: float = center.x - view_w * 0.5
	var right: float = center.x + view_w * 0.5
	var top: float = center.y - view_h * 0.5
	var bottom: float = center.y + view_h * 0.5
	for c in get_tree().get_nodes_in_group("chest"):
		if c and c is Node2D:
			var cid: int = (c as Node).get_instance_id()
			var pos: Vector2 = (c as Node2D).global_position
			if pos.x >= left and pos.x <= right and pos.y >= top and pos.y <= bottom:
				discovered_chests[cid] = {"x": pos.x, "y": pos.y}
	# 移除已消失的宝箱
	var chest_ids_live: Dictionary = {}
	for c2 in get_tree().get_nodes_in_group("chest"):
		if c2 and c2 is Node:
			chest_ids_live[(c2 as Node).get_instance_id()] = true
	var to_remove: Array = []
	for kid in discovered_chests.keys():
		if not chest_ids_live.has(kid):
			to_remove.append(kid)
	for rid in to_remove:
		discovered_chests.erase(rid)
	for d in get_tree().get_nodes_in_group("door"):
		if d and d is Node2D:
			var posd: Vector2 = (d as Node2D).global_position
			if posd.x >= left and posd.x <= right and posd.y >= top and posd.y <= bottom:
				var dh_v = d.get("door_h")
				var dh: float = 36.0
				if dh_v != null:
					dh = float(dh_v)
				var y_top_d: float = posd.y - dh
				if d.has_method("_closed_top_position"):
					var top_vec: Vector2 = d.call("_closed_top_position")
					y_top_d = float(top_vec.y)
				discovered_doors[(d as Node).get_instance_id()] = {"x": posd.x, "top": y_top_d, "bottom": posd.y}
	for l in get_tree().get_nodes_in_group("ladder"):
		if l and l is Node2D:
			var wl = l.get("width")
			var hl = l.get("height")
			var w_l: float = wl if wl != null else 12.0
			var h_l: float = hl if hl != null else 80.0
			var posl: Vector2 = (l as Node2D).global_position
			var l_left: float = posl.x - float(w_l) * 0.5
			var l_right: float = posl.x + float(w_l) * 0.5
			var l_top: float = posl.y - float(h_l) * 0.5
			var l_bottom: float = posl.y + float(h_l) * 0.5
			if l_right >= left and l_left <= right and l_bottom >= top and l_top <= bottom:
				discovered_ladders[(l as Node).get_instance_id()] = {"x": posl.x, "top": l_top, "bottom": l_bottom}
	for w in get_tree().get_nodes_in_group("wall"):
		if w and w is Node2D:
			var poly: Polygon2D = null
			var is_border: bool = false
			if w is Polygon2D:
				poly = w as Polygon2D
				var pr = (w as Node).get_parent()
				if pr and pr is Node and (pr as Node).get("name") != null and String((pr as Node).get("name")) == "Borders":
					is_border = true
			else:
				for c in (w as Node2D).get_children():
					if c is Polygon2D:
						poly = c as Polygon2D
						var pr2 = (c as Node).get_parent()
						if pr2 and pr2 is Node and (pr2 as Node).get("name") != null and String((pr2 as Node).get("name")) == "Borders":
							is_border = true
						break
			var miny: float = 0.0
			var maxy: float = 0.0
			var wx: float = (w as Node2D).global_position.x
			if poly:
				var pts: PackedVector2Array = poly.polygon
				var local_min_y: float = 999999.0
				var local_max_y: float = -999999.0
				for i in range(pts.size()):
					local_min_y = min(local_min_y, pts[i].y)
					local_max_y = max(local_max_y, pts[i].y)
				var top_world: Vector2 = (poly as Node2D).to_global(Vector2(0, local_min_y))
				var bottom_world: Vector2 = (poly as Node2D).to_global(Vector2(0, local_max_y))
				miny = min(top_world.y, bottom_world.y)
				maxy = max(top_world.y, bottom_world.y)
			else:
				var posw: Vector2 = (w as Node2D).global_position
				miny = posw.y - 40.0
				maxy = posw.y + 40.0
			if maxy >= top and miny <= bottom and wx >= left - 2.0 and wx <= right + 2.0:
				discovered_walls[(w as Node).get_instance_id()] = {"x": wx, "top": miny, "bottom": maxy, "border": is_border}
