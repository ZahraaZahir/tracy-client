extends Node

signal world_loaded(data: Dictionary)
signal progress_updated(current: int, total: int)

var patched_bugs_count: int = 0
var total_bugs_count: int = 0
var is_persistence_ready: bool = false

signal inventory_updated(inventory: Array)
var current_inventory: Array = []

func _ready() -> void:
	BaseApiService.request_finished.connect(_on_base_request_finished)

func save_state(pos: Vector2, map_name: String) -> void:
	if not is_persistence_ready: 
		return
	
	var payload = {
		"posX": pos.x,
		"posY": pos.y,
		"mapName": map_name
	}
	BaseApiService.send_request("/world/save", HTTPClient.METHOD_POST, payload, true)

func load_state() -> void:
	is_persistence_ready = false
	BaseApiService.send_request("/world/load", HTTPClient.METHOD_GET, {}, true)

func _on_base_request_finished(endpoint: String, success: bool, data: Dictionary) -> void:
	if endpoint == "/world/load" and success:
		var actual_data = data.get("data", data)
		current_inventory = actual_data.get("inventory", [])
		inventory_updated.emit(current_inventory)
		world_loaded.emit(actual_data)
		
	elif endpoint == "/world/loot" and success:
		add_loot(data)
		print("HUD DEBUG: Loot received and added to state.")
		
	elif endpoint == "/world/save" and success:
		print("SYSTEM: World synced.")
		
func sync_progress(fixed_list: Array, total: int) -> void:
	patched_bugs_count = fixed_list.size()
	total_bugs_count = total
	progress_updated.emit(patched_bugs_count, total_bugs_count)
	
func add_loot(block_data: Dictionary) -> void:
	current_inventory.append(block_data)
	inventory_updated.emit(current_inventory)
