extends Node

func _ready():
	# 1. Wait for the world to settle
	await get_tree().create_timer(1.0).timeout
	_export_pure_map()

func _export_pure_map():
	var grass = get_tree().current_scene.find_child("Grass", true, false)
	var soil = get_tree().current_scene.find_child("Soil", true, false)
	var water = get_tree().current_scene.find_child("Water", true, false)
	
	if !grass:
		print("ERROR: Grass layer not found. Check your node names!")
		return

	# 2. Calculate the Bounds
	var rect = grass.get_used_rect()
	var img = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)

	print("STARTING EXPORT: Drawing ", rect.size.x, "x", rect.size.y, " pixels...")

	# 3. Paint the Image based on Tiles
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			var map_pos = rect.position + Vector2i(x, y)
			
			# Priority: Water > Soil > Grass
			var color = Color(0,0,0,0) # Default transparent
			
			if water and water.get_cell_source_id(map_pos) != -1:
				color = Color("#4cc0d9") # Blue
			elif soil and soil.get_cell_source_id(map_pos) != -1:
				color = Color("#c7874a") # Brown
			elif grass.get_cell_source_id(map_pos) != -1:
				color = Color("#6bbf3b") # Green
				
			img.set_pixel(x, y, color)

	# 4. Save to a specific absolute path to avoid "User Folder" confusion
	# This will save to your actual Desktop (Change 'User' to your computer name)
	var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP) + "/tracy_full_map.png"
	var err = img.save_png(desktop_path)
	
	if err == OK:
		print("--- SUCCESS ---")
		print("Map saved to your Desktop: ", desktop_path)
	else:
		print("Save failed with error code: ", err)
