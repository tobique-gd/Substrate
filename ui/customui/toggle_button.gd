@tool
extends Panel
class_name ToggleButton

signal _on_selected_toggle(val: bool, value: int)

@export var texture: Texture2D
@onready var texture_rect: TextureRect = $TextureRect

@export_category("Styles")
@export var normal: StyleBox
@export var hover: StyleBox
@export var toggled: StyleBox

@export var radio_buttons: Array[Panel]

var is_hovered := false
@export var is_selected := false
@export var value : int

func _ready() -> void:
	if texture:
		texture_rect.texture = texture
	_update_style()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_hovered:
			_toggle()

	if event is InputEventMouseMotion:
		var inside := get_global_rect().has_point(event.position)

		if inside and not is_hovered:
			is_hovered = true
			if not is_selected:
				add_theme_stylebox_override("panel", hover)

		elif not inside and is_hovered:
			is_hovered = false
			if not is_selected:
				add_theme_stylebox_override("panel", normal)

func _toggle() -> void:
	# If part of a radio group, enforce radio behavior
	if radio_buttons.size() > 0:
		for b in radio_buttons:
			if b != self:
				b.is_selected = false
				b.add_theme_stylebox_override("panel", b.normal)
		is_selected = true
	else:
		# Normal toggle button behavior
		is_selected = not is_selected

	_update_style()
	_on_selected_toggle.emit(is_selected, value)

func _update_style() -> void:
	if is_selected:
		add_theme_stylebox_override("panel", toggled)
	else:
		add_theme_stylebox_override("panel", hover if is_hovered else normal)
