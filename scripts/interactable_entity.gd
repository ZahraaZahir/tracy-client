extends CharacterBody2D

@export var entity_id: String = "npc_01"

@export var is_fixed: bool = false:
	set(value):
		is_fixed = value
		if is_fixed and prompt:
			prompt.visible = false
		_apply_visual_state()

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = %InspectPrompt  
@onready var anchor: Marker2D = $PromptAnchor

var player_is_near: bool = false

func _ready() -> void:
	$InteractionZone.body_entered.connect(_on_player_entered)
	$InteractionZone.body_exited.connect(_on_player_exited)
	
	_apply_visual_state()
	prompt.visible = false

func _process(_delta: float) -> void:
	if player_is_near and not is_fixed:
		if Input.is_action_just_pressed("interact"):
			_open_inspector()

	if prompt.visible:
		_update_prompt_position()

func _update_prompt_position() -> void:
	var screen_origin = get_global_transform_with_canvas().origin
	
	var cam_zoom = get_viewport().get_camera_2d().zoom.x
	
	prompt.global_position = screen_origin + (anchor.position * cam_zoom)

func _open_inspector() -> void:
	print("CLIENT: Inspecting ", entity_id)
	EntityService.fetch_entity(entity_id) 
	print("SYSTEM: Request sent for ", entity_id)

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
		player_is_near = true
		if not is_fixed: 
			prompt.visible = true

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = false
		prompt.visible = false
