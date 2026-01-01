extends MenuBar

@export var open_file_dialog : FileDialog
@export var save_file_dialog : FileDialog
@export var file_popup : PopupMenu
@export var recent_submenu: PopupMenu

var FILE_id_procedures := {
	0: new,
	1: open,
	2: noop,
	4: save_file,
	5: save_file_as
}

func noop():
	pass

func save_file():
	if !SaveManager.save():
		save_file_as()

func save_file_as():
	save_file_dialog.show()

func open():
	open_file_dialog.show()

func new():
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		current_scene.queue_free()
	SaveManager.current_path = ""
	SaveManager.assert_window_title()
	var base_scene = preload("res://preview/main.tscn").instantiate()
	get_tree().get_root().add_child(base_scene)
	get_tree().set_current_scene(base_scene)

func _ready() -> void:
	file_popup.set_item_submenu(2, "RecentSubmenu")
	update_recent_files()

func update_recent_files():
	recent_submenu.clear()
	var sorted_files = SaveManager.get_recent_files_sorted()
	for i in range(sorted_files.size()):
		var file_entry = sorted_files[i]
		var path = file_entry["path"]
		var file_name = path.split("/")[-1]
		recent_submenu.add_item(file_name, i)
	recent_submenu.id_pressed.connect(_on_recent_file_selected.bind())

func _on_recent_file_selected(id: int):
	var sorted_files = SaveManager.get_recent_files_sorted()
	if id >= 0 and id < sorted_files.size():
		var path = sorted_files[id]["path"]
		SaveManager.open_substrate_file(path)

func _on_file_id_pressed(id: int):
	FILE_id_procedures[id].call()

func _on_open_file_dialog_file_selected(path: String):
	SaveManager.open_substrate_file(path)

func _on_save_file_dialog_file_selected(path: String):
	SaveManager.save_as(path)
