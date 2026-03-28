extends Control

@onready var email_input: LineEdit = $CenterContainer/CredentialsContainer/EmailContainer/EmailInput
@onready var username_input: LineEdit = $CenterContainer/CredentialsContainer/UsernameContainer/UsernameInput
@onready var password_input: LineEdit = $CenterContainer/CredentialsContainer/PasswordContainer/PasswordInput
@onready var back_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/BackButton
@onready var register_button: Button = $CenterContainer/CredentialsContainer/ButtonsContainer/RegisterButton
@onready var status_label: Label = $CenterContainer/CredentialsContainer/StatusLabel
@onready var confirm_password_input: LineEdit = $CenterContainer/CredentialsContainer/ConfirmPasswordContainer/ConfirmPasswordInput

const COLOR_ERROR = Color("ff6761ff")
const COLOR_SUCCESS = Color("65ffb7ff")
const COLOR_PENDING = Color("#ffef4b")

func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	AuthService.auth_finished.connect(_on_auth_result)
	status_label.text = ""

func _on_register_pressed() -> void:
	var email = email_input.text.strip_edges()
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var confirm = confirm_password_input.text.strip_edges()
	
	if email.is_empty() or username.is_empty() or password.is_empty() or confirm.is_empty():
		_set_status("Error: All fields required.", COLOR_ERROR)
		return
	
	if password != confirm:
		_set_status("Error: Passwords do not match.", COLOR_ERROR)
		return
		
	_set_status("Connecting to system...", COLOR_PENDING)
	register_button.disabled = true
	AuthService.register(email, username, password)
	
func _on_auth_result(success: bool, message: String) -> void:
	register_button.disabled = false
	
	if success:
		_set_status("Registration Successful!", COLOR_SUCCESS)
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree():
			_on_back_pressed()
	else:
		_set_status("Error: " + message, COLOR_ERROR)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/welcome/welcome.tscn")

func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_label.visible = true
