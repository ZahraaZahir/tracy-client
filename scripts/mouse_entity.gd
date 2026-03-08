extends "res://scripts/interactable_entity.gd"

@onready var flowers = $FlowerPatch

func _apply_visual_state() -> void:
	super._apply_visual_state()
	
	if is_fixed:
		_perform_bloom()

func _perform_bloom():
	flowers.visible = true
	for flower in flowers.get_children():
		flower.scale = Vector2.ZERO
		# Create a Tween for each flower
		var tween = create_tween()
		# TRANS_ELASTIC + EASE_OUT = The perfect 'pop'
		tween.tween_property(flower, "scale", Vector2.ONE, 0.5)\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_OUT)
