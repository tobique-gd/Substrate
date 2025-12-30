extends Control

@export var file_dialog : FileDialog
@export var meshinstances_to_export : Array[MeshInstance3D]

func _on_export_button_pressed() -> void:
	if file_dialog:
		file_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	
	for meshinstance in meshinstances_to_export:
		gltf_document_save.append_from_scene(meshinstance, gltf_state_save)
		# The file extension in the output `path` (`.gltf` or `.glb`) determines
		# whether the output uses text or binary format.
		# `GLTFDocument.generate_buffer()` is also available for saving to memory.

	gltf_document_save.write_to_filesystem(gltf_state_save, path)
