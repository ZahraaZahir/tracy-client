extends Node

@onready var ui_click_player: AudioStreamPlayer = $UIClickPlayer
@onready var ui_solved_player: AudioStreamPlayer = $UISolvePlayer
@onready var ui_drop_player: AudioStreamPlayer = $UIDropPlayer
@onready var ui_deselect_player: AudioStreamPlayer = $UIDeselectPlayer

func _ready() -> void:
	_connect_buttons_recursive(get_tree().root)
	get_tree().node_added.connect(_on_node_added)
	
	if get_node_or_null("/root/EntityService"):
		get_node("/root/EntityService").entity_fixed_globally.connect(_on_entity_solved)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_signals(node)

func _connect_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		_connect_signals(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)

func _connect_signals(button: BaseButton) -> void:
	if not button.pressed.is_connected(_play_click):
		button.pressed.connect(_play_click)

func _play_click() -> void:
	ui_click_player.play()

func _on_entity_solved(_id: String) -> void:
	ui_solved_player.play()

func play_block_drop() -> void:
	ui_drop_player.pitch_scale = 1.0
	ui_drop_player.play()

func play_block_deselect() -> void:
	ui_deselect_player.pitch_scale = 1.15
	ui_deselect_player.play()
