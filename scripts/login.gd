extends Control

@onready var identifier_input: LineEdit = $CenterContainer/CredentialsContainer/IdentifierContainer/IdentifierInput
@onready var password_input: LineEdit = $CenterContainer/CredentialsContainer/PasswordContainer/PasswordInput
@onready var login_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/LoginButton
@onready var status_label: Label = $CenterContainer/CredentialsContainer/StatusLabel
@onready var back_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/BackButton

const COLOR_ERROR = Color("ff6761ff")
const COLOR_SUCCESS = Color("65ffb7ff")
const COLOR_PENDING = Color("#ffef4b")

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	ApiService.request_completed.connect(_on_api_response)
	
	status_label.text = ""
	identifier_input.grab_focus()

func _on_login_pressed() -> void:
	var id = identifier_input.text.strip_edges()
	var pw = password_input.text.strip_edges()
	
	if id.is_empty() or pw.is_empty():
		_update_status("Error: Enter credentials.", COLOR_ERROR)
		return
	
	_update_status("Authenticating...", COLOR_PENDING)
	login_button.disabled = true
	
	ApiService.login(id, pw)

func _on_api_response(endpoint: String, success: bool, response_data: Dictionary) -> void:
	if endpoint != "/auth/login":
		return
		
	login_button.disabled = false
	
	if success:
		_update_status("Login Successful!", COLOR_SUCCESS)
		print("Token acquired: ", ApiService.auth_token)
	else:
		var error_msg = response_data.get("message", "Invalid email or password.")
		_update_status("Error: " + str(error_msg), COLOR_ERROR)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/welcome.tscn")

func _update_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_label.visible = true
