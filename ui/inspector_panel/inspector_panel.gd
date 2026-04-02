extends CanvasLayer

const CODE_ROW_SCENE = preload("res://ui/inspector_panel/code_row.tscn")
const CODE_LABEL_SCENE = preload("res://ui/inspector_panel/code_text.tscn")
const CODE_SLOT_SCENE = preload("res://ui/inspector_panel/code_slot/code_slot.tscn")

const THEME = {
	"keyword": Color("#A82820"),
	"punctuation": Color("#1A7878"),
	"variable": Color("#2A4A8A"),
	"string": Color("#4E7010"),
	"boolean": Color("#8A2868"),
	"number": Color("#B83C18"),
	"comment": Color("#7A7850"),
	"text": Color("#333333"),
	"line_bg": Color("#3A2C10", 0.15),
	"editor_bg": Color("#E8D9B5"),
	"footer_bg": Color("3a2c1000"),
	"footer_text": Color("#897042")
}

@onready var panel = $ContentRoot
@onready var main_window = $ContentRoot/MainWindow
@onready var status_label = find_child("status_label", true, false)

@onready var editor_rows = %EditorRows
@onready var submit_button = %submit_button
@onready var footer_bar = %FooterBar
@onready var stats_label = %StatusBarInfo

var current_entity_id: String = ""
var current_edits: Dictionary = {}
var slot_nodes: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS 
	visible = false 
	main_window.self_modulate = THEME.editor_bg
	
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = THEME.footer_bg
	footer_style.corner_radius_bottom_left = 5
	footer_style.corner_radius_bottom_right = 5
	footer_bar.add_theme_stylebox_override("panel", footer_style)
	
	var footer_margin = footer_bar.get_node("MarginContainer")
	footer_margin.add_theme_constant_override("margin_left", 30)
	footer_margin.add_theme_constant_override("margin_right", 45)
	footer_margin.add_theme_constant_override("margin_top", 8) 
	footer_margin.add_theme_constant_override("margin_bottom", 8)

	var btn_container = submit_button.get_parent()
	if btn_container is BoxContainer:
		btn_container.add_theme_constant_override("separation", 20)

	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size.y = 15
	$ContentRoot/VBoxContainer.add_child(bottom_spacer)

	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)
	
	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
		
func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if not success: return
	
	current_entity_id = data.id 
	current_edits.clear()
	slot_nodes.clear()
	
	status_label.text = "SYSTEM READY"
	status_label.remove_theme_color_override("font_color")
	panel.modulate.a = 1.0
	visible = true
	get_tree().paused = true
	
	submit_button.disabled = false
	submit_button.modulate.a = 1.0
	
	for child in editor_rows.get_children():
		child.free()
	
	var editor_margin_container = editor_rows.get_parent()
	if editor_margin_container is MarginContainer:
		editor_margin_container.add_theme_constant_override("margin_left", 30)

	var is_fixed = data.get("isFixed", false)
	var solutions = data.get("solutionMap") if data.get("solutionMap") != null else {}
	var lines_data = data.get("lines") if data.get("lines") != null else[]

	stats_label.text = "Tracy++ | UTF-8 | %d lines" % [lines_data.size()]
	stats_label.add_theme_color_override("font_color", THEME.footer_text)

	for i in range(lines_data.size()):
		var row = CODE_ROW_SCENE.instantiate()
		editor_rows.add_child(row)
		
		if row.has_method("set_line_data"):
			row.set_line_data(i + 1, i % 2 == 1)
		
		var row_hbox = row.find_child("HBoxContainer", true, false)
		if row_hbox:
			row_hbox.add_theme_constant_override("separation", 25)
		
		var content_box = row.find_child("Content", true, false)
		if content_box:
			content_box.add_theme_constant_override("separation", 0)
			for token in lines_data[i]:
				if token.get("type") == "slot":
					_create_slot_node(content_box, token, is_fixed, solutions)
				else:
					_create_text_node(content_box, token)

func _create_text_node(parent: Node, token: Dictionary):
	var label = CODE_LABEL_SCENE.instantiate()
	label.text = token.get("content", "").replace(" ", " ")
	var type = token.get("type", "text")
	label.add_theme_color_override("font_color", THEME.get(type, THEME.text))
	label.add_theme_font_size_override("font_size", 28)
	parent.add_child(label)

func _create_slot_node(parent: Node, token: Dictionary, is_fixed: bool, solutions: Dictionary):
	var slot_id = token.get("id", "s1")
	var slot_instance = CODE_SLOT_SCENE.instantiate()
	parent.add_child(slot_instance)
	
	var val = str(solutions.get(slot_id)) if is_fixed else str(token.get("currentValue", "???"))
	var state = "fixed" if is_fixed else "bug"
	
	slot_instance.setup(slot_id, val, state)
	slot_instance.add_theme_font_size_override("font_size", 28)
	current_edits[slot_id] = val
	slot_nodes[slot_id] = slot_instance
	slot_instance.pressed.connect(_on_slot_clicked.bind(slot_id))
	
func _update_slot(id: String, val, state: String):
	current_edits[id] = val 
	
	var display_text = str(val)
	
	if typeof(val) == TYPE_STRING:
		display_text = "\"" + display_text + "\""
	
	slot_nodes[id].set_slot_state(state, display_text)

func _on_slot_clicked(slot_id: String):
	var node = slot_nodes[slot_id]
	
	if node.current_state == "draft":
		_update_slot(slot_id, node.original_value, "bug")
	else:
		var cheat_val
		if current_entity_id == "npc_cow_01":
			cheat_val = 1.0
		elif current_entity_id == "npc_mouse_01":
			cheat_val = "Sunflower"
		else:
			cheat_val = false
		_update_slot(slot_id, cheat_val, "draft")
		
func _on_submit_pressed():
	submit_button.disabled = true
	status_label.text = "PATCHING..."
	EntityService.solve_entity(current_entity_id, current_edits)

func _on_solve_result(success: bool, message: String, _wrong: String):
	if success:
		status_label.text = "STATUS: PATCHED!"
		status_label.add_theme_color_override("font_color", Color("65ffb7"))
		
		var tween = create_tween().bind_node(self) 
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func(): 
			visible = false
			get_tree().paused = false
		)
	else:
		_set_status_error(message)

func _set_status_error(message: String):
	status_label.text = "ERROR: " + message
	status_label.add_theme_color_override("font_color", Color("ff6761"))
	
	submit_button.disabled = false 
	
	var original_x = panel.position.x
	var shake = create_tween().bind_node(self)
	shake.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake.tween_property(panel, "position:x", original_x + 10, 0.05)
	shake.tween_property(panel, "position:x", original_x - 10, 0.05)
	shake.tween_property(panel, "position:x", original_x, 0.05)
	shake.set_loops(2)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and visible:
		visible = false
		get_tree().paused = false
