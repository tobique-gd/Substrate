extends Panel

var value : Vector3 = Vector3()

@export var vector_components : Array[VectorComponent]

signal value_changed(value)

func _ready() -> void:
	for vector_component in vector_components:
		vector_component.value_changed.connect(_on_vector_component_value_changed.bind())

func update_value(params):
	value = params["value"]
	_update_components(params)

func _update_components(params):
	var i = 0
	for vector_component in vector_components:
		vector_component.vector_index = i
		vector_component.value = snappedf(value[i], 0.001)
		vector_component.min_value = params["min"][i]
		vector_component.max_value = params["max"][i]
		
		i += 1


func _on_vector_component_value_changed(_value:float, _vector_index:int):
	value[_vector_index] = _value
	emit_signal("value_changed", value)
	
