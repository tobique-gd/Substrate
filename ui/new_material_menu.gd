extends Control
@export var name_edit : LineEdit
@export var basic_shader : Shader
const MAX_NAME_LENGTH = 64
const FORBIDDEN_CHARACTERS = ["\\", "/", ":", "*", "?", "\"", "<", ">", "|"]

func _on_create_pressed() -> void:
	if not name_edit:
		return
	
	if not basic_shader:
		return
	
	var material_name = name_edit.text.strip_edges()
	
	if material_name.is_empty():
		return
	
	if material_name.length() > MAX_NAME_LENGTH:
		return
	
	for forbidden_char in FORBIDDEN_CHARACTERS:
		if forbidden_char in material_name:
			return
	
	if not DirAccess.dir_exists_absolute(GlobalPaths.materials_folder_path):
		return
	
	var save_path = GlobalPaths.materials_folder_path + material_name + ".tres"
	
	if ResourceLoader.exists(save_path):
		return
	
	var mat = ShaderMaterial.new()
	mat.shader = basic_shader.duplicate(true)
	mat.resource_name = material_name
	
	var error = ResourceSaver.save(mat, save_path)
	
	if error == OK:
		hide()

func _on_cancel_pressed() -> void:
	name_edit.clear()
	hide()
