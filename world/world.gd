extends Node2D

@onready var player = $Player
@onready var env_layer = $Environment
const MAP_ID = "main_world"
const BUG_SCENE = preload("res://bug/Bug.tscn")

func _ready() -> void:
	if BaseApiService.auth_token.is_empty():
		print("WORLD: No token found. Redirecting to login...")
		get_tree().change_scene_to_file("res://ui/welcome/welcome.tscn")
		return

	WorldService.world_loaded.connect(_on_world_loaded)
	WorldService.load_state()
	
	if not EntityService.entity_fixed_globally.is_connected(_on_entity_fixed):
		EntityService.entity_fixed_globally.connect(_on_entity_fixed)

func _on_world_loaded(data: Dictionary) -> void:
	if not player: return
	
	if data.has("posX") and data.has("posY"):
		var target_pos = Vector2(data.posX, data.posY)
		if target_pos.length() > 0.1:
			player.global_position = target_pos
	
	if data.has("fixedGlitches") and data.has("totalEntities"):
		ProgressionService.sync(data.fixedGlitches, data.totalEntities)
		
		await get_tree().process_frame 
		
		var fixed_ids = data.get("fixedGlitches", [])
		var inventory_list = data.get("inventory", [])
		var inventory_count = inventory_list.size()
		
		for npc in get_tree().get_nodes_in_group("interactable"):
			if npc.entity_id in fixed_ids:
				npc.load_silent_state()
		
		var total_npcs = data.totalEntities
		var fixed_count = fixed_ids.size()
		var unfixed_count = total_npcs - fixed_count
		var spawn_count = unfixed_count - inventory_count
		
		print("DEBUG SPAWN: Total:", total_npcs, " Fixed:", fixed_count, " Unfixed:", unfixed_count, " In-Pocket:", inventory_count)
		
		_spawn_bugs(max(0, spawn_count))
	
	WorldService.is_persistence_ready = true
	await get_tree().process_frame 
	
	if StoryService.should_play("game_intro"):
		_play_intro_sequence()

func _play_intro_sequence():
	var dialogue_resource = load("res://dialogue/main.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "game_intro")
	StoryService.mark_as_seen("game_intro")

func _spawn_bugs(count: int) -> void:
	if count <= 0:
		print("WORLD: Logic blocks accounted for. No bugs spawned.")
		return
	
	var player_pos = player.global_position
	var space_state = get_world_2d().direct_space_state
	var spawned_count = 0
	var attempts = 0
	var max_attempts = count * 20
	
	while spawned_count < count and attempts < max_attempts:
		attempts += 1
		
		var angle = randf() * TAU
		var distance = randf_range(200, 450) 
		var target_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		
		var query = PhysicsPointQueryParameters2D.new()
		query.position = target_pos
		query.collision_mask = 1
		var intersections = space_state.intersect_point(query)
		
		var map_pos = env_layer.local_to_map(env_layer.to_local(target_pos))
		var has_env_tile = env_layer.get_cell_source_id(map_pos) != -1
		
		if intersections.is_empty() and not has_env_tile:
			var bug = BUG_SCENE.instantiate()
			
			bug.z_index = 3           
			bug.y_sort_enabled = true
			
			add_child(bug)
			bug.global_position = target_pos
			
			var s = randf_range(0.9, 1.1)
			bug.scale = Vector2(s, s)
			spawned_count += 1

	if spawned_count < count:
		push_warning("WORLD: Limited walkable space. Only spawned %d/%d bugs." % [spawned_count, count])

func _on_entity_fixed(_id: String) -> void:
	WorldService.save_state(player.global_position, MAP_ID)
	
