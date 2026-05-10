extends Node

func _ready():
	SignalBus.bug_slain.connect(_on_bug_slain)
	BaseApiService.request_finished.connect(_on_request_finished)

func _on_bug_slain():
	print("LOOT_MANAGER: Bug killed, firing logic recapture request...")
	BaseApiService.send_request("/world/loot", HTTPClient.METHOD_POST, {}, true)

func _on_request_finished(endpoint: String, success: bool, _data: Dictionary):
	if endpoint == "/world/loot" and success:
		if StoryService.should_play("first_kill"):
			DialogueManager.show_example_dialogue_balloon(
				load("res://dialogue/main.dialogue"), 
				"first_kill"
			)
			StoryService.mark_as_seen("first_kill")
