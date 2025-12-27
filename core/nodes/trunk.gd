extends SubstrateNode
class_name TrunkGenerator

var node_parameters = {
	"trunk_height": {"type": "float", "min": 2.0, "max": 10.0, "value": 4.0},
	"trunk_radius": {"type": "float", "min": 0.2, "max": 1.0, "value": 0.4},
	"segment_count": {"type": "int", "min": 4, "max": 20, "value": 8},
	"bend_amount": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.3},
	"bend_variation": {"type": "float", "min": 0.0, "max": 2.0, "value": 0.5},
	"taper_amount": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.7},
	"sides": {"type": "int", "min": 6, "max": 16, "value": 8},
	"seed": {"type": "int", "min": 0, "max": 999999, "value": 0}
}

var node_name = "Trunk"
var node_ports = {"right": 0}

func is_base_node():
	return true

func get_parameter_definitions():
	return node_parameters

func get_port_definitions():
	return node_ports

func set_parameters(p):
	node_parameters = p

func generate(params, geometry: Mesh = null) -> Mesh:
	var height = params.trunk_height.value
	var radius = params.trunk_radius.value
	var segments = params.segment_count.value
	var sides = params.sides.value
	var bend = params.bend_amount.value
	var bend_var = params.bend_variation.value
	var taper = params.taper_amount.value
	var rng = RandomNumberGenerator.new()
	rng.seed = params.seed.value

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var points = []
	for i in range(segments + 1):
		var t = float(i) / segments
		var local_radius = radius * (1.0 - t * taper)
		var bend_offset = Vector3(
			bend * sin(t * PI * 2.0 + rng.randf() * bend_var),
			0.0,
			bend * cos(t * PI * 2.0 + rng.randf() * bend_var)
		)
		var pos = Vector3(0, t * height, 0) + bend_offset
		points.append({"pos": pos, "radius": local_radius})

	for i in range(segments):
		var p0 = points[i]
		var p1 = points[i + 1]
		for s in range(sides):
			var a0 = float(s) / sides * PI * 2.0
			var a1 = float(int(s + 1) % int(sides)) / sides * PI * 2.0
			var v00 = p0.pos + Vector3(cos(a0), 0, sin(a0)) * p0.radius
			var v01 = p0.pos + Vector3(cos(a1), 0, sin(a1)) * p0.radius
			var v10 = p1.pos + Vector3(cos(a0), 0, sin(a0)) * p1.radius
			var v11 = p1.pos + Vector3(cos(a1), 0, sin(a1)) * p1.radius

			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)

			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)

	var mesh = st.commit()
	return mesh
