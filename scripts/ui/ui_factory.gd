class_name UIFactory
extends RefCounted


static func label(text: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func button(text: String, position: Vector2, size: Vector2) -> Button:
	var node := Button.new()
	node.text = text
	node.position = position
	node.size = size
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_stylebox_override("normal", style(Color("0b2039"), Color(GamePalette.CYAN, 0.38), 2, 5))
	node.add_theme_stylebox_override("hover", style(Color("12334d"), GamePalette.CYAN, 2, 5))
	node.add_theme_stylebox_override("pressed", style(Color("071628"), GamePalette.GREEN, 2, 5))
	return node


static func panel(position: Vector2, size: Vector2, border: Color) -> Panel:
	var node := Panel.new()
	node.position = position
	node.size = size
	node.add_theme_stylebox_override("panel", style(Color("061126e8"), border, 2, 10))
	return node


static func progress_bar(position: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = position
	node.size = size
	node.show_percentage = false
	node.max_value = 100.0
	node.add_theme_stylebox_override("background", style(Color("08101f"), Color(color, 0.15), 1, 2))
	node.add_theme_stylebox_override("fill", style(Color(color, 0.84), color, 0, 2))
	return node


static func style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(border, 0.10)
	box.shadow_size = 12
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box
