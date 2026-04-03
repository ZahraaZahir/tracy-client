extends "res://entities/base/interactable_entity.gd"

func _play_celebration() -> void:
	var tween = create_tween().bind_node(self)
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
