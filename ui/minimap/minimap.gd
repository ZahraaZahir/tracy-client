extends Control

# --- ASSETS ---
const BUG_DOT = preload("res://assets/ui/minimap/bug_dot.png")
const NPC_DOT = preload("res://assets/ui/minimap/NPC_mark.png")
const CHECK_DOT = preload("res://assets/ui/minimap/checkmark.png")

# --- UI CONFIG ---
const UI_SIZE = Vector2(268, 190)
const UI_CENTER = Vector2(134, 95)

@export var zoom_factor: float = 0.3
var map_display_size: Vector2 # The size of the scaled image

# --- STATE ---
var world_origin: Vector2 = Vector2.ZERO
var markers: Dictionary = {}

@onready var map_layer = %MapLayer
@onready var marker_container = %Markers
@onready var background_img = %Background
@onready var tracy_icon = %TracyIcon # Static icon node

func _ready():
	WorldService.world_loaded.connect(_on_world_data_received)
	SignalBus.register_on_map.connect(_on_entity_registered)
	EntityService.entity_fixed_globally.connect(_on_npc_fixed)

func _on_world_data_received(_data):
	_calculate_world_projection()
	await get_tree().process_frame
	for npc in get_tree().get_nodes_in_group("interactable"):
		_on_entity_registered(npc, "npc")

func _calculate_world_projection():
	var grass = get_tree().current_scene.find_child("Grass", true, false)
	if grass:
		var rect = grass.get_used_rect()
		var tile_size = grass.tile_set.tile_size.x
		
		world_origin = Vector2(rect.position) * tile_size
		var world_size_px = Vector2(rect.size) * tile_size
		
		# Proportional size of the map image in UI pixels
		map_display_size = world_size_px * zoom_factor
		
		background_img.size = map_display_size
		marker_container.size = map_display_size
		background_img.position = Vector2.ZERO

func _process(_delta):
	var tracy = get_tree().get_first_node_in_group("tracy")
	if not tracy or map_display_size == Vector2.ZERO: return
	
	# 1. Calculate Tracy's absolute coordinate on the large map image
	var tracy_map_pos = (tracy.global_position - world_origin) * zoom_factor
	
	# 2. Determine where the MapLayer SHOULD be to center her
	var ideal_layer_pos = UI_CENTER - tracy_map_pos
	
	# 3. CLAMP the MapLayer so it never reveals the void
	# min_pos: the furthest the map can slide left/up
	# max_pos: the furthest the map can slide right/down (always 0,0)
	var min_pos = UI_SIZE - map_display_size
	var max_pos = Vector2.ZERO
	
	var clamped_layer_pos = ideal_layer_pos.clamp(min_pos, max_pos)
	map_layer.position = clamped_layer_pos
	
	# 4. THE FIX: Icon Position
	# tracy_map_pos is where she is on the image. 
	# clamped_layer_pos is where the image is on the screen.
	# Adding them gives her exact screen position within the frame.
	tracy_icon.position = tracy_map_pos + clamped_layer_pos
	
	# 5. Safety: Keep the icon inside the UI box even if Tracy glitches out of bounds
	tracy_icon.position = tracy_icon.position.clamp(Vector2.ZERO, UI_SIZE)
	
	# 6. SYNC DOTS
	for entity in markers.keys():
		if is_instance_valid(entity):
			var dot = markers[entity]
			var entity_rel = (entity.global_position - world_origin) * zoom_factor
			dot.position = entity_rel - (dot.size / 2.0)
		else:
			markers[entity].queue_free()
			markers.erase(entity)

func _on_entity_registered(entity: Node2D, type: String):
	if markers.has(entity): return 
	var dot = TextureRect.new()
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if type == "bug":
		dot.texture = BUG_DOT
		dot.size = Vector2(16, 16)
	elif type == "npc":
		var is_fixed = entity.get("entity_id") in WorldService.current_fixed_list
		dot.texture = CHECK_DOT if is_fixed else NPC_DOT
		dot.size = Vector2(22, 22)
		if is_fixed: dot.modulate = Color.GREEN
	marker_container.add_child(dot)
	markers[entity] = dot

func _on_npc_fixed(id: String):
	for entity in markers.keys():
		if is_instance_valid(entity) and entity.get("entity_id") == id:
			markers[entity].texture = CHECK_DOT
			markers[entity].modulate = Color.GREEN
