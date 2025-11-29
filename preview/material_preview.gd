extends Node

var sphere_mesh := SphereMesh.new()

func render_material_preview(material: Material, size: Vector2i) -> Image:
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

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 0.9)
	root.add_child(cam)

	var mesh_i := MeshInstance3D.new()
	mesh_i.mesh = sphere_mesh
	mesh_i.material_override = material
	root.add_child(mesh_i)

	await get_tree().process_frame
	await get_tree().process_frame

	var img := vp.get_texture().get_image()
	img.flip_y()
	img = img.duplicate(true)
	vp.queue_free()
	return img
