extends VSplitContainer

@export var node_editor: GraphEdit
@export var asset_browser: Panel
@export var model_viewport: SubViewportContainer
@export var texture_creation_viewport: Panel

var panels := {}
var views := {
	"generating": ["model_viewport", "node_editor"],
	"texturing": ["model_viewport", "asset_browser"],
	"texture_creation": ["texture_creation_viewport"]
}

func _ready():
	panels = {
		"node_editor": node_editor,
		"asset_browser": asset_browser,
		"model_viewport": model_viewport,
		"texture_creation_viewport": texture_creation_viewport
	}

func update(view:String):
	if not views.has(view):
		return
	for k in panels.keys():
		panels[k].visible = k in views[view]

func _on_generating_tab_pressed():
	update("generating")

func _on_texturing_tab_pressed():
	update("texturing")

func _on_texture_creation_tab_pressed():
	update("texture_creation")
