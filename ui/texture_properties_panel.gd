extends Control

@export var add_meshset_menu : Control
@export var meshset_list : ItemList
@export var meshset_mesh_preview_container : HFlowContainer
@export var texture_creator_node : Node3D
@export var properties : GridContainer

@onready var MESHSET_MESH_ENTRY = preload("res://ui/customui/meshset_mesh_entry.tscn")

signal generate_texture(meshset_data)
signal params_changed(params)

var meshsets : Array[Dictionary] = []
var current_meshset : Dictionary = {}
var preview_request_id : int = 0
var original_params = {}

func _ready() -> void:
	_init_properties_header()
	add_meshset_menu.meshset_updated.connect(update_meshset_list.bind())

func get_texture_parameters_from_node(node):
	return node.texture_parameters

func _on_add_meshset_button_pressed() -> void:
	add_meshset_menu.show()

func update_meshset_list(m_meshsets : Array[Dictionary]) -> void:
	meshsets.append_array(m_meshsets)
	_add_meshsets_to_list(m_meshsets)
	update_texture()

func _on_remove_meshset_button_pressed() -> void:
	_remove_selected_meshsets()
	if meshset_list.item_count == 0:
		_reset_all()
	else:
		_refresh_after_meshset_change()

func _on_meshset_list_item_selected(index : int) -> void:
	await _build_meshset_previews(index)

func _on_panel_clicked(uid : int, selected : bool) -> void:
	if current_meshset.is_empty():
		return
	if not current_meshset["item_models"].has(uid):
		return
	current_meshset["item_models"][uid]["allowed"] = selected
	update_texture()

func update_texture() -> void:
	emit_signal("generate_texture", meshsets)
	_rebuild_properties_ui()

func _on_slider_changed(value, param) -> void:
	original_params[param]["value"] = value
	texture_creator_node.texture_parameters = original_params
	emit_signal("generate_texture", meshsets)

func _on_vec3_component_changed(value, param) -> void:
	original_params[param]["value"] = value
	texture_creator_node.texture_parameters = original_params
	emit_signal("generate_texture", meshsets)


func get_properties():
	return original_params

func _add_meshsets_to_list(m_meshsets : Array[Dictionary]) -> void:
	for meshset in m_meshsets:
		meshset_list.add_item(meshset["item_name"], meshset["item_tex"])

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

func _find_meshset_by_name(name : String) -> Dictionary:
	for mset in meshsets:
		if mset["item_name"] == name:
			return mset
	return {}

func _build_meshset_previews(index : int) -> void:
	preview_request_id += 1
	var request_id = preview_request_id

	_delete_meshset_previews()
	current_meshset = _find_meshset_by_name(meshset_list.get_item_text(index))
	if current_meshset.is_empty():
		return

	for uid in current_meshset["item_models"].keys():
		var entry_data = current_meshset["item_models"][uid]
		var mesh : Mesh = entry_data["mesh"].mesh
		var img = await MeshsetPreview.render_meshset_mesh_preview(mesh, Vector2i(256, 256))
		if request_id != preview_request_id:
			return
		_create_mesh_preview_entry(uid, img)

func _create_mesh_preview_entry(uid : int, img : Image) -> void:
	var tex : ImageTexture = ImageTexture.create_from_image(img)
	var entry = MESHSET_MESH_ENTRY.instantiate()
	meshset_mesh_preview_container.add_child(entry)
	entry.panel_clicked.connect(_on_panel_clicked.bind())
	entry.uid = uid
	entry.selected = current_meshset["item_models"][uid]["allowed"]
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
	label.add_theme_font_size_override("font_size", 20)
	properties.add_child(label)
	properties.add_child(HSeparator.new())

func clear() -> void:
	for c in properties.get_children():
		c.queue_free()
