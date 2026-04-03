extends "res://entities/base/interactable_entity.gd"

@onready var flowers = $FlowerPatch

func _ready() -> void:
	super._ready()
	if not is_fixed:
		flowers.hide()
		flowers.visible = false

func _silent_setup() -> void:
	if flowers:
		flowers.show()
		flowers.visible = true
		for flower in flowers.get_children():
			flower.scale = Vector2.ONE

func _play_celebration() -> void:
	if flowers:
		flowers.show()
		flowers.visible = true
		for flower in flowers.get_children():
			flower.scale = Vector2.ZERO
			var tween = create_tween().bind_node(self)
			tween.tween_property(flower, "scale", Vector2.ONE, 0.5)\
				.set_trans(Tween.TRANS_ELASTIC)\
				.set_ease(Tween.EASE_OUT)
