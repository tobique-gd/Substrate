extends Node3D

@export var texture_properties_panel : Control
@export var cam : Camera3D

var texture_parameters = {
	"spread": {
		"type": "vec3",
		"min": Vector3(0.0, 0.0, 0.0),
		"max": Vector3(10.0, 10.0, 10.0),
		"value": Vector3(0.0, 0.0, 0.0)
	},

	"rotation": {
		"type": "vec3",
		"min": Vector3(0.0, 0.0, 0.0),
		"max": Vector3(360.0, 360.0, 360.0),
		"value": Vector3(0.0, 0.0, 0.0)
	},

	"scale": {
		"type": "vec3",
		"min": Vector3(0.0, 0.0, 0.0),
		"max": Vector3(5.0, 5.0, 5.0),
		"value": Vector3(1.0, 1.0, 1.0)
	},

	"padding": {"type": "float", "min": 0.0, "max": 4.0, "value": 1.0},
	"seed": {"type": "int", "min": 0, "max": 999999, "value": 0}
}




func _ready() -> void:
	texture_properties_panel.generate_texture.connect(_on_generate_texture.bind())

func _on_generate_texture(meshset_data: Array[Dictionary]) -> void:
	for c in get_children():
		c.queue_free()

	var combined_aabb : AABB
	var m_z = 0.0
	var first = true
	
	var id = 0
	for meshset in meshset_data:
		for mesh_entry in meshset["item_models"].values():
			if mesh_entry.has("allowed") and not mesh_entry["allowed"]:
				continue

			var meshinstance : MeshInstance3D = mesh_entry["mesh"]
			var mesh_clone : MeshInstance3D = meshinstance.duplicate()
			
			
			add_child(mesh_clone)
			mesh_clone.transform = get_instance_transform(id)
	
			
			var aabb = mesh_clone.mesh.get_aabb()
			var world_aabb = mesh_clone.global_transform *aabb
			
			if first:
				combined_aabb = world_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(world_aabb)
			
			id += 1
			
	if first:
		return
	
	if combined_aabb.size.y * texture_parameters["padding"].value > 0.0001:
		cam.size = max(combined_aabb.size.y, combined_aabb.size.x) * texture_parameters["padding"].value
		var center = combined_aabb.position + combined_aabb.size * 0.5
		cam.global_position = Vector3(center.x, center.y, 5)
		
	

func get_instance_transform(id):
	var rng = RandomNumberGenerator.new()
	rng.seed = texture_parameters["seed"].value + id * 928371

	var spread = texture_parameters["spread"].value
	var pos = Vector3(
		rng.randf_range(-spread.x, spread.x),
		rng.randf_range(-spread.y, spread.y),
		rng.randf_range(-spread.z, spread.z)
	)

	var rot = texture_parameters["rotation"].value
	var rx = deg_to_rad(rng.randf_range(-rot.x, rot.x))
	var ry = deg_to_rad(rng.randf_range(-rot.y, rot.y))
	var rz = deg_to_rad(rng.randf_range(-rot.z, rot.z))

	var scl = texture_parameters["scale"].value
	var scale = Vector3(
		rng.randf_range(scl.x, scl.x),
		rng.randf_range(scl.y, scl.y),
		rng.randf_range(scl.z, scl.z)
	)

	var t = Transform3D()
	t.origin = pos
	t.basis = Basis.from_euler(Vector3(rx, ry, rz))
	t.basis = t.basis.scaled(scale)

	return t
