extends SpringArm3D

var min_length := 0.01
var max_length := 50.0
var panning := false
var rotating := false
var last_pos := Vector2.ZERO
var pan_sensitivity := 0.01
var rotate_sensitivity := 0.01
var zoom_sensitivity := 1.0

@export var cam_path : NodePath
var cam : Camera3D

signal zoom_changed(zoom:float)


func _ready() -> void:
	cam = get_node(cam_path)

func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() != null:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if Input.is_key_pressed(KEY_SHIFT):
					panning = true
				else:
					rotating = true
				last_pos = event.position
			else:
				panning = false
				rotating = false

		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				spring_length = clamp(spring_length - zoom_sensitivity, min_length, max_length)
				zoom_changed.emit(spring_length)
				
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				spring_length = clamp(spring_length + zoom_sensitivity, min_length, max_length)
				zoom_changed.emit(spring_length)
			
				
	if event is InputEventMouseMotion:
		var delta = event.position - last_pos
		if rotating:
			rotation.y -= delta.x * rotate_sensitivity
			rotation.x = clamp(rotation.x - delta.y * rotate_sensitivity, -1.5, 1.5)
			
		elif panning:
			var right = -cam.transform.basis.x
			var up = cam.transform.basis.y
			var zoom_norm = log(spring_length + 1.0)
			translate((right * delta.x + up * delta.y) * pan_sensitivity * zoom_norm)
		
		last_pos = event.position

	if event is InputEventMagnifyGesture:
		spring_length = clamp(spring_length / event.factor, min_length, max_length)
		zoom_changed.emit(spring_length)
