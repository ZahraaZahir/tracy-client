extends CharacterBody2D

const MAX_SPEED = 150.0
const ACCELERATION = 500.0
const FRICTION = 500.0

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var attack_area = $AttackArea


var is_attacking: bool = false

func _ready():
	add_to_group("tracy")

func _physics_process(delta):
	if ProgressionService.is_ui_active:
		_apply_friction(delta)
		animation_state.travel("Idle")
		move_and_slide()
		return

	_handle_movement(delta)
	move_and_slide()

func _input(event):
	if ProgressionService.is_ui_active: return
	if (event.is_action_pressed("attack")) and not is_attacking:
		_perform_attack()

func _handle_movement(delta):
	if is_attacking:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		return
		
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", input_vector)
		animation_tree.set("parameters/Walk/blend_position", input_vector)
		animation_tree.set("parameters/Sword/blend_position", input_vector)
		_orient_attack_area(input_vector)
		animation_state.travel("Walk")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animation_state.travel("Idle")
		_apply_friction(delta)

func _apply_friction(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _perform_attack():
	is_attacking = true
	animation_state.travel("Sword")
	
	await get_tree().physics_frame
	
	var targets = attack_area.get_overlapping_bodies()
	for body in targets:
		if body.has_method("take_damage"):
			body.take_damage()
	
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func _orient_attack_area(direction: Vector2):
	attack_area.position = direction * 20
