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
		var msg = ""
		
		if success:
			msg = data.get("message", "Action successful")
		else:
			if data.has("details") and data["details"] is Array:
				var errors = []
				for issue in data["details"]:
					errors.append("• " + issue.get("message", "Invalid input"))
				msg = "\n".join(errors)
			else:
				msg = data.get("message", data.get("error", "Action failed"))
				
		auth_finished.emit(success, msg)
