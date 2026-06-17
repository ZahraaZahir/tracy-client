extends CharacterBody2D

@export var entity_id: String = "npc_01"

@export var is_fixed: bool = false:
	set(value):
		is_fixed = value
		if is_node_ready():
			_apply_visual_state()
			if is_fixed:
				EntityService.request_prompt_hide.emit()

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var buzz_player: AudioStreamPlayer2D = get_node_or_null("BuzzPlayer") 

var player_is_near: bool = false

func _ready() -> void:
	add_to_group("interactable")
	$InteractionZone.body_entered.connect(_on_player_entered)
	$InteractionZone.body_exited.connect(_on_player_exited)
	EntityService.entity_fixed_globally.connect(_on_live_solve)
	_apply_visual_state()
	SignalBus.register_on_map.emit(self, "npc")

func _process(_delta: float) -> void:
	if player_is_near and not is_fixed:
		if Input.is_action_just_pressed("interact"):
			EntityService.fetch_entity(entity_id)

func _apply_visual_state() -> void:
	if not is_inside_tree() or not sprite or not anim: return
	
	if sprite.material:
		sprite.material.set_shader_parameter("is_glitched", !is_fixed)

	if buzz_player:
		if is_fixed:
			buzz_player.stop()
		elif not buzz_player.playing:
			buzz_player.play()
			
	if is_fixed:
		anim.play("idle_normal")
	else:
		anim.play("glitch_active")

func load_silent_state() -> void:
	is_fixed = true
	_silent_setup()

func _on_live_solve(fixed_id: String) -> void:
	if fixed_id == entity_id:
		is_fixed = true
		_play_celebration()

func _silent_setup() -> void: pass
func _play_celebration() -> void: pass

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = true
		if not is_fixed: 
			EntityService.request_prompt_show.emit(self)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_near = false
		EntityService.request_prompt_hide.emit()
