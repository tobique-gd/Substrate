extends Control

signal material_changed(mat)

@export var inspector_panel : Control
@export var node_editor : GraphEdit
@export var mesh_instance: MeshInstance3D
@export var asset_browser_list : ItemList
@export var model_viewport : SubViewportContainer

var selected_node = null
var holding_material = false
var dragged_material: Material = null
var drag_icon: TextureRect = null


func _ready():
	node_editor.render.connect(render_mesh)
	node_editor.clear_selected_node.connect(_clear_selected_node)
	inspector_panel.params_changed.connect(_on_inspector_params_changed)
	set_process_input(true)

func _clear_selected_node():
	selected_node = null
	clear_ui()
	clear_ui_add()

func render_mesh():
	if get_node_editor_children() == 0:
		clear_material()
		clear_tree_mesh()
	
	var connections = get_clean_connections()

	var outgoing = {}
	var incoming = {}
	for c in connections:
		outgoing[c["from_node"]] = c["to_node"]
		incoming[c["to_node"]] = c["from_node"]

	var base_node: GeneratorNode = null
	if connections == []:
		if selected_node:
			base_node = selected_node
		else:
			for node in node_editor.get_children():
				if node is GeneratorNode and node.is_base_node():
					base_node = node
	else:
		for node in node_editor.get_children():
			if node is GraphNode and not incoming.has(node.name):
				base_node = node
				break
		if base_node == null and selected_node:
			base_node = selected_node

	if base_node == null:
		return

	var current: GeneratorNode = base_node
	var result = base_node.generate(base_node.get_parameters(), null)

	while outgoing.has(current.name):
		var next_node_name: String = outgoing[current.name]
		var next_node = node_editor.get_node(next_node_name)
		if next_node is GeneratorNode:
			result = next_node.generate(next_node.get_parameters(), result)
		current = next_node
		
	if result is Mesh:
		set_tree_mesh(result)

func get_clean_connections():
	var existing = {}
	for n in node_editor.get_children():
		existing[n.name] = true

	var clean = []
	for c in node_editor.connections:
		if existing.has(c["from_node"]) and existing.has(c["to_node"]):
			clean.append(c)

	return clean

func _on_inspector_params_changed(params):
	if selected_node == null:
		return
	selected_node.set_parameters(params)
	render_mesh()

func set_tree_mesh(mesh: Mesh) -> void:
	mesh_instance.mesh = mesh

func clear_tree_mesh():
	mesh_instance.mesh = ArrayMesh.new()

func get_node_editor_children():
	var amount = 0
	for i in node_editor.get_children():
		if i is GeneratorNode:
			amount +=1
	return amount

func build_selected_node(_node):
	clear_ui()
	var params = selected_node.get_parameters()
	inspector_panel.build_ui(params, selected_node)
	render_mesh()

func clear_ui():
	inspector_panel.clear()

func clear_ui_add():
	inspector_panel.clear_add()

func _on_graph_edit_node_deselected(_node: Node) -> void:
	selected_node = null
	clear_ui()
	clear_ui_add()

func _on_graph_edit_node_selected(node: Node) -> void:
	selected_node = node
	build_selected_node(node)

func _input(event: InputEvent) -> void:
	if holding_material:
		if drag_icon:
			drag_icon.global_position = get_viewport().get_mouse_position() - drag_icon.size * 0.5

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() == false:
			var mouse_pos = get_viewport().get_mouse_position()
			var rect = model_viewport.get_global_rect()

			if rect.has_point(mouse_pos):
				assign_material(dragged_material)

			holding_material = false
			dragged_material = null

			if drag_icon:
				drag_icon.queue_free()
				drag_icon = null


func _on_asset_browser_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var icon = asset_browser_list.get_item_icon(index)
		var material_path = GlobalPaths.materials_folder_path + str(asset_browser_list.get_item_text(index) + ".tres")

		dragged_material = load(material_path)
		holding_material = true

		drag_icon = TextureRect.new()
		drag_icon.texture = icon
		drag_icon.expand = true
		drag_icon.size = Vector2(48, 48)
		drag_icon.modulate = Color(1, 1, 1, 0.85)
		drag_icon.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(drag_icon)
		drag_icon.z_index = 10
		drag_icon.global_position = get_viewport().get_mouse_position() - drag_icon.size * 0.5


func assign_material(mat: Material) -> void:
	mesh_instance.material_override = mat
	emit_signal("material_changed", mat)

func clear_material() -> void:
	mesh_instance.material_override = null
	emit_signal("material_changed", null)
