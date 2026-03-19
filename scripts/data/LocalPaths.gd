extends Node

class_name LocalPaths

static func root_dir() -> String:
	if OS.has_feature("web"):
		return "user://"
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://")
	var exe := OS.get_executable_path()
	if exe == "":
		return "user://"
	return exe.get_base_dir()

static func file_path(filename: String) -> String:
	return root_dir().path_join(filename)

static func ensure_text_file(filename: String, res_path: String, default_text: String = "") -> String:
	var dst := file_path(filename)
	if FileAccess.file_exists(dst):
		var existing := ""
		var ef := FileAccess.open(dst, FileAccess.READ)
		if ef:
			existing = ef.get_as_text()
			ef.close()
		if existing.strip_edges() != "":
			return dst
	var content := ""
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f:
		content = f.get_as_text()
		f.close()
	if content.strip_edges() == "" and default_text != "":
		content = default_text
	if content.strip_edges() != "":
		var wf := FileAccess.open(dst, FileAccess.WRITE)
		if wf:
			wf.store_string(content)
			wf.close()
	return dst
