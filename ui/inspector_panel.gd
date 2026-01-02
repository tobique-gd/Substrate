extends Control

@export var properties : GridContainer

signal params_changed(params)

var original_params = {}

func _ready() -> void:
	clear_add()

func build_ui(params, node):
	original_params = params.duplicate(true)
	
	var node_name = Label.new()
	node_name.text = node.resource.node_name
	var font = load("res://assets/fonts/Lato/Lato-Bold.ttf")
	node_name.add_theme_font_override("font", font)
	node_name.add_theme_font_size_override("font_size", 24)



	node_name.add_theme_font_override("default_font", load("res://assets/fonts/Lato/Lato-Bold.ttf"))
	properties.add_child(node_name)
	var sep = HSeparator.new()
	properties.add_child(sep)
	
	for param in params.keys():
		var param_label = Label.new()
		param_label.text = param.capitalize()
		var slider_s = load("res://ui/customui/parameter_slider.tscn")
		var slider : ProgressBar= slider_s.instantiate()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_FILL
		
		slider.name = param
		slider.min_value = params[param]["min"]
		slider.max_value = params[param]["max"]
		slider.value = params[param]["value"]
		slider.value_changed.connect(_on_slider_changed.bind(param))
		properties.add_child(param_label)
		properties.add_child(slider)
		
		if params[param]["type"] == "float":
			slider.step = 0.001
		if params[param]["type"] == "int":
			slider.step = 1

func _on_slider_changed(value, param):
	original_params[param]["value"] = value
	emit_signal("params_changed", original_params)

func get_properties():
	return original_params

func clear():
	for c in properties.get_children():
		c.queue_free()
	
func clear_add():
	var node_name = Label.new()
	node_name.text = "Properties"
	var font = load("res://assets/fonts/Lato/Lato-Bold.ttf")
	node_name.add_theme_font_override("font", font)
	node_name.add_theme_font_size_override("font_size", 24)
	properties.add_child(node_name)
	var sep = HSeparator.new()
	properties.add_child(sep)
	
