extends Button

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""

@onready var pulse_tween: Tween

func _ready():
	pivot_offset = size / 2
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)

func set_slot_state(new_state: String, new_val: String):
	current_state = new_state
	text = new_val
	
	if pulse_tween: pulse_tween.kill()
	modulate.a = 1.0
	
	match current_state:
		"bug":
			add_theme_color_override("font_color", Color("#ff5555"))
		"draft":
			add_theme_color_override("font_color", Color("dce548ff"))
		"fixed":
			add_theme_color_override("font_color", Color("#50fa7b"))

func _on_hover(is_entering: bool):
	var t = create_tween()
	var target_scale = Vector2(1.1, 1.1) if is_entering else Vector2(1.0, 1.0)
	t.tween_property(self, "scale", target_scale, 0.1).set_trans(Tween.TRANS_QUAD)

func get_slot_id() -> String:
	return slot_id
