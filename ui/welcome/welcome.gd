extends Control

func _on_login_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().change_scene_to_file("res://ui/auth/login/login.tscn")

func _on_register_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().change_scene_to_file("res://ui/auth/register/register.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
