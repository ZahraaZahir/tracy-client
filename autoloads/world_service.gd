extends Node

signal world_loaded(data: Dictionary)
signal progress_updated(current: int, total: int)
signal inventory_updated(inventory: Array)


var current_inventory: Array = [] 
var patched_bugs_count: int = 0
var total_bugs_count: int = 0
var is_persistence_ready: bool = false
var _pending_loot_queue: Array = []

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)
	SignalBus.collection_animation_done.connect(_on_animation_finished)


func add_loot(loot_data: Dictionary) -> void:
	_pending_loot_queue.append(loot_data)
	print("WORLD SERVICE: Server loot received. Holding in queue. Size: ", _pending_loot_queue.size())

func _on_animation_finished() -> void:
	if _pending_loot_queue.size() > 0:
		var confirmed_loot = _pending_loot_queue.pop_front()
		current_inventory.append(confirmed_loot)
		inventory_updated.emit(current_inventory)
		
		print("WORLD SERVICE: Animation handshake complete. Item added to Inventory.")
	else:
		print("WORLD SERVICE: Warning - Animation finished but queue was empty.")

# 3. THE CLEANUP (Logic Side)
func remove_blocks(used_blocks: Dictionary) -> void:
	var used_ids = []
	for val in used_blocks.values():
		if typeof(val) == TYPE_DICTIONARY and val.has("blockId"):
			used_ids.append(val.blockId)
	
	current_inventory = current_inventory.filter(func(item):
		return not used_ids.has(item.get("blockId"))
	)
	inventory_updated.emit(current_inventory)


func save_state(pos: Vector2, map_name: String) -> void:
	if not is_persistence_ready: return
	var payload = { "posX": pos.x, "posY": pos.y, "mapName": map_name }
	BaseApiService.send_request("/world/save", HTTPClient.METHOD_POST, payload, true)

func load_state() -> void:
	is_persistence_ready = false
	BaseApiService.send_request("/world/load", HTTPClient.METHOD_GET, {}, true)


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
		
	elif endpoint == "/world/save":
		print("SYSTEM: Database sync successful.")

func sync_progress(fixed_list: Array, total: int) -> void:
	patched_bugs_count = fixed_list.size()
	total_bugs_count = total
	progress_updated.emit(patched_bugs_count, total_bugs_count)
