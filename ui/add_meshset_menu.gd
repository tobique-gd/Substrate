extends Control

@export var file_dialog: FileDialog
@export var meshset_browser: ItemList


func _on_import_button_pressed() -> void:
	file_dialog.popup()


func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		if path.is_absolute_path():
			meshset_browser.add_meshset(path)



func _on_cancel_pressed() -> void:
	hide()

func _on_add_button_pressed() -> void:
	pass # Replace with function body.
