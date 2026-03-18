extends Node

signal entity_data_received(success: bool, data: Dictionary)

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func fetch_entity(entity_id: String) -> void:
	var endpoint = "/entities/" + entity_id
	BaseApiService.send_request(endpoint, HTTPClient.METHOD_GET, {}, true)

func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if endpoint.begins_with("/entities/"):
		
		print("--- API RESPONSE START ---")
		print("Endpoint: ", endpoint)
		print("Success: ", success)
		print("Data Received: ", data)
		print("--- API RESPONSE END ---")

		
		if success:
			entity_data_received.emit(true, data)
		else:
			entity_data_received.emit(false, data)
