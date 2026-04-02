extends PanelContainer

@onready var line_number = %LineNumber

func set_line_data(number: int, is_highlighted: bool):
	if line_number:
		line_number.text = str(number)
		line_number.add_theme_color_override("font_color", Color("#897042"))
		line_number.add_theme_font_size_override("font_size", 24)
	
	if is_highlighted:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#3A2C10", 0.15)
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		add_theme_stylebox_override("panel", style)
	else:
		var style = StyleBoxEmpty.new()
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		add_theme_stylebox_override("panel", style)
