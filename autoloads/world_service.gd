extends Node

signal world_loaded(data: Dictionary)
signal progress_updated(current: int, total: int)
signal inventory_updated(inventory: Array)

var current_inventory: Array = [] 
var patched_bugs_count: int = 0
var total_bugs_count: int = 0
var is_persistence_ready: bool = false

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func save_state(pos: Vector2, map_name: String) -> void:
	if not is_persistence_ready: return
	
	var payload = {
		"posX": pos.x,
		"posY": pos.y,
		"mapName": map_name
	}
	BaseApiService.send_request("/world/save", HTTPClient.METHOD_POST, payload, true)

func load_state() -> void:
	is_persistence_ready = false
	BaseApiService.send_request("/world/load", HTTPClient.METHOD_GET, {}, true)

func add_loot(loot_data: Dictionary) -> void:
	current_inventory.append(loot_data)
	inventory_updated.emit(current_inventory)
	print("WORLD SERVICE: Item added. Total: ", current_inventory.size())

func remove_blocks(used_blocks: Dictionary) -> void:
	var used_ids = []
	for val in used_blocks.values():
		if typeof(val) == TYPE_DICTIONARY and val.has("blockId"):
			used_ids.append(val.blockId)
	
	current_inventory = current_inventory.filter(func(item):
		return not used_ids.has(item.get("blockId"))
	)
	inventory_updated.emit(current_inventory)

func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if not success: return

	if endpoint == "/world/load":
		var actual_data = data.get("data", data)
		current_inventory = actual_data.get("inventory", [])
		inventory_updated.emit(current_inventory)
		world_loaded.emit(actual_data)
		
	elif endpoint == "/world/loot":
		add_loot(data)
		var player = get_tree().get_first_node_in_group("tracy")
		if player:
			save_state(player.global_position, "main_world")
			print("SYSTEM: Loot secured and world saved.")
		
	elif endpoint == "/world/save":
		print("SYSTEM: Cloud sync complete.")
		
func sync_progress(fixed_list: Array, total: int) -> void:
	patched_bugs_count = fixed_list.size()
	total_bugs_count = total
	progress_updated.emit(patched_bugs_count, total_bugs_count)
