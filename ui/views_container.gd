extends VSplitContainer

@export var node_editor: GraphEdit
@export var asset_browser: Panel

var view_panels = {
	"generating": {
		"node_editor": true,
		"asset_browser": false
	},
	"texturing": {
		"node_editor": false,
		"asset_browser": true
	}
}

func update(view: String):
	var config = view_panels.get(view)
	if config == null:
		return
	node_editor.visible = config["node_editor"]
	asset_browser.visible = config["asset_browser"]


func _on_generating_tab_pressed() -> void:
	update("generating")


func _on_texturing_tab_pressed() -> void:
	update("texturing")
