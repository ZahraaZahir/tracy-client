extends Node

const BASE_URL = "http://localhost:3050/api/v1"
var auth_token: String = ""

signal request_completed(endpoint: String, success: bool, response_data: Dictionary)

func register(email: String, username: String, password: String) -> void:
	_post_request("/auth/register", {
		"email": email,
		"username": username,
		"password": password
	})

func login(identifier: String, password: String) -> void:
	_post_request("/auth/login", {
		"identifier": identifier,
		"password": password
	})

func _post_request(endpoint: String, payload: Dictionary) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(_on_request_completed.bind(http, endpoint))
	
	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	
	var error = http.request(BASE_URL + endpoint, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		push_error("Could not initialize HTTP request")
		request_completed.emit(endpoint, false, {"message": "Local connection error"})
		http.queue_free()

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_node: HTTPRequest, endpoint: String) -> void:
	var response_text = body.get_string_from_utf8()
	var json_data = JSON.parse_string(response_text)
	
	if json_data == null:
		json_data = {"message": "Server error: " + response_text}
	
	var success = (response_code >= 200 and response_code < 300)
	
	if success and endpoint == "/auth/login":
		if json_data.has("token"):
			auth_token = json_data["token"]
			print("JWT session started.")

	request_completed.emit(endpoint, success, json_data)
	http_node.queue_free()
