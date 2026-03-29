extends CharacterBody2D

signal player_approached(entity)
signal player_left()

@export var entity_id: String = "npc_01"

@export var is_fixed: bool = false:
	set(value):
		is_fixed = value
		if is_fixed:
			player_left.emit()
		_apply_visual_state()

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var player_is_near: bool = false

func _ready() -> void:
	add_to_group("interactable")
	$InteractionZone.body_entered.connect(_on_player_entered)
	$InteractionZone.body_exited.connect(_on_player_exited)
	EntityService.entity_fixed_globally.connect(_on_entity_fixed_externally)
	
	_apply_visual_state()

func _process(_delta: float) -> void:
	if player_is_near and not is_fixed:
		if Input.is_action_just_pressed("interact"):
			_open_inspector()

func _open_inspector() -> void:
	EntityService.fetch_entity(entity_id)

func _apply_visual_state() -> void:
	if not is_inside_tree() or not sprite: return
	
	if sprite.material:
		sprite.material.set_shader_parameter("is_glitched", !is_fixed)

	if is_fixed:
		anim.play("idle_normal")
	else:
		anim.play("glitch_active")

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("DEBUG: Player entered zone of ", entity_id) # <--- Add this
		player_is_near = true
		if not is_fixed: 
			EntityService.request_prompt_show.emit(self)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = false
		player_left.emit() 

func _on_entity_fixed_externally(fixed_id: String) -> void:
	if fixed_id == entity_id:
		is_fixed = true
