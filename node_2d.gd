extends Node2D

func _ready():
	# 1. Wait for tiles to load
	await get_tree().process_frame
	
	var grass = find_child("Grass", true, false)
	if !grass: 
		print("Error: Grass layer not found.")
		return

	# 2. Calculate the World Dimensions
	var used_rect = grass.get_used_rect()
	var tile_size = grass.tile_set.tile_size
	var world_size_px = Vector2(used_rect.size) * Vector2(tile_size)
	var world_center_px = (Vector2(used_rect.position) * Vector2(tile_size)) + (world_size_px / 2.0)

	# 3. Configure the Viewport to match the World Size
	var viewport = $SubViewportContainer/SubViewport
	viewport.size = world_size_px
	
	# 4. Position the Camera in the center of the world
	var cam = viewport.get_camera_2d()
	cam.global_position = world_center_px
	cam.zoom = Vector2(1, 1) # Capture at full resolution

	# 5. Take the Snapshot
	await get_tree().process_frame # Wait for render
	var img = viewport.get_texture().get_image()
	
	# 6. Save to your computer
	img.save_png("user://full_world_map.png")
	print("SUCCESS: Map saved to user://full_world_map.png")
	
	# To find the file:
	print("Find it here: ", OS.get_user_data_dir())
