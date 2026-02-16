extends Control

@onready var http_request = $HTTPRequest
@onready var status_label = $StatusLabel
@onready var ping_button = $PingButton

const SERVER_URL = "http://localhost:3050/status"

func _ready():
	ping_button.pressed.connect(_on_ping_button_pressed)
	http_request.request_completed.connect(_on_request_completed)

func _on_ping_button_pressed():
	status_label.text = "Contacting Tracy..."
	ping_button.disabled = true
	
	var error = http_request.request(SERVER_URL)
	if error != OK:
		status_label.text = "Error starting request!"
		ping_button.disabled = false

func _on_request_completed(result, response_code, headers, body):
	ping_button.disabled = false
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("status"):
			status_label.text = "Connected! Server Status: " + json["status"]
			status_label.modulate = Color.GREEN
		else:
			status_label.text = "Invalid JSON received."
	else:
		status_label.text = "Failed! Code: " + str(response_code)
		status_label.modulate = Color.RED
