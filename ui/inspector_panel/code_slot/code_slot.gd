extends Button

signal block_dropped(id: String, block_data: Dictionary)

@onready var drop_zone: DropZone = $Area2D/DropZone

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""
var pulse_tween: Tween
var base_color: Color = Color(1, 1, 1)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	drop_zone.occupant_changed.connect(_on_occupant_changed)

func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)
	
func _on_occupant_changed(_zone, _spot, _old, new_occupant):
	print("DEBUG: Signal triggered! New occupant is: ", new_occupant)
	
	if new_occupant:
		var inventory_item = new_occupant.get_meta("slot_root")
		if inventory_item:
			print("DEBUG: Block detected! Value: ", inventory_item.logic_block.value)
			block_dropped.emit(slot_id, inventory_item.logic_block)
			
			inventory_item.queue_free()

func set_slot_state(new_state: String, new_val: String):
	current_state = new_state
	text = new_val
	if pulse_tween: pulse_tween.kill()
	modulate.a = 1.0
	add_theme_constant_override("outline_size", 2)
	
	match current_state:
		"bug":
			base_color = Color("#ff5555")
			disabled = false
			_start_glitch_pulse()
		"draft":
			base_color = Color("#c68b12")
			disabled = false
		"fixed":
			base_color = Color("#009868")
			disabled = true
			add_theme_constant_override("outline_size", 0)
	_apply_colors(base_color)

func _apply_colors(color: Color):
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", color)

func _on_mouse_entered():
	if current_state != "fixed": add_theme_color_override("font_outline_color", Color(1, 1, 1))

func _on_mouse_exited():
	if current_state != "fixed": add_theme_color_override("font_outline_color", base_color)

func _start_glitch_pulse():
	pulse_tween = create_tween().set_loops().bind_node(self).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.tween_property(self, "modulate:a", 0.5, 0.3)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _pressed():
	if current_state == "draft":
		block_dropped.emit(slot_id, {})
