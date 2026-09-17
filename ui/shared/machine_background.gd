class_name MachineBackground
extends Control
## Vector diagnostic backdrop. Scales with the menu; no raster art or story disclosure.
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("080e12"))
	for x in range(0,int(size.x),64):
		draw_line(Vector2(x,0),Vector2(x,size.y),Color(0.23,0.32,0.36,0.10))
	for y in range(0,int(size.y),64):
		draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.23,0.32,0.36,0.10))
	# Abstract infrastructure channels at the perimeter.
	for side in [0,1]:
		var x := size.x*0.07 if side == 0 else size.x*0.81
		for i in 9:
			var y := size.y*0.18+i*size.y*0.07
			var width := size.x*0.12
			draw_rect(Rect2(x,y,width,size.y*0.05),Color("18252d"),false,1)
			for j in 6:
				draw_line(Vector2(x+12,y+8+j*4),Vector2(x+width-30,y+8+j*4),Color("142027"),1)
			draw_rect(Rect2(x+width-17,y+12,3,3),Color("526b72") if i%3 else Color("8a7958"))
	draw_line(Vector2(40,40),Vector2(size.x-40,40),CharacterTheme.DIM,1)
	draw_line(Vector2(40,size.y-40),Vector2(size.x-40,size.y-40),CharacterTheme.DIM,1)
