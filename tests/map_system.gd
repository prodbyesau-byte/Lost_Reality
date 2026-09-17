extends Node
## End-to-end map tests, including fresh-process persistence. Never touches user saves.
var failures := 0
var checks := 0
var game: Node
var ui: MapUI
var menu: SaveLoadMenu
var actor: PlayerActor
var store: SaveStore

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS  ", message)
	else:
		failures += 1
		push_error("FAIL  " + message)

func tick(count: int = 3) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await tick()
	event = InputEventKey.new()
	event.physical_keycode = code
	Input.parse_input_event(event)
	await tick()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var restarting := "--map-restart-seed" in args or "--map-restart-load" in args
	store = SaveStore.new("user://map_restart_regression" if restarting else "user://map_regression_" + str(Time.get_ticks_usec()))
	SaveManager.store = store
	game = preload("res://core/game.tscn").instantiate()
	add_child(game)
	var start: StartScreen
	for child in game.get_children():
		if child is MapUI: ui = child
		if child is SaveLoadMenu: menu = child
		if child is StartScreen: start = child
	await key(KEY_M)
	check(not ui.overlay.visible and start.overlay.visible and get_tree().paused, "M cannot steal pause from start screen")
	await start._new_game()
	actor = SceneRouter.player
	if restarting:
		await restart_test("--map-restart-seed" in args)
	else:
		await exploration_tests()
		await marker_tests()
		await input_tests()
		await persistence_tests()
		await migration_tests()
		await resolution_tests()
		if MapManager.debug_enabled():
			check(MapManager.debug_reveal(), "Explicit development flag enables reveal")
			check(discovered_count(MapCatalog.area(SceneRouter.current_id)) == 3136, "Development reveal covers only current floor")
			check(MapManager.debug_clear() and GameState.get_section("exploration") == ExplorationSchema.defaults(), "Development clear resets all exploration")
		else:
			check(not MapManager.debug_reveal() and not MapManager.debug_clear() and MapManager.debug_registered().is_empty(), "Debug commands disabled in normal gameplay")
	print("MAP RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func discovered_count(area: MapAreaData) -> int:
	var count := 0
	for y in area.dimensions.y:
		for x in area.dimensions.x:
			if MapManager.is_explored(area, Vector2i(x, y)): count += 1
	return count

func move_to(point: Vector3) -> void:
	actor.position = point
	actor.reset_motion()
	await tick(3)
	MapManager.reveal_near_player()

func exploration_tests() -> void:
	var area := MapCatalog.area("tenement")
	check(GameState.get_section("exploration") == ExplorationSchema.defaults(), "New Game begins with completely empty exploration")
	await tick(12)
	var initial := discovered_count(area)
	check(initial > 0 and initial < 400, "Spawn reveals only nearby terrain, not the scene")
	var chunks: Dictionary = MapManager.zone_state(area).chunks
	var first_key: String = chunks.keys()[0]
	var parts := first_key.split(",")
	var chunk := Vector2i(int(parts[0]), int(parts[1]))
	var texture := MapManager.chunk_texture(area, chunk)
	check(texture == MapManager.chunk_texture(area, chunk), "Unchanged terrain reuses its cached texture")
	var image := texture.get_image()
	var fog_matches := true
	for y in 16:
		for x in 16:
			fog_matches = fog_matches and (image.get_pixel(x, y).a > 0.0) == MapManager.is_explored(area, chunk * 16 + Vector2i(x, y))
	check(fog_matches, "Rendered texture has no opaque pixels in unexplored cells")
	check(ui.minimap.visible and ui.minimap.size == Vector2(224, 224), "Live square minimap exists during gameplay")
	check(not MapManager.is_explored(area, area.cell_at(Vector2(8, -9))), "Distant destination remains undiscovered")
	var retained := area.cell_at(Vector2(-5, 4))
	await move_to(Vector3(-5, 0.05, 8))
	check(discovered_count(area) > initial and MapManager.is_explored(area, retained), "Walking reveals progressively and keeps previous cells")
	var player_blip := find_marker(area, "player")
	check(player_blip.position.distance_to(Vector2(actor.position.x, actor.position.z)) < 0.001, "Player marker uses live world position")
	await tick()
	check(ui.minimap.map_to_screen(player_blip.position).distance_to(ui.minimap.size / 2) < 0.1, "Minimap remains centered on player without camera lag")
	await move_to(Vector3(-2, 0.05, 1))
	check(not MapManager.is_explored(area, area.cell_at(Vector2(2, 1))), "Exploration cannot see through full-height cutaway collision wall")
	await move_to(Vector3(-4.1, 0.05, -0.7))
	check(not MapManager.is_explored(area, area.cell_at(Vector2(-4.1, -3.5))), "Closed door blocks exploration")
	var door: WorldDoor
	for child in SceneRouter.current_level.get_children():
		if child is WorldDoor: door = child
	door.interact(actor)
	await tick(12)
	check(MapManager.is_explored(area, area.cell_at(Vector2(-4.1, -3.5))), "Opening a door progressively reveals the visible passage")
	check(MapManager.zone_state(area).pois.has("savepoint") and not MapManager.zone_state(area).pois.has("courtyard_exit"), "Only personally discovered POIs are persisted")
	if "--visual" in OS.get_cmdline_user_args():
		await move_to(Vector3(-5, 0.05, 4))
		await capture("map_minimap")

func find_marker(area: MapAreaData, id: String) -> Dictionary:
	for marker in MapManager.visible_markers(area):
		if marker.id == id: return marker
	return {}

func marker_tests() -> void:
	var area := MapCatalog.area("tenement")
	await move_to(Vector3(-2, 0.05, 1))
	var marker := MapTrackable.new()
	marker.area_id = "tenement"
	marker.marker_id = "test_enemy"
	marker.title = "TEST ONLY"
	marker.category = MapTrackable.Category.ENEMY
	marker.position = Vector3(-3, 0, 1)
	SceneRouter.current_level.add_child(marker)
	await tick()
	check(not find_marker(area, "test_enemy").is_empty(), "Dynamic component registers and is visible within sight")
	marker.position.x = -3.5
	await tick()
	check(find_marker(area, "test_enemy").position.x == -3.5, "Moving blip updates live without rediscovery")
	marker.position = Vector3(2, 0, 1)
	check(find_marker(area, "test_enemy").is_empty(), "Teleport between physics ticks cannot leak a blip across fog or walls")
	await tick()
	check(find_marker(area, "test_enemy").is_empty(), "Enemy behind wall is hidden")
	# Explore the other side, then return: discovery alone must never reveal an enemy.
	await move_to(Vector3(2, 0.05, 1))
	await move_to(Vector3(-2, 0.05, 1))
	await tick()
	check(MapManager.is_explored(area, area.cell_at(Vector2(2, 1))) and find_marker(area, "test_enemy").is_empty(), "Explored terrain does not bypass live line-of-sight rules")
	marker.position = Vector3(-3, 0, 1)
	marker.floor_id = "1"
	await tick()
	check(find_marker(area, "test_enemy").is_empty(), "Markers on other floors are hidden")
	marker.floor_id = "0"
	marker.enabled = false
	await tick()
	check(find_marker(area, "test_enemy").is_empty(), "Disabled markers stay hidden")
	marker.enabled = true
	marker.position = Vector3(-10, 0, 10)
	await tick()
	check(find_marker(area, "test_enemy").is_empty(), "Out-of-sight moving entities are hidden")
	var registered := MapManager._markers.size()
	marker.queue_free()
	await tick()
	check(MapManager._markers.size() == registered - 1, "Freed components unregister without dangling references")
	check(MapCatalog.floor_at("tenement", 0.05) == "0" and MapCatalog.area("tenement", "1") == null, "Only authored floors exist")

func input_tests() -> void:
	await key(KEY_M)
	check(ui.overlay.visible and get_tree().paused and not menu.overlay.visible, "M opens world map and exclusively pauses gameplay")
	check(ui.canvas.area == ui.minimap.area, "Both maps use the same area and exploration")
	check(ui.canvas.center.distance_to(Vector2(actor.position.x, actor.position.z)) < 0.01, "World map opens centered on player")
	var before := actor.position
	await key(KEY_W)
	check(actor.position == before, "Gameplay does not move while map is open")
	await key(KEY_C)
	check(ui.overlay.visible and not menu.overlay.visible, "Character input cannot open over map")
	var start_center := ui.canvas.center
	var drag := InputEventMouseButton.new()
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = true
	ui.canvas._gui_input(drag)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 60)
	ui.canvas._gui_input(motion)
	await tick(10)
	check(ui.canvas.center.distance_to(start_center) > 1, "Drag pans the map smoothly")
	var zoom := ui.canvas.zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	ui.canvas._gui_input(wheel)
	await tick(10)
	check(ui.canvas.zoom > zoom and ui.canvas.zoom <= ui.canvas.target_zoom, "Mouse wheel zoom interpolates toward target")
	ui.center_on_player()
	if "--visual" in OS.get_cmdline_user_args(): await capture("map_world")
	await key(KEY_ESCAPE)
	check(not ui.overlay.visible and not menu.overlay.visible and not get_tree().paused, "ESC closes map before normal pause menu")
	await key(KEY_ESCAPE)
	check(menu.overlay.visible and get_tree().paused, "Next ESC opens normal pause menu")
	await key(KEY_M)
	check(menu.overlay.visible and not ui.overlay.visible and get_tree().paused, "M cannot steal another menu's pause")
	menu.close()
	await key(KEY_M)
	await key(KEY_M)
	check(not ui.overlay.visible and not get_tree().paused, "M toggles map closed")
	ui.open()
	menu.open(false)
	check(not ui.overlay.visible and menu.overlay.visible and get_tree().paused, "System menu safely takes over map pause")
	menu.close()

