extends TreeGenerator
class_name PlantGenerator

var node_parameters = {
	"plane_count": {"type": "int", "min": 1, "max": 6, "value": 2},
	"horizontal_size" : {"type":"float", "min": 0.05, "max":0.5, "value":0.2},
	"vertical_size" : {"type":"float", "min": 0.05, "max":0.5, "value":0.2}
}

var node_name : String = "Plant"
var node_ports = {"right": 0}

func is_base_node():
	return true

func get_parameter_definitions():
	return node_parameters

func get_port_definitions():
	return node_ports

func set_parameters(p):
	node_parameters = p

func generate(_params, _geometry: Mesh = null) -> Mesh:
	var plane_count = node_parameters["plane_count"]["value"]
	var verts_pv = PackedVector3Array()
	var norms_pv = PackedVector3Array()
	var uvs_pv = PackedVector2Array()
	var idx_pv = PackedInt32Array()
	var index_offset = 0

	for n in range(plane_count):
		var angle = deg_to_rad(180.0 / float(plane_count) * float(n))
		var quad : QuadMesh = QuadMesh.new()
		quad.size = Vector2(node_parameters.horizontal_size.value, node_parameters.vertical_size.value)
		var arrays = quad.surface_get_arrays(0)
		var verts = arrays[Mesh.ARRAY_VERTEX]
		var norms = arrays[Mesh.ARRAY_NORMAL]
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		var idx = arrays[Mesh.ARRAY_INDEX]
		var rot = Transform3D(Basis().rotated(Vector3.UP, angle), Vector3.ZERO)

		for v in verts:
			verts_pv.append(rot.basis * v)

		for no in norms:
			norms_pv.append(rot.basis * no)
	
		for uv in uvs:
			uvs_pv.append(uv)

		for i in idx:
			idx_pv.append(i + index_offset)

		index_offset += verts.size()

	var final_arrays = []
	final_arrays.resize(Mesh.ARRAY_MAX)
	final_arrays[Mesh.ARRAY_VERTEX] = verts_pv
	final_arrays[Mesh.ARRAY_NORMAL] = norms_pv
	final_arrays[Mesh.ARRAY_TEX_UV] = uvs_pv
	final_arrays[Mesh.ARRAY_INDEX] = idx_pv

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, final_arrays)
	return mesh
