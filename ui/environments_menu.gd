extends Panel

var hdri_library_path = "res://assets/hdris/"
const ROUNDED_TEXTURE_RECT = preload("res://ui/customui/rounded_texture_rect_button.tscn")

@export var environment_texture_container: VBoxContainer
@export var top_panel : Panel

func open(pos: Vector2) -> void:
	if not DirAccess.dir_exists_absolute(hdri_library_path):
		return
	_load_hdris(pos)
	
func _load_hdris(pos: Vector2) -> void:
	for child in environment_texture_container.get_children():
		child.queue_free()
	
	var hdri_dir = DirAccess.open(hdri_library_path)
	var all_hdris = hdri_dir.get_files()
	
	var total_height = 0.0
	var container_width = _get_container_width()
	var separation = float(environment_texture_container.get_theme_constant("separation"))
	
	for file in all_hdris:
		if file.get_extension().to_lower() == "exr":
			var rect_instance : CustomTextureButton = ROUNDED_TEXTURE_RECT.instantiate()
			rect_instance.texture = load(hdri_library_path + file)
			environment_texture_container.add_child(rect_instance)
			rect_instance._on_click.connect(top_panel.on_click.bind())
			rect_instance.preset = file.get_basename()
			var rect_height = _calculate_rect_height(rect_instance.texture, container_width)
			rect_instance.custom_minimum_size = Vector2(container_width, rect_height)
			total_height += rect_height + separation
			

	
	_set_panel_height(total_height - all_hdris.size() / 2.0)
	
	global_position = pos
	show()

func _get_container_width() -> float:
	var margin_left = float($MarginContainer.get_theme_constant("margin_left"))
	var margin_right = float($MarginContainer.get_theme_constant("margin_right"))
	return $MarginContainer.size.x - margin_left - margin_right

func _calculate_rect_height(texture: Texture2D, width: float) -> float:
	var tex_size = texture.get_size()
	var aspect_ratio = tex_size.x / tex_size.y
	return width / aspect_ratio

func _set_panel_height(content_height: float) -> void:
	var margin_top = float($MarginContainer.get_theme_constant("margin_top"))
	var margin_bottom = float($MarginContainer.get_theme_constant("margin_bottom"))
	size.y = content_height + margin_top + margin_bottom

func close() -> void:
	hide()
