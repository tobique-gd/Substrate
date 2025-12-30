extends Node

var registered := []

func register_property(node: Object, property: String) -> void:
	registered.append({
		"path": String(node.get_path()),
		"property": property
	})

func _ready():
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		for arg in args:
			if arg.ends_with(".substrate"):
				open_substrate_file(arg)


	
func open_substrate_file(path: String):
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		current_scene.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	var base_scene = preload("res://preview/main.tscn").instantiate()
	get_tree().get_root().add_child(base_scene)
	get_tree().set_current_scene(base_scene)
	
	SaveManager.load_substrate(path)
	
	if base_scene.has_method("on_substrate_loaded"):
		base_scene.on_substrate_loaded()



func save_substrate(path: String) -> void:
	var root := {}
	
	for item in registered:
		var node := get_node_or_null(item.path)
		if not node:
			continue
		var value = node.get(item.property)
		root[item.path] = root.get(item.path, {})
		root[item.path][item.property] = _encode(value)
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(root)

func load_substrate(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
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

#REMOVE IN BUILD
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cut"):
		save_substrate("user://test.substrate")
	
	if Input.is_action_just_pressed("ui_copy"):
		open_substrate_file("user://test.substrate")
