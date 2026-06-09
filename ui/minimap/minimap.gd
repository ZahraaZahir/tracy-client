extends Control

# --- CONFIGURATION ---
@export var npc_dot_size: Vector2 = Vector2(22, 22)
@export var bug_dot_size: Vector2 = Vector2(16, 16)

# --- ASSETS ---
const BUG_DOT = preload("res://assets/ui/minimap/bug_dot.png")
const NPC_DOT = preload("res://assets/ui/minimap/NPC_mark.png")
const CHECK_DOT = preload("res://assets/ui/minimap/checkmark.png")

# --- STATE ---
var map_scale: float = 0.0
var world_origin: Vector2 = Vector2.ZERO
var markers: Dictionary = {}

# Update these paths to use the % symbol
@onready var map_layer = %MapLayer
@onready var marker_container = %Markers
@onready var background_img = %Background # Or whatever you named it

func _ready():
	# Connect to world data arrival
	WorldService.world_loaded.connect(_on_world_data_received)
	
	# Connect to real-time events
	SignalBus.register_on_map.connect(_on_entity_registered)
	EntityService.entity_fixed_globally.connect(_on_npc_fixed)

func _on_world_data_received(_data):
	_calculate_bounds()
	
	# THE KEY: Wait one frame so NPCs can load their 'Fixed' state from the DB
	await get_tree().process_frame
	
	# Now perform the scan for starting entities (NPCs)
	for npc in get_tree().get_nodes_in_group("interactable"):
		_on_entity_registered(npc, "npc")

func _calculate_bounds():
	var grass = get_tree().current_scene.find_child("Grass", true, false)
	if grass:
		var rect = grass.get_used_rect()
		var tile_size = grass.tile_set.tile_size.x
		world_origin = Vector2(rect.position) * tile_size
		var world_width_px = rect.size.x * tile_size
		
		map_scale = size.x / float(world_width_px)
		background_img.size = Vector2(rect.size) * tile_size * map_scale

func _process(_delta):
	var tracy = get_tree().get_first_node_in_group("tracy")
	if not tracy or map_scale == 0: return
	
	# --- THE CORRECT RADAR MATH ---
	var relative_pos = tracy.global_position - world_origin
	var map_pos = relative_pos * map_scale
	
	# Move the world layer so Tracy (centered icon) looks like she's walking
	map_layer.position = (size / 2.0) - map_pos
	
	# --- SYNC DOTS ---
	for entity in markers.keys():
		if is_instance_valid(entity):
			var dot = markers[entity]
			var entity_rel = entity.global_position - world_origin
			dot.position = (entity_rel * map_scale) - (dot.size / 2.0)
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
		dot.size = bug_dot_size
	elif type == "npc":
		# THE SOURCE OF TRUTH FIX:
		# Check the WorldService memory directly using the NPC's ID
		var npc_id = entity.get("entity_id")
		var is_actually_fixed = npc_id in WorldService.current_fixed_list
		
		dot.texture = CHECK_DOT if is_actually_fixed else NPC_DOT
		dot.size = npc_dot_size
		if is_actually_fixed: dot.modulate = Color.GREEN

	marker_container.add_child(dot)
	markers[entity] = dot
func _on_npc_fixed(id: String):
	for entity in markers.keys():
		if is_instance_valid(entity) and entity.get("entity_id") == id:
			var dot = markers[entity]
			dot.texture = CHECK_DOT
			dot.modulate = Color.GREEN
			break
