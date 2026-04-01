extends Button

var slot_id: String = ""
var current_state: String = ""
var original_value: String = ""

func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val
	set_slot_state(state, val)

func set_slot_state(new_state: String, new_val: String):
	current_state = new_state
	text = new_val
	
	match current_state:
		"bug":
			add_theme_color_override("font_color", Color("ff5555"))
			disabled = false
		
		"draft":
			add_theme_color_override("font_color", Color("f1fa8c"))
			disabled = false
			
		"fixed":
			add_theme_color_override("font_color", Color("50fa7b"))
			disabled = true

func get_slot_id() -> String:
	return slot_id
