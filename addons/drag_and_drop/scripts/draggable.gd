@tool
extends Node

class_name Draggable

enum DRAGGABLE_STATE {IDLE, DRAGGING, DROPPING, RETURNING, AUTO_MOVING}
@export_group("Config")
## Optional explicit reference to the target Area2D. Overwrites parent and owner references.
## The Area2D has to be an ancestor of this node.
@export var area_reference: Area2D = null:
	set(value):
		area_reference = value
		update_configuration_warnings()
## Name of the InputMap action that handles drag start and end
@export var drag_input_name: StringName = &"draggable_click":
	set(value):
		drag_input_name = value
		update_configuration_warnings()
## Node the draggable's area temporarily re-parents to while in DRAGGING state.
## The area shouldn't be an ancestor of this node. If unset, will use the tree root.
## [br][br]
## [i]Hint[/i]: 
## If the scene root is the Area2D, either assign [code]drag_layer_parent[/code] at runtime once the game tree is available or
## transform the scene so that the root has the area as a child, 
## allowing the [code]drag_layer_parent[/code] can be attached to something other than the area. 
@export var drag_layer_parent: Node = null

@export_group("Behavior")
## Controls the speed at which the draggable node moves towards the cursor or towards the drop zone when dropped or returning.
## Differences in values between (1..25) are more noticeable.
## A maximum of 50 is allowed for when one wants to stick the draggable to the cursor
@export_range(1.0, 50.0, 1.0) var dragging_speed: float = 25.0
## Z_Index dragged area will take. It is recommended to not
## set it to maximum as z_index is additive for children if 
## z_as_relative is set and they also have to be outside of the defined range
@export_range(-4096, 4096) var drag_z_index: int = 1000
## Enable to use relative dragging instead of snapping the center to the mouse
@export var relative_dragging: bool = false
## Information used by dropzones for checking if Draggable is accepted.
## The base DraggableType has an id that's checked by the
## dropzone for matching
@export var type: DraggableType = DraggableType.new()

var state = DRAGGABLE_STATE.IDLE

var initial_z_index = 0
var drag_offset := Vector2.ZERO
var previous_position := Vector2.ZERO
var previous_parent = null
var next_position := Vector2.ZERO

var a: Area2D = null

const CLOSE_ENOUGH_THRESHOLD = .5

signal drag_started(area: Area2D)
signal drag_ended(area: Area2D, drop_spot: SnappingSpot)
signal state_changed(area: Area2D, state: DRAGGABLE_STATE)

#region Lifecycle

func _ready():
	var candidate: Area2D = null

	if area_reference != null:
		assert(area_reference is Area2D, "Selected node for 'area_reference' must be an Area2D")
		assert(area_reference.is_ancestor_of(self), "Selected Area2D must be an ancestor of this Draggable")
		candidate = area_reference
	elif get_parent() is Area2D:
		candidate = get_parent() as Area2D
	elif owner is Area2D:
		candidate = owner as Area2D
	a = candidate
	assert(a != null, "Draggable node '%s' must be linked to an Area2D (export, parent, or owner)" % name)
	if a != null and not Engine.is_editor_hint():
		a.set_meta("draggable", self)

	initial_z_index = a.z_index
	previous_position = a.global_position
	next_position = a.global_position
	a.input_event.connect(_on_input_event)

func _process(delta):
	match state:
		DRAGGABLE_STATE.IDLE:
			pass
		DRAGGABLE_STATE.DRAGGING:
			_handle_dragging(delta)
		DRAGGABLE_STATE.DROPPING:
			_handle_dropping(delta)
		DRAGGABLE_STATE.RETURNING:
			_handle_returning(delta)
		DRAGGABLE_STATE.AUTO_MOVING:
			_handle_auto_moving(delta)

func _handle_dragging(delta: float) -> void:
	a.global_position = _move_toward(a.global_position, a.get_global_mouse_position() + drag_offset, delta)

func _handle_dropping(delta: float) -> void:
	a.global_position = _move_toward(a.global_position, next_position, delta)

	if a.global_position.distance_squared_to(next_position) <= CLOSE_ENOUGH_THRESHOLD:
		previous_position = next_position
		a.global_position = next_position
		_change_state_to(DRAGGABLE_STATE.IDLE)

func _handle_returning(delta: float) -> void:
	a.global_position = _move_toward(a.global_position, previous_position, delta)

	if a.global_position.distance_squared_to(next_position) <= CLOSE_ENOUGH_THRESHOLD:
		a.global_position = previous_position

		if previous_parent and a.get_parent() != previous_parent:
			a.reparent(previous_parent)
		_change_state_to(DRAGGABLE_STATE.IDLE)

