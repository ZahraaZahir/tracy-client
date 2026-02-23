extends Node

signal auth_finished(success: bool, message: String)

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func register(email: String, user: String, password: String) -> void:
	var payload = {"email": email, "username": user, "password": password}
	BaseApiService.send_request("/auth/register", HTTPClient.METHOD_POST, payload)

func login(identifier: String, password: String) -> void:
	var payload = {"identifier": identifier, "password": password}
	BaseApiService.send_request("/auth/login", HTTPClient.METHOD_POST, payload)

func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if endpoint == "/auth/register" or endpoint == "/auth/login":
		var msg = data.get("message", data.get("error", "Action successful" if success else "Action failed"))
		auth_finished.emit(success, msg)
