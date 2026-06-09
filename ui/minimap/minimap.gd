extends Control

const BUG_DOT = preload("res://assets/ui/minimap/bug_dot.png")
const NPC_DOT = preload("res://assets/ui/minimap/NPC_mark.png")
const CHECK_DOT = preload("res://assets/ui/minimap/checkmark.png")

const UI_SIZE = Vector2(268, 190)
const UI_CENTER = Vector2(134, 95)

@export var zoom_factor: float = 0.3
@export var npc_marker_size: Vector2 = Vector2(22, 22)
@export var bug_marker_size: Vector2 = Vector2(16, 16)

var world_origin: Vector2 = Vector2.ZERO
var map_display_size: Vector2 = Vector2.ZERO
var markers: Dictionary = {}

@onready var map_layer = %MapLayer
@onready var marker_container = %Markers
@onready var background_img = %Background
@onready var tracy_icon = %TracyIcon

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
		map_display_size = world_size_px * zoom_factor
		background_img.size = map_display_size
		marker_container.size = map_display_size
		background_img.position = Vector2.ZERO
		marker_container.position = Vector2.ZERO

func _process(_delta):
	var tracy = get_tree().get_first_node_in_group("tracy")
	if not tracy or map_display_size == Vector2.ZERO: return
	
	var tracy_map_pos = (tracy.global_position - world_origin) * zoom_factor
	var ideal_layer_pos = UI_CENTER - tracy_map_pos
	var min_pos = UI_SIZE - map_display_size
	var max_pos = Vector2.ZERO
	
	var clamped_layer_pos = ideal_layer_pos.clamp(min_pos, max_pos)
	map_layer.position = clamped_layer_pos
	tracy_icon.position = tracy_map_pos + clamped_layer_pos
	
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
		dot.size = bug_marker_size
	elif type == "npc":
		var is_fixed = entity.get("entity_id") in WorldService.current_fixed_list
		dot.texture = CHECK_DOT if is_fixed else NPC_DOT
		dot.size = npc_marker_size
		if is_fixed: dot.modulate = Color.GREEN
	marker_container.add_child(dot)
	markers[entity] = dot

func _on_npc_fixed(id: String):
	for entity in markers.keys():
		if is_instance_valid(entity) and entity.get("entity_id") == id:
			var dot = markers[entity]
			dot.texture = CHECK_DOT
			dot.modulate = Color.GREEN
			break
