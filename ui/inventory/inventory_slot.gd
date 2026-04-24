extends Control

@onready var area: Area2D = $Area2D
@onready var visuals: PanelContainer = $Area2D/PanelContainer
@onready var label: Label = $Area2D/PanelContainer/Label
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var draggable: Node = $Area2D/Draggable

var logic_block: Dictionary = {}

const TYPE_COLORS = {
	"boolean": Color("#8A2868"), 
	"number": Color("#B83C18"),
	"int": Color("#B83C18"),
	"float": Color("#B83C18"),
	"string": Color("#4E7010")
}

func _ready() -> void:
	area.set_meta("slot_root", self)
	
	get_tree().process_frame.connect(_sync_collision_size)

func setup_block(block_data: Dictionary, drag_layer: Node) -> void:
	logic_block = block_data
	draggable.drag_layer_parent = drag_layer

	var val = block_data.get("value", "??")
	if typeof(val) == TYPE_STRING:
		label.text = '"%s"' % val
	else:
		label.text = str(val)
	
	var block_type = block_data.get("type", "string")
	var style = visuals.get_theme_stylebox("panel").duplicate()
	style.bg_color = TYPE_COLORS.get(block_type, Color("#333333"))
	visuals.add_theme_stylebox_override("panel", style)

func _sync_collision_size() -> void:
	if not visuals or not collision_shape: return
	
	var box_size = visuals.size
	
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = box_size
		# Center the hitbox over the visuals
		collision_shape.position = box_size / 2
