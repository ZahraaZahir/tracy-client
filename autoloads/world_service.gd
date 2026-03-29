extends Node

signal world_loaded(data: Dictionary)

var is_persistence_ready: bool = false

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func save_state(pos: Vector2, map_name: String) -> void:
	if not is_persistence_ready: 
		return
	
	var payload = {
		"posX": pos.x,
		"posY": pos.y,
		"mapName": map_name
	}
	BaseApiService.send_request("/world/save", HTTPClient.METHOD_POST, payload, true)

func load_state() -> void:
	is_persistence_ready = false
	BaseApiService.send_request("/world/load", HTTPClient.METHOD_GET, {}, true)

func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if endpoint == "/world/load" and success:
		var actual_data = data.get("data", {})
		world_loaded.emit(actual_data)
	elif endpoint == "/world/save" and success:
		print("SYSTEM: World synced.")
