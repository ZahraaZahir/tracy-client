extends CharacterBody2D

@export var entity_id: String = "npc_cow_01"

@export var is_fixed: bool = false:
	set(value):
		is_fixed = value
		_update_visual_state()

@onready var anim: AnimationPlayer = $AnimationPlayer

# Internal state tracking
var player_is_near: bool = false

func _ready() -> void:
	$InteractionZone.body_entered.connect(_on_player_enter)
	$InteractionZone.body_exited.connect(_on_player_exit)
	_update_visual_state()

func _process(_delta: float) -> void:
	if player_is_near and not is_fixed:
		if Input.is_action_just_pressed("interact"):
			_simulate_fix()

func _simulate_fix() -> void:
	print("Fixed entity ", entity_id)
	is_fixed = true

func _update_visual_state() -> void:
	if not is_inside_tree(): return
	if is_fixed:
		anim.play("idle_normal")
	else:
		anim.play("glitch_active")

func _on_player_enter(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = true
		print("Prompt: Press E to Inspect Cow")

func _on_player_exit(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = false
