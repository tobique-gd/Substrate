@tool
extends Panel
class_name RadioButton

signal _on_selected(val)

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
	if texture != null:
		texture_rect.texture = texture
	add_theme_stylebox_override("panel", toggled if is_selected else normal)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_hovered:
			_select()
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

func _select() -> void:
	for b in radio_buttons:
		if b != self:
			b.is_selected = false
			b.add_theme_stylebox_override("panel", b.normal)
	_on_selected.emit(value)
	is_selected = true
	add_theme_stylebox_override("panel", toggled)