func persistence_tests() -> void:
	await move_to(Vector3(-5, 0.05, 4))
	for slot in SaveConstants.MANUAL_SLOTS:
		for child in SceneRouter.current_level.get_children():
			if child is WorldSavePoint: SaveManager.begin_manual_session(child)
		check(SaveManager.save_manual(slot, store.revision(slot)).ok, "SavePoint-only manual slot %d saves exploration" % slot)
		menu.close()
	var expected: Dictionary = store.read_slot(1).data.sections.exploration
	await move_to(Vector3(-9, 0.05, 10))
	for slot in SaveConstants.MANUAL_SLOTS:
		var result: Dictionary = await SaveManager.load_slot(slot)
		check(result.ok and GameState.get_section("exploration") == store.read_slot(slot).data.sections.exploration, "Slot %d restores exact exploration before gameplay resumes" % slot)
	check(GameState.get_section("exploration").zones["tenement:0"].pois.has("savepoint"), "Discovered Savepoint survives load")
	var result: Dictionary = await SceneRouter.travel("courtyard", "entry", true)
	check(result.ok and store.read_slot(0).data.sections.exploration.zones["tenement:0"] == expected.zones["tenement:0"], "Transition autosave retains previous-area exploration")
	await tick(12)
	MapManager.reveal_near_player()
	check(MapManager.discovered_zones().size() == 2, "Scene transition reveals independently identified second area")
	var across := GameState.get_section("exploration")
	check(SaveManager.autosave_after_transition().ok and store.read_slot(0).data.sections.exploration == across, "Autosave persists both areas and POIs")
	ui.open()
	check(ui.zones.item_count == 2, "World map offers only visited areas and authored floors")
	ui._select_zone(ui._zone_ids.find("tenement:0"))
	check(ui.zones.get_item_text(ui.zones.selected).begins_with("The Tenement"), "Area selector label matches displayed unloaded area")
	check(ui.canvas.area.area_id == "tenement" and find_marker(ui.canvas.area, "savepoint").size() > 0, "Unloaded area retains discovered POIs on world map")
	check(find_marker(ui.canvas.area, "player").is_empty(), "Player does not leak onto a different area's map")
	if "--visual" in OS.get_cmdline_user_args(): await capture("map_previous_area")
	ui.close()
	result = await SaveManager.load_slot(0)
	check(result.ok and GameState.get_section("exploration") == across, "Autosave restores exploration exactly")
	result = await SceneRouter.new_game()
	check(result.ok and GameState.get_section("exploration") == ExplorationSchema.defaults(), "New Game clears every area, floor and POI")
	check(Progression.snapshot() == ProgressionSchema.defaults(), "New Game still has Level 0 and six zero base stats")
	check(store.read_slot(0).data.sections.exploration == across, "New Game does not overwrite autosave exploration")

