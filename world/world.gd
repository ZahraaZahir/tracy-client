extends Node2D

@onready var player = $Player
const MAP_ID = "main_world"
const BUG_SCENE = preload("res://bug/Bug.tscn")

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
	
	if data.has("fixedGlitches") and data.has("totalEntities"):
		ProgressionService.sync(data.fixedGlitches, data.totalEntities)
		
		await get_tree().process_frame
		
		for npc in get_tree().get_nodes_in_group("interactable"):
			if npc.entity_id in data.fixedGlitches:
				npc.load_silent_state()
		var unfixed_count = data.totalEntities - data.fixedGlitches.size()
		_spawn_bugs(unfixed_count)
	
	WorldService.is_persistence_ready = true

func _spawn_bugs(count: int) -> void:
	if count <= 0:
		print("WORLD: No glitches to spawn. All systems stable.")
		return
	
	print("WORLD: Preparing to spawn ", count, " bugs...")
	var player_pos = player.global_position
	
	for i in range(count):
		var bug = BUG_SCENE.instantiate()
		var angle = randf() * TAU
		var distance = randf_range(150, 400) 
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		add_child(bug)
		bug.global_position = spawn_pos
		var s = randf_range(0.8, 1.2)
		bug.scale = Vector2(s, s)
		
		print("WORLD: Bug ", i + 1, " spawned at ", spawn_pos)
	

func _on_entity_fixed(_id: String) -> void:
	WorldService.save_state(player.global_position, MAP_ID)
	
