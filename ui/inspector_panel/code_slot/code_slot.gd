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
var highlight_tween: Tween
var base_color: Color = Color(1, 1, 1)

var _held_inventory_item = null
var _held_area: Area2D = null

func _ready():
	add_to_group("code_slots")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	drop_zone.occupant_changed.connect(_on_occupant_changed)
	
	var area = $Area2D
	area.area_entered.connect(_on_drag_entered)
	area.area_exited.connect(_on_drag_exited)

func _on_drag_entered(_other_area: Area2D):
	if is_locked: return
	if highlight_tween: highlight_tween.kill()
	
	highlight_tween = create_tween().bind_node(self)
	highlight_tween.tween_property(self, "modulate", Color(1.2, 1.2, 0.9, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_drag_exited(_other_area: Area2D):
	if is_locked: return
	if highlight_tween: highlight_tween.kill()
	
	highlight_tween = create_tween().bind_node(self)
	highlight_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	
func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)
	
func _on_occupant_changed(_zone, _spot, _old, new_occupant):
	if highlight_tween: highlight_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if new_occupant == null: return
	var inventory_item = new_occupant.get_meta("slot_root", null)
	if inventory_item == null: return

	if _held_area != null and _held_area != new_occupant:
		restore_held_item()

	_held_inventory_item = inventory_item
	_held_area = new_occupant

	_held_inventory_item.modulate.a = 0.0
	_held_inventory_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_area.visible = false

	if SfxManager:
		SfxManager.play_block_drop()

	block_dropped.emit(slot_id, inventory_item.logic_block)

func restore_held_item() -> void:
	if is_instance_valid(_held_inventory_item) and is_instance_valid(_held_area):
		_held_inventory_item.modulate.a = 1.0
		_held_inventory_item.mouse_filter = Control.MOUSE_FILTER_PASS
		
		_held_area.visible = true
		_held_area.z_index = 0

		var draggable = _held_area.get_meta("draggable", null)
		if draggable:
			draggable.state = 0
		
		_held_area.reparent(_held_inventory_item, false)
		_held_area.position = Vector2(60, 40)
		
		DropUtils.clear_occupant_reference(drop_zone, _held_area)

		if SfxManager:
			SfxManager.play_block_deselect()

	_held_inventory_item = null
	_held_area = null

func consume_held_item() -> void:
	if is_instance_valid(_held_inventory_item):
		_held_inventory_item.queue_free()
	if is_instance_valid(_held_area):
		_held_area.queue_free()
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
	var text_size = label.get_combined_minimum_size()
	
	custom_minimum_size.x = text_size.x + 20 
	
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var target_width = max(text_size.x + 60.0, 180.0) 
		var target_height = 100.0 
		
		collision_shape.shape.size = Vector2(target_width, target_height)
		collision_shape.position = Vector2(custom_minimum_size.x / 2.0, size.y / 2.0)
		
func _apply_colors(color: Color):
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", color)
	
func _on_mouse_entered():
	if is_locked: return
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	
	if current_state == "draft":
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
