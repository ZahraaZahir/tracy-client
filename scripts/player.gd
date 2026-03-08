extends CharacterBody2D

const MAX_SPEED = 150.0
const ACCELERATION = 500.0
const FRICTION = 500.0

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", input_vector)
		animation_tree.set("parameters/Walk/blend_position", input_vector)
		animation_tree.set("parameters/Sword/blend_position", input_vector)

		animation_state.travel("Walk")
		
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animation_state.travel("Idle")
		
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if Input.is_action_just_pressed("attack"):
		animation_state.travel("Sword")
		
	if $Camera2D:
		$Camera2D.global_position = $Camera2D.global_position.round()

	move_and_slide()
