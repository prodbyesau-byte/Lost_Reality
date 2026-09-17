extends Node
## Real scene-tree integration tests. Run in an isolated save directory.
var failures: int = 0
var checks: int = 0
var menu: SaveLoadMenu
var actor: PlayerActor
var store: SaveStore

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func tick(count: int = 2) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var restart := "--restart-seed" in args or "--restart-load" in args
	store = SaveStore.new("user://restart_regression" if restart else "user://regression_" + str(Time.get_ticks_usec()))
	SaveManager.store = store
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	for startup in game.get_children():
		if startup is StartScreen:
			await startup._new_game()
	await tick(4)
	actor = SceneRouter.player
	for child in game.get_children():
		if child is SaveLoadMenu:
			menu = child
	if restart:
		await _restart_test("--restart-seed" in args)
		_finish()
		return
	check(not SceneRouter.busy and SceneRouter.current_id == "tenement", "Project boots into tenement")
	check(SaveConstants.MANUAL_SLOTS == [1, 2, 3] and SaveConstants.ALL_SLOTS.size() == 4, "Exactly three manual and one autosave slot")
	check(actor.is_on_floor(), "Player grounded on 3D collision floor")
	await _movement_tests()
	await _interaction_tests()
	await _save_tests()
	await _transition_tests()
	if "--visual" in args:
		await SceneRouter.travel("tenement", "entry", false)
		await tick(30)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/gameplay.png")
		menu.open(false)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/menu.png")
		menu.close()
	_cleanup(store.directory)
	_finish()

