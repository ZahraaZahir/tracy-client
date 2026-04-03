extends Node

const BASE_URL = "http://localhost:3050/api/v1"
var developer_id: String = "GUEST"
var auth_token: String = ""

signal request_finished(endpoint: String, success: bool, data: Dictionary)

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func send_request(endpoint: String, method: int, payload: Dictionary = {}, use_auth: bool = false) -> void:   
	var http = HTTPRequest.new()
	add_child(http)
	
	http.process_mode = PROCESS_MODE_ALWAYS
	
	http.request_completed.connect(_on_request_completed.bind(http, endpoint))
	
	var headers =["Content-Type: application/json"]
	if use_auth and not auth_token.is_empty():
		headers.append("Authorization: Bearer " + auth_token)
	
	var body = JSON.stringify(payload) if not payload.is_empty() else ""
	var err = http.request(BASE_URL + endpoint, headers, method, body)
	
	if err != OK:
		push_error("Failed to start request: " + endpoint)
		request_finished.emit(endpoint, false, {"message": "Local connection error"})
		http.queue_free()

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, endpoint: String) -> void:
	print("BRIDGE DEBUG: Received response from ", endpoint, " | Code: ", response_code)

	var response_text = body.get_string_from_utf8()
	var json_data = JSON.parse_string(response_text)
	if json_data == null:
		json_data = {"message": "Server communication error."}
	
	var success = (response_code >= 200 and response_code < 300)
	var actual_payload = json_data
	if json_data.has("data"):
		actual_payload = json_data["data"] 
	if success and actual_payload.has("token"):
		auth_token = actual_payload["token"]
		print("TOKEN CAPTURED: ", auth_token.left(10), "...") 
	if success and actual_payload.has("username"):
		developer_id = actual_payload["username"]
	
	request_finished.emit(endpoint, success, actual_payload)
	http_node.queue_free()
	
func logout() -> void: 
		auth_token = ""
		developer_id = "GUEST"
		get_tree().change_scene_to_file("res://ui/welcome/welcome.tscn")
