extends Control

signal block_dropped(id: String, block_data: Dictionary)

@onready var drop_zone: DropZone = $Area2D/DropZone
@onready var label: Label = $Label

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""
var is_locked: bool = false
var pulse_tween: Tween
var base_color: Color = Color(1, 1, 1)

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
	print("!!! PHYSICS OVERLAP DETECTED !!!")
	if new_occupant == null: return

	var inventory_item = new_occupant.get_meta("slot_root", null)
	if inventory_item == null: return

	print("SUCCESS: Drop detected! Value: ", inventory_item.logic_block.value)
	block_dropped.emit(slot_id, inventory_item.logic_block)

	new_occupant.queue_free()

	if is_instance_valid(inventory_item):
		inventory_item.queue_free()

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

func _apply_colors(color: Color):
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", color)

func _on_mouse_entered():
	if not is_locked: label.add_theme_color_override("font_outline_color", Color(1, 1, 1))

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
			block_dropped.emit(slot_id, {})
			accept_event()
