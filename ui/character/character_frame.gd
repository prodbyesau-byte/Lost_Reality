class_name CharacterFrame
extends Control
## Reusable machine enclosure; never intercepts controls or modifies their layout.
var header_rule := true
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var interference := MachineInterference.new()
	add_child(interference)
	interference.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _draw() -> void:
	var edge := PackedVector2Array([Vector2(14,0),Vector2(size.x,0),Vector2(size.x,size.y-14),Vector2(size.x-14,size.y),Vector2(0,size.y),Vector2(0,14),Vector2(14,0)])
	draw_colored_polygon(edge,Color("0c1217"))
	draw_polyline(edge,CharacterTheme.DIM,1,true)
	draw_line(Vector2(20,12),Vector2(90,12),CharacterTheme.ACCENT,2)
	for x in [16.0,size.x-16]:
		for y in [16.0,size.y-16]:
			draw_line(Vector2(x-3,y),Vector2(x+3,y),CharacterTheme.MUTED,1)
			draw_line(Vector2(x,y-3),Vector2(x,y+3),CharacterTheme.MUTED,1)
	for i in 5:
		draw_rect(Rect2(size.x-62+i*7,13,3,3),CharacterTheme.DIM)
	if header_rule:
		draw_line(Vector2(38,91),Vector2(size.x-38,91),CharacterTheme.DIM,1)
		draw_line(Vector2(38,size.y-47),Vector2(size.x-38,size.y-47),CharacterTheme.DIM,1)
