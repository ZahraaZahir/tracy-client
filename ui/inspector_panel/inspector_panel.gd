extends CanvasLayer

const CODE_ROW_SCENE = preload("res://ui/inspector_panel/code_row.tscn")
const CODE_LABEL_SCENE = preload("res://ui/inspector_panel/code_text.tscn")
const CODE_SLOT_SCENE = preload("res://ui/inspector_panel/code_slot/code_slot.tscn")

const THEME = {
	"keyword": Color("#A82820"), "punctuation": Color("#1A7878"),
	"variable": Color("#2A4A8A"), "string": Color("#4E7010"),
	"boolean": Color("#8A2868"), "number": Color("#B83C18"),
	"comment": Color("#7A7850"), "text": Color("#333333")
}

@onready var panel = $ContentRoot
@onready var editor_rows = %EditorRows
@onready var submit_button = %submit_button
@onready var stats_label = %StatusBarInfo
@onready var exit_button = %exit_button

var current_entity_id: String = ""
var current_edits: Dictionary = {}
var slot_nodes: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 
	visible = false
	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)
	
	exit_button.pressed.connect(_on_exit_pressed)
	
	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	
func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if not success: return
	
	current_entity_id = data.id 
	current_edits.clear()
	slot_nodes.clear()
	visible = true
	get_tree().paused = true
	
	submit_button.disabled = false
	panel.modulate.a = 1.0
	
	for child in editor_rows.get_children(): child.free()
	
	var is_fixed = data.get("isFixed", false)
	var solutions = data.get("solutionMap")
	if solutions == null or typeof(solutions) != TYPE_DICTIONARY:
		solutions = {}
	
	var lines = data.get("lines", [])
	stats_label.text = "Tracy++ | UTF-8 | %d lines" % lines.size()

	for i in range(lines.size()):
		var row = CODE_ROW_SCENE.instantiate()
		editor_rows.add_child(row)
		row.set_line_data(i + 1, i % 2 == 1)
		
		var row_hbox = row.get_child(0)
		var content_box = row.find_child("Content", true, false)
		if !content_box: continue
		
		content_box.add_theme_constant_override("separation", 0)
		var tokens = lines[i].duplicate()
		
		var leading_spaces = ""
		while !tokens.is_empty() and tokens[0].get("type") == "text" and tokens[0].content.strip_edges() == "":
			leading_spaces += tokens.pop_front().content
					
		if leading_spaces:
			var indent = CODE_LABEL_SCENE.instantiate()
			indent.text = leading_spaces.replace(" ", " ") 
			indent.add_theme_font_size_override("font_size", 28)
			row_hbox.add_child(indent)
			row_hbox.move_child(indent, content_box.get_index())
		
		for token in tokens:
			if token.get("type") == "slot":
				_create_slot_node(content_box, token, is_fixed, solutions)
			else:
				_create_text_node(content_box, token)

func _create_text_node(parent: Node, token: Dictionary):
	var label = CODE_LABEL_SCENE.instantiate()
	label.text = token.get("content", "").replace(" ", " ")
	label.add_theme_color_override("font_color", THEME.get(token.get("type", "text"), THEME.text))
	label.add_theme_font_size_override("font_size", 28)
	parent.add_child(label)

func _create_slot_node(parent: Node, token: Dictionary, fixed: bool, solutions: Dictionary):
	var id = token.get("id", "s1")
	var node = CODE_SLOT_SCENE.instantiate()
	parent.add_child(node)
	
	var state = ""
	var val = ""
	if fixed:
		state = "fixed"
		val = str(solutions.get(id, "FIXED"))
	else:
		state = "bug"
		val = str(token.get("currentValue", "???"))
	
	node.setup(id, val, state)
	node.add_theme_font_size_override("font_size", 28)
	
	current_edits[id] = solutions.get(id) if fixed else token.get("currentValue")
	slot_nodes[id] = node
	node.pressed.connect(_on_slot_clicked.bind(id))
	
func _update_slot(id: String, val, state: String, is_bug: bool = false):
	current_edits[id] = val 
	var txt = str(val)
	if typeof(val) == TYPE_STRING and !is_bug: txt = "\"" + txt + "\""
	slot_nodes[id].set_slot_state(state, txt)

func _on_slot_clicked(id: String):
	var node = slot_nodes[id]
	if node.current_state == "draft":
		_update_slot(id, node.original_value, "bug", true)
	else:
		var cheat = 1.0 if current_entity_id == "npc_cow_01" else "Sunflower" if current_entity_id == "npc_mouse_01" else false
		_update_slot(id, cheat, "draft")
		
func _on_submit_pressed():
	submit_button.disabled = true
	var payload = {"answers": current_edits}
	EntityService.solve_entity(current_entity_id, payload)

func _on_solve_result(success: bool, _message: String, _wrong: String):
	if success:
		var tween = create_tween().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func(): 
			visible = false
			get_tree().paused = false
		)
	else:
		_handle_error()

func _handle_error():
	submit_button.disabled = false
	var original_x = panel.position.x
	var shake = create_tween().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake.tween_property(panel, "position:x", original_x + 10, 0.05)
	shake.tween_property(panel, "position:x", original_x - 10, 0.05)
	shake.tween_property(panel, "position:x", original_x, 0.05)
	shake.set_loops(2)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and visible:
		visible = false
		get_tree().paused = false
		
func _on_exit_pressed() -> void:
	visible = false
	get_tree().paused = false
	ProgressionService.is_ui_active = false 
