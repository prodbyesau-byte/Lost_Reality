class_name EquipmentSocket
extends Button
## A presentation socket; selection never creates equipment or changes GameState.
var slot_id := ""
var title := ""
var item_icon: Texture2D

func _ready() -> void:
	custom_minimum_size = Vector2(168,88)
	toggle_mode = true
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	toggled.connect(func(_active: bool) -> void: queue_redraw())
	set_item(null, "")

func set_item(icon: Texture2D, item_name: String) -> void:
	item_icon = icon
	queue_redraw()

func _draw() -> void:
	var color := CharacterTheme.ACCENT if is_hovered() or button_pressed else CharacterTheme.MUTED
	var rect := Rect2(9,9,65,70)
	draw_rect(rect,Color("090f13"))
	draw_rect(rect,color,false,1)
	draw_rect(rect.grow(-4),CharacterTheme.DIM,false,1)
	for p in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		draw_circle(p,2,CharacterTheme.ACCENT)
	if item_icon:
		draw_texture_rect(item_icon,rect.grow(-9),false)
	else:
		_draw_icon(rect.get_center(),color)
	var lines := title.split("\n")
	for i in lines.size():
		draw_string(get_theme_default_font(),Vector2(84,40+i*18),lines[i],HORIZONTAL_ALIGNMENT_LEFT,78,14,CharacterTheme.TEXT)

func _draw_icon(c: Vector2, color: Color) -> void:
	var points: Array[Vector2] = []
	match slot_id:
		"head":
			draw_arc(c-Vector2(0,2),16,PI,TAU,20,color,1.5,true)
			points = [Vector2(-16,-2),Vector2(-13,14),Vector2(-5,19),Vector2(-5,3),Vector2(5,3),Vector2(5,19),Vector2(13,14),Vector2(16,-2)]
		"chest":
			points = [Vector2(-7,-20),Vector2(-22,-12),Vector2(-17,0),Vector2(-11,-3),Vector2(-11,19),Vector2(11,19),Vector2(11,-3),Vector2(17,0),Vector2(22,-12),Vector2(7,-20),Vector2(4,-13),Vector2(-4,-13),Vector2(-7,-20)]
		"legs":
			points = [Vector2(-14,-20),Vector2(14,-20),Vector2(17,20),Vector2(4,20),Vector2(0,-2),Vector2(-4,20),Vector2(-17,20),Vector2(-14,-20)]
		"necklace":
			draw_arc(c-Vector2(0,5),18,0,PI,28,color,1.5,true)
			points = [Vector2(0,8),Vector2(-6,16),Vector2(0,23),Vector2(6,16),Vector2(0,8)]
		"ring_1","ring_2":
			draw_arc(c+Vector2(0,4),13,0,TAU,32,color,1.5,true)
			points = [Vector2(0,-19),Vector2(-7,-12),Vector2(0,-5),Vector2(7,-12),Vector2(0,-19)]
		"feet":
			points = [Vector2(-12,-19),Vector2(5,-19),Vector2(5,1),Vector2(20,10),Vector2(20,18),Vector2(-15,18),Vector2(-15,5),Vector2(-12,-19)]
		"main_hand":
			points = [Vector2(-15,20),Vector2(12,-17),Vector2(20,-22),Vector2(18,-12),Vector2(-10,23)]
			draw_line(c+Vector2(-16,4),c+Vector2(1,17),color,2,true)
		"off_hand":
			points = [Vector2(0,-21),Vector2(-19,-13),Vector2(-15,11),Vector2(0,24),Vector2(15,11),Vector2(19,-13),Vector2(0,-21)]
	var packed := PackedVector2Array()
	for point in points:
		packed.append(c+point)
	if packed.size() > 1:
		draw_polyline(packed,color,1.5,true)
