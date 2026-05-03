extends CanvasLayer

@onready var progress_label = $MainMargin/TopLeft/ProgressWidget/Padding/ProgressHBox/Label
@onready var progress_widget = $MainMargin/TopLeft/ProgressWidget
@onready var dev_id_label = $MainMargin/TopLeft/IDWidget/Padding/IDHBox/Label
@onready var logout_button = $MainMargin/TopRight/Padding/LoginButton

const INVENTORY_SLOT_SCENE = preload("res://ui/inventory/inventory_slot.tscn")
@onready var hud_inventory_list = %HudInventoryList
@onready var inventory_ui = $MainMargin/InventoryContainer

func _ready() -> void:
	ProgressionService.ui_state_changed.connect(_on_ui_state_changed)
	ProgressionService.progress_updated.connect(_on_progress_updated)
	
	WorldService.inventory_updated.connect(_on_inventory_updated)
	
	logout_button.pressed.connect(_on_logout_pressed)
	_setup_developer_id()
	_on_inventory_updated(WorldService.current_inventory)
	
	progress_label.text = "Fixed: 0 / 0"
	
	inventory_ui.visible = !ProgressionService.is_ui_active

func _setup_developer_id() -> void:
	var dev_name = BaseApiService.developer_id
	if dev_name.is_empty(): dev_name = "GUEST"

	dev_id_label.text = "Developer ID: %s " % dev_name.to_upper()

func _on_progress_updated(current: int, total: int) -> void:
	progress_label.text = "Fixed: %d / %d" % [current, total]
	var tween = create_tween()
	progress_widget.pivot_offset = progress_widget.size / 2 
	
	tween.tween_property(progress_widget, "scale", Vector2(1.1, 1.1), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(progress_widget, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
func _on_logout_pressed() -> void:
	BaseApiService.logout()
	
func _on_inventory_updated(inventory_data: Array) -> void:
	print("HUD DEBUG: Updating list with ", inventory_data.size(), " items.")
	for child in hud_inventory_list.get_children():
		child.queue_free()
		
	for block_data in inventory_data:
		var slot = INVENTORY_SLOT_SCENE.instantiate()
		slot.is_draggable = false
		hud_inventory_list.add_child(slot)
		slot.setup_block(block_data, null)
		
func _on_ui_state_changed(is_active: bool) -> void:
	inventory_ui.visible = !is_active
