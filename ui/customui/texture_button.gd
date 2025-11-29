extends TextureRect
class_name CustomTextureButton

signal _on_click(environment_texture)

var preset = ""

func _input(event: InputEvent) -> void:
	if visible:
		var mouse_pos = get_global_mouse_position()
		var rect = get_global_rect()
		
		if event is InputEventMouseMotion:
			if rect.has_point(mouse_pos):
				material.set("shader_parameter/focused", true)
			else:
				material.set("shader_parameter/focused", false)
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if rect.has_point(mouse_pos):
				_on_click.emit(preset)
