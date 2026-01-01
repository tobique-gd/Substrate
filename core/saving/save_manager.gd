extends Node

var registered := []
var current_path : String = ""
var has_unsaved_changes : bool = false
var current_window_title : String = ""

var recent_files : Dictionary = {}
var current_file = ""

func register_property(node: Object, property: String) -> void:
	registered.append({
		"path": String(node.get_path()),
		"property": property
	})

func mark_modified():
	if current_window_title != "":
		if current_window_title[0] != "*":
			update_window_title("*"+current_window_title)
	has_unsaved_changes = true

func update_window_title(updated_title : String):
	DisplayServer.window_set_title(updated_title)
	current_window_title = updated_title

func add_recent_file(path: String):
	var timestamp = Time.get_unix_time_from_system()
	recent_files[path] = {
		"path": path,
		"last_used": timestamp
	}
	if recent_files.size() > 10:
		var oldest = null
		for key in recent_files.keys():
			if oldest == null or recent_files[key]["last_used"] < recent_files[oldest]["last_used"]:
				oldest = key
		recent_files.erase(oldest)

func save_recent_files():
	var f = FileAccess.open(GlobalPaths.recent_files_log_path, FileAccess.WRITE)
	f.store_var(recent_files)
	f.close()

func load_recent_files():
	if !FileAccess.file_exists(GlobalPaths.recent_files_log_path):
		recent_files = {}
		return
	
	var f = FileAccess.open(GlobalPaths.recent_files_log_path, FileAccess.READ)
	recent_files = f.get_var()
	f.close()

func get_recent_files_sorted() -> Array:
	var arr = recent_files.values()
	arr.sort_custom(_sort_by_last_used)
	return arr

func _sort_by_last_used(a, b):
	return int(b["last_used"] - a["last_used"])

func _ready():
	load_recent_files()
	await get_tree().process_frame
	assert_window_title()
	
	
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		for arg in args:
			if arg.ends_with(".substrate"):
				open_substrate_file(arg)

func assert_window_title():
	current_file = "Untitled" if current_path == "" else current_path.split("/")[-1]
	update_window_title("Substrate - " + current_file)

func open_substrate_file(path: String):
	if !FileAccess.file_exists(path):
		return
	
	current_path = path
	has_unsaved_changes = false
	registered.clear()
	assert_window_title()

	add_recent_file(path)
	save_recent_files()

	var current_scene = get_tree().get_current_scene()
	if current_scene:
		current_scene.queue_free()

	await get_tree().create_timer(0.5).timeout
	var base_scene = preload("res://preview/main.tscn").instantiate()
	get_tree().get_root().add_child(base_scene)
	get_tree().set_current_scene(base_scene)

	load_substrate(path)

func save() -> bool:
	if current_path == "":
		return false
	save_substrate(current_path)
	has_unsaved_changes = false

	add_recent_file(current_path)
	save_recent_files()
	return true

func save_as(path: String):
	current_path = path
	save_substrate(path)
	has_unsaved_changes = false

	add_recent_file(path)
	save_recent_files()

func save_substrate(path: String) -> void:
	var root : Dictionary = {}
	for item in registered:
		var node := get_node_or_null(item.path)
		if not node:
			continue
		var value = node.get(item.property)
		root[item.path] = root.get(item.path, {})
		root[item.path][item.property] = _encode(value)

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(root)
	file.close()
	
	assert_window_title()

func load_substrate(path: String) -> void:
	if !FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return

	for node_path in data.keys():
		var node := get_node_or_null(NodePath(node_path))
		if not node:
			continue
		for prop in data[node_path].keys():
			node.set(String(prop), _decode(data[node_path][prop]))
		if node.has_method("load_substrate_data"):
			node.load_substrate_data()

func _encode(value):
	if typeof(value) == TYPE_OBJECT and value is Resource:
		return { "__res__": value.resource_path }
	if typeof(value) == TYPE_ARRAY:
		var out := []
		for v in value:
			out.append(_encode(v))
		return out
	if typeof(value) == TYPE_DICTIONARY:
		var out := {}
		for k in value.keys():
			out[k] = _encode(value[k])
		return out
	return value

func _decode(value):
	if typeof(value) == TYPE_DICTIONARY and value.has("__res__"):
		return load(value["__res__"])
	if typeof(value) == TYPE_ARRAY:
		var out := []
		for v in value:
			out.append(_decode(v))
		return out
	if typeof(value) == TYPE_DICTIONARY:
		var out := {}
		for k in value.keys():
			out[k] = _decode(value[k])
		return out
	return value

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Shortcuts.is_shortcut(event, Shortcuts.shortcuts["save_project"]):
			if current_path == "":
				var fd := FileDialog.new()
				get_tree().get_root().add_child(fd)
				fd.use_native_dialog = true
				fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
				fd.access = FileDialog.ACCESS_FILESYSTEM
				fd.filters = ["*.substrate"]
				fd.popup_centered(Vector2i(200, 200))
				fd.file_selected.connect(_on_save_as_selected.bind())
			else:
				save()

func _on_save_as_selected(path: String) -> void:
	save_as(path)
