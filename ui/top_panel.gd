extends Panel

@export var viewport : SubViewport
@export var grid_renderer : Node3D
@export var environment_selection : PanelContainer
@export var environments_menu : Panel
@export var radio_buttons : Array[RadioButton]
@export var world_environment : WorldEnvironment
@export var directional_light : DirectionalLight3D
@export var drawing_options_menu : Panel
@export var drawing_options : Button


@export var option_button: OptionButton
@export var current_environment_texture: TextureRect


var debug_mappings = {
	0: Viewport.DEBUG_DRAW_DISABLED,
	1: Viewport.DEBUG_DRAW_OVERDRAW,
	2: Viewport.DEBUG_DRAW_NORMAL_BUFFER,
	3: Viewport.DEBUG_DRAW_UNSHADED,
}

var environment_presets = {
	"default": "res://core/environments/default.tres",
	"sky1": "res://core/environments/sky1.tres",
	"hill1": "res://core/environments/hill1.tres",
	"grass_field1": "res://core/environments/grass_field1.tres",
	"studio1":"res://core/environments/studio1.tres"
}

var environment_hdri_folder_path = GlobalPaths.environment_hdri_folder_path

var debug_draw_enabled = false
var current_environment_preset = "grass_field1"
var environment_button_hovered = false
var environment_button_toggled = false

var current_radio_mode = 0

@export var grid_toggle_button : ToggleButton


func _ready() -> void:
	grid_toggle_button._on_selected_toggle.connect(_on_button_selected.bind())
	environment_selection.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for btn in radio_buttons:
		btn._on_selected.connect(_radio_selected)

func _on_button_selected(toggled_on: bool, _value: int):
	if debug_draw_enabled:
		return
	for c in grid_renderer.get_children():
		c.visible = toggled_on

func _on_option_button_item_selected(index: int) -> void:
	var id = option_button.get_item_id(index)
	viewport.debug_draw = debug_mappings[id]
	grid_renderer.build()
	debug_draw_enabled = false
	if debug_mappings[id] != Viewport.DEBUG_DRAW_DISABLED:
		grid_renderer._clear()
		debug_draw_enabled = true
		return
	
	if current_radio_mode == 1 or current_radio_mode == 0:
		_update_environment("default")
	

func _radio_selected(value):
	current_radio_mode = value
	if debug_draw_enabled:
		return
	match value:
		0:
			viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			_update_environment("default")
			return
		1:
			viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
			_update_environment("default")
			return
		2:
			viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
			
	_apply_radio_mode()

func _apply_radio_mode():
	_update_environment(current_environment_preset)

func _update_environment(env:String):
	world_environment.environment = load(environment_presets[env])

func _input(event: InputEvent) -> void:
	handle_environment_selection(event)

func handle_environment_selection(event : InputEvent):
	if drawing_options_menu.visible:
		if event is InputEventMouseMotion:
			if environment_selection.get_global_rect().has_point(get_global_mouse_position()):
				current_environment_texture.material.set("shader_parameter/focused", true)
				environment_button_hovered = true
			else:
				current_environment_texture.material.set("shader_parameter/focused", false)
				environment_button_hovered = false
		
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and environment_selection.get_global_rect().has_point(get_global_mouse_position()):
			match environment_button_toggled:
				true:
					environments_menu.close()
					environment_button_toggled = false
				false:
					environment_button_toggled = true
					environments_menu.open(drawing_options_menu.global_position + Vector2(drawing_options_menu.size.x + 8.0, 0.0))

func _on_drawing_options_toggled(toggled_on: bool) -> void:
	drawing_options_menu.global_position = drawing_options.global_position + Vector2(-drawing_options_menu.size.x / 2.0, drawing_options.size.y + 10) + Vector2(drawing_options.size.x, 0.0)
	drawing_options_menu.visible = toggled_on
	if toggled_on == false:
		environments_menu.close()
		environment_button_toggled = false
			

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var rect_margin = Vector2(30.0, 30.0)
		if not Rect2(drawing_options_menu.get_global_rect().position - rect_margin / 2.0, drawing_options_menu.get_global_rect().size + rect_margin).has_point(get_global_mouse_position()):
			drawing_options_menu.hide()
			drawing_options.button_pressed = false
			environments_menu.close()
			environment_button_toggled = false

func on_click(preset):
	if environments_menu.visible:
		current_environment_preset = preset
		if FileAccess.file_exists(environment_hdri_folder_path + preset + ".exr"):
			current_environment_texture.texture = load(environment_hdri_folder_path + preset + ".exr")
		if current_radio_mode == 2:
			_update_environment(current_environment_preset)