func migration_tests() -> void:
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/milestone2_v3.json"))
	var original := legacy.duplicate(true)
	var migrated := SaveMigrator.migrate(legacy)
	check(migrated.ok and migrated.data.version == 4 and legacy == original, "v3 fixture migrates to v4 without mutating source")
	check(migrated.data.sections.exploration == ExplorationSchema.defaults() and migrated.data.sections.progression == legacy.sections.progression, "Migration adds empty exploration and preserves allocated profession state")
	check(SaveValidator.validate(migrated.data, 1).is_empty(), "Migrated v3 fixture passes pure save validation")
	var v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/milestone1_v2.json"))
	var v1 := v2.duplicate(true)
	v1.version = 1
	v1.game_state = v1.sections
	v1.erase("sections")
	for source in [v1, v2, legacy]:
		check(SaveMigrator.migrate(source).data.sections.exploration == ExplorationSchema.defaults(), "Sequential migration from v%d keeps map undiscovered" % source.version)
	var invalid: Array = [null, {}, {"zones": []}, {"zones": {"unknown:0": {"chunks": {}, "pois": {}}}}]
	for chunks in [{"0,0": "garbage"}, {"-1,0": "ff".repeat(32)}, {"0,0": "00".repeat(32)}, {"3,3": "ff".repeat(32)}, {"00,0": "ff".repeat(32)}]:
		invalid.append({"zones": {"tenement:0": {"chunks": chunks, "pois": {}}}})
	invalid.append({"zones": {"tenement:0": {"chunks": {}, "pois": {"savepoint": true}}}})
	invalid.append({"zones": {"tenement:0": {"chunks": {}, "pois": {"unknown": true}}}})
	for index in invalid.size():
		check(not ExplorationSchema.valid(invalid[index]), "Malformed exploration case %d rejected" % index)
	var bad: Dictionary = migrated.data.duplicate(true)
	bad.sections.exploration = invalid[-1]
	check(not SaveValidator.validate(bad, 1).is_empty(), "Malformed map rejected before applying any save state")
	var path := store.path_for(1)
	# A separate isolated store prevents an intentional bad fixture recovering a backup.
	var invalid_store := SaveStore.new(store.directory + "_invalid")
	DirAccess.make_dir_recursive_absolute(invalid_store.directory)
	var file := FileAccess.open(invalid_store.path_for(1), FileAccess.WRITE)
	file.store_string(SaveSerializer.encode(bad))
	file.close()
	var before := GameState.snapshot()
	var position := actor.position
	SaveManager.store = invalid_store
	var failed: Dictionary = await SaveManager.load_slot(1)
	check(not failed.ok and GameState.snapshot() == before and actor.position == position, "Bad exploration cannot partially change live player or state")
	file = FileAccess.open(invalid_store.path_for(1), FileAccess.WRITE)
	file.store_string(SaveSerializer.encode(legacy))
	file.close()
	var result: Dictionary = await SaveManager.load_slot(1)
	check(result.ok and GameState.get_section("exploration") == ExplorationSchema.defaults() and Progression.snapshot().selected_profession == "engineer", "Existing save loads through checksum, migration, validation and scene restore")
	SaveManager.store = store
	check(not path.begins_with("user://saves"), "All map test files remain isolated from real saves")

func resolution_tests() -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(2560, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var test_ui := MapUI.new()
		viewport.add_child(test_ui)
		await tick()
		check(test_ui.minimap.position == Vector2(24, 24) and test_ui.minimap.size.x == test_ui.minimap.size.y and test_ui.minimap.get_rect().end.x < dimensions.x, "Minimap stays square and top-left at %s" % dimensions)
		viewport.queue_free()
		await tick()

func restart_test(seed: bool) -> void:
	if seed:
		await tick(12)
		await move_to(Vector3(-5, 0.05, 8))
		var expected := GameState.get_section("exploration")
		check(SaveManager.autosave_after_transition().ok, "Fresh-process seed stores discovered cells and POIs")
		var file := FileAccess.open(store.directory.path_join("expected.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(expected))
		file.close()
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.directory.path_join("expected.json")))
		var result: Dictionary = await SaveManager.load_slot(0)
		check(result.ok and GameState.get_section("exploration") == expected, "Fresh process restores exact cells and discovered POIs")
		check(find_marker(MapCatalog.area("tenement"), "savepoint").size() > 0, "Fresh process rebuilds persistent POI presentation")

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await tick(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/output/" + name + ".png")
