extends Control

@export var node_add_menu : Control
@export var node_list : ItemList
@export var search_bar : LineEdit

@onready var available_nodes : Array[SubstrateNode] = node_add_menu.available_nodes

signal add_node_selected(node_name)

func spawn(pos):
	search_bar.clear()
	node_list.clear()
	var all_nodes = available_nodes
	for file in all_nodes:
		node_list.add_item(file.node_name)
	
	for c in get_children():
		c.release_focus()
		if c is ItemList:
			c.deselect_all()
	
	global_position = pos
	search_bar.grab_focus()
	visible = true
	


func search_node_list(text):
	if text == "":
		node_list.clear()
		for node in available_nodes:
			node_list.add_item(node.node_name)
		return
	
	var returning_nodes = []
	for node in available_nodes:
		if node.node_name.to_lower().contains(text):
			returning_nodes.append(node)
	
	node_list.clear()
	for n in returning_nodes:
		node_list.add_item(n.node_name)
	
	if node_list.item_count>0:
		node_list.select(0)

func despawn(pos):
	if not get_global_rect().has_point(pos):
		visible = false


func _input(event: InputEvent) -> void:
	if visible:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				despawn(get_global_mouse_position())
		if event is InputEventKey:
			if event.keycode == KEY_ENTER:
				if search_bar.text != "":
					add_selected_node(0)

func add_selected_node(index: int):
	emit_signal("add_node_selected", node_list.get_item_text(index))
	hide()


func _on_search_bar_text_changed(new_text: String) -> void:
	search_node_list(new_text)


func _on_search_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	add_selected_node(index)
