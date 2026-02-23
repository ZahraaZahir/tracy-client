extends Node

const BASE_URL = "http://localhost:3050/api/v1"
var auth_token: String = ""

signal request_completed(endpoint: String, success: bool, response_data: Dictionary)

func register(email: String, username: String, password: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(_on_request_completed.bind(http_request, "/auth/register"))
	
	var body = JSON.stringify({
		"email": email,
		"username": username,
		"password": password
	})
	
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(BASE_URL + "/auth/register", headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		push_error("Failed to start HTTP request")
		request_completed.emit("/auth/register", false, {"message": "Local request error"})
		http_request.queue_free()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest, endpoint: String) -> void:
	request_node.queue_free()
	
	var response_text = body.get_string_from_utf8()
	var json_data = JSON.parse_string(response_text)
	
	if json_data == null:
		json_data = {"message": "Invalid server response"}
	
	var success = (response_code == 201 or response_code == 200)
	
	if success:
		print("API Success [" + endpoint + "]: ", json_data)
	else:
		push_error("API Error [" + endpoint + "] (" + str(response_code) + "): " + str(json_data))
	
	request_completed.emit(endpoint, success, json_data)
