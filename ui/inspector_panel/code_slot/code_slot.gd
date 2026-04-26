extends Control

signal block_dropped(id: String, block_data: Dictionary)

@onready var drop_zone: DropZone = $Area2D/DropZone
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""
var is_locked: bool = false
var pulse_tween: Tween
var base_color: Color = Color(1, 1, 1)

var _held_inventory_item = null
var _held_area: Area2D = null

func _ready():
	add_to_group("code_slots")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	drop_zone.occupant_changed.connect(_on_occupant_changed)

func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)

func _on_occupant_changed(_zone, _spot, _old, new_occupant):
	if new_occupant == null: return
	var inventory_item = new_occupant.get_meta("slot_root", null)
	if inventory_item == null: return

	# Capture the new item
	_held_inventory_item = inventory_item
	_held_area = new_occupant
	
	# Hide visually - the Label in inspector_panel handles the "text" display
	_held_inventory_item.visible = false
	_held_area.visible = false

	block_dropped.emit(slot_id, inventory_item.logic_block)

func consume_held_item() -> void:
	if is_instance_valid(_held_inventory_item):
		_held_inventory_item.queue_free()
	if is_instance_valid(_held_area):
		_held_area.queue_free()
	_held_inventory_item = null
	_held_area = null

func restore_held_item() -> void:
	if is_instance_valid(_held_inventory_item) and is_instance_valid(_held_area):
		# 1. Force visual visibility
		_held_inventory_item.visible = true
		_held_area.visible = true
		_held_area.z_index = 0
		
		# 2. Reset plugin internal state to IDLE
		var draggable = _held_area.get_meta("draggable", null)
		if draggable:
			draggable.state = 0 # DRAGGABLE_STATE.IDLE
		
		# 3. Force Reparent and Hard-Reset position
		# false = do not keep global transform (snaps to local 0,0 of parent)
		_held_area.reparent(_held_inventory_item, false)
		_held_area.position = Vector2(60, 40) # Match the exact center of inventory_slot.tscn
		
		# 4. Clear plugin's internal tracking
		DropUtils.clear_occupant_reference(drop_zone, _held_area)
		
	_held_inventory_item = null
	_held_area = null

func set_slot_state(new_state: String, new_val: String):
	current_state = new_state
	label.text = new_val
	is_locked = (current_state == "fixed")
	if pulse_tween: pulse_tween.kill()
	modulate.a = 1.0
	add_theme_constant_override("outline_size", 2)

	match current_state:
		"bug":
			base_color = Color("#ff5555")
			_start_glitch_pulse()
		"draft":
			base_color = Color("#c68b12")
		"fixed":
			base_color = Color("#009868")
			add_theme_constant_override("outline_size", 0)
	_apply_colors(base_color)
	_resync_hitbox()

func _resync_hitbox():
	await get_tree().process_frame
	var new_size = label.get_combined_minimum_size()
	new_size.x += 20
	custom_minimum_size.x = new_size.x
	
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(new_size.x, 48)
		collision_shape.position = Vector2(new_size.x / 2, 24)

func _apply_colors(color: Color):
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", color)

func _on_mouse_entered():
	if is_locked: return
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	
	# TRIGGER REPLACE:
	# If we have an item and the user is carrying a NEW item, kick the old one back.
	if current_state == "draft":
		# Check if anything is currently being dragged in the DragLayer
		var drag_layer = get_tree().root.find_child("DragLayer", true, false)
		if drag_layer and drag_layer.get_child_count() > 0:
			restore_held_item()
			block_dropped.emit(slot_id, {})

func _on_mouse_exited():
	if not is_locked: label.add_theme_color_override("font_outline_color", base_color)

func _start_glitch_pulse():
	pulse_tween = create_tween().set_loops().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.tween_property(self, "modulate:a", 0.5, 0.3)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _gui_input(event: InputEvent) -> void:
	if is_locked: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_state == "draft":
			restore_held_item()
			block_dropped.emit(slot_id, {})
			accept_event()

func flash_incomplete() -> void:
	if pulse_tween: pulse_tween.kill()
	modulate.a = 1.0
	pulse_tween = create_tween().set_loops(5).bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.tween_property(self, "modulate:a", 0.2, 0.1)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	pulse_tween.finished.connect(func(): _start_glitch_pulse(), CONNECT_ONE_SHOT)
	
func flash_error() -> void:
	if pulse_tween: pulse_tween.kill()
	modulate.a = 1.0
	_apply_colors(Color("#ff5555"))
	
	pivot_offset = size / 2
	pulse_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	pulse_tween.finished.connect(func(): _apply_colors(base_color), CONNECT_ONE_SHOT)
