extends CanvasLayer

const INVENTORY_SLOT_SCENE = preload("res://ui/inventory/inventory_slot.tscn")
const CODE_ROW_SCENE = preload("res://ui/inspector_panel/code_row.tscn")
const CODE_LABEL_SCENE = preload("res://ui/inspector_panel/code_text.tscn")
const CODE_SLOT_SCENE = preload("res://ui/inspector_panel/code_slot/code_slot.tscn")

@onready var inventory_list = %InventoryList
@onready var drag_layer = $DragLayer
@onready var warning_label = $MarginContainer/WarningLabel
@onready var warning_container = $MarginContainer
@onready var panel = $ContentRoot
@onready var editor_rows = %EditorRows
@onready var submit_button = %submit_button
@onready var stats_label = %StatusBarInfo
@onready var exit_button = %exit_button

const THEME = {
	"keyword": Color("#A82820"), "punctuation": Color("#1A7878"),
	"variable": Color("#2A4A8A"), "string": Color("#4E7010"),
	"boolean": Color("#8A2868"), "number": Color("#B83C18"),
	"comment": Color("#7A7850"), "text": Color("#333333")
}

var current_entity_id: String = ""
var current_edits: Dictionary = {}
var slot_nodes: Dictionary = {}
var warning_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)
	exit_button.pressed.connect(_on_exit_pressed)
	warning_container.visible = false

	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)

func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if not success: return

	for child in drag_layer.get_children():
		child.queue_free()
	
	current_entity_id = data.id
	current_edits.clear()
	slot_nodes.clear()
	visible = true
	ProgressionService.is_ui_active = true
	submit_button.disabled = false
	panel.modulate.a = 1.0

	_populate_inventory(data.get("inventory", []))

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
			indent.text = leading_spaces
			indent.add_theme_font_size_override("font_size", 28)
			row_hbox.add_child(indent)
			row_hbox.move_child(indent, content_box.get_index())

		for token in tokens:
			if token.get("type") == "slot":
				_create_slot_node(content_box, token, is_fixed, solutions)
			else:
				_create_text_node(content_box, token)
	if StoryService.should_play("first_inspect"):
		DialogueManager.show_example_dialogue_balloon(
			load("res://dialogue/main.dialogue"), 
			"first_inspect"
		)
		StoryService.mark_as_seen("first_inspect")


func _create_text_node(parent: Node, token: Dictionary):
	var label = CODE_LABEL_SCENE.instantiate()
	label.text = token.get("content", "").replace(" ", " ")
	label.add_theme_color_override("font_color", THEME.get(token.get("type", "text"), THEME.text))
	label.add_theme_font_size_override("font_size", 28)
	parent.add_child(label)

func _create_slot_node(parent: Node, token: Dictionary, fixed: bool, solutions: Dictionary):
	var id = token.get("id", "s1")
	var node = CODE_SLOT_SCENE.instantiate()
	parent.add_child(node)

	var state = "fixed" if fixed else "bug"
	var val = ""
	if fixed:
		var solution = solutions.get(id, {})
		var block_val = solution.get("value", "FIXED")
		val = '"%s"' % str(block_val) if solution.get("type") == "string" else str(block_val)
	else:
		val = str(token.get("currentValue", "???"))

	node.setup(id, val, state)
	current_edits[id] = solutions.get(id) if fixed else token.get("currentValue")
	slot_nodes[id] = node
	node.block_dropped.connect(_on_block_dropped)

func _update_slot(id: String, val, state: String, is_bug: bool = false):
	current_edits[id] = val
	var txt: String
	if typeof(val) == TYPE_DICTIONARY:
		var block_val = val.get("value")
		txt = '"%s"' % str(block_val) if val.get("type") == "string" else str(block_val)
	elif typeof(val) == TYPE_STRING and not is_bug:
		txt = '"%s"' % val
	else:
		txt = str(val)
	slot_nodes[id].set_slot_state(state, txt)

func _on_block_dropped(id: String, block_data: Dictionary):
	if block_data.is_empty():
		_update_slot(id, slot_nodes[id].original_value, "bug", true)
	else:
		_update_slot(id, block_data, "draft")

func _on_submit_pressed():
	var unresolved: Array =[]
	for id in current_edits:
		if typeof(current_edits[id]) != TYPE_DICTIONARY:
			unresolved.append(id)
			
	if not unresolved.is_empty():
		_handle_incomplete(unresolved)
		return

	submit_button.disabled = true
	
	for node in slot_nodes.values():
		node.is_locked = true
		
	EntityService.solve_entity(current_entity_id, {"answers": current_edits})
	
func _on_solve_result(success: bool, message: String, wrong_slot: String):
	if success:
		WorldService.remove_blocks(current_edits)
		for node in slot_nodes.values():
			node.consume_held_item()
		var tween = create_tween().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func():
			visible = false
			ProgressionService.is_ui_active = false
		)
	else:
		_handle_error(wrong_slot, message)

func _handle_error(wrong_slot: String, message: String = ""):
	submit_button.disabled = false
	
	for node in slot_nodes.values():
		node.is_locked = false

	if wrong_slot != "" and slot_nodes.has(wrong_slot):
		slot_nodes[wrong_slot].flash_error()

	if message != "":
		_show_warning(message, 3.0)

	var original_x = panel.position.x
	var shake = create_tween().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake.tween_property(panel, "position:x", original_x + 10, 0.05)
	shake.tween_property(panel, "position:x", original_x - 10, 0.05)
	shake.tween_property(panel, "position:x", original_x, 0.05)
	shake.set_loops(2)
	
func _handle_incomplete(unresolved: Array) -> void:
	_show_warning("Please fill the slot with a code block from the inventory.", .0)
	
	for id in unresolved:
		slot_nodes[id].flash_incomplete()

	get_tree().create_timer(1.5).timeout.connect(func():
		warning_container.visible = false
	, CONNECT_ONE_SHOT)

func _on_exit_pressed() -> void:
	visible = false
	ProgressionService.is_ui_active = false

func _populate_inventory(inventory_data: Array) -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	for block_data in inventory_data:
		var slot = INVENTORY_SLOT_SCENE.instantiate()
		inventory_list.add_child(slot)
		slot.setup_block(block_data, drag_layer)

func _show_warning(message_text: String, duration: float) -> void:
	warning_label.text = message_text
	warning_container.visible = true
	
	if warning_tween:
		warning_tween.kill()
		
	warning_tween = create_tween().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	warning_tween.tween_interval(duration)
	warning_tween.tween_callback(func(): warning_container.visible = false)
