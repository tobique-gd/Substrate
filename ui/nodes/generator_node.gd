extends GraphNode
class_name GeneratorNode

@export var resource : TreeGenerator = null

var color_node_type_map = {
	0 : Color(.5, .75, .75),
	1 : Color(0.92, 0.66, 0.85)
	
}

func _enter_tree() -> void:
	title = resource.node_name
	size = Vector2(200, 80)
	create_inputs(resource.node_ports)



func get_parameters():
	if resource:
		return resource.get_parameter_definitions()

func set_parameters(params):
	if resource:
		resource.set_parameters(params)

func generate(params, geometry):
	if resource:
		return resource.generate(params, geometry)

func is_base_node():
	if resource:
		return resource.is_base_node()

func create_inputs(inputs):
	if inputs == {}:
		return
	
	for input in inputs:
		var ctrl = GraphElement.new()
		add_child(ctrl)

		if input == "right":
			set_slot(0, false, inputs[input], color_node_type_map[inputs[input]], true, inputs[input], color_node_type_map[inputs[input]])
		elif input == "left":
			set_slot(1, true, inputs[input], color_node_type_map[inputs[input]], false, inputs[input], color_node_type_map[inputs[input]])
		
		
