extends CharacterBody2D

# --- 1. CONFIGURATION ---
const MAX_SPEED = 150.0
const ACCELERATION = 500.0
const FRICTION = 500.0

# --- 2. NODE REFERENCES ---
@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var attack_area = $AttackArea # Area2D positioned in front of Tracy

func _ready():
	# Ensure Tracy is recognized by the bugs
	add_to_group("tracy")

func _physics_process(delta):
	# 1. UI LOCK: If terminal is open, Tracy stops.
	if ProgressionService.is_ui_active:
		_apply_friction(delta)
		animation_state.travel("Idle")
		move_and_slide()
		return

	# 2. MOVEMENT LOGIC
	_handle_movement(delta)
	
	move_and_slide()

func _input(event):
	# 3. ATTACK LOGIC: Only trigger if UI is not active
	if ProgressionService.is_ui_active: return
	
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_perform_attack()

# --- 4. HELPER FUNCTIONS (The "Gears") ---

func _handle_movement(delta):
	# don't interrupt sword animation with walk/idle
	if animation_state.get_current_node() == "Sword":
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		input_vector = input_vector.normalized()
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
	animation_state.travel("Sword")
	var targets = attack_area.get_overlapping_bodies()
	for body in targets:
		if body.has_method("take_damage"):
			body.take_damage()

func _orient_attack_area(direction: Vector2):
	# This ensures the 'hitzone' follows her sword
	# If your AttackArea is a child of Tracy, we shift its position
	attack_area.position = direction * 20 # Adjust the '20' to fit your sprite
