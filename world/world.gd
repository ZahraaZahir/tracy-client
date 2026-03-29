extends Node2D

@onready var player = $Player

func _ready() -> void:
	WorldService.world_loaded.connect(_on_world_loaded)
	WorldService.load_state()
	
	if not EntityService.entity_fixed_globally.is_connected(_on_entity_fixed):
		EntityService.entity_fixed_globally.connect(_on_entity_fixed)

func _on_world_loaded(data: Dictionary) -> void:
	if not player: return
	
	if data.has("posX") and data.has("posY"):
		var target_pos = Vector2(data.posX, data.posY)
		if target_pos.length() > 0.1:
			player.set_deferred("global_position", target_pos)
			print("SYSTEM: Player restored to: ", target_pos)
	
	if data.has("fixedGlitches"):
		var fixed_list = data.fixedGlitches
		await get_tree().process_frame 
		for npc in get_tree().get_nodes_in_group("interactable"):
			if npc.entity_id in fixed_list:
				npc.is_fixed = true
				
	WorldService.is_persistence_ready = true

func _on_entity_fixed(id: String) -> void:
	print("SYSTEM: Success detected on ", id, ". Committing player position...")
	# Force the save to happen right where Tracy is standing
	WorldService.save_state(player.global_position, get_tree().current_scene.name)
