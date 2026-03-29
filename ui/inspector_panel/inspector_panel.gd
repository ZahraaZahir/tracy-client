extends CanvasLayer

@onready var panel = $ContentRoot
@onready var background = $BackgroundOverlay
@onready var terminal = $ContentRoot/VBoxContainer/TerminalContainer/TerminalDisplay
@onready var status_label = $ContentRoot/VBoxContainer/status_label
@onready var submit_button = $ContentRoot/VBoxContainer/HBoxContainer/submit_button

var current_entity_id: String = ""

func _ready() -> void:
	# Hide the entire layer at start
	visible = false 
	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)
	
	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)

func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if not success: return

	current_entity_id = data.id 
	status_label.remove_theme_color_override("font_color")
	panel.modulate.a = 1.0
	visible = true
	
	if data.isFixed:
		status_label.text = "STATUS: STABLE"
		submit_button.disabled = true
		terminal.text = _render_terminal_text(data.templateCode, data.solutionMap, true)
	else:
		status_label.text = "STATUS: CORRUPTED"
		submit_button.disabled = false
		terminal.text = _render_terminal_text(data.templateCode, {}, false)

func _render_terminal_text(template: String, solutions: Dictionary, fixed: bool) -> String:
	var result_text = template
	if fixed:
		for key in solutions.keys():
			var find_me = "{{" + key + "}}"
			var replace_with = str(solutions[key]) 
			result_text = result_text.replace(find_me, replace_with)
	else:
		var regex = RegEx.new()
		regex.compile("\\{\\{.*?\\}\\}") 
		result_text = regex.sub(result_text, "[ ___ ]", true)
	return result_text

func _on_submit_pressed() -> void:
	var my_answer = {}
	if current_entity_id == "npc_cow_01":
		my_answer = {"s1": 1.0}
	elif current_entity_id == "npc_girl_farmer_01":
		my_answer = {"s1": true}
	elif current_entity_id == "npc_mouse_01":
		my_answer = {"s1": "Sunflower"} 
	
	submit_button.disabled = true
	EntityService.solve_entity(current_entity_id, my_answer)

func _on_solve_result(success: bool, message: String, _wrong_slot: String) -> void:
	if success:
		status_label.text = "STATUS: PATCHED!"
		status_label.add_theme_color_override("font_color", Color("65ffb7"))
		
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)
		
		tween.tween_callback(func(): 
			visible = false 
		)
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
