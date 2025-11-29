extends TreeGenerator
class_name SimpleBranches

# Global counter to track vertex indices manually
var _vert_count: int = 0

var node_parameters = {
	# === SEED & COUNT ===
	"seed": {"type": "int", "min": 0, "max": 9999, "value": 0},
	"count": {"type": "int", "min": 1, "max": 200, "value": 20},
	
	# === HEIGHT DISTRIBUTION ===
	"min_height": {"type": "float", "min": 0.0, "max": 10.0, "value": 1.0},
	"max_height": {"type": "float", "min": 0.0, "max": 10.0, "value": 4.0},
	
	# === BRANCH LENGTH & TAPER ===
	"length": {"type": "float", "min": 0.1, "max": 10.0, "value": 3.0},
	"length_variation": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.3},
	"radius": {"type": "float", "min": 0.01, "max": 2.0, "value": 0.15},
	"radius_variation": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.4},
	"taper": {"type": "float", "min": 0.0, "max": 1.0, "value": 1.0},
	
	# === GRAVITY & CURVATURE ===
	"gravity": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.5},
	"gravity_falloff": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.2},
	"curvature": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.0},
	
	# === BRANCH ANGLE ===
	"branch_angle": {"type": "float", "min": 0.0, "max": 180.0, "value": 45.0},
	"angle_variation": {"type": "float", "min": 0.0, "max": 90.0, "value": 15.0},
	"angle_z_twist": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.5},
	
	# === HEIGHT-BASED SCALING ===
	"length_by_height": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.5},
	"radius_by_height": {"type": "float", "min": 0.0, "max": 1.0, "value": 0.3},
	
	# === GEOMETRY ===
	"segments": {"type": "int", "min": 3, "max": 24, "value": 6},
	"length_segments": {"type": "int", "min": 2, "max": 32, "value": 8},
	
	# === TREE TYPE PRESETS ===
	"tree_type": {"type": "int", "min": 0, "max": 3, "value": 0},  # 0=Custom, 1=Spruce, 2=Oak, 3=Willow
}

var node_name = "Branches"
var node_ports = {"left": 0, "right": 0}

func get_port_definitions(): return node_ports
func get_parameter_definitions(): return node_parameters
func set_parameters(p): node_parameters = p

func _apply_tree_preset(tree_type: int, params: Dictionary) -> Dictionary:
	var p = params.duplicate()
	
	match tree_type:
		1:  # Spruce - Dense, conical
			p.count.value = 80
			p.min_height.value = 0.5
			p.max_height.value = 4.5
			p.length.value = 2.5
			p.length_variation.value = 0.2
			p.radius.value = 0.12
			p.gravity.value = 0.3
			p.branch_angle.value = 55.0
			p.angle_variation.value = 10.0
			p.taper.value = 1.0
			p.length_by_height.value = 0.6
			p.radius_by_height.value = 0.4
		2:  # Oak - Thick, spreading
			p.count.value = 40
			p.min_height.value = 1.5
			p.max_height.value = 3.5
			p.length.value = 4.0
			p.length_variation.value = 0.5
			p.radius.value = 0.25
			p.gravity.value = 0.6
			p.branch_angle.value = 30.0
			p.angle_variation.value = 25.0
			p.taper.value = 0.7
		3:  # Willow - Long, drooping
			p.count.value = 60
			p.min_height.value = 1.0
			p.max_height.value = 4.0
			p.length.value = 5.0
			p.length_variation.value = 0.6
			p.radius.value = 0.1
			p.gravity.value = 0.85
			p.branch_angle.value = 20.0
			p.angle_variation.value = 20.0
			p.taper.value = 0.9
			p.gravity_falloff.value = 0.3
	
	return p

func generate(params, input_mesh: Mesh = null) -> Mesh:
	if input_mesh == null: return ArrayMesh.new()
	
	var p = params.duplicate()
	if params.tree_type.value != 0:
		p = _apply_tree_preset(params.tree_type.value, p)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = p.seed.value
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# RESET VERTEX COUNTER
	_vert_count = 0
	
	# --- 1. COPY TRUNK AND GET DATA ---
	var input_st = SurfaceTool.new()
	input_st.create_from(input_mesh, 0)
	var arr = input_st.commit_to_arrays()
	var verts = arr[Mesh.ARRAY_VERTEX]
	var normals = arr[Mesh.ARRAY_NORMAL]
	var uvs = arr[Mesh.ARRAY_TEX_UV]
	
	# Paste trunk into our new mesh
	for i in range(verts.size()):
		if normals and i < normals.size():
			st.set_normal(normals[i])
		if uvs and i < uvs.size():
			st.set_uv(uvs[i])
		st.add_vertex(verts[i])
		_vert_count += 1 # MANUALLY TRACK INDEX
		
	if arr[Mesh.ARRAY_INDEX]:
		for idx in arr[Mesh.ARRAY_INDEX]:
			st.add_index(idx)
	else:
		for i in range(verts.size()):
			st.add_index(i)

	# --- 2. GENERATE BRANCHES ---
	var branches_created = 0
	var attempts = 0
	
	while branches_created < p.count.value and attempts < 5000:
		attempts += 1
		
		# Pick a random vertex from the trunk
		var idx = rng.randi() % verts.size()
		var start_pos = verts[idx]
		
		# Check Height
		if start_pos.y < p.min_height.value or start_pos.y > p.max_height.value:
			continue
			
		# Determine Direction
		var start_dir = Vector3.RIGHT
		if normals and idx < normals.size():
			start_dir = normals[idx]
		else:
			start_dir = Vector3(start_pos.x, 0, start_pos.z).normalized()
		
		# Randomize direction slightly
		start_dir = _randomize_direction(start_dir, p, rng)
		
		_build_branch(st, start_pos, start_dir, p, rng)
		branches_created += 1

	st.generate_normals()
	return st.commit()

