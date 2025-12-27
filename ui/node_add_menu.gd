extends Control

@export var vbox : VBoxContainer
@export var node_list : ItemList

@export var available_nodes : Array[SubstrateNode] = []

signal add_node_selected(node_name)

func spawn(pos):
	
	node_list.clear()

	var all_nodes = available_nodes
	
	for file in all_nodes:
		node_list.add_item(file.node_name)
	
	
	
	for c in get_children():
			c.release_focus()
			if c is ItemList:
				c.deselect_all()
	
	size.x = 182.0
	size.y = 300.0
	global_position = pos - Vector2(size.x / 2.0, 40)
	
	
	
	visible = true

func despawn(pos):
	if not get_global_rect().has_point(pos):
		visible = false


func _on_node_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	emit_signal("add_node_selected", node_list.get_item_text(index))
	hide()
