extends Node

signal entity_data_received(success: bool, data: Dictionary)
signal entity_solve_finished(success: bool, message: String, wrong_slot: String)
signal entity_fixed_globally(id: String)
signal request_prompt_show(target_node: Node2D)
signal request_prompt_hide()

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func fetch_entity(entity_id: String) -> void:
	var endpoint = "/entities/" + entity_id
	BaseApiService.send_request(endpoint, HTTPClient.METHOD_GET, {}, true)

func solve_entity(entity_id: String, payload: Dictionary) -> void:
	var endpoint = "/entities/" + entity_id + "/solve"
	BaseApiService.send_request(endpoint, HTTPClient.METHOD_POST, payload, true)
	
func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if endpoint.begins_with("/entities/") and not endpoint.ends_with("/solve"):
		entity_data_received.emit(success, data)
	elif endpoint.ends_with("/solve"):
		if success:
			if data.has("fixedGlitches") and data.has("totalEntities"):
				ProgressionService.sync(data.fixedGlitches, data.totalEntities)
			var parts = endpoint.split("/")
			if parts.size() > 2:
				entity_fixed_globally.emit(parts[2])
		
		var msg = data.get("message", "Error")
		var wrong = data.get("wrongSlot", "")
		entity_solve_finished.emit(success, msg, wrong)
		
