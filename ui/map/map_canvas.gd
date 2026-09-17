class_name MapCanvas
extends Control
## Cached, fog-masked terrain chunks; live markers are a separate cheap overlay.
var area: MapAreaData
var follow_player := true
var center := Vector2.ZERO
var target_center := Vector2.ZERO
var zoom := 20.0
var target_zoom := 20.0
var dragging := false
var _font: Font

func _ready() -> void:
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE if follow_player else Control.MOUSE_FILTER_STOP
	_font = CharacterTheme.machine_font()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if follow_player:
		area = MapCatalog.area(SceneRouter.current_id, MapManager.current_floor)
		if is_instance_valid(SceneRouter.player):
			center = Vector2(SceneRouter.player.global_position.x, SceneRouter.player.global_position.z)
		zoom = size.x / (MapManager.minimap_range * 2.0)
	else:
		center = center.lerp(target_center, 1.0 - exp(-18.0 * delta))
		zoom = lerpf(zoom, target_zoom, 1.0 - exp(-18.0 * delta))
	queue_redraw()

func map_to_screen(point: Vector2) -> Vector2:
	return size * 0.5 + (point - center) * zoom

func screen_to_map(point: Vector2) -> Vector2:
	return center + (point - size * 0.5) / zoom

func focus_area(next: MapAreaData, point: Vector2) -> void:
	area = next
	center = point
	target_center = point
	zoom = clampf(minf(size.x, size.y) / 35.0, 10.0, 36.0)
	target_zoom = zoom
	dragging = false
	queue_redraw()

func pan_by(pixels: Vector2) -> void:
	if area == null:
		return
	target_center -= pixels / target_zoom
	var rect := area.bounds().grow(8.0)
	target_center = target_center.clamp(rect.position, rect.end)

func zoom_by(factor: float) -> void:
	target_zoom = clampf(target_zoom * factor, 5.0, 90.0)

func _gui_input(event: InputEvent) -> void:
	if follow_player:
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.2)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 1.2)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan_by(event.relative)
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1217"))
	if area != null:
		_draw_terrain()
		for marker in MapManager.visible_markers(area):
			_draw_marker(marker)
		if MapManager.debug_enabled() and MapManager.debug_markers:
			for marker in MapManager.debug_registered():
				if marker.area == area.area_id and marker.floor == area.floor_id:
					draw_circle(map_to_screen(marker.position), 8.0, Color.MAGENTA, false, 1.0)
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), CharacterTheme.DIM, false, 1.0)
	draw_string(_font, Vector2(size.x - 23, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CharacterTheme.ACCENT)
	if follow_player:
		draw_string(_font, Vector2(12, 22), "LOCAL // %s" % MapManager.current_floor, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CharacterTheme.MUTED)
		draw_string(_font, Vector2(12, size.y - 12), "[M] MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CharacterTheme.TEXT)

func _draw_terrain() -> void:
	var first := area.cell_at(screen_to_map(Vector2.ZERO))
	var last := area.cell_at(screen_to_map(size))
	var max_chunk := Vector2i((area.dimensions.x - 1) / 16, (area.dimensions.y - 1) / 16)
	var start := Vector2i(floori(float(first.x) / 16), floori(float(first.y) / 16)).max(Vector2i.ZERO)
	var finish := Vector2i(floori(float(last.x) / 16), floori(float(last.y) / 16)).min(max_chunk)
	for y in range(start.y, finish.y + 1):
		for x in range(start.x, finish.x + 1):
			var chunk := Vector2i(x, y)
			var texture := MapManager.chunk_texture(area, chunk)
			if texture != null:
				var position := area.origin + Vector2(chunk * 16) * area.cell_size
				draw_texture_rect(texture, Rect2(map_to_screen(position), Vector2.ONE * 16 * area.cell_size * zoom), false)
	if MapManager.debug_enabled() and MapManager.debug_grid and zoom * area.cell_size >= 4.0:
		for y in range(maxi(0, first.y), mini(area.dimensions.y, last.y + 1)):
			for x in range(maxi(0, first.x), mini(area.dimensions.x, last.x + 1)):
				var pos := area.origin + Vector2(x, y) * area.cell_size
				draw_rect(Rect2(map_to_screen(pos), Vector2.ONE * area.cell_size * zoom), Color(0.5, 0.7, 0.7, 0.25), false)

func _draw_marker(marker: Dictionary) -> void:
	var point := map_to_screen(marker.position)
	if not Rect2(Vector2.ONE * 8, size - Vector2.ONE * 16).has_point(point):
		return
	var color := CharacterTheme.ACCENT
	match marker.kind:
		"PLAYER":
			var angle: float = -marker.get("rotation", 0.0)
			var points := PackedVector2Array()
			for offset in [Vector2(0, -8), Vector2(5, 6), Vector2(0, 3), Vector2(-5, 6)]:
				points.append(point + offset.rotated(angle))
			draw_circle(point, 11, Color("0b1217"))
			draw_colored_polygon(points, CharacterTheme.TEXT)
		"SAVEPOINT":
			draw_rect(Rect2(point - Vector2.ONE * 5, Vector2.ONE * 10), Color("0b1217"))
			draw_rect(Rect2(point - Vector2.ONE * 5, Vector2.ONE * 10), CharacterTheme.ACCENT, false, 2)
			draw_line(point - Vector2(3, 0), point + Vector2(3, 0), color, 1.5)
			draw_line(point - Vector2(0, 3), point + Vector2(0, 3), color, 1.5)
		"LOCATION":
			if follow_player:
				return
			draw_circle(point, 2, CharacterTheme.MUTED)
		"ENEMY":
			color = CharacterTheme.ERROR
			draw_circle(point, 4, color)
		_:
			draw_circle(point, 4, color)
	if not follow_player and marker.kind != "PLAYER":
		draw_string(_font, point + Vector2(10, -8), marker.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
