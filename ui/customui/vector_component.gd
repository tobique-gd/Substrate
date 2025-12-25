extends HBoxContainer

@export var displayed_text : Label
@export var displayed_text_edit : LineEdit
@export var sensitivity := 0.01
@export var min_value := -INF
@export var max_value := INF
@export var step := 0.01

var value := 0.0
var _click_time := 0.0
var _double_time := 0.25
var _dragging := false
var _accumulated_value := 0.0
var _og_mouse_pos := Vector2()

func _ready() -> void:
	_update_text()
	displayed_text_edit.focus_exited.connect(_on_displayed_text_edit_focus_exited)
	displayed_text_edit.text_submitted.connect(_on_displayed_text_edit_text_submitted.bind())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and displayed_text.visible and displayed_text.get_global_rect().has_point(event.position):
			var t = Time.get_ticks_msec() / 1000.0
			if t - _click_time <= _double_time:
				_enter_edit()
				return
			_click_time = t
			_dragging = true
			_accumulated_value = value
			var canvas_to_screen = get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()
			_og_mouse_pos = canvas_to_screen * get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if Input.is_action_just_released("LMB") and _dragging:
		_dragging = false
		Input.warp_mouse(_og_mouse_pos)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and _dragging:
		_accumulated_value += event.relative.x * sensitivity
		value = snapped(clamp(_accumulated_value, min_value, max_value), step)
		_update_text()

func _enter_edit() -> void:
	displayed_text.visible = false
	displayed_text_edit.visible = true
	displayed_text_edit.text = str(value)
	displayed_text_edit.grab_focus()

func _on_displayed_text_edit_text_submitted(new_text: String) -> void:
	value = clamp(float(new_text), min_value, max_value)
	_update_text()
	_exit_edit()

func _on_displayed_text_edit_focus_exited() -> void:
	_exit_edit()

func _exit_edit() -> void:
	displayed_text_edit.visible = false
	displayed_text.visible = true

func _update_text() -> void:
	displayed_text.text = str(value)
	displayed_text_edit.text = str(value)
