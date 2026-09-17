class_name MapUI
extends CanvasLayer
## Owns only map UI and its pause. Cannot acquire pause from another open menu.
var minimap: MapCanvas
var overlay: Control
var canvas: MapCanvas
var zones: OptionButton
var _zone_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)
	minimap = MapCanvas.new()
	minimap.name = "Minimap"
	minimap.position = Vector2(24, 24)
	minimap.size = Vector2(224, 224)
	root.add_child(minimap)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color("080e13")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	overlay.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	column.add_child(header)
	var title := CharacterTheme.label("WORLD MAP", 24, CharacterTheme.TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	zones = OptionButton.new()
	zones.item_selected.connect(_select_zone)
	header.add_child(zones)
	var recenter := Button.new()
	recenter.text = "RECENTER"
	recenter.pressed.connect(center_on_player)
	header.add_child(recenter)
	var close_button := Button.new()
	close_button.text = "CLOSE [M / ESC]"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	canvas = MapCanvas.new()
	canvas.follow_player = false
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(canvas)
	column.add_child(CharacterTheme.label("DRAG TO PAN  /  SCROLL TO ZOOM     ·     ◇ LOCATION   + SAVEPOINT   ▲ YOU     ·     UNEXPLORED SIGNAL HIDDEN", 13, CharacterTheme.MUTED, true))
	if MapManager.debug_enabled():
		_build_debug(column)
	overlay.hide()
	EventBus.blocking_menu_opened.connect(close)
	EventBus.scene_changed.connect(func(_id: String) -> void:
		if overlay.visible: close())

func _process(_delta: float) -> void:
	minimap.visible = not get_tree().paused and not SceneRouter.busy and is_instance_valid(SceneRouter.player) and not SceneRouter.current_id.is_empty()
	if canvas.dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		canvas.dragging = false

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if overlay.visible:
		if event.is_action_pressed("world_map") or event.is_action_pressed("menu"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action("character") or event.is_action("interact"):
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("world_map"):
		open()
		get_viewport().set_input_as_handled()

func open() -> bool:
	if get_tree().paused or SceneRouter.busy or SaveManager.busy or not is_instance_valid(SceneRouter.player) or SceneRouter.current_id.is_empty():
		return false
	SaveManager.end_manual_session()
	overlay.show()
	get_tree().paused = true
	_refresh_zones()
	center_on_player()
	return true

func close() -> void:
	if not overlay.visible:
		return
	overlay.hide()
	canvas.dragging = false
	get_tree().paused = false

func _refresh_zones() -> void:
	_zone_ids = MapManager.discovered_zones()
	var current := SceneRouter.current_id + ":" + MapManager.current_floor
	if not current in _zone_ids and MapCatalog.zone(current) != null:
		_zone_ids.append(current)
	zones.clear()
	for id in _zone_ids:
		var area := MapCatalog.zone(id)
		zones.add_item(MapCatalog.definitions()[area.area_id].title + " / " + area.definition.title)

func center_on_player() -> void:
	var area := MapCatalog.area(SceneRouter.current_id, MapManager.current_floor)
	if area == null:
		return
	var position := SceneRouter.player.global_position
	canvas.focus_area(area, Vector2(position.x, position.z))
	zones.select(_zone_ids.find(area.zone_id()))

func _select_zone(index: int) -> void:
	if index < 0 or index >= _zone_ids.size():
		return
	zones.select(index)
	var area := MapCatalog.zone(_zone_ids[index])
	if area.area_id == SceneRouter.current_id and area.floor_id == MapManager.current_floor:
		center_on_player()
		return
	# Center on discovered cells, not an unrevealed room or destination.
	var sum := Vector2.ZERO
	var count := 0
	for key in MapManager.zone_state(area).chunks:
		var parts: PackedStringArray = key.split(",")
		var origin := Vector2i(int(parts[0]), int(parts[1])) * 16
		for y in 16:
			for x in 16:
				var cell := origin + Vector2i(x, y)
				if MapManager.is_explored(area, cell):
					sum += area.cell_center(cell)
					count += 1
	canvas.focus_area(area, sum / maxf(1, count))

func _build_debug(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	for title in ["DEV: REVEAL CURRENT", "CLEAR EXPLORATION", "GRID", "REGISTERED MARKERS"]:
		var button := Button.new()
		button.text = title
		row.add_child(button)
	row.get_child(0).pressed.connect(func() -> void: MapManager.debug_reveal(); _refresh_zones())
	row.get_child(1).pressed.connect(func() -> void: MapManager.debug_clear(); _refresh_zones(); center_on_player())
	row.get_child(2).pressed.connect(func() -> void: MapManager.debug_grid = not MapManager.debug_grid)
	row.get_child(3).pressed.connect(func() -> void: MapManager.debug_markers = not MapManager.debug_markers; print(MapManager.debug_registered()))
