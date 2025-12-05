extends Control

@export var add_meshset_menu : Control
@export var meshset_list : ItemList
var meshsets : Array[Dictionary] = []

func _ready() -> void:
	add_meshset_menu.meshset_updated.connect(update_meshset_list.bind())

func _on_add_meshset_button_pressed() -> void:
	add_meshset_menu.show()

func update_meshset_list(m_meshsets:Array[Dictionary]):
	meshsets = m_meshsets
	for meshset in m_meshsets:
		meshset_list.add_item(meshset["item_name"], meshset["item_tex"])
	
	
