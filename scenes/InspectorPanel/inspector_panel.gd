extends CanvasLayer 

@onready var panel = $PanelContainer 
@onready var terminal = $PanelContainer/TerminalDisplay

func _ready() -> void:
	panel.visible = false
	EntityService.entity_data_received.connect(_on_npc_data_arrived)

func _on_npc_data_arrived(success: bool, data: Dictionary) -> void:
	if success:
		show_terminal(data.get("templateCode", "No template received"))
	else:
		print("IDE: Fetch failed.")

func show_terminal(code_text: String) -> void:
	panel.visible = true
	terminal.text = code_text
	terminal.set_caret_line(0)

func _input(event):
	# Allow closing with Escape
	if event.is_action_pressed("ui_cancel") and panel.visible:
		panel.visible = false
