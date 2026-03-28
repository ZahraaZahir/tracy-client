extends "res://entities/base/interactable_entity.gd"

@export var target_offset: Vector2 = Vector2(150, 0) 
@onready var target_pos: Vector2 = global_position + target_offset
var arrived: bool = false

func _process(delta):
	super._process(delta)
	
	if is_fixed:
		if not arrived:
			_move_to_workplace(delta)
		else:
			if anim.current_animation != "work_active":
				anim.play("work_active")

func _move_to_workplace(_delta):
	if anim.current_animation != "idle_normal":
		anim.play("idle_normal")
	
	var dir = (target_pos - global_position).normalized()
	velocity = dir * 60.0
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 5.0:
		arrived = true
		velocity = Vector2.ZERO
