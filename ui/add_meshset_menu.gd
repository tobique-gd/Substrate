extends Control

@export var file_dialog: FileDialog
@export var meshset_browser: ItemList

var using_meshsets : Array[Dictionary] = []

signal meshset_updated(meshset)

func _on_import_button_pressed() -> void:
	file_dialog.popup()

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		if path.is_absolute_path():
			meshset_browser.add_meshset(path)
	
	meshset_browser.update_itemlist()

func _on_cancel_pressed() -> void:
	hide()

func _on_add_button_pressed() -> void:
	var created_array :Array[Dictionary]= []
	var selected_meshset_indices = meshset_browser.get_selected_items()
	
	for index in selected_meshset_indices:
		created_array.append(meshset_browser.meshsets[index])
	
	using_meshsets=created_array
	meshset_updated.emit(using_meshsets.duplicate(true))
	hide()


func _on_visibility_changed() -> void:
	if visible:
		meshset_browser.update()
