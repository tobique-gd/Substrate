extends Panel

var selected: bool = true
@onready var check_box: CheckBox = $CheckBox
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

@export var deselected_stylebox : StyleBoxFlat
@export var selected_stylebox : StyleBoxFlat

var uid : int = -1

signal panel_clicked(_uid, _selected)

func _ready() -> void:
	selected = check_box.button_pressed
	

func _on_check_box_toggled(toggled_on: bool) -> void:
	selected = toggled_on
	update()

func update():
	add_theme_stylebox_override("panel", selected_stylebox if selected else deselected_stylebox)
	panel_clicked.emit(uid, selected)
	check_box.button_pressed = selected
	

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if self.get_global_rect().has_point(get_global_mouse_position()):
				selected = !selected
				check_box.button_pressed = selected
			

func update_image_texture(tex: ImageTexture):
	texture_rect.texture = tex
