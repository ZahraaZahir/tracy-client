extends Node

const BASE_URL = "http://localhost:3050"
var auth_token: String = ""

func register(email: String, username: String, password: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(_on_request_completed.bind(http_request))
	
	var body = JSON.stringify({
		"email": email,
		"username": username,
		"password": password
	})
	
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(BASE_URL + "/auth/register", headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		push_error("Failed to start HTTP request")
		http_request.queue_free()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest) -> void:
	request_node.queue_free()
	
	var response_text = body.get_string_from_utf8()
	var json_data = JSON.parse_string(response_text)
	
	if response_code == 201 or response_code == 200:
		print("Registration Successful: ", json_data)
	else:
		var error_msg = "Unknown Error"
		if json_data and json_data.has("error"):
			error_msg = json_data["error"]
		push_error("Registration Failed (" + str(response_code) + "): " + error_msg)
