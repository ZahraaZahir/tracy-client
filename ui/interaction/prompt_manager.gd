extends Label

var target_npc: Node2D = null

func _ready() -> void:
	hide()
	EntityService.request_prompt_show.connect(_on_show_requested)
	EntityService.request_prompt_hide.connect(_on_hide_requested)
	print("PROMPT SYSTEM: Initialized and listening...")

func _process(_delta: float) -> void:
	if target_npc and is_visible():
		var screen_pos = target_npc.get_global_transform_with_canvas().origin
		position = screen_pos + Vector2(-size.x / 2, -80)

func _on_show_requested(node: Node2D) -> void:
	print("PROMPT SYSTEM: Showing for ", node.entity_id)
	target_npc = node
	text = "[I] Inspect"
	show()

func _on_hide_requested() -> void:
	print("PROMPT SYSTEM: Hiding")
	target_npc = null
	hide()
