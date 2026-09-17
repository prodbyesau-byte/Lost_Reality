class_name CharacterTheme
extends RefCounted
## Single Future Machine theme. Existing class/path retained for compatibility.
const TEXT := Color("dce4e7")
const MUTED := Color("89979e")
const ACCENT := Color("88adb5")
const DIM := Color("344148")
const SURFACE := Color("11181d")
const WARNING := Color("b9a071")
const ERROR := Color("cf7977")

static func box(background: Color, border: Color = DIM, margin: float = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin*0.65
	style.content_margin_bottom = margin*0.65
	return style

static func machine_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas","Cascadia Mono","monospace"])
	return font

static func theme() -> Theme:
	var result := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI","Arial"])
	result.default_font = font
	result.default_font_size = 16
	result.set_color("font_color","Label",TEXT)
	for type in ["Button","CheckButton","CheckBox","OptionButton"]:
		result.set_color("font_color",type,TEXT)
		result.set_color("font_hover_color",type,Color("eff7fa"))
		result.set_color("font_pressed_color",type,TEXT)
		result.set_color("font_disabled_color",type,MUTED)
		result.set_stylebox("normal",type,box(SURFACE))
		result.set_stylebox("hover",type,box(Color("1d2a31"),ACCENT))
		result.set_stylebox("pressed",type,box(Color("253840"),ACCENT))
		result.set_stylebox("disabled",type,box(Color("101519"),Color("283138")))
		result.set_stylebox("focus",type,box(Color(0,0,0,0),TEXT))
	result.set_stylebox("background","ProgressBar",box(Color("090f13"),DIM,0))
	result.set_stylebox("fill","ProgressBar",box(ACCENT,ACCENT,0))
	result.set_stylebox("panel","TooltipPanel",box(SURFACE))
	result.set_color("font_color","TooltipLabel",TEXT)
	var window_frame := box(Color("0c1318"),ACCENT,22)
	window_frame.expand_margin_top = 34
	result.set_stylebox("embedded_border","Window",window_frame)
	result.set_color("title_color","Window",TEXT)
	result.set_color("title_outline_modulate","Window",Color(0,0,0,0))
	result.set_font("title_font","Window",machine_font())
	result.set_constant("title_height","Window",34)
	result.set_font_size("title_font_size","Window",18)
	result.set_stylebox("panel","AcceptDialog",box(Color("0c1318"),DIM,22))
	for type in ["VScrollBar","HScrollBar"]:
		result.set_stylebox("scroll",type,box(Color("090f13"),DIM,3))
		result.set_stylebox("grabber",type,box(DIM,ACCENT,3))
		result.set_stylebox("grabber_highlight",type,box(Color("536973"),ACCENT,3))
		result.set_stylebox("grabber_pressed",type,box(ACCENT,ACCENT,3))
	for type in ["HSlider","VSlider"]:
		result.set_stylebox("slider",type,box(SURFACE,DIM,2))
		result.set_stylebox("grabber_area",type,box(ACCENT,ACCENT,2))
	return result

static func label(text: String, size: int = 16, color: Color = TEXT, technical: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	if technical: label.add_theme_font_override("font",machine_font())
	return label
