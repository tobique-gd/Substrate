extends Panel

@export var viewport : SubViewport
@onready var option_button: OptionButton = $MarginContainer/VBoxContainer/OptionButton
@export var grid_renderer : Node3D
@export var environment_seleciton : PanelContainer
@onready var environment_texture: TextureRect = $MarginContainer/VBoxContainer/EnvironmentSelection/MarginContainer/EnvironmentTexture
@export var environments_menu : Panel

@export var radio_buttons : Array[RadioButton]
@export var world_environment : WorldEnvironment
@export var directional_light : DirectionalLight3D

signal _on_selected(val)

var debug_mappings = {
	0: Viewport.DEBUG_DRAW_DISABLED,
	1: Viewport.DEBUG_DRAW_OVERDRAW,
	2: Viewport.DEBUG_DRAW_NORMAL_BUFFER,
	3: Viewport.DEBUG_DRAW_UNSHADED,
}

var environment_presets = {
	"default": "res://core/environments/default.tres",
	"sky": "res://core/environments/sky1.tres"
}

var debug_draw_enabled = false
var current_environment_preset = environment_presets["default"]

func _on_option_button_item_selected(index: int) -> void:
	var id = option_button.get_item_id(index)
	viewport.debug_draw = debug_mappings[id]
	grid_renderer.build()
	debug_draw_enabled = false
	if debug_mappings[id] != Viewport.DEBUG_DRAW_DISABLED:
		grid_renderer._clear()
		debug_draw_enabled = true
		return
	_apply_radio_mode()

func _ready() -> void:
	environment_seleciton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for btn in radio_buttons:
		btn._on_selected.connect(_radio_selected)

func _radio_selected(value):
	if debug_draw_enabled:
		return
	
	match value:
		0:
			viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			current_environment_preset = environment_presets["default"]
		1:
			viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
			current_environment_preset = environment_presets["default"]
		2:
			viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
			current_environment_preset = environment_presets["sky"]

	_apply_radio_mode()

func _apply_radio_mode():
	_update_environment(current_environment_preset)

func _update_environment(env):
	world_environment.environment = load(env)

func _input(event: InputEvent) -> void:
	handle_environment_selection(event)


var hovered = false
func handle_environment_selection(event : InputEvent):
	
	if event is InputEventMouseMotion:
		if environment_seleciton.get_global_rect().has_point(get_global_mouse_position()):
			environment_texture.material.set("shader_parameter/focused", true)
			hovered = true
		else:
			environment_texture.material.set("shader_parameter/focused", false)
			hovered = false
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and hovered:
		environments_menu.open(global_position + Vector2(size.x + 15.0, 40.0))
	
	
