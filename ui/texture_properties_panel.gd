extends Control

@export var add_meshset_menu : Control
@export var meshset_list : ItemList
@export var meshset_mesh_preview_container : HFlowContainer
@export var texture_creator_node : Node3D
@export var properties : GridContainer

@onready var MESHSET_MESH_ENTRY = preload("res://ui/customui/meshset_mesh_entry.tscn")

signal generate_texture(meshset_data)
signal params_changed(params)

var meshsets : Array = []
var current_meshset : Dictionary = {}
var preview_request_id : int = 0
var original_params = {}


const MESH_UID_BITS := 16
const MESH_UID_MASK := (1 << MESH_UID_BITS) - 1

func _ready() -> void:
	SaveManager.register_property(self, "meshsets")
	_init_properties_header()
	add_meshset_menu.meshset_updated.connect(update_meshset_list.bind())

func load_substrate_data():
	_add_meshsets_to_list(meshsets)
	update_texture(true)


func get_texture_parameters_from_node(node):
	return node.texture_parameters

func _on_add_meshset_button_pressed() -> void:
	add_meshset_menu.show()

func update_meshset_list(m_meshsets : Array[Dictionary]) -> void:
	meshsets.append_array(m_meshsets)
	_add_meshsets_to_list(m_meshsets)
	update_texture(true)

	

	

func _on_remove_meshset_button_pressed() -> void:
	_remove_selected_meshsets()
	if meshset_list.item_count == 0:
		_reset_all()
	else:
		_refresh_after_meshset_change()

func _on_meshset_list_item_selected(index : int) -> void:
	await _build_meshset_previews(index)

func _on_panel_clicked(uid : int, selected : bool) -> void:
	var data = unpack_preview_uid(uid)

	if current_meshset.is_empty():
		return
	if not current_meshset["item_models"].has(data.mesh_uid):
		return

	current_meshset["item_models"][data.mesh_uid]["allowed"] = selected
	update_texture()


func update_texture(rebuild_ui := false) -> void:
	emit_signal("generate_texture", meshsets)
	if rebuild_ui:
		_rebuild_properties_ui()

func _on_slider_changed(value, param) -> void:
	original_params[param]["value"] = value
	texture_creator_node.texture_parameters = original_params
	emit_signal("generate_texture", meshsets)

func _on_vec3_component_changed(value, param) -> void:
	value.x = snapped(value.x, 0.0001)
	value.y = snapped(value.y, 0.0001)
	value.z = snapped(value.z, 0.0001)

	original_params[param]["value"] = value
	texture_creator_node.texture_parameters = original_params
	emit_signal("generate_texture", meshsets)

func make_preview_uid(meshset_uid: int, mesh_uid: int) -> int:
	return (meshset_uid << MESH_UID_BITS) | mesh_uid

func unpack_preview_uid(uid: int) -> Dictionary:
	return {
		"meshset_uid": uid >> MESH_UID_BITS,
		"mesh_uid": uid & MESH_UID_MASK
	}


func get_properties():
	return original_params

var counter = 0

func _add_meshsets_to_list(m_meshsets : Array) -> void:
	for meshset in m_meshsets:
		var meshset_uid = counter
		meshset["uid"] = int(meshset_uid)
		
		var list_index := meshset_list.item_count
		meshset_list.add_item(meshset["item_name"], meshset["item_tex"])
		meshset_list.set_item_metadata(list_index, meshset_uid)

		counter += 1
		
func _remove_selected_meshsets() -> void:
	var selected := meshset_list.get_selected_items()
	selected.sort()
	selected.reverse()
	for index in selected:
		meshsets.remove_at(index)
		meshset_list.remove_item(index)

func _reset_all() -> void:
	update_texture()
	clear()
	_init_properties_header()
	_delete_meshset_previews()

func _refresh_after_meshset_change() -> void:
	_delete_meshset_previews()
	update_texture()

func _delete_meshset_previews() -> void:
	for c in meshset_mesh_preview_container.get_children():
		c.queue_free()

func _find_meshset_by_id(id: int) -> Dictionary:
	for mset in meshsets:
		if mset["uid"] == int(id):
			return mset
	return {}

func _resolve_mesh(entry_data: Dictionary) -> Mesh:
	var scene := load(entry_data["scene_path"]) as PackedScene
	if scene == null:
		return null

	var inst := scene.instantiate()
	var node := inst.get_node_or_null(NodePath(entry_data["node_path"]))
	if node is MeshInstance3D:
		return node.mesh

	return null


func _build_meshset_previews(index : int) -> void:
	preview_request_id += 1
	var request_id = preview_request_id

	_delete_meshset_previews()
	
	var meshset_uid = meshset_list.get_item_metadata(index)
	current_meshset = _find_meshset_by_id(meshset_uid)
	if current_meshset.is_empty():
		return

	for mesh_uid in current_meshset["item_models"].keys():
		var entry_data = current_meshset["item_models"][mesh_uid]
		var mesh := _resolve_mesh(entry_data)
		if mesh == null:
			continue

		var img = await MeshsetPreview.render_meshset_mesh_preview(mesh, Vector2i(256, 256))
		if request_id != preview_request_id:
			return

		var preview_uid := make_preview_uid(meshset_uid, int(mesh_uid))
		_create_mesh_preview_entry(preview_uid, img)



func _create_mesh_preview_entry(uid : int, img : Image) -> void:
	var tex : ImageTexture = ImageTexture.create_from_image(img)
	var entry = MESHSET_MESH_ENTRY.instantiate()
	meshset_mesh_preview_container.add_child(entry)

	entry.panel_clicked.connect(_on_panel_clicked.bind())
	entry.uid = uid

	var data = unpack_preview_uid(uid)
	
	entry.selected = current_meshset["item_models"][data.mesh_uid]["allowed"]

	entry.update()
	entry.update_image_texture(tex)


func _rebuild_properties_ui() -> void:
	clear()
	build_ui(get_texture_parameters_from_node(texture_creator_node))

func build_ui(params) -> void:
	original_params = params.duplicate(true)
	_add_properties_header()
	for param in params.keys():
		_build_param_control(param, params[param])

func _build_param_control(param, data) -> void:
	match data["type"]:
		"float", "int":
			_add_slider_param(param, data)
		"vec3":
			_add_vec3_param(param, data)

func _add_slider_param(param, data) -> void:
	var label = Label.new()
	label.text = param.capitalize()

	var slider = load("res://ui/customui/parameter_slider.tscn").instantiate()
	slider.name = param
	slider.min_value = data["min"]
	slider.max_value = data["max"]
	slider.value = data["value"]
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_FILL
	slider.step = 1 if data["type"] == "int" else 0.001
	slider.value_changed.connect(_on_slider_changed.bind(param))

	properties.add_child(label)
	properties.add_child(slider)

func _add_vec3_param(param, data) -> void:
	var label = Label.new()
	label.text = param.capitalize()

	var vec3_component = load("res://ui/customui/vector3_component.tscn").instantiate()
	vec3_component.update_value(data)
	vec3_component.value_changed.connect(_on_vec3_component_changed.bind(param))
	
	properties.add_child(label)
	properties.add_child(vec3_component)

func _init_properties_header() -> void:
	clear()
	_add_properties_header()

func _add_properties_header() -> void:
	var label = Label.new()
	label.text = "Texture Properties"
	label.add_theme_font_override("font", load("res://assets/fonts/Lato/Lato-Bold.ttf"))
	label.add_theme_font_size_override("font_size", 24)
	properties.add_child(label)
	properties.add_child(HSeparator.new())

func clear() -> void:
	for c in properties.get_children():
		c.queue_free()
