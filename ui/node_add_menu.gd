extends Control

@export var vbox : VBoxContainer
@export var node_list : ItemList

@export var nodes_folder_path : String

signal add_node_selected(node_name)

func spawn(pos):
	
	if not DirAccess.dir_exists_absolute(nodes_folder_path):
		return
	
	node_list.clear()
	var node_dir = DirAccess.open(nodes_folder_path)
	
	var all_nodes = node_dir.get_files()
	
	for file in all_nodes:
		if file.get_extension() == "gd":
			node_list.add_item(file.get_basename().capitalize())
	
	
	
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