func _movement_tests() -> void:
	var rig := actor.camera_rig
	check(rig.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera is orthographic")
	var up := rig.movement_direction(Vector2.UP)
	check(up.x < 0 and up.z < 0 and is_equal_approx(up.length(), 1.0), "Movement maps screen up to ground plane")
	check(is_equal_approx(rig.movement_direction(Vector2(1, -1).normalized()).length(), 1.0), "Diagonal movement has no speed bonus")
	for input in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var direction := rig.movement_direction(input.normalized())
		check(is_equal_approx(direction.length(), 1.0) and is_zero_approx(direction.y), "Grounded direction %s is normalized" % input)
	rig.adjust_zoom(-100)
	check(rig.desired_size == rig.minimum_size, "Zoom lower bound")
	rig.adjust_zoom(100)
	check(rig.desired_size == rig.maximum_size, "Zoom upper bound")
	rig.desired_size = 19
	actor.position = Vector3(5, 0.05, -6)
	actor.reset_motion()
	await tick()
	var start := actor.position
	Input.action_press("move_up")
	await tick(4)
	check(actor.velocity.length() > 0.5 and actor.velocity.length() < actor.speed, "Smooth acceleration")
	await tick(20)
	check(actor.position.distance_to(start) > 0.5, "Input drives physical movement")
	check(Vector2(actor.velocity.x, actor.velocity.z).length() <= actor.speed + 0.01, "Speed remains bounded")
	Input.action_release("move_up")
	await tick(20)
	check(Vector2(actor.velocity.x, actor.velocity.z).length() < 0.01, "Responsive deceleration to rest")
	check(rig.global_position.distance_to(actor.position + Vector3.UP * 0.8) < 0.3, "Camera smoothly converges on player")
	actor.position = Vector3(10.7, 0.05, 0)
	actor.reset_motion()
	Input.action_press("move_right")
	Input.action_press("move_down")
	await tick(70)
	Input.action_release("move_right")
	Input.action_release("move_down")
	check(actor.position.x < 11.55, "Boundary wall blocks sustained motion")
	await tick(20)
	actor.position = Vector3(5, 0.05, 5)
	actor.reset_motion()
	Input.action_press("move_up")
	Input.action_press("move_right")
	await tick(45)
	Input.action_release("move_up")
	Input.action_release("move_right")
	check(actor.position.z > 4.0, "Obstacle collision blocks movement")
	await tick(20)

func object_of_type(type: String) -> Interactable:
	for object in get_tree().get_nodes_in_group("interactables"):
		if (type == "save" and object is WorldSavePoint) or (type == "door" and object is WorldDoor) or (type == "lamp" and object is TestObject):
			return object
	return null

func _interaction_tests() -> void:
	var lamp := object_of_type("lamp") as TestObject
	actor.position = lamp.position + Vector3(0, 0.01, 1.4)
	actor.reset_motion()
	await tick(3)
	check(actor.interactor.can_interact(lamp), "Nearby object can be interacted with")
	var hud: GameHUD
	for node in get_parent().find_children("*","",true,false):
		if node is GameHUD: hud = node
	hud._update_interaction()
	check(hud.interaction.visible and hud.interaction.text == "E - Activate", "Nearby object supplies contextual action")
	var corner := hud.interaction.position + hud.interaction.size
	check(corner.distance_to(get_viewport().get_visible_rect().size - Vector2(32,32)) < 1.0, "Interaction prompt anchored bottom-right")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/player_interaction.png")
	lamp.interact(actor)
	check(GameState.get_section("world").get(lamp.persistent_id, false), "Test object changes persistent state")
	actor.position = Vector3(10, 0.01, 10)
	await tick()
	check(not actor.interactor.can_interact(lamp), "Out-of-range interaction rejected")
	hud._update_interaction()
	check(not hud.interaction.visible, "Interaction prompt hides out of range")
	# Put a solid wall between two nearby points to exercise LOS independently of range.
	actor.position = Vector3(0.8, 0.01, 1)
	var probe := Interactable.new()
	probe.position = Vector3(-0.8, 0, 1)
	SceneRouter.current_level.add_child(probe)
	await tick()
	check(not actor.interactor.can_interact(probe), "Interaction cannot pass through walls")
	probe.queue_free()
	var door := object_of_type("door") as WorldDoor
	actor.position = door.position + Vector3(0, 0.01, 1.5)
	actor.reset_motion()
	await tick()
	check(actor.interactor.can_interact(door), "Door is selectable")
	door.interact(actor)
	await tick()
	check(door.opened and door.collider.disabled, "Door opening disables collision")
	actor.position = door.position + Vector3(0, 0.01, 0)
	door.interact(actor)
	check(door.opened, "Door cannot close through player")
	actor.position = door.position + Vector3(0, 0.01, 1.5)
	door.interact(actor)
	await tick()
	check(not door.opened and not door.collider.disabled, "Door closing restores collision")
	# Exercise actual input dispatch, selection and menu routing as well as service APIs.
	var point := object_of_type("save")
	actor.position = point.position + Vector3(0, 0.01, 1.5)
	actor.reset_motion()
	await tick(3)
	check(actor.interactor.focused == point, "Nearest SavePoint receives focus")
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	Input.parse_input_event(press)
	await tick()
	check(menu.overlay.visible and menu.save_mode, "E key opens authorized SavePoint menu")
	press = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = false
	Input.parse_input_event(press)
	menu.close()

func authorize() -> void:
	var point := object_of_type("save")
	actor.position = point.position + Vector3(0, 0.01, 1.5)
	actor.reset_motion()
	await tick(3)
	check(SaveManager.begin_manual_session(point), "SavePoint authorizes a manual session")
	check(menu.overlay.visible and get_tree().paused, "SavePoint opens paused save menu")

func _save_tests() -> void:
	check(not SaveManager.save_manual(1).ok, "Manual saving outside SavePoint is denied")
	check(not SaveManager.begin_manual_session(object_of_type("lamp")), "Ordinary object cannot grant save authorization")
	for slot in SaveConstants.MANUAL_SLOTS:
		await authorize()
		check(SaveManager.save_manual(slot).ok, "Manual slot %d writes" % slot)
		check(not SaveManager.authorized(), "Successful save consumes authorization")
		menu.close()
		var loaded := store.read_slot(slot)
		check(loaded.ok and loaded.data.metadata.slot == slot, "Manual slot %d reads" % slot)
	await authorize()
	var before := store.revision(1)
	check(not SaveManager.save_manual(1).ok and store.revision(1) == before, "Unconfirmed overwrite preserves existing save")
	menu._request_save(1)
	check(menu.confirmation.visible, "Existing slot displays overwrite confirmation")
	menu.confirmation.hide()
	check(SaveManager.save_manual(1, before).ok, "Confirmed overwrite succeeds")
	menu.close()
	check(FileAccess.file_exists(store.path_for(1) + ".bak"), "Overwrite retains recovery backup")
	var payload := store.read_slot(1).data as Dictionary
	check(payload.metadata.timestamp > 0 and payload.metadata.playtime >= 0, "Timestamp and total playtime persisted")
	check(payload.player.position.size() == 3 and payload.player.rotation.size() == 3, "Full player transform persisted")
	# Pause menu offers load only, even immediately after a SavePoint session.
	menu.open(false)
	check(not menu.save_mode and not SaveManager.authorized(), "Pause menu cannot grant manual saving")
	menu.close()
	await authorize()
	actor.position = Vector3(10, 0.01, 10)
	check(not SaveManager.save_manual(2, store.revision(2)).ok, "Authorization rechecks distance at write time")
	menu.close()
	for slot in [-1, 4, 999]:
		check(not store.read_slot(slot).ok, "Invalid slot %d rejected" % slot)
	var encoded := SaveSerializer.encode(payload)
	check(not SaveSerializer.decode(encoded.replace("haunted", "broken")).ok, "Unknown envelope rejected")
	var envelope: Dictionary = JSON.parse_string(encoded)
	envelope.payload += " "
	check(not SaveSerializer.decode(JSON.stringify(envelope)).ok, "Checksum detects payload tampering")
	check(not SaveSerializer.decode("{bad json").ok, "Truncated JSON rejected")
	var oversized_path := store.directory.path_join("oversized")
	_write_text(oversized_path, "x".repeat(SaveConstants.MAX_FILE_BYTES + 1))
	check(not store.read_file(oversized_path, 1).ok, "Oversized files rejected before parsing")
	var invalid := payload.duplicate(true)
	invalid.player.position = ["bad", 0, 0]
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Wrong transform types rejected")
	invalid = payload.duplicate(true)
	invalid.player.position = [NAN, 0, 0]
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Nonfinite transforms rejected")
	invalid = payload.duplicate(true)
	invalid.scene = "res://arbitrary.tscn"
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Unregistered scene rejected")
	invalid = payload.duplicate(true)
	invalid.player.position = [500, 0, 0]
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Out-of-bounds position rejected")
	invalid = payload.duplicate(true)
	invalid.metadata.playtime = -1
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Negative playtime rejected")
	invalid = payload.duplicate(true)
	invalid.sections.world = {"lamp": "wrong"}
	check(not SaveValidator.validate(invalid, 1).is_empty(), "Malformed world state rejected")
	var old := payload.duplicate(true)
	old.version = 1
	old.game_state = old.sections
	old.erase("sections")
	var migrated := SaveMigrator.migrate(old)
	check(migrated.ok and migrated.data.version == SaveConstants.VERSION and old.version == 1, "Version 1 migration works without mutating source")
	_write_text(store.directory.path_join("legacy"), SaveSerializer.encode(old))
	check(store.read_file(store.directory.path_join("legacy"), 1).ok, "Legacy envelope passes complete read/migrate/validate pipeline")
	var future := payload.duplicate(true)
	future.version = 999
	check(not SaveMigrator.migrate(future).ok, "Future versions rejected safely")
	check(GameState.set_section("extension_test", {"nested": {"array": [1, "value", true]}}), "Future namespaces accept JSON data")
	check(not GameState.set_section("bad", {"object": actor}), "Runtime objects cannot enter persistent state")
	GameState.register_section("extension_test", func(value: Variant) -> bool: return value is Dictionary and value.has("nested"))
	check(not GameState.validate_sections({"extension_test": {}}).is_empty(), "Future systems can register validation")
	# Recovery and failed-load transactionality.
	_write_text(store.path_for(1), "corrupted")
	var recovered := store.read_slot(1)
	check(recovered.ok and recovered.recovered, "Corrupt primary recovers valid backup")
	check(store.write_slot(1, payload).ok, "Saving after recovery preserves a valid backup")
	check(store.read_file(store.path_for(1) + ".bak", 1).ok, "Corrupt primary never replaces valid backup")
	_write_text(store.path_for(1), "bad")
	_write_text(store.path_for(1) + ".bak", "bad")
	var original_position := actor.position
	var original_state := GameState.snapshot()
	var failed: Dictionary = await SaveManager.load_slot(1)
	check(not failed.ok and actor.position == original_position and GameState.snapshot() == original_state, "Unrecoverable load leaves running game unchanged")
	_write_text(store.path_for(1) + ".tmp", SaveSerializer.encode(payload))
	check(store.read_slot(1).ok and store.read_slot(1).recovered, "Interrupted first commit recovers verified temporary file")
	_write_text(store.path_for(1), SaveSerializer.encode(future))
	check(not store.read_slot(1).ok and store.read_slot(1).get("future", false), "Newer primary never silently falls back to older progress")
	check(not store.write_slot(1, payload).ok, "Newer save cannot be overwritten by older game")
	_write_text(store.path_for(1), SaveSerializer.encode(payload))
	var blocked := payload.duplicate(true)
	blocked.player.position = [5, 0, 3]
	_write_text(store.path_for(1), SaveSerializer.encode(blocked))
	failed = await SaveManager.load_slot(1)
	check(not failed.ok and actor.position == original_position and GameState.snapshot() == original_state, "Position inside obstacle fails before applying loaded state")
	_write_text(store.path_for(1), SaveSerializer.encode(payload))
	# A path that is a file simulates an unwritable save directory.
	_write_text(store.directory.path_join("not_a_directory"), "occupied")
	var inaccessible := SaveStore.new(store.directory.path_join("not_a_directory"))
	check(not inaccessible.write_slot(1, payload).ok, "Filesystem failure is reported without crashing")
	await authorize()
	var stale_revision := store.revision(2)
	var changed := payload.duplicate(true)
	changed.metadata.slot = 2
	changed.metadata.timestamp += 1
	check(store.write_slot(2, changed).ok, "External revision fixture writes")
	check(not SaveManager.save_manual(2, stale_revision).ok, "Stale overwrite confirmation is rejected")
	menu.close()

func _transition_tests() -> void:
	var original := SceneRouter.current_level
	var invalid: Dictionary = await SceneRouter.travel("missing")
	check(not invalid.ok and SceneRouter.current_level == original, "Unknown destination leaves scene intact")
	invalid = await SceneRouter.travel("courtyard", "missing")
	check(not invalid.ok and SceneRouter.current_level == original, "Missing entrance leaves scene intact")
	var result: Dictionary = await SceneRouter.travel("courtyard")
	check(result.ok and SceneRouter.current_id == "courtyard", "Cross-scene transition succeeds")
	check(actor.velocity == Vector3.ZERO, "Transition clears movement velocity")
	check(store.read_slot(0).ok and store.read_slot(0).data.scene == "courtyard", "Transition autosaves destination scene")
	var auto_revision := store.revision(0)
	await authorize()
	actor.rotation.y = 1.2
	GameState.total_playtime = 123.5
	var position := actor.position
	check(SaveManager.save_manual(3, store.revision(3)).ok, "Save records second level")
	menu.close()
	await SceneRouter.travel("tenement", "entry", false)
	GameState.reset()
	menu.open(false)
	result = await SaveManager.load_slot(3)
	check(result.ok and SceneRouter.current_id == "courtyard", "Load restores correct scene while menu paused")
	check(actor.position.distance_to(position) < 0.01 and absf(actor.rotation.y - 1.2) < 0.001, "Load restores position and rotation exactly")
	check(absf(GameState.total_playtime - 123.5) < 0.1, "Load restores total playtime")
	check(GameState.get_section("extension_test").has("nested"), "Unknown extension section survives save/load")
	check(store.revision(0) == auto_revision, "Loading never overwrites autosave")
	menu.close()
	await SceneRouter.travel("tenement", "entry", false)
	check(GameState.get_section("world").get("tenement/lamp", false), "World state survives scene transitions and save/load")
	result = await SaveManager.load_slot(0)
	check(result.ok and SceneRouter.current_id == "courtyard", "Autosave slot loads correctly")
	await tick()

func _restart_test(seed: bool) -> void:
	if seed:
		await SceneRouter.travel("courtyard", "entry", false)
		await authorize()
		actor.rotation.y = 0.75
		GameState.total_playtime = 456.0
		GameState.set_section("restart_probe", {"marker": "survives process exit"})
		Progression.award_xp(123)
		Progression.allocate_attribute("intelligence")
		Progression.select_profession("engineer")
		check(SaveManager.save_manual(2, store.revision(2)).ok, "Restart fixture saved through authorized SavePoint")
		menu.close()
	else:
		check(SceneRouter.current_id == "tenement" and GameState.get_section("restart_probe").is_empty(), "Fresh process starts without runtime fixture state")
		var result: Dictionary = await SaveManager.load_slot(2)
		check(result.ok and SceneRouter.current_id == "courtyard", "Fresh process restores saved scene")
		check(actor.position.distance_to(Vector3(-9, 0, 5.5)) < 0.03, "Fresh process restores saved position")
		check(absf(actor.rotation.y - 0.75) < 0.001, "Fresh process restores rotation")
		check(absf(GameState.total_playtime - 456.0) < 0.1, "Fresh process restores playtime")
		check(GameState.get_section("restart_probe").get("marker") == "survives process exit", "Fresh process restores persistent namespace")
		check(Progression.snapshot().level == 1 and Progression.snapshot().xp == 23 and Progression.snapshot().attribute_points == 2, "Fresh process restores level, XP and attribute points")
		check(Progression.base_stat("intelligence") == 1 and Progression.effective_stat("intelligence") == 2 and Progression.snapshot().selected_profession == "engineer", "Fresh process restores stats and active profession without duplicate bonuses")
		_cleanup(store.directory)

func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func _cleanup(directory: String) -> void:
	assert(directory.begins_with("user://regression_") or directory == "user://restart_regression")
	for filename in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)

func _finish() -> void:
	get_tree().paused = false
	print("REGRESSION RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)



