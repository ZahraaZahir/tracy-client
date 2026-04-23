extends CharacterBody2D

enum State { IDLE, ALERT, HURT, DYING }

const SPEED_FLEE = 100.0
const MAX_HEALTH = 3

var current_state = State.IDLE
var health = MAX_HEALTH
var target_player: CharacterBody2D = null
var hurt_timer: SceneTreeTimer = null

@onready var anim_tree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")

func _ready():
	anim_tree.active = true
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			_logic_idle()
		State.ALERT:
			_logic_alert(delta)
		State.HURT, State.DYING:
			velocity = Vector2.ZERO
	move_and_slide()

func _logic_idle():
	velocity = Vector2.ZERO
	anim_tree.set("parameters/IDLE/blend_position", Vector2.DOWN)

func _logic_alert(delta):
	if target_player == null:
		_transition_to_state(State.IDLE)
		return
	var dir_away = (global_position - target_player.global_position).normalized()
	velocity = velocity.move_toward(dir_away * SPEED_FLEE, 400.0 * delta)
	anim_tree.set("parameters/ALERT/blend_position", dir_away)

func take_damage():
	if current_state == State.HURT or current_state == State.DYING:
		return
	health -= 1
	print("BUG: Ouch! Health remaining: ", health)
	if health <= 0:
		_transition_to_state(State.DYING)
	else:
		_transition_to_state(State.HURT)

func _transition_to_state(new_state: State):
	current_state = new_state
	match new_state:
		State.IDLE:
			state_machine.travel("IDLE")
		State.ALERT:
			state_machine.travel("ALERT")
		State.HURT:
			state_machine.travel("HURT")
			var hurt_dir = Vector2.ZERO
			if target_player != null:
				hurt_dir = (global_position - target_player.global_position).normalized()
			else:
				hurt_dir = Vector2.DOWN
			anim_tree.set("parameters/HURT/blend_position", hurt_dir)
			_start_hurt_recovery()
		State.DYING:
			anim_tree.set("parameters/conditions/is_dead", true)
			state_machine.travel("DYING")
			_on_death()

func _start_hurt_recovery():
	if hurt_timer != null:
		hurt_timer.timeout.disconnect(_on_hurt_done)
	hurt_timer = get_tree().create_timer(0.4)
	hurt_timer.timeout.connect(_on_hurt_done)

func _on_hurt_done():
	hurt_timer = null
	if current_state == State.HURT:
		if target_player != null:
			_transition_to_state(State.ALERT)
		else:
			_transition_to_state(State.IDLE)

func _on_death():
	print("BUG DIED: Awaiting server loot...")
	$DetectionArea.body_entered.disconnect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.disconnect(_on_detection_area_body_exited)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("tracy"):
		target_player = body
		_transition_to_state(State.ALERT)
	else:
		print("DETECTION: something entered but not tracy, it was: ", body.name)

func _on_detection_area_body_exited(body):
	if body == target_player:
		target_player = null
		_transition_to_state(State.IDLE)
