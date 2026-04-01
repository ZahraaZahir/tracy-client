extends Button

# --- DATA STATE ---
var slot_id: String = ""       # Unique ID (e.g., "s1")
var current_state: String = ""  # "bug", "draft", or "fixed"
var original_value: String = "" # The 'Ground Truth' error value

# 1. THE SETUP: Called by the InspectorPanel when spawning the node
func setup(id: String, val: String, state: String):
	slot_id = id
	original_value = val # We cache this forever for the 'Reset' logic
	set_slot_state(state, val)

# 2. THE STATE CONTROLLER: This is the ONLY way the visual should change
func set_slot_state(new_state: String, new_val: String):
	current_state = new_state
	text = new_val # Update the button's display text
	
	# We use 'match' because it is a clean way to handle State Machines
	match current_state:
		"bug":
			# Dracula Red: High visibility for errors
			add_theme_color_override("font_color", Color("ff5555"))
			disabled = false
		
		"draft":
			# Dracula Yellow: Indicates 'Unsaved/In-Progress'
			add_theme_color_override("font_color", Color("f1fa8c"))
			disabled = false
			
		"fixed":
			# Dracula Green: Indicates Success
			add_theme_color_override("font_color", Color("50fa7b"))
			# IMPORTANT: Disable the button so the player can't edit a solved line
			disabled = true

# 3. GETTERS (Helper Functions)
# Used by the InspectorPanel to pull data back into the 'Memory Map'
func get_slot_id() -> String:
	return slot_id
