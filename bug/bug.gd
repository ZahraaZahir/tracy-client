extends CharacterBody2D

enum State { IDLE, ALERT, HURT, DYING }

const SPEED_FLEE = 60.0 
const MAX_HEALTH = 3

var current_state = State.IDLE
var health = MAX_HEALTH
var target_player: CharacterBody2D = null
var is_dead: bool = false 

@onready var anim_tree = $AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")

@onready var hit_player: AudioStreamPlayer2D = get_node_or_null("HitPlayer") 

func _ready():
	anim_tree.active = true
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	if is_dead: return 
	
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
	if is_dead or current_state == State.HURT:
		return
		
	health -= 1
	print("BUG: Ouch! Health remaining: ", health)
	
	if hit_player and health > 0:
		hit_player.play()
	
	if health <= 0:
		_enter_dying_state()
	else:
		_transition_to_state(State.HURT)

func _enter_dying_state():
	is_dead = true
	current_state = State.DYING
	
	if SfxManager:
		SfxManager.play_bug_death(global_position)
		
	$DetectionArea.set_deferred("monitoring", false)
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	elif has_node("CollisionShape2D2"):
		$CollisionShape2D2.set_deferred("disabled", true)
	
	anim_tree.set("parameters/conditions/is_dead", true)
	state_machine.travel("DYING")
	SignalBus.bug_slain.emit()
	await get_tree().create_timer(3).timeout
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0.0, 0.1) 
		tween.tween_property(self, "modulate:a", 1.0, 0.1) 
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.4)
	tween.set_parallel(false)
	SignalBus.collection_animation_done.emit()
	tween.tween_callback(queue_free)

func _transition_to_state(new_state: State):
	if is_dead: return
	current_state = new_state
	match new_state:
		State.IDLE: state_machine.travel("IDLE")
		State.ALERT: state_machine.travel("ALERT")
		State.HURT:
			state_machine.travel("HURT")
			_start_hurt_recovery()

func _start_hurt_recovery():
	await get_tree().create_timer(0.4).timeout
	if not is_dead:
		_transition_to_state(State.ALERT if target_player else State.IDLE)

func _on_detection_area_body_entered(body):
	if is_dead: return
	if body.is_in_group("tracy"):
		target_player = body
		_transition_to_state(State.ALERT)

func _on_detection_area_body_exited(body):
	if body == target_player:
		target_player = null
		if not is_dead:
			_transition_to_state(State.IDLE)
