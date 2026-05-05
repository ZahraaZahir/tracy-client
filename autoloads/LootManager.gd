extends Node

func _ready():
	SignalBus.bug_slain.connect(_on_bug_slain)

func _on_bug_slain():
	print("LOOT MANAGER: Bug killed, firing logic recapture request...")
	BaseApiService.send_request("/world/loot", HTTPClient.METHOD_POST, {}, true)
