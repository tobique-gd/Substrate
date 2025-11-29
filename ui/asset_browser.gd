extends Panel

@export var create_mat_menu : Control

func _on_create_mat_button_pressed() -> void:
	if create_mat_menu:
		create_mat_menu.show()
