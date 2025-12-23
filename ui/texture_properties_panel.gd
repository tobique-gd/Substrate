extends Control

@export var add_meshset_menu : Control
@export var meshset_list : ItemList
@export var meshset_mesh_preview_container : HFlowContainer

var meshsets : Array[Dictionary] = []


@onready var MESHSET_MESH_ENTRY = preload("res://ui/customui/meshset_mesh_entry.tscn")

var preview_request_id : int = 0

signal generate_texture(meshset_data)

@export var texture_creator_node : Node3D

func get_texture_parameters_from_node(node):
	return node.texture_parameters

func _ready() -> void:
	clear_add()
	
	add_meshset_menu.meshset_updated.connect(update_meshset_list.bind())

func _on_add_meshset_button_pressed() -> void:
	add_meshset_menu.show()

func update_meshset_list(m_meshsets:Array[Dictionary]):
	meshsets.append_array(m_meshsets)
	for meshset in m_meshsets:
		meshset_list.add_item(meshset["item_name"], meshset["item_tex"])
	
	update_texture()

func _on_remove_meshset_button_pressed() -> void:
	var selected := meshset_list.get_selected_items()
	selected.sort()
	selected.reverse()
	for index in selected:
		meshsets.remove_at(index)
		meshset_list.remove_item(index)
	
	if meshset_list.item_count == 0:
		update_texture()
		clear()
		clear_add()
		delete_meshset_previews()
		return
	
	delete_meshset_previews()
	update_texture()
		
		

var current_meshset:Dictionary = {}

func delete_meshset_previews():
	for c in meshset_mesh_preview_container.get_children():
		c.queue_free()

func _on_meshset_list_item_selected(index: int) -> void:
	preview_request_id += 1
	var request_id = preview_request_id
	
	delete_meshset_previews()
	
	current_meshset = {}
	for mset in meshsets:
		
		if mset["item_name"] == meshset_list.get_item_text(index):
			current_meshset = mset
			break
	
	if current_meshset.is_empty():
		return
	
	for uid in current_meshset["item_models"].keys():
		var entry_data = current_meshset["item_models"][uid]
		var meshinstance : MeshInstance3D = entry_data["mesh"]
		var mesh = meshinstance.mesh
		
		var img = await MeshsetPreview.render_meshset_mesh_preview(mesh, Vector2i(256, 256))
		
		if request_id != preview_request_id:
			return
		
		var tex : ImageTexture = ImageTexture.create_from_image(img)
		var entry = MESHSET_MESH_ENTRY.instantiate()
		meshset_mesh_preview_container.add_child(entry)
		entry.panel_clicked.connect(_on_panel_clicked.bind())
		entry.uid = uid
		
		
		entry.selected = current_meshset["item_models"][uid]["allowed"]
		entry.update()
		
		entry.update_image_texture(tex)



func _on_panel_clicked(uid: int, selected: bool) -> void:
	if current_meshset.is_empty():
		return
	if not current_meshset["item_models"].has(uid):
		return
	current_meshset["item_models"][uid]["allowed"] = selected
	
	update_texture()

func update_texture():
	emit_signal("generate_texture", meshsets)
	
	clear()
	build_ui(get_texture_parameters_from_node(texture_creator_node))



@export var properties : GridContainer

signal params_changed(params)

var original_params = {}

func build_ui(params):
	original_params = params.duplicate(true)
	
	var node_name = Label.new()
	node_name.text = "Texture Properties"
	var font = load("res://assets/fonts/Lato/Lato-Bold.ttf")
	node_name.add_theme_font_override("font", font)
	node_name.add_theme_font_size_override("font_size", 28)



	node_name.add_theme_font_override("default_font", load("res://assets/fonts/Lato/Lato-Bold.ttf"))
	properties.add_child(node_name)
	var sep = HSeparator.new()
	properties.add_child(sep)
	
	for param in params.keys():
		if params[param]["type"] == "float" or params[param]["type"] == " int":
			var param_label = Label.new()
			param_label.text = param.capitalize()
			var slider_s = load("res://ui/customui/parameter_slider.tscn")
			var slider : ProgressBar= slider_s.instantiate()
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.size_flags_vertical = Control.SIZE_FILL
			
			slider.name = param
			slider.min_value = params[param]["min"]
			slider.max_value = params[param]["max"]
			slider.value = params[param]["value"]
			slider.value_changed.connect(_on_slider_changed.bind(param))
			properties.add_child(param_label)
			properties.add_child(slider)
			
			if params[param]["type"] == "float":
				slider.step = (params[param]["max"] - params[param]["min"]) / 1000.0
			if params[param]["type"] == "int":
				slider.step = 1
		else:
			if params[param]["type"] == "vec3":
				var vec3_component_loader = load("res://ui/customui/vector3_component.tscn")
				var vec3_component : Panel = vec3_component_loader.instantiate()
				
				var param_label = Label.new()
				param_label.text = param.capitalize()
				
				properties.add_child(param_label)
				properties.add_child(vec3_component)

func _on_slider_changed(value, param):
	original_params[param]["value"] = value
	texture_creator_node.texture_parameters = original_params
	emit_signal("generate_texture", meshsets)

func get_properties():
	return original_params

func clear():
	for c in properties.get_children():
		c.queue_free()
	
func clear_add():
	var node_name = Label.new()
	node_name.text = "Texture Properties"
	var font = load("res://assets/fonts/Lato/Lato-Bold.ttf")
	node_name.add_theme_font_override("font", font)
	node_name.add_theme_font_size_override("font_size", 28)
	properties.add_child(node_name)
	var sep = HSeparator.new()
	properties.add_child(sep)
	
