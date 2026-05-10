extends Node
var seen_dialogues: Array = []

func _ready() -> void:
	WorldService.world_loaded.connect(_on_world_sync)

func _on_world_sync(data: Dictionary) -> void:
	if data.has("seenDialogues"):
		seen_dialogues = data["seenDialogues"]
		print("STORY: Synchronized flags from server: ", seen_dialogues)

func should_play(flag: String) -> bool:
	return not seen_dialogues.has(flag)

func mark_as_seen(flag: String) -> void:
	if not seen_dialogues.has(flag):
		seen_dialogues.append(flag)
		var player = get_tree().get_first_node_in_group("tracy")
		if player:
			WorldService.save_state(player.global_position, "main_world")
