extends Node

const EQUIPMENT_CSV_PATH = "res://data/equipment.csv"
const EQUIPMENT_PACKED_PATH = "res://data/packed/equipment.json"

var equipment_data: Dictionary = {}

func _ready():
    load_equipment_data()

func load_equipment_data():
    equipment_data.clear()
    if _should_use_packed(EQUIPMENT_CSV_PATH, EQUIPMENT_PACKED_PATH):
        if _load_from_json(EQUIPMENT_PACKED_PATH):
            return
    if _load_from_csv(EQUIPMENT_CSV_PATH):
        _write_packed(EQUIPMENT_PACKED_PATH)
        return
    print("Error: Could not open equipment data.")

func _load_from_csv(path: String) -> bool:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return false
    var headers = file.get_csv_line()
    while not file.eof_reached():
        var line = file.get_csv_line()
        if line.size() != headers.size():
            continue
        var entry = {}
        for i in range(headers.size()):
            entry[headers[i]] = line[i]
        var id := String(entry.get("id", ""))
        if id != "":
            equipment_data[id] = entry
    file.close()
    return equipment_data.size() > 0

func _load_from_json(path: String) -> bool:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return false
    var text := f.get_as_text()
    f.close()
    var data = JSON.parse_string(text)
    if data is Array:
        for rec_i in data:
            if rec_i is Dictionary:
                var rec: Dictionary = rec_i
                var id := String(rec.get("id", ""))
                if id != "":
                    equipment_data[id] = rec
    return equipment_data.size() > 0

func _write_packed(path: String):
    var dir := DirAccess.open("res://")
    if dir:
        dir.make_dir_recursive("data/packed")
    var arr: Array = []
    for k in equipment_data.keys():
        arr.append(equipment_data[k])
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(arr))
        f.close()

func _should_use_packed(csv_path: String, packed_path: String) -> bool:
    if not FileAccess.file_exists(packed_path):
        return false
    if not FileAccess.file_exists(csv_path):
        return true
    var csv_mtime: int = int(FileAccess.get_modified_time(csv_path))
    var packed_mtime: int = int(FileAccess.get_modified_time(packed_path))
    return packed_mtime >= csv_mtime

func get_equipment_by_id(id: String) -> Dictionary:
    return equipment_data.get(id, {})

func get_all_equipment() -> Dictionary:
    return equipment_data

