extends ItemList


func _ready():
	load_materials()

func load_materials():
	clear()
	var materials_folder_path = GlobalPaths.materials_folder_path
	if not DirAccess.dir_exists_absolute(materials_folder_path):
		return

	var dir = DirAccess.open(materials_folder_path)
	if dir == null:
		return

	for f in dir.get_files():
		var mat = load(materials_folder_path + f)
		if not mat is Material:
			continue

		var img = await MaterialPreview.render_material_preview(mat, Vector2i(200, 200))
		var tex : ImageTexture = ImageTexture.create_from_image(img)
		add_item(f.get_basename(), tex, false)
