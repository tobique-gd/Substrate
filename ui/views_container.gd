extends VSplitContainer

@export var node_editor: GraphEdit
@export var asset_browser: Panel
@export var model_viewport: SubViewportContainer
@export var texture_editor_viewport: Panel
@export var properties: Control
@export var meshset_properties: Control
@export var export_properties: Control

var panels := {}
var views := {
	"generating": ["model_viewport", "node_editor", "properties"],
	"texturing": ["model_viewport", "asset_browser"],
	"texture_editing": ["texture_editor_viewport", "meshset_properties"],
	"exporting": ["model_viewport", "export_properties"]
}

func _ready():
	SaveManager.register_property(self, "current_view")
	
	panels = {
		"node_editor": node_editor,
		"asset_browser": asset_browser,
		"model_viewport": model_viewport,
		"texture_editor_viewport": texture_editor_viewport,
		"properties": properties,
		"meshset_properties":meshset_properties,
		"export_properties":export_properties
	}

var current_view = "generating"

func update(view:String):
	if not views.has(view):
		return
	for k in panels.keys():
		panels[k].visible = k in views[view]
	current_view = view



func load_substrate_data():
	update(current_view)

func _on_generating_tab_pressed():
	update("generating")

func _on_texturing_tab_pressed():
	update("texturing")

func _on_texture_creation_tab_pressed():
	update("texture_editing")


func _on_export_tab_pressed() -> void:
	update("exporting")
