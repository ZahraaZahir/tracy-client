extends Node

func _ready():
	SignalBus.bug_slain.connect(_on_bug_slain)

func _on_bug_slain():
	print("LOOT MANAGER: Bug killed, requesting loot...")
	BaseApiService.send_request("/world/loot", HTTPClient.METHOD_POST, {}, true)
	BaseApiService.request_finished.connect(_on_loot_received, CONNECT_ONE_SHOT)

func _on_loot_received(endpoint: String, success: bool, data: Dictionary):
	if endpoint == "/world/loot" and success:
		WorldService.add_loot(data)

		var player = get_tree().get_first_node_in_group("tracy")
		if player:
			WorldService.save_state(player.global_position, "main_world")
			print("LOOT MANAGER: Saved game after securing loot.")
