extends Control

var current_material : StandardMaterial3D = null

@export var properties_container : VBoxContainer
@export var asset_browser_list : ItemList
@export var float_field_scene : PackedScene

@onready var slider_s = preload("res://ui/customui/parameter_slider.tscn")
@onready var vec3_component = preload("res://ui/customui/vector3_component.tscn")

func _ready() -> void:

	texture_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	texture_dialog.access = FileDialog.ACCESS_FILESYSTEM
	texture_dialog.use_native_dialog = true
	texture_dialog.file_selected.connect(_on_texture_selected.bind())
	
	texture_dialog.add_filter("*.png ; PNG Images")
	texture_dialog.add_filter("*.jpg ; JPEG Images")
	texture_dialog.add_filter("*.jpeg ; JPEG Images")
	add_child(texture_dialog)
	
	asset_browser_list.item_selected.connect(asset_list_item_selected.bind())
	add_default_text()

func asset_list_item_selected(index:int):
	current_material = asset_browser_list.get_item_metadata(index)
	_update_properties()

var material_properties := {
	"Albedo": {
		"albedo_color": { "type": "color" },
		"albedo_texture": { "type": "texture" },
		"albedo_texture_force_srgb": { "type": "bool" }
	},
	"Roughness": {

		"roughness": { "type": "float", "min": 0.0, "max": 1.0 },
		"roughness_texture": { "type": "texture" }
	},
	"Metallic": {
		"metallic": { "type": "float", "min": 0.0, "max": 1.0 },
		"metallic_texture": { "type": "texture" }
		
	},
	"Normal": {
		"normal_enabled": { "type": "bool" },
		"normal_texture": { "type": "texture" },
		"normal_scale": { "type": "float", "min": 0.0, "max": 2.0 }
	},
	"Emission": {
		"emission_enabled": { "type": "bool" },
		"emission": { "type": "color" },
		"emission_energy_multiplier": { "type": "float", "min": 0.0, "max": 16.0 },
		"emission_texture": { "type": "texture" }
	},
	"Transparency": {
		"transparency": {
			"type": "enum",
			"values": {
				0: "Disabled",
				1: "Alpha",
				2: "Alpha Scissor",
				3: "Depth Prepass",
				4: "Alpha Hash"
			}
		},
		"alpha_scissor_threshold": { "type": "float", "min": 0.0, "max": 1.0, "show_if": { "prop": "transparency", "value": 2 } },
		"alpha_antialiasing_edge": { "type": "float", "min": 0.0, "max": 1.0, "show_if": { "prop": "transparency", "value": 2 } }
	},
	"Backlight": {
		"backlight_enabled": { "type": "bool" },
		"backlight": { "type": "color" },
		"backlight_texture": { "type": "texture" }
	},
	"UV": {
		"uv1_scale": { "type": "vec3", "min": Vector3(0,0,0), "max": Vector3(10,10,10) },
		"uv1_offset": { "type": "vec3", "min": Vector3(0,0,0), "max": Vector3(10,10,10) },
		"uv2_scale": { "type": "vec3", "min": Vector3(0,0,0), "max": Vector3(10,10,10) },
		"uv2_offset": { "type": "vec3", "min": Vector3(0,0,0), "max": Vector3(10,10,10) }
	},
	"Shading": {
		"shading_mode": {
			"type": "enum",
			"values": {
				0: "Unshaded",
				1: "Per Pixel",
				2: "Per Vertex"
			}
		}
	},
	"Culling": {
		"cull_mode": {
			"type": "enum",
			"values": {
				0: "Back",
				1: "Front",
				2: "Disabled"
			}
		}
	},

	"Other": {
		"anisotropy_enabled": { "type": "bool" },
		"anisotropy": { "type": "float", "min": -1.0, "max": 1.0 },
		"anisotropy_flowmap": { "type": "texture" },
		"refraction_enabled": { "type": "bool" },
		"refraction_scale": { "type": "float", "min": 0.0, "max": 1.0 },
		"refraction_texture": { "type": "texture" }
	}
}


var current_texture_prop : String = ""

@onready var texture_dialog : FileDialog = FileDialog.new()


func _assign_texture(prop:String):
	current_texture_prop = prop
	texture_dialog.popup_centered()

func _on_texture_selected(path:String):
	if current_material and current_texture_prop != "":
		var img = Image.new()
		var err = img.load(path)
		if err != OK:
			push_error("Failed to load image: " + path)
			return
		var tex = ImageTexture.new()
		tex.create_from_image(img)
		var tx2D : Texture2D = tex.create_from_image(img)
		current_material.set(current_texture_prop, tx2D)
	current_texture_prop = ""




func _update_properties():
	clear_properties()
	if current_material == null:
		add_default_text()
		return
	for section in material_properties.keys():
		_add_section(section, material_properties[section])

func _add_section(title:String, props:Dictionary):
	var wrapper = VBoxContainer.new()
	
	var header = Button.new()
	header.text = title
	header.toggle_mode = true
	header.button_pressed = false
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.visible = false

	var content = VBoxContainer.new()
	margin.add_child(content)
	content.add_theme_constant_override("separation", 5)

	header.toggled.connect(func(v): margin.visible = v)

	wrapper.add_child(header)
	wrapper.add_child(margin)
	properties_container.add_child(wrapper)

	for prop in props.keys():
		_add_property(content, prop, props[prop])


func _add_property(parent:VBoxContainer, prop:String, data:Dictionary):
	var row = HBoxContainer.new()
	var label = Label.new()
	label.text = prop.capitalize()
	label.custom_minimum_size.x = 200
	row.add_child(label)

	match data.type:
		"bool":
			var cb : CheckBox = CheckBox.new()

			cb.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cb.anchor_right = 1.0
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.button_pressed = current_material.get(prop)
			cb.toggled.connect(func(v): current_material.set(prop, v))
			row.add_child(cb)

		"float":
			var field : ProgressBar= slider_s.instantiate()
			field.min_value = data.min
			field.max_value = data.max
			field.step = 0.001
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.size_flags_vertical = Control.SIZE_FILL
			field.value = current_material.get(prop)
			field.value_changed.connect(func(v): current_material.set(prop, v))
			row.add_child(field)
			
		"vec3":
			var vec3_comp = vec3_component.instantiate()
			var current_value : Vector3 = current_material.get(prop)

			vec3_comp.update_value({
				"value": current_value,
				"min": data.min,
				"max": data.max
			})


			vec3_comp.value_changed.connect(func(v:Vector3):
				current_material.set(prop, v)
			)
			vec3_comp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vec3_comp.size_flags_vertical = Control.SIZE_FILL
			
			row.add_child(vec3_comp)

		
		"color":
			var picker = ColorPickerButton.new()
			picker.custom_minimum_size.y = 24.0
			picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
			picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			picker.color = current_material.get(prop)
			picker.color_changed.connect(func(c): current_material.set(prop, c))
			row.add_child(picker)

		"texture":
			var btn = Button.new()
			btn.text = "Assign Texture"
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(func(): _assign_texture(prop))
			row.add_child(btn)

		"enum":
			var opt = OptionButton.new()
			for k in data.values.keys():
				opt.add_item(data.values[k], k)
			opt.selected = current_material.get(prop)
			opt.item_selected.connect(func(id): current_material.set(prop, id))
			row.add_child(opt)

	parent.add_child(row)


func add_default_text():
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.text = "Select a material to manipulate its properties."
	properties_container.add_child(label)

func clear_properties():
	for c in properties_container.get_children():
		c.queue_free()
