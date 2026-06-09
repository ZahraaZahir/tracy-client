extends Node

const BUTTON_CLICK_SFX = preload("res://audio/sounds/button_click.wav")
const BUG_DEATH_SFX = preload("res://audio/sounds/bug_death.wav")
const ENTITY_SOLVED_SFX = preload("res://audio/sounds/entity_solved.wav")

var ui_click_player: AudioStreamPlayer
var ui_solved_player: AudioStreamPlayer

func _ready() -> void:
	ui_click_player = AudioStreamPlayer.new()
	ui_click_player.stream = BUTTON_CLICK_SFX
	ui_click_player.bus = "sfx"
	add_child(ui_click_player)
	
	ui_solved_player = AudioStreamPlayer.new()
	ui_solved_player.stream = ENTITY_SOLVED_SFX
	ui_solved_player.bus = "sfx"
	add_child(ui_solved_player)
	
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

func play_bug_death(position: Vector2) -> void:
	play_spatial_sfx(BUG_DEATH_SFX, position)
	
func play_spatial_sfx(stream: AudioStream, position: Vector2) -> void:
	var spatial_player = AudioStreamPlayer2D.new()
	spatial_player.stream = stream
	spatial_player.global_position = position
	spatial_player.bus = "sfx"
	
	get_tree().root.add_child(spatial_player)
	spatial_player.play()
	
	spatial_player.finished.connect(spatial_player.queue_free)
