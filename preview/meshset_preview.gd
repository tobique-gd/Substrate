extends Node

func render_meshset_mesh_preview(mesh: Mesh, size: Vector2i) -> Image:
	var vp := SubViewport.new()
	vp.disable_3d = false
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.size = size
	vp.world_3d = World3D.new()
	vp.world_3d.environment = load("res://core/environments/grass_field1.tres")
	get_tree().root.add_child.call_deferred(vp)

	var root := Node3D.new()
	vp.add_child(root)

	var mesh_i := MeshInstance3D.new()
	mesh_i.mesh = mesh
	root.add_child(mesh_i)

	var aabb := mesh.get_aabb()
	var size3 := aabb.size

	
	var center := Vector3(aabb.position.x + size3.x * 0.5,
						  aabb.position.y + size3.y * 0.5,
						  aabb.position.z + size3.z * 0.5)

	var axis := 0
	if size3.y < size3.x and size3.y < size3.z:
		axis = 1
	elif size3.z < size3.x and size3.z < size3.y:
		axis = 2

	var dir := Vector3.ZERO
	if axis == 0:
		dir = Vector3(1, 0, 0)
	elif axis == 1:
		dir = Vector3(0, 1, 0)
	else:
		dir = Vector3(0, 0, 1)

	# Create camera
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.01
	cam.far = 100.0

	var ortho_size := 0.0
	if axis == 0:
		ortho_size = max(size3.y, size3.z)
	elif axis == 1:
		ortho_size = max(size3.x, size3.z)
	else:
		ortho_size = max(size3.x, size3.y)

	cam.size = ortho_size * 1.1

	var distance := size3.length()
	var cam_pos := center + dir * distance
	var basis := Basis().looking_at(center - cam_pos, Vector3.UP)

	basis = basis.rotated(Vector3.FORWARD, PI)

	cam.global_transform = Transform3D(basis, cam_pos)
	root.add_child(cam)

	await get_tree().process_frame
	await get_tree().process_frame

	var img := vp.get_texture().get_image()
	img.flip_y()
	img = img.duplicate(true)
	vp.queue_free()
	return img
