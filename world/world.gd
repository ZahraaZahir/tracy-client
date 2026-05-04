extends Node2D

@onready var player = $Player
const MAP_ID = "main_world"
const BUG_SCENE = preload("res://bug/Bug.tscn")

func _ready() -> void:
	if player and not player.is_in_group("tracy"):
		player.add_to_group("tracy")
		
	WorldService.world_loaded.connect(_on_world_loaded)
	WorldService.load_state()
	
	if not EntityService.entity_fixed_globally.is_connected(_on_entity_fixed):
		EntityService.entity_fixed_globally.connect(_on_entity_fixed)

func _on_world_loaded(data: Dictionary) -> void:
	if not player: return
	
	# 1. Sync Position
	if data.has("posX") and data.has("posY"):
		var target_pos = Vector2(data.posX, data.posY)
		if target_pos.length() > 0.1:
			player.global_position = target_pos
	
	# 2. Sync Progression & NPCs
	if data.has("fixedGlitches") and data.has("totalEntities"):
		ProgressionService.sync(data.fixedGlitches, data.totalEntities)
		
		await get_tree().process_frame 
		
		var total_unfixed_npcs = 0
		var fixed_ids = data.get("fixedGlitches", [])
		
		for npc in get_tree().get_nodes_in_group("interactable"):
			if npc.entity_id in fixed_ids:
				npc.load_silent_state()
			else:
				total_unfixed_npcs += 1
		
		var inventory_count = WorldService.current_inventory.size()
		var spawn_count = total_unfixed_npcs - inventory_count
		
		print("WORLD: NPCs left: ", total_unfixed_npcs, " | Inventory: ", inventory_count)
		_spawn_bugs(max(0, spawn_count))
	
	WorldService.is_persistence_ready = true

func _spawn_bugs(count: int) -> void:
	if count <= 0:
		print("WORLD: No bugs needed.")
		return
	
	var player_pos = player.global_position
	for i in range(count):
		var bug = BUG_SCENE.instantiate()
		var angle = randf() * TAU
		var distance = randf_range(200, 450) 
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		add_child(bug)
		bug.global_position = spawn_pos
		var s = randf_range(0.9, 1.1)
		bug.scale = Vector2(s, s)

func _on_entity_fixed(_id: String) -> void:
	WorldService.save_state(player.global_position, MAP_ID)
