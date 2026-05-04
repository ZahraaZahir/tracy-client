extends Node

signal progress_updated(current: int, total: int)
signal ui_state_changed(is_active: bool)

var fixed_count: int = 0
var total_count: int = 0

var is_ui_active: bool = false:
	set(value):
		is_ui_active = value
		ui_state_changed.emit(is_ui_active)
	
func sync(fixed_list: Array, total: int) -> void:
	fixed_count = fixed_list.size()
	total_count = total
	progress_updated.emit(fixed_count, total_count)
