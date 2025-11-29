extends Node


var shortcuts = {
	"add_node": {
		"key": KEY_A,
		"shift": true,
		"ctrl": false,
		"alt": false
	},
	"delete_node": {
		"key": KEY_X,
		"shift": false,
		"ctrl": false,
		"alt": false
	}
}

func is_shortcut(event: InputEventKey, shortcut: Dictionary) -> bool:
	if not event.pressed:
		return false
	if event.keycode != shortcut["key"]:
		return false
	if event.shift_pressed != shortcut["shift"]:
		return false
	if event.ctrl_pressed != shortcut["ctrl"]:
		return false
	if event.alt_pressed != shortcut["alt"]:
		return false
	return true
