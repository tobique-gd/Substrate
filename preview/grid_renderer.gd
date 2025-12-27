extends Node3D

@export var grid_size: int = 10
@export var spacing: float = 1.0
@export var axis_radius: float = 0.2
@export var axis_length: float = 10000.0
@export var zoom_arm: SpringArm3D


var grid_nodes = []
var axis_nodes = []

func _ready():
	
	zoom_arm.zoom_changed.connect(_on_zoom_changed.bind())
	_create_grid()
	_create_axis(Vector3(1,0,0), Color(0.561,0.235,0.278))
	_create_axis(Vector3(0,0,1), Color(0.467,0.671,0.886))
	update_grid_and_axes(1.0)


func _on_zoom_changed(zoom: float):
	update_grid_and_axes(zoom)

func update_grid_and_axes(zoom_value: float):
	var t = clamp(zoom_value / zoom_arm.max_length, 0.0, 1.0)
	var scale_factor = lerp(0.4, 2.0, t)


	for n in grid_nodes:
		if n.mesh:
			n.mesh.top_radius = axis_radius * 0.4 * scale_factor
			n.mesh.bottom_radius = axis_radius * 0.8 * scale_factor

	for a in axis_nodes:
		if a.mesh:
			a.mesh.top_radius = axis_radius * scale_factor
			a.mesh.bottom_radius = axis_radius * scale_factor


func _create_grid():
	for n in grid_nodes:
		n.queue_free()
	grid_nodes.clear()
	var half = grid_size * spacing
	for i in range(-grid_size, grid_size + 1):
		var c1 = CylinderMesh.new()
		c1.radial_segments = 32
		c1.top_radius = axis_radius * 0.4
		c1.bottom_radius = axis_radius * 0.4
		c1.height = half * 2
		var mi1 = MeshInstance3D.new()
		mi1.mesh = c1
		var mat1 = StandardMaterial3D.new()
		mat1.albedo_color = Color(0.3, 0.3, 0.3)
		mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi1.material_override = mat1
		mi1.transform = Transform3D(Basis().rotated(Vector3(1,0,0), deg_to_rad(90)), Vector3(i * spacing, 0, 0))
		add_child(mi1)
		grid_nodes.append(mi1)

		var c2 = CylinderMesh.new()
		c2.radial_segments = 32
		c2.top_radius = axis_radius * 0.4
		c2.bottom_radius = axis_radius * 0.4
		c2.height = half * 2
		var mi2 = MeshInstance3D.new()
		mi2.mesh = c2
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = Color(0.3, 0.3, 0.3)
		mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi2.material_override = mat2
		mi2.transform = Transform3D(Basis().rotated(Vector3(0,0,1), deg_to_rad(90)), Vector3(0, 0, i * spacing))
		add_child(mi2)
		grid_nodes.append(mi2)


func _create_axis(direction: Vector3, color: Color):
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = axis_radius
	cylinder.bottom_radius = axis_radius
	cylinder.height = axis_length
	cylinder.radial_segments = 4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = mat
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cylinder
	var t = Transform3D.IDENTITY
	if direction == Vector3(1,0,0):
		t.basis = Basis(Vector3(0,0,1), deg_to_rad(90))
	elif direction == Vector3(0,0,1):
		t.basis = Basis(Vector3(1,0,0), deg_to_rad(90))
	mesh_instance.transform = t
	add_child(mesh_instance)
	axis_nodes.append(mesh_instance)

func _clear():
	for c in get_children():
		c.hide()

func build():
	for c in get_children():
		c.show()
