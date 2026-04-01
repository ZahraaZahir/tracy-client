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
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/welcome/welcome.tscn"))
	
	AuthService.auth_finished.connect(_on_auth_result)
	status_label.text = ""
	identifier_input.grab_focus()

func _on_login_pressed() -> void:
	var id = identifier_input.text.strip_edges()
	var pw = password_input.text.strip_edges()
	
	if id.is_empty() or pw.is_empty():
		_set_status("Error: Enter credentials.", COLOR_ERROR)
		return
	
	_set_status("Authenticating...", COLOR_PENDING)
	login_button.disabled = true
	AuthService.login(id, pw)

func _on_auth_result(success: bool, message: String) -> void:
	login_button.disabled = false
	
	if success:
		_set_status("Welcome, Developer.", COLOR_SUCCESS)
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("/Users/sarabimar/Documents/Uni/9th Semester /Final Year Project/tracy-client/world/world.tscn")
	else:
		_set_status("Error: " + message, COLOR_ERROR)

func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_label.visible = true
