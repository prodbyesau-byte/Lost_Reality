class_name CharacterBackdrop
extends Control
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var bounds := Rect2(26,20,size.x-52,size.y-40)
	for x in range(26,int(size.x)-26,32):
		draw_line(Vector2(x,20),Vector2(x,size.y-20),Color(0.4,0.5,0.55,0.05))
	for y in range(20,int(size.y)-20,32):
		draw_line(Vector2(26,y),Vector2(size.x-26,y),Color(0.4,0.5,0.55,0.05))
	draw_rect(bounds,CharacterTheme.DIM,false,1)
	for y in range(30,int(size.y)-25,12):
		draw_line(Vector2(26,y),Vector2(31,y),CharacterTheme.MUTED,1)
	draw_line(Vector2(size.x/2,20),Vector2(size.x/2,32),CharacterTheme.ACCENT,1)
	draw_line(Vector2(size.x/2,size.y-32),Vector2(size.x/2,size.y-20),CharacterTheme.ACCENT,1)
