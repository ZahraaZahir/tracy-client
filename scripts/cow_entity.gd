extends "res://scripts/interactable_entity.gd"

var is_falling: bool = false

func _apply_visual_state() -> void:
	super._apply_visual_state()
	
	if is_fixed:
		_trigger_fall_effect()

func _trigger_fall_effect():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1) # Squash
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1) # Stretch back
	print("COW: *Moo* (Physics restored)")