func _handle_auto_moving(delta: float) -> void:
	a.global_position = _move_toward(a.global_position, next_position, delta)

	if a.global_position.distance_squared_to(next_position) <= CLOSE_ENOUGH_THRESHOLD:
		previous_position = next_position
		a.global_position = next_position
		_change_state_to(DRAGGABLE_STATE.IDLE)

func _exp_decay(from: Vector2, to: Vector2, decay: float, delta: float) -> Vector2:
	return to + (from - to) * exp(-decay * delta)

func _move_toward(from: Vector2, to: Vector2, delta: float) -> Vector2:
	return _exp_decay(from, to, dragging_speed, delta)

#endregion

#region Input Handling

func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed(drag_input_name) and state == DRAGGABLE_STATE.IDLE:
		previous_position = a.global_position
		previous_parent = a.get_parent()
		if drag_layer_parent:
			assert(not a.is_ancestor_of(drag_layer_parent), "Drag Layer Parent cannot be a descendant of the draggable's Area2D, this would create a reparenting loop.")
			a.reparent(drag_layer_parent)
		else:
			a.reparent(get_tree().root)

		if relative_dragging:
			drag_offset = a.global_position - event.position

		_change_state_to(DRAGGABLE_STATE.DRAGGING)
		drag_started.emit(a)

# Changed _input to _unhandled_input so that GUI Control nodes (like CodeSlot)
# consuming the mouse-release event via _gui_input/accept_event() don't block drop detection.
# Drop detection uses screen-space rect testing to bypass CanvasLayer world-space coord corruption.
func _unhandled_input(event):
	if not (event.is_action_released(drag_input_name) and state == DRAGGABLE_STATE.DRAGGING):
		return

	var mouse_screen_pos = a.get_viewport().get_mouse_position()
	var dropzone: DropZone = null

	for slot in get_tree().get_nodes_in_group("code_slots"):
		var slot_area: Area2D = slot.get_node_or_null("Area2D")
		if slot_area == null: continue
		var canvas_layer = slot.get_parent()
		while canvas_layer != null and not canvas_layer is CanvasLayer:
			canvas_layer = canvas_layer.get_parent()
		var screen_pos = canvas_layer.get_final_transform() * slot_area.global_position if canvas_layer else slot_area.global_position
		var col_shape = slot_area.get_node_or_null("CollisionShape2D")
		if col_shape == null: continue
		var half = col_shape.shape.size / 2.0
		if Rect2(screen_pos - half, col_shape.shape.size).has_point(mouse_screen_pos):
			dropzone = slot_area.get_node_or_null("DropZone")
			break

	var drop_spot: SnappingSpot = null
	if dropzone:
		drop_spot = dropzone.try_dropping(a)

	drag_ended.emit(a, drop_spot)
	move_to(drop_spot.point.global_position if drop_spot else previous_position,
			DRAGGABLE_STATE.DROPPING if drop_spot else DRAGGABLE_STATE.RETURNING)

#endregion

#region Exposed Functions

func move_to(pos: Vector2, reason := DRAGGABLE_STATE.AUTO_MOVING) -> void:
	if state != DRAGGABLE_STATE.RETURNING:
		next_position = pos
	_change_state_to(reason)

#endregion

#region Internal Functions

func _change_state_to(new_state: DRAGGABLE_STATE) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		DRAGGABLE_STATE.DRAGGING, DRAGGABLE_STATE.AUTO_MOVING:
			a.z_index = drag_z_index
		_:
			a.z_index = initial_z_index
	state_changed.emit(a, state)

#endregion

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()

	if not ProjectSettings.has_setting("input/" + drag_input_name):
		warnings.append("Action " + str(drag_input_name) + " could not be found in the InputMap")
	if area_reference != null and not (area_reference is Area2D):
		warnings.append("Selected node for 'area_reference' is not an Area2D")
	if area_reference != null and area_reference is Area2D and not area_reference.is_ancestor_of(self):
		warnings.append("Selected Area2D is not an ancestor of this Draggable; prefer parent/grandparent to avoid cross-branch issues")
	if area_reference == null and not (get_parent() is Area2D) and not (owner is Area2D):
		warnings.append("No Area2D found via export, parent, or owner; Draggable requires an Area2D")

	var check_a = area_reference
	if not check_a:
		var parent = get_parent()
		check_a = parent if parent is Area2D else owner
	if check_a and drag_layer_parent and check_a.is_ancestor_of(drag_layer_parent):
		warnings.append("Drag Layer Parent cannot be a descendant of the draggable's Area2D, this would create a reparenting loop.")
	return warnings
	
