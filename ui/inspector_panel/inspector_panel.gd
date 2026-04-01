extends CanvasLayer

const CODE_LABEL_SCENE = preload("res://ui/inspector_panel/code_text.tscn")
const CODE_SLOT_SCENE = preload("res://ui/inspector_panel/code_slot/code_slot.tscn")

@onready var panel = $ContentRoot
@onready var editor_rows = $ContentRoot/VBoxContainer/TerminalContainer/EditorRows
@onready var status_label = $ContentRoot/VBoxContainer/status_label
@onready var submit_button = $ContentRoot/VBoxContainer/HBoxContainer/submit_button

var current_entity_id: String = ""
var current_edits: Dictionary = {}
var slot_nodes: Dictionary = {}

func _ready() -> void:
	visible = false 
	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)
	
	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)

func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if not success: return

	current_entity_id = data.id 
	current_edits.clear()
	slot_nodes.clear()
	
	status_label.remove_theme_color_override("font_color")
	panel.modulate.a = 1.0
	visible = true
	submit_button.disabled = false
	
	for child in editor_rows.get_children():
		child.free()
	
	var is_fixed = data.get("isFixed", false)
	var solutions = data.get("solutionMap")
	if solutions == null:
		solutions = {}
	
	for line_data in data.get("lines", []):
		var line_node = HBoxContainer.new()
		line_node.add_theme_constant_override("separation", 0) 
		editor_rows.add_child(line_node)
		
		for token in line_data:
			if token.get("type") == "slot":
				_create_slot_node(line_node, token, is_fixed, solutions)
			else:
				_create_text_node(line_node, token)

func _create_text_node(parent: Node, token: Dictionary):
	var label = CODE_LABEL_SCENE.instantiate()
	label.text = token.get("content", "")
	
	match token.get("type", "text"):
		"keyword": label.add_theme_color_override("font_color", Color("ff79c6"))
		"punctuation": label.add_theme_color_override("font_color", Color("8be9fd"))
		"text": label.add_theme_color_override("font_color", Color("f8f8f2"))
	
	parent.add_child(label)

func _create_slot_node(parent: Node, token: Dictionary, is_fixed: bool, solutions: Dictionary):
	print("FACTORY: Processing token: ", token)
	
	var slot_id = token.get("id", token.get("slotId", "unknown"))
	
	if slot_id == "unknown":
		print("!!! ERROR: Backend token is missing an ID. Using 's1' as fallback.")
		slot_id = "s1"

	var slot_instance = CODE_SLOT_SCENE.instantiate()
	parent.add_child(slot_instance)
	
	var initial_val: String = ""
	if is_fixed:
		initial_val = str(solutions.get(slot_id, "FIXED"))
		slot_instance.setup(slot_id, initial_val, "fixed")
	else:
		var bug = token.get("currentValue")
		initial_val = str(bug) if bug != null else "???"
		slot_instance.setup(slot_id, initial_val, "bug")
	
	current_edits[slot_id] = initial_val
	slot_nodes[slot_id] = slot_instance
	
	print("MEMORY: Added ", slot_id, " with value: ", initial_val)
	
	slot_instance.pressed.connect(_on_slot_clicked.bind(slot_id))

func _on_slot_clicked(slot_id: String):
	var slot_node = slot_nodes[slot_id]
	
	if slot_node.current_state == "draft":
		current_edits[slot_id] = slot_node.original_value
		slot_node.set_slot_state("bug", slot_node.original_value)
	else:
		var new_val = "false" 
		
		if current_entity_id == "npc_cow_01": 
			new_val = "1" 
		
		if current_entity_id == "npc_mouse_01": 
			new_val = "Sunflower"
		
		current_edits[slot_id] = new_val
		slot_node.set_slot_state("draft", new_val)

func _on_submit_pressed():
	if current_edits.size() == 0:
		return

	var payload = current_edits 
	
	print("FLATTENED PAYLOAD: ", JSON.stringify(payload))
	
	submit_button.disabled = true
	status_label.text = "PATCHING..."
	
	EntityService.solve_entity(current_entity_id, payload)

func _on_solve_result(success: bool, message: String, _wrong_slot: String) -> void:
	if success:
		status_label.text = "STATUS: PATCHED!"
		status_label.add_theme_color_override("font_color", Color("65ffb7"))
		
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): visible = false)
	else:
		_set_status_error(message)

func _set_status_error(message: String) -> void:
	status_label.text = "ERROR: " + message
	status_label.add_theme_color_override("font_color", Color("ff6761"))
	submit_button.disabled = false
	
	var original_x = panel.position.x
	var shake_tween = create_tween()
	shake_tween.tween_property(panel, "position:x", original_x + 10, 0.05)
	shake_tween.tween_property(panel, "position:x", original_x - 10, 0.05)
	shake_tween.tween_property(panel, "position:x", original_x, 0.05)
	shake_tween.set_loops(2)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		visible = false
