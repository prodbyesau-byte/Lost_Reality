class_name UIStyle
extends RefCounted
const INK := Color("e1e7df")
const MUTED := Color("8ca39f")
const ACCENT := Color("a9dfc5")

static func panel(color: Color = Color("121e25"), border: Color = Color("384d50")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_color("font_color", "Label", INK)
	result.set_color("font_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("627572"))
	result.set_stylebox("normal", "Button", panel(Color("24373b")))
	result.set_stylebox("hover", "Button", panel(Color("34514f"), ACCENT))
	result.set_stylebox("pressed", "Button", panel(Color("1c3431"), ACCENT))
	result.set_stylebox("focus", "Button", panel(Color(0, 0, 0, 0), ACCENT))
	result.set_stylebox("disabled", "Button", panel(Color("19272c")))
	return result

static func label(text: String, size: int = 18, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result
