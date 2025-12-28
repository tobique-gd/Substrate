extends ItemList

@export var meshsets: Array[Dictionary]
@export var default_meshsets: Array[Dictionary]

func update():
	var files := ResourceLoader.list_directory(GlobalPaths.default_meshsets_path)
	if files.is_empty():
		return

	for file in files:
		if not file.ends_with(".glb"):
			continue

		var name := file.get_basename()

		var exists := false
		for meshset in meshsets:
			if meshset["item_name"] == name:
				exists = true
				break

		if exists:
			continue

		add_meshset(GlobalPaths.default_meshsets_path + file)

	update_itemlist()


func add_meshset(path: String):
	var scene := ResourceLoader.load(path) as PackedScene
	if scene == null:
		return

	var root := scene.instantiate()

	var item_name := path.get_file().get_basename()

	var tex: Texture2D = search_through_children(root)
	if tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.GRAY)
		tex = ImageTexture.create_from_image(img)

	var model_array := create_model_array(root)

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
	var model_dict := {}
	_collect_meshes(root, root, model_dict, 0)
	return model_dict


func _collect_meshes(node, root: Node, model_dict: Dictionary, index: int, path: NodePath = NodePath("")) -> int:
	for child in node.get_children():
		var child_path = String(path) + child.name
		if child is MeshInstance3D:
			model_dict[index] = {
				"scene_path": root.scene_file_path,
				"node_path": String(child_path),
				"allowed": true
			}
			index += 1
		else:
			index = _collect_meshes(child, root, model_dict, index, child_path)
	return index



func update_itemlist():
	clear()
	for meshset in meshsets:
		add_item(meshset["item_name"], meshset["item_tex"])
