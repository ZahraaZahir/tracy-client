extends Control

@onready var login_button: Button = $CenterContainer/VBoxContainer/LoginButton
@onready var register_button: Button = $CenterContainer/VBoxContainer/RegisterButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)

func _on_login_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/login_scene.tscn")

func _on_register_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/register_scene.tscn")
