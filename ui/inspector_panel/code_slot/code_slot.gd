extends Button

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""
var pulse_tween: Tween

var base_color: Color = Color(1, 1, 1)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)

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
	if current_state != "fixed":
		add_theme_color_override("font_outline_color", Color(1, 1, 1))

func _on_mouse_exited():
	if current_state != "fixed":
		add_theme_color_override("font_outline_color", base_color)

func _start_glitch_pulse():
	pulse_tween = create_tween().set_loops().bind_node(self)
	pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.tween_property(self, "modulate:a", 0.5, 0.3)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.1)

func get_slot_id() -> String:
	return slot_id