func _randomize_direction(base_dir: Vector3, p: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	# Create perpendicular vectors
	var right = base_dir.cross(Vector3.UP).normalized()
	if not right.is_normalized():
		right = Vector3.RIGHT
	
	# Branch angle from trunk
	var angle_rad = deg_to_rad(p.branch_angle.value + rng.randf_range(-p.angle_variation.value, p.angle_variation.value))
	
	# Z-twist (rotational variation around trunk)
	var twist = rng.randf_range(0.0, TAU) * p.angle_z_twist.value
	
	# Rotate away from trunk
	var rotated = base_dir.rotated(right, angle_rad)
	rotated = rotated.rotated(base_dir, twist)
	
	return rotated.normalized()

func _calculate_height_factor(height: float, p: Dictionary) -> float:
	# Normalize height to 0-1 range (0 = bottom, 1 = top)
	var height_range = p.max_height.value - p.min_height.value
	if height_range <= 0:
		return 1.0
	
	var normalized_height = (height - p.min_height.value) / height_range
	normalized_height = clamp(normalized_height, 0.0, 1.0)
	
	# Inverse: bottom branches are longer/thicker (close to 1.0), top branches shorter/thinner
	var inverted = 1.0 - normalized_height
	
	# Blend length and radius scaling
	var length_scale = lerp(1.0, inverted, p.length_by_height.value)
	var radius_scale = lerp(1.0, inverted, p.radius_by_height.value)
	
	# Return average of both scalings
	return (length_scale + radius_scale) / 2.0

func _build_branch(st: SurfaceTool, start_pos: Vector3, direction: Vector3, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var segs = p.length_segments.value
	var sides = p.segments.value
	
	# Randomize length and radius
	var total_len = p.length.value * rng.randf_range(1.0 - p.length_variation.value, 1.0 + p.length_variation.value)
	var start_radius = p.radius.value * rng.randf_range(1.0 - p.radius_variation.value, 1.0 + p.radius_variation.value)
	
	# Apply height-based scaling (shorter/thinner at top, longer/thicker at bottom)
	var height_factor = _calculate_height_factor(start_pos.y, p)
	total_len *= height_factor
	start_radius *= height_factor
	
	var current_pos = start_pos
	var current_dir = direction
	
	var path_points = []
	var path_radii = []
	
	# --- Build branch skeleton ---
	for i in range(segs + 1):
		var t = float(i) / segs
		path_points.append(current_pos)
		
		# Apply taper
		var radius_at_t = lerp(start_radius, 0.0, pow(t, p.taper.value))
		path_radii.append(radius_at_t)
		
		# Move forward
		current_pos += current_dir * (total_len / segs)
		
		# Apply gravity with falloff
		var gravity_influence = p.gravity.value * p.gravity_falloff.value
		current_dir = current_dir.lerp(Vector3.DOWN, gravity_influence).normalized()
		
		# Apply curvature (smooth S-curve)
		if p.curvature.value > 0.0:
			var curve_amount = sin(t * PI) * p.curvature.value * 0.1
			current_dir = current_dir.rotated(Vector3.RIGHT, curve_amount).normalized()
	
	# --- Skin the skeleton into geometry ---
	for i in range(segs):
		var p1 = path_points[i]
		var p2 = path_points[i + 1]
		var r1 = path_radii[i]
		var r2 = path_radii[i + 1]
		
		# Skip if radius is too small
		if r1 < 0.001 and r2 < 0.001:
			continue
		
		# Calculate perpendicular plane to branch
		var forward = (p2 - p1).normalized()
		var right = forward.cross(Vector3.UP).normalized()
		if not right.is_normalized():
			right = Vector3.RIGHT
		var up = right.cross(forward).normalized()
		
		# Use our Manual Counter
		var base_idx = _vert_count
		
		# Add vertices for this segment
		for s in range(sides + 1):
			var angle = (float(s) / sides) * TAU
			var circle = (right * cos(angle) + up * sin(angle))
			
			# Bottom ring vertex
		
			st.add_vertex(p1 + circle * r1)
			_vert_count += 1 # INCREMENT
			
			# Top ring vertex
			
			st.add_vertex(p2 + circle * r2)
			_vert_count += 1 # INCREMENT
		
		# Add triangles
		for s in range(sides):
			var b = base_idx + (s * 2)
			
			# First triangle
			st.add_index(b)
			st.add_index(b + 1)
			st.add_index(b + 2)
			
			# Second triangle
			st.add_index(b + 1)
			st.add_index(b + 3)
			st.add_index(b + 2)
