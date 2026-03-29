extends CanvasLayer

@onready var panel = $ContentRoot
@onready var terminal = $ContentRoot/VBoxContainer/TerminalContainer/TerminalDisplay
@onready var status_label = $ContentRoot/VBoxContainer/status_label
@onready var submit_button = $ContentRoot/VBoxContainer/HBoxContainer/submit_button

var current_entity_id: String = ""

func _ready() -> void:
	panel.visible = false
	EntityService.entity_data_received.connect(_on_npc_data_arrived)
	EntityService.entity_solve_finished.connect(_on_solve_result)

func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if success:
		current_entity_id = data.id 
		panel.visible = true
		
		if data.isFixed:
			status_label.text = "STATUS: STABLE"
			submit_button.disabled = true
	
			terminal.text = _render_terminal_text(data.templateCode, data.solutionMap, true)
		else:
			status_label.text = "STATUS: CORRUPTED"
			submit_button.disabled = false
			terminal.text = _render_terminal_text(data.templateCode, {}, false)
	else:
		push_error("UI: Could not find NPC data in the database.")

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
		my_answer = {"s1": false}
	elif current_entity_id == "npc_mouse_01":
		my_answer = {"s1": "Sunflower"} 
	EntityService.solve_entity(current_entity_id, my_answer)

func _on_solve_result(success: bool, message: String, _wrong_slot: String) -> void:
	if success:
		print("VICTORY: ", message)
		status_label.text = "STATUS: PATCHED"
		await get_tree().create_timer(1.5).timeout
		panel.visible = false 
	else:
		status_label.text = "ERROR: " + message
		print("LOGIC ERROR: ", message)

func _input(event):
	if event.is_action_pressed("ui_cancel") and panel.visible:
		panel.visible = false
