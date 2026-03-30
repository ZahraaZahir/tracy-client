extends CanvasLayer

@onready var progress_label = $MainMargin/TopRight/ProgressWidget/Padding/ProgressHBox/Label
@onready var progress_widget = $MainMargin/TopRight/ProgressWidget

func _ready() -> void:
	ProgressionService.progress_updated.connect(_on_progress_updated)
	
	progress_label.text = "Fixed: 0 / 0"

func _on_progress_updated(current: int, total: int) -> void:
	progress_label.text = "Fixed: %d / %d" % [current, total]
	
	var tween = create_tween()
	progress_widget.pivot_offset = progress_widget.size / 2 
	
	tween.tween_property(progress_widget, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(progress_widget, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
