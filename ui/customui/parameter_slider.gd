extends ProgressBar
class_name SubstrateSlider

@export var text: Label
@export var edit: LineEdit

var _click_time := 0.0
var _double_time := 0.25
var _dragging := false
var _accumulated_value := 0.0
var og_mouse_pos = Vector2()



func _enter_tree() -> void:
	edit.text = str(value)
	text.text = str(value)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and get_global_rect().has_point(event.position):
			var t = Time.get_ticks_msec() / 1000.0
			if t - _click_time <= _double_time:
				edit.visible = true
				edit.grab_focus()
				edit.text = str(value)
			_click_time = t
			_dragging = true
			var canvas_to_screen = get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()
			og_mouse_pos = canvas_to_screen * get_viewport().get_mouse_position()
			_accumulated_value = value
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if Input.is_action_just_released("LMB") and _dragging:
		_dragging = false
		Input.warp_mouse(og_mouse_pos)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and _dragging:
		var width = get_global_rect().size.x
		var range = max_value - min_value
		var delta_value = (event.relative.x / width) * range
		_accumulated_value = clamp(_accumulated_value + delta_value, min_value, max_value)
		value = snapped(_accumulated_value, step)
		text.text = str(value)

func _on_line_edit_text_submitted(new_text: String) -> void:
	value = float(new_text)
	text.text = str(value)
	edit.hide()

func _on_drag_started() -> void:
	mouse_default_cursor_shape = Control.CURSOR_HSIZE

func _on_drag_ended(value_changed: bool) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_line_edit_focus_exited() -> void:
	edit.hide()
