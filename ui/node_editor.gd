extends GraphEdit

@export var node_add_menu: Control
@export var node_search_menu : Control

signal render()
signal clear_selected_node()

var added_node = null
var selected_node = null

func _ready():
	if node_add_menu:
		node_search_menu.add_node_selected.connect(add_selected_node_with_resource.bind())
		node_add_menu.add_node_selected.connect(add_selected_node_with_resource.bind())

func _input(event):
	if event is InputEventKey:
		if Shortcuts.is_shortcut(event, Shortcuts.shortcuts["add_node"]):
			SaveManager.mark_modified()
			if node_add_menu and get_global_rect().has_point(get_global_mouse_position()):
				
				node_add_menu.spawn(get_global_mouse_position())
					
		if Shortcuts.is_shortcut(event, Shortcuts.shortcuts["delete_node"])  and selected_node:
			selected_node.free()
			clear_selected_node.emit()
			render.emit()
			selected_node = null
		
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT and node_add_menu and get_global_rect().has_point(event.position):
			node_add_menu.spawn(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and node_add_menu and node_add_menu.visible:
			node_add_menu.despawn(event.position)

	if added_node:
		if event is InputEventMouseMotion:
			added_node.position_offset = get_node_offset(added_node.size)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			added_node.selected = false
			added_node = null
	
	

func add_selected_node_with_resource(node_name):
	var node_instance = GeneratorNode.new()
	var resource = load("res://core/nodes/" + node_name.to_lower() + ".tres")
	if resource == null:
		return
	node_instance.resource = resource.duplicate()
	add_child(node_instance)
	node_instance.selected = true
	node_instance.position_offset = get_node_offset(node_instance.size)
	added_node = node_instance

func get_node_offset(node_size):
	return (get_local_mouse_position() + scroll_offset) / zoom - node_size / 2.0

	

func _on_connection_request(from_node, from_port, to_node, to_port):
	connect_node(from_node, from_port, to_node, to_port)
	render.emit()

func _on_disconnection_request(from_node, from_port, to_node, to_port):
	disconnect_node(from_node, from_port, to_node, to_port)
	render.emit()

func _on_node_deselected(_node):
	selected_node = null

func _on_node_selected(node):
	selected_node = node
