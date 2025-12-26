extends Panel

var materials : Dictionary = {}

@export var asset_browser_list : ItemList

const BASIC_SHADER = preload("res://assets/shaders/default_material.gdshader")

func _on_create_mat_button_pressed() -> void:
	pass

func _on_add_material_button_pressed() -> void:
	if !asset_browser_list:
		return
	
	var new_material = ShaderMaterial.new()
	new_material.shader = BASIC_SHADER
	
	var material_name = generate_material_name()
	var new_id = materials.size()
	
	var preview_img = await MaterialPreview.render_material_preview(new_material, Vector2i(200, 200))
	var tex : ImageTexture = ImageTexture.create_from_image(preview_img)
	
	var default_material_properties = {
		"material_name": material_name,
		"material_tex": preview_img,
		"material_resource": new_material
	}
	var _idx = asset_browser_list.item_count
	materials.set(new_id, default_material_properties)
	
	asset_browser_list.add_item(material_name, tex)
	asset_browser_list.set_item_metadata(_idx, new_material)
	

func generate_material_name():
	var mat_number = 1
	var default_mat_name = "Material_001"
	var current_material_name = default_mat_name
	for mat in materials.values():
		var mat_name = mat["material_name"]
		if mat_name == current_material_name:
			mat_number += 1
			current_material_name = "Material_" + str(mat_number).pad_zeros(3)
		
	return current_material_name

func _on_remove_material_button_pressed() -> void:
	pass # Replace with function body.
