extends Control

@onready var email_input: LineEdit = $CenterContainer/CredentialsContainer/EmailContainer/EmailInput
@onready var username_input: LineEdit = $CenterContainer/CredentialsContainer/UsernameContainer/UsernameInput
@onready var password_input: LineEdit = $CenterContainer/CredentialsContainer/PasswordContainer/PasswordInput
@onready var back_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/BackButton
@onready var register_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/RegisterButton
@onready var status_label: Label = $CenterContainer/CredentialsContainer/StatusLabel

func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)
	back_button.pressed.connect(_on_back_pressed)
	ApiService.request_completed.connect(_on_api_response)
	status_label.text = "" # Start empty

func _on_register_pressed() -> void:
	var email = email_input.text.strip_edges()
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email.is_empty() or username.is_empty() or password.is_empty():
		_set_status("Error: All fields required.", Color.RED)
		return
	
	_set_status("Connecting to system...", Color.YELLOW)
	register_button.disabled = true
	ApiService.register(email, username, password)

func _on_api_response(endpoint: String, success: bool, response_data: Dictionary) -> void:
	if endpoint != "/auth/register":
		return
		
	register_button.disabled = false
	
	if success:
		_set_status("Registration Successful!", Color.GREEN)
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree():
			_on_back_pressed()
	else:
		var err_msg = response_data.get("message", response_data.get("error", "Registration failed"))
		_set_status("Error: " + str(err_msg), Color.RED)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/welcome.tscn")

func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
