extends Control

@export var vbox : VBoxContainer
@export var node_list : ItemList
@export var search_node_menu : Control
@export var available_nodes : Array[SubstrateNode] = []

signal add_node_selected(node_name)

var waiting_for_keyboard_idle = true
var ready_for_typing = false

func spawn(pos):
	node_list.clear()

	for file in available_nodes:
		node_list.add_item(file.node_name)

	for c in get_children():
		c.release_focus()
		if c is ItemList:
			c.deselect_all()

	size = Vector2(182.0, 300.0)
	global_position = pos - Vector2(size.x / 2.0, 40.0)
	visible = true

	waiting_for_keyboard_idle = true
	ready_for_typing = false

func despawn(pos):
	if not get_global_rect().has_point(pos):
		visible = false

func _on_node_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	emit_signal("add_node_selected", node_list.get_item_text(index))
	hide()

func _on_search_button_pressed() -> void:
	spawn_search_menu()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if waiting_for_keyboard_idle:
		if event is InputEventKey and not event.pressed and _keyboard_idle():
			waiting_for_keyboard_idle = false
			ready_for_typing = true
		return

	if not ready_for_typing:
		return

	if event is InputEventKey and event.pressed:
		if _is_typing_key(event):
			spawn_search_menu()
			return

func spawn_search_menu():
	search_node_menu.spawn(global_position)
	hide()

func _keyboard_idle() -> bool:
	for key in range(KEY_SPACE, KEY_Z + 1):
		if Input.is_key_pressed(key):
			return false
	return not (
		Input.is_key_pressed(KEY_SHIFT) or
		Input.is_key_pressed(KEY_CTRL) or
		Input.is_key_pressed(KEY_ALT)
	)

func _is_typing_key(event: InputEventKey) -> bool:
	if event.ctrl_pressed or event.alt_pressed:
		return false
	return event.unicode > 0