func build_equipment_icon(attack_id: String, size: int = 112) -> Texture2D:
    var img: Image = null
    if attack_id == "bullet":
        img = _build_gun_image(18, 7)
    elif attack_id == "melee":
        img = _build_sword_image(6, 16)
    elif attack_id == "magic":
        img = _build_orb_image(16, 16)
    elif attack_id == "roar":
        img = _build_dragon_head_image(28, 20)
    if img == null:
        return null
    if size > 0:
        var w: int = img.get_width()
        var h: int = img.get_height()
        var max_dim: int = max(w, h)
        var scale: float = float(size) / float(max(max_dim, 1))
        var target_w: int = max(1, int(round(w * scale)))
        var target_h: int = max(1, int(round(h * scale)))
        img.resize(target_w, target_h, Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(img)

func _build_gun_image(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var metal := Color(0.08, 0.08, 0.1, 1.0)
    var dark := Color(0.18, 0.2, 0.24, 1.0)
    var barrel := Color(0.06, 0.06, 0.08, 1.0)
    var wood := Color(0.55, 0.32, 0.16, 1.0)
    _rect(img, 1, 3, 15, 2, metal)
    _rect(img, 13, 2, 4, 2, barrel)
    _rect(img, 2, 2, 3, 2, wood)
    _rect(img, 6, 3, 5, 2, wood)
    _rect(img, 11, 5, 2, 2, dark)
    _rect(img, 10, 4, 1, 2, dark)
    _rect(img, 4, 5, 2, 1, dark)
    _rect(img, 6, 5, 2, 2, wood)
    return img

func _build_sword_image(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var metal := Color(0.75, 0.8, 0.9, 1.0)
    var dark := Color(0.2, 0.22, 0.3, 1.0)
    var glow := Color(0.5, 0.9, 1.0, 1.0)
    var wood := Color(0.5, 0.3, 0.16, 1.0)
    _rect(img, 2, 1, 2, 11, metal)
    _rect(img, 2, 2, 1, 9, glow)
    _rect(img, 1, 12, 4, 1, dark)
    _rect(img, 2, 13, 2, 2, wood)
    return img

func _build_orb_image(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var gold := Color(0.95, 0.82, 0.28, 1.0)
    var gold_dark := Color(0.35, 0.25, 0.12, 1.0)
    var white := Color(0.96, 0.94, 0.88, 1.0)
    var black := Color(0.05, 0.05, 0.08, 1.0)
    var red := Color(0.85, 0.18, 0.18, 1.0)
    var cx: float = w * 0.5 - 0.5
    var cy: float = h * 0.5 - 0.5
    var r: float = min(w, h) * 0.5 - 0.5
    for y in range(h):
        for x in range(w):
            var sx: float = float(x) - cx
            var sy: float = float(y) - cy
            var adx: float = abs(sx)
            var ady: float = abs(sy)
            var maxd: float = max(adx, ady)
            if maxd > r:
                continue
            if adx + ady > r * 1.55:
                continue
            var d: float = sqrt(sx * sx + sy * sy)
            var ang: float = atan2(sy, sx)
            var col := black
            if d >= r * 0.88:
                col = gold_dark
            elif d >= r * 0.78:
                col = gold
            elif d >= r * 0.7:
                col = red
            elif d >= r * 0.62:
                col = black
                var seg := int(floor(((ang + PI) / TAU) * 24.0))
                if seg % 6 == 0:
                    col = gold
            elif d >= r * 0.56:
                col = gold
            else:
                var curve: float = sy + sin(sx / max(r, 1.0) * PI) * r * 0.2
                col = white if curve >= 0.0 else black
                var top_dot: float = sqrt(sx * sx + (sy + r * 0.32) * (sy + r * 0.32))
                var bot_dot: float = sqrt(sx * sx + (sy - r * 0.32) * (sy - r * 0.32))
                if top_dot <= r * 0.16:
                    col = black
                if bot_dot <= r * 0.16:
                    col = white
            img.set_pixel(x, y, col)
    for i in range(8):
        var ang2: float = TAU * float(i) / 8.0 + 0.2
        var px2: int = int(round(cx + cos(ang2) * r * 0.8))
        var py2: int = int(round(cy + sin(ang2) * r * 0.8))
        if px2 >= 0 and py2 >= 0 and px2 < img.get_width() and py2 < img.get_height():
            img.set_pixel(px2, py2, red)
    for i3 in range(8):
        var ang3: float = TAU * float(i3) / 8.0
        var px3: int = int(round(cx + cos(ang3) * r * 0.95))
        var py3: int = int(round(cy + sin(ang3) * r * 0.95))
        if px3 >= 0 and py3 >= 0 and px3 < img.get_width() and py3 < img.get_height():
            img.set_pixel(px3, py3, gold_dark)
    img.set_pixel(int(cx), int(cy), red)
    return img

func _build_roar_image(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var blue := Color(0.35, 0.75, 1.0, 1.0)
    var cyan := Color(0.6, 0.95, 1.0, 0.9)
    var white := Color(0.9, 0.98, 1.0, 0.9)
    var cx: float = w * 0.5 - 0.5
    var cy: float = h * 0.5 - 0.5
    var r: float = min(w, h) * 0.5 - 0.5
    for y in range(h):
        for x in range(w):
            var dx: float = float(x) - cx
            var dy: float = float(y) - cy
            var d: float = sqrt(dx * dx + dy * dy)
            if d > r:
                continue
            var band1: float = abs(d - r * 0.35)
            var band2: float = abs(d - r * 0.6)
            var band3: float = abs(d - r * 0.85)
            if band1 <= 0.7:
                img.set_pixel(x, y, white)
            elif band2 <= 0.7:
                img.set_pixel(x, y, cyan)
            elif band3 <= 0.7:
                img.set_pixel(x, y, blue)
    return img

func _build_dragon_head_image(w: int, h: int) -> Image:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var main := Color(0.98, 0.82, 0.26, 1.0)
    var mid := Color(0.92, 0.7, 0.2, 1.0)
    var dark := Color(0.62, 0.42, 0.12, 1.0)
    var horn := Color(1.0, 0.95, 0.7, 1.0)
    var whisker := Color(1.0, 0.96, 0.82, 0.85)
    var eye := Color(1.0, 0.45, 0.25, 1.0)
    var pupil := Color(0.18, 0.08, 0.02, 1.0)
    var nose := Color(0.3, 0.2, 0.08, 1.0)
    _rect(img, 5, 8, 14, 7, main)
    _rect(img, 7, 6, 12, 3, mid)
    _rect(img, 10, 4, 8, 3, mid)
    _rect(img, 19, 9, 5, 5, dark)
    _rect(img, 20, 8, 4, 2, dark)
    _rect(img, 22, 10, 2, 2, dark)
    _rect(img, 6, 5, 3, 1, dark)
    _rect(img, 16, 5, 2, 1, dark)
    _rect(img, 9, 3, 3, 2, horn)
    _rect(img, 15, 3, 3, 2, horn)
    _rect(img, 8, 2, 2, 1, horn)
    _rect(img, 17, 2, 2, 1, horn)
    _rect(img, 7, 7, 2, 2, eye)
    _rect(img, 8, 8, 1, 1, pupil)
    _rect(img, 18, 7, 1, 1, nose)
    _rect(img, 6, 10, 4, 1, whisker)
    _rect(img, 6, 11, 5, 1, whisker)
    _rect(img, 6, 12, 4, 1, whisker)
    _rect(img, 17, 10, 5, 1, whisker)
    _rect(img, 16, 11, 6, 1, whisker)
    _rect(img, 17, 12, 5, 1, whisker)
    _rect(img, 3, 11, 3, 1, dark)
    _rect(img, 23, 11, 3, 1, dark)
    return img

func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
    for yy in range(h):
        for xx in range(w):
            var px := x + xx
            var py := y + yy
            if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
                img.set_pixel(px, py, col)
