extends ItemList

@export var meshsets: Array[Dictionary]

func update():
	if not DirAccess.dir_exists_absolute(GlobalPaths.default_meshsets_path):
		return
	var meshsets_dir = DirAccess.open(GlobalPaths.default_meshsets_path)
		
	for file in meshsets_dir.get_files():
		if file.get_extension() == "glb":
			for meshset in meshsets:
				if meshset["item_name"] == file.get_basename():
					return
			
			add_meshset(GlobalPaths.default_meshsets_path + file)
	
	update_itemlist()

func add_meshset(path: String):
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var err = gltf_document.append_from_file(path, gltf_state)
	if err != OK:
		return

	var root = gltf_document.generate_scene(gltf_state)
	if root == null:
		return

	var item_name = path.split("/")[-1].get_basename()

	var tex: Texture2D = null
	tex = search_through_children(root)

	if tex == null:
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.GRAY)
		tex = ImageTexture.create_from_image(img)
	
	var model_array : Dictionary = create_model_array(root)
	
	meshsets.append({
		"item_name": item_name,
		"item_models": model_array,
		"item_tex": tex
	})

	

func search_through_children(node):
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh = child.mesh
			if mesh and mesh.get_surface_count() > 0:
				var mat = mesh.surface_get_material(0)
				if mat is Material:
					return mat.albedo_texture
		else:
			var result = search_through_children(child)
			if result != null:
				return result


	return null

func create_model_array(root) -> Dictionary:
	var model_dict : Dictionary = {}
	_collect_meshes(root, model_dict, 0)
	return model_dict


func _collect_meshes(node, model_dict: Dictionary, index: int) -> int:
	for child in node.get_children():
		if child is MeshInstance3D:
			model_dict[index] = {
				"mesh": child,
				"allowed": true
			}
			index += 1
		else:
			index = _collect_meshes(child, model_dict, index)
	return index


func update_itemlist():
	clear()
	for meshset in meshsets:
		add_item(meshset["item_name"], meshset["item_tex"])
