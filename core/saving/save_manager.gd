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
			update_window_title("*" + current_window_title)
	has_unsaved_changes = true

func update_window_title(updated_title : String):
	DisplayServer.window_set_title(updated_title)
	current_window_title = updated_title

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
	var save_data := {}

	for item in registered:
		var node := get_node_or_null(item.path)
		if not node:
			continue

		var value = node.get(item.property)
		value = serialize_resources(value)

		if not save_data.has(item.path):
			save_data[item.path] = {}
		save_data[item.path][item.property] = value

	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_var(save_data)
	f.close()
	assert_window_title()

func load_substrate(path: String) -> void:
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

	var f = FileAccess.open(path, FileAccess.READ)
	var save_data = f.get_var()
	f.close()

	for node_path in save_data.keys():
		var node := get_node_or_null(NodePath(node_path))
		if not node:
			continue

		for prop in save_data[node_path].keys():
			var val = deserialize_resources(save_data[node_path][prop])
			node.set(prop, val)

		if node.has_method("load_substrate_data"):
			await node.load_substrate_data()

func assert_window_title():
	current_file = "Untitled" if current_path == "" else current_path.get_file()
	update_window_title("Substrate - " + current_file)

func add_recent_file(path: String):
	var timestamp = Time.get_unix_time_from_system()
	recent_files[path] = {"path": path, "last_used": timestamp}
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
	var arr := recent_files.values()
	arr.sort_custom(func(a, b):
		return int(b["last_used"] - a["last_used"])
	)
	return arr

func _ready():
	load_recent_files()
	await get_tree().process_frame
	assert_window_title()

	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.ends_with(".substrate"):
			open_substrate_file(arg)

func open_substrate_file(path: String):
	load_substrate(path)

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



func serialize_resources(value):
	if value is Resource:
		return {"__is_resource": true, "bytes": resource_to_bytes(value), "type": value.get_class()}
	elif value is Dictionary:
		var new_dict = {}
		for k in value.keys():
			new_dict[k] = serialize_resources(value[k])
		return new_dict
	elif value is Array:
		var new_arr = []
		for item in value:
			new_arr.append(serialize_resources(item))
		return new_arr
	else:
		return value

func deserialize_resources(value):
	if value is Dictionary and value.get("__is_resource", false):
		return bytes_to_resource(value.bytes)
	elif value is Dictionary:
		var new_dict = {}
		for k in value.keys():
			new_dict[k] = deserialize_resources(value[k])
		return new_dict
	elif value is Array:
		var new_arr = []
		for item in value:
			new_arr.append(deserialize_resources(item))
		return new_arr
	else:
		return value


func resource_to_bytes(res: Resource) -> PackedByteArray:
	var tmp_path = "user://temp_res.tres"
	ResourceSaver.save(res, tmp_path)
	var f = FileAccess.open(tmp_path, FileAccess.READ)
	var bytes = f.get_buffer(f.get_length())
	f.close()
	DirAccess.remove_absolute(tmp_path)
	return bytes

func bytes_to_resource(bytes: PackedByteArray) -> Resource:
	var tmp_path = "user://temp_load_res.tres"
	var f = FileAccess.open(tmp_path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	var res = load(tmp_path)
	DirAccess.remove_absolute(tmp_path)
	return res
