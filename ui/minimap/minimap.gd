extends Control

# --- CONFIGURATION ---
@export var npc_dot_size: Vector2 = Vector2(30, 30)
@export var bug_dot_size: Vector2 = Vector2(12, 12)

# --- ASSETS ---
const BUG_DOT = preload("res://assets/ui/minimap/bug_dot.png")
const NPC_DOT = preload("res://assets/ui/minimap/NPC_mark.png")
const CHECK_DOT = preload("res://assets/ui/minimap/checkmark.png")

# --- STATE ---
var map_scale: float = 0.0
var world_origin: Vector2 = Vector2.ZERO
var markers: Dictionary = {} # { world_node: TextureRect_ui }

@onready var map_layer = $MapLayer
@onready var marker_container = $MapLayer/Markers

func _ready():
	# 1. Wait for World to finish spawning all entities
	await get_tree().process_frame
	
	# 2. Setup the Map Projection based on the 'Grass' layer
	_calculate_world_bounds()
	
	# 3. Connect to the global communication lines
	SignalBus.register_on_map.connect(_on_entity_registered)
	EntityService.entity_fixed_globally.connect(_on_npc_fixed)

	# 4. BOOT-UP SCAN: Find NPCs that are already in the world
	for npc in get_tree().get_nodes_in_group("interactable"):
		_on_entity_registered(npc, "npc")

func _process(_delta):
	var tracy = get_tree().get_first_node_in_group("tracy")
	if not tracy or map_scale == 0: return
	
	# --- CENTER THE RADAR ON TRACY ---
	# We move the entire background layer in the opposite direction
	var relative_pos = tracy.global_position - world_origin
	map_layer.position = (-relative_pos * map_scale) + (size / 2.0)
	
	# --- UPDATE DYNAMIC MARKER POSITIONS ---
	for entity in markers.keys():
		if is_instance_valid(entity):
			var dot = markers[entity]
			var entity_rel_pos = entity.global_position - world_origin
			# Position the dot and offset by half size to center it
			dot.position = (entity_rel_pos * map_scale) - (dot.size / 2.0)
		else:
			# Auto-cleanup if a bug is killed/removed
			markers[entity].queue_free()
			markers.erase(entity)

func _calculate_world_bounds():
	var grass = get_tree().current_scene.find_child("Grass", true, false)
	if grass:
		var rect = grass.get_used_rect()
		var tile_size = grass.tile_set.tile_size.x
		
		world_origin = Vector2(rect.position) * tile_size
		var world_width_px = rect.size.x * tile_size
		
		# 1 world pixel = (UI_Size / World_Width) map pixels
		map_scale = size.x / float(world_width_px)
		
		# FORCE the background image to match the world proportions
		# This ensures the dots align with the drawing
		$MapLayer/Background.size = Vector2(rect.size) * tile_size * map_scale

func _on_entity_registered(entity: Node2D, type: String):
	if markers.has(entity): return # Prevent double-adding

	# Create a UI component to handle the huge images
	var dot = TextureRect.new()
	
	# THE FIX FOR HUGE ASSETS:
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if type == "bug":
		dot.texture = BUG_DOT
		dot.size = bug_dot_size
	elif type == "npc":
		# Set initial state (Mark vs Checkmark)
		var is_fixed = entity.get("is_fixed")
		dot.texture = CHECK_DOT if is_fixed else NPC_DOT
		dot.size = npc_dot_size
		if is_fixed: dot.modulate = Color.GREEN

	marker_container.add_child(dot)
	markers[entity] = dot

func _on_npc_fixed(id: String):
	# Loop through our markers to find the one matching the fixed NPC ID
	for entity in markers.keys():
		if is_instance_valid(entity) and entity.get("entity_id") == id:
			var dot = markers[entity]
			dot.texture = CHECK_DOT
			dot.modulate = Color.GREEN
			break
