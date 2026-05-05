extends CanvasLayer

@onready var item_label = find_child("ItemLabel")

func _ready():
	process_mode = PROCESS_MODE_ALWAYS 
	find_child("collect_button").pressed.connect(_on_collect_button_pressed)

func display_loot(loot_data: Dictionary):
	var val = str(loot_data.get("value", "???"))
	var type = str(loot_data.get("type", "logic"))
	
	item_label.text = "[ %s ]\n(%s block)" % [val.to_upper(), type]
	get_tree().paused = true

func _on_collect_button_pressed():
	get_tree().paused = false
	queue_free() 
