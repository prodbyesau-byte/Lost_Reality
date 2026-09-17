extends Node
var checks: int = 0
var failures: int = 0
var menu: SaveLoadMenu
var store: SaveStore
var events := {"levels": [], "unlocks": 0, "professions": 0}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func tick(count: int = 3) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func run() -> void:
	store = SaveStore.new("user://regression_progression_" + str(Time.get_ticks_usec()))
	SaveManager.store = store
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	for startup in game.get_children():
		if startup is StartScreen:
			await startup._new_game()
	await tick()
	for child in game.get_children():
		if child is SaveLoadMenu:
			menu = child
	EventBus.level_up.connect(func(level: int) -> void: events.levels.append(level))
	EventBus.progression_unlocked.connect(func() -> void: events.unlocks += 1)
	EventBus.profession_changed.connect(func(_previous: String, _selected: String) -> void: events.professions += 1)
	await test_start_and_ui()
	await test_progression()
	await test_persistence()
	await test_migration_and_corruption()
	await test_new_game_and_limits()
	if "--visual" in OS.get_cmdline_user_args():
		await SceneRouter.new_game()
		menu.open_character()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/character_level0.png")
		Progression.debug_award_xp(100)
		Progression.allocate_attribute("strength")
		Progression.select_profession("engineer")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/character_level1.png")
	menu.close()
	for filename in DirAccess.get_files_at(store.directory):
		DirAccess.remove_absolute(store.directory.path_join(filename))
	DirAccess.remove_absolute(store.directory)
	print("PROGRESSION RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func test_start_and_ui() -> void:
	check(Progression.snapshot() == ProgressionSchema.defaults(), "New launch starts at exact Level 0 defaults")
	for id in StatCatalog.NAMES:
		check(Progression.base_stat(id) == 0 and Progression.effective_stat(id) == 0, "%s starts with zero base and total" % id)
	check(Progression.snapshot().selected_profession == "", "No starting profession")
	check(not Progression.allocate_attribute("strength").ok, "Level 0 cannot allocate attributes")
	for id in ProfessionCatalog.definitions():
		check(not Progression.select_profession(id).ok, "%s cannot be selected at Level 0" % id)
		var definition: Dictionary = ProfessionCatalog.definitions()[id]
		check(definition.has("description") and definition.has("unlock_requirements") and definition.has("starting_bonuses") and definition.has("stat_modifiers") and definition.has("skill_modifiers"), "%s definition contains expansion fields" % id)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = true
	Input.parse_input_event(key)
	await tick()
	check(menu.overlay.visible and menu.character_view and get_tree().paused, "C opens character UI in existing pause menu")
	key = InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = false
	Input.parse_input_event(key)
	for button in menu.character_panel.allocation_buttons.values():
		check(button.disabled, "Level 0 allocation button disabled")
	for button in menu.character_panel.profession_buttons.values():
		check(button.disabled, "Level 0 profession button disabled")
	check(menu.character_panel.summary.text.contains("Level 0") and menu.character_panel.summary.text.contains("100"), "UI displays initial level and next XP requirement")
	check(not SaveManager.authorized(), "Character UI never grants manual save permission")
	var start_position: Vector3 = SceneRouter.player.position
	Input.action_press("move_up")
	await tick(10)
	Input.action_release("move_up")
	check(SceneRouter.player.position == start_position, "Character menu pauses player movement")
	menu.close()
	check(not get_tree().paused, "Closing character UI resumes game")

func test_progression() -> void:
	check(not Progression.award_xp(0).ok and not Progression.award_xp(-1).ok, "Nonpositive XP awards rejected")
	check(not Progression.award_xp(1000000001).ok, "Unbounded XP awards rejected")
	check(Progression.award_xp(99).ok, "XP can be earned before Level 1")
	check(Progression.snapshot().level == 0 and Progression.snapshot().xp == 99 and events.levels.is_empty(), "XP below boundary does not level up")
	check(Progression.award_xp(1).ok, "Exact XP threshold accepted")
	var state := Progression.snapshot()
	check(state.level == 1 and state.xp == 0 and state.attribute_points == 3, "Level 1 grants first 3 points exactly once")
	check(events.levels == [1] and events.unlocks == 1, "Level 1 emits level-up and progression-unlocked events once")
	check(state.selected_profession == "", "Level-up never automatically selects a profession")
	check(state.stats == StatCatalog.zero_stats(), "Level-up leaves base stats zero until allocated")
	for id in state.profession_unlocks:
		check(state.profession_unlocks[id], "%s unlocks at Level 1" % id)
	menu.open_character()
	check(not menu.character_panel.allocation_buttons.strength.disabled and not menu.character_panel.profession_buttons.engineer.disabled, "Level 1 UI enables attributes and professions")
	menu.character_panel.allocation_buttons.strength.pressed.emit()
	check(Progression.base_stat("strength") == 1 and Progression.snapshot().attribute_points == 2, "UI button spends exactly one attribute point")
	check(not Progression.allocate_attribute("not_a_stat").ok, "Unknown stat rejected")
	check(Progression.allocate_attribute("fitness").ok and Progression.allocate_attribute("perception").ok, "Remaining points allocate independently")
	check(not Progression.allocate_attribute("strength").ok, "Overspending attributes rejected")
	check(menu.character_panel.allocation_buttons.strength.disabled, "UI disables allocation at zero points")
	menu.character_panel.profession_buttons.engineer.pressed.emit()
	check(Progression.snapshot().selected_profession == "engineer", "UI activates Engineer")
	check(Progression.base_stat("intelligence") == 0 and Progression.effective_stat("intelligence") == 1 and Progression.effective_stat("dexterity") == 1, "Starting bonus and modifier are separate from base stats")
	check(not Progression.select_profession("engineer").ok, "Repeated profession selection is a no-op")
	check(not Progression.select_profession("missing").ok, "Unknown profession rejected")
	check(Progression.select_profession("police_officer").ok, "Unlocked profession can replace active profession")
	check(Progression.effective_stat("intelligence") == 0 and Progression.effective_stat("perception") == 2, "Switching removes prior bonuses and adds only current bonuses")
	check(Progression.select_profession("paramedic").ok, "Paramedic can be selected")
	check(Progression.effective_stat("fitness") == 2 and Progression.effective_stat("willpower") == 1, "Paramedic modifiers resolve correctly")
	check(Progression.select_profession("engineer").ok and Progression.effective_stat("intelligence") == 1 and Progression.snapshot().attribute_points == 0, "Repeated switches cannot farm points or bonuses")
	check(events.professions == 4, "Profession events fire only on changes")
	check(Progression.skill_modifiers().is_empty(), "Skill modifier contract available without implementing skills")
	var definition: Dictionary = ProfessionCatalog.definitions().engineer
	definition.unlock_requirements.base_stats = {"strength": 2}
	check(not ProfessionCatalog.eligible(definition, 1, Progression.snapshot().stats), "Data-driven stat unlock requirement enforced")
	check(ProfessionCatalog.eligible(definition, 1, {"strength": 2}), "Data-driven stat unlock requirement satisfied")
	check(not ProfessionCatalog.definitions().engineer.unlock_requirements.base_stats.has("strength"), "Definition callers cannot mutate catalog")
	menu.character_panel.debug_button.pressed.emit()
	check(Progression.snapshot().xp == 100, "Debug XP button works while paused")
	check(Progression.award_xp(267).ok, "Multi-level XP award accepted")
	check(Progression.snapshot().level == 3 and Progression.snapshot().xp == 17 and Progression.snapshot().attribute_points == 4, "XP carries across multiple thresholds and grants each reward")
	check(events.levels == [1, 2, 3] and events.unlocks == 1, "Each crossed level emits one event; unlock never repeats")
	check(SceneRouter.player.speed == 4.8, "Progression stats do not hardcode movement effects")
	menu.close()

func authorize() -> void:
	var point: WorldSavePoint
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if candidate is WorldSavePoint:
			point = candidate
	SceneRouter.player.position = point.position + Vector3(0, 0.01, 1.5)
	SceneRouter.player.reset_motion()
	await tick()
	check(SaveManager.begin_manual_session(point), "Progression saves use existing SavePoint authorization")

func test_persistence() -> void:
	# JSON represents numbers as floats; compare the canonical persisted representation.
	var expected: Dictionary = JSON.parse_string(JSON.stringify(Progression.snapshot()))
	for slot in SaveConstants.MANUAL_SLOTS:
		await authorize()
		check(SaveManager.save_manual(slot).ok, "Progression writes manual slot %d" % slot)
		menu.close()
		check(store.read_slot(slot).data.sections.progression == expected, "Manual slot %d persists all progression fields" % slot)
	await SceneRouter.travel("courtyard")
	check(store.read_slot(0).data.sections.progression == expected, "Transition autosave includes progression")
	var level_events: int = events.levels.size()
	for slot in SaveConstants.ALL_SLOTS:
		Progression.award_xp(10)
		menu.open(false)
		var result: Dictionary = await SaveManager.load_slot(slot)
		check(result.ok and Progression.snapshot() == expected, "Loading slot %d restores progression exactly" % slot)
		menu.close()
	check(events.levels.size() == level_events, "Loading never replays level-up rewards or events")
	check(Progression.effective_stat("intelligence") == 1, "Repeated loads never stack profession bonuses")
	await authorize()
	menu.open_character()
	check(not SaveManager.authorized(), "Switching from SavePoint to character revokes save capability")
	menu.close()

func test_migration_and_corruption() -> void:
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/milestone1_v2.json"))
	var migrated := SaveMigrator.migrate(legacy)
	check(migrated.ok and migrated.data.version == 3 and legacy.version == 2 and not legacy.sections.has("progression"), "Actual M1-shaped v2 fixture migrates without source mutation")
	check(migrated.data.sections.progression == ProgressionSchema.defaults(), "M1 migration adds zeroed Level 0 progression")
	check(migrated.data.player == legacy.player and migrated.data.metadata == legacy.metadata and migrated.data.sections.world == legacy.sections.world, "M1 migration preserves transform, metadata and world state")
	var v1 := legacy.duplicate(true)
	v1.version = 1
	v1.game_state = v1.sections
	v1.erase("sections")
	check(SaveMigrator.migrate(v1).data.sections.progression == ProgressionSchema.defaults(), "v1 to v2 to v3 migration chain works")
	_write(store.path_for(1), SaveSerializer.encode(legacy))
	var result: Dictionary = await SaveManager.load_slot(1)
	check(result.ok and Progression.snapshot() == ProgressionSchema.defaults() and SceneRouter.current_id == "tenement", "M1 save loads through full checksum/migration/scene pipeline")
	check(SceneRouter.player.position.distance_to(Vector3(-5, 0.01, 4)) < 0.01 and GameState.get_section("world").get("tenement/lamp", false), "M1 world and player placement restored")
	check(GameState.get_section("future_extension").get("preserve") == "untouched", "M1 unknown namespace preserved")
	var valid := migrated.data as Dictionary
	var malformed: Array[Dictionary] = []
	var bad := ProgressionSchema.defaults()
	bad.level = -1
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.level = 1.5
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.xp = 100
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.xp = "10"
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.xp = NAN
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.attribute_points = 100
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.stats.strength = 1
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.stats.erase("fitness")
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.selected_profession = "engineer"
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.profession_unlocks.engineer = true
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.profession_unlocks.engineer = 0
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.selected_profession = "unknown"
	malformed.append(bad)
	bad = ProgressionSchema.defaults()
	bad.level = ProgressionRules.maximum_level() + 1
	malformed.append(bad)
	for index in malformed.size():
		check(not ProgressionSchema.valid(malformed[index]), "Invalid progression schema case %d rejected" % index)
		check(not GameState.set_section("progression", malformed[index]), "Invalid runtime state case %d rejected" % index)
	var corrupted := valid.duplicate(true)
	corrupted.sections.progression = malformed[9]
	# No valid recovery artifacts for this isolated fixture slot.
	_write(store.path_for(1), SaveSerializer.encode(corrupted))
	var before := GameState.snapshot()
	var position: Vector3 = SceneRouter.player.position
	result = await SaveManager.load_slot(1)
	check(not result.ok and before == GameState.snapshot() and position == SceneRouter.player.position, "Invalid progression cannot partially apply state or scene")
	corrupted = valid.duplicate(true)
	corrupted.sections.erase("progression")
	check(not SaveValidator.validate(corrupted, 1).is_empty(), "v3 requires progression; missing data is not silently reset")
	_write(store.path_for(1), SaveSerializer.encode(legacy))
	await authorize()
	check(SaveManager.save_manual(1, store.revision(1)).ok, "Migrated M1 slot can be overwritten with confirmation")
	menu.close()
	check(store.read_slot(1).data.version == 3 and store.read_file(store.path_for(1) + ".bak", 1).ok, "Migrated overwrite retains valid recoverable previous data")

func test_new_game_and_limits() -> void:
	Progression.award_xp(100)
	Progression.allocate_attribute("strength")
	Progression.select_profession("engineer")
	GameState.set_section("world", {"tenement/lamp": true})
	GameState.total_playtime = 99
	await SceneRouter.travel("courtyard")
	var revisions := {}
	for slot in SaveConstants.ALL_SLOTS:
		revisions[slot] = store.revision(slot)
	menu.open(false)
	menu.new_game_confirmation.popup_centered()
	check(menu.new_game_confirmation.visible, "New Game has unsaved-progress confirmation")
	menu.new_game_confirmation.confirmed.emit()
	await tick()
	check(Progression.snapshot() == ProgressionSchema.defaults(), "Confirmed New Game resets every progression field")
	check(SceneRouter.current_id == "tenement" and GameState.get_section("world").is_empty() and GameState.total_playtime < 1, "New Game resets world, playtime and starting scene")
	check(not get_tree().paused and not menu.overlay.visible and not SaveManager.authorized(), "New Game resumes play without save authorization")
	for slot in SaveConstants.ALL_SLOTS:
		check(store.revision(slot) == revisions[slot], "New Game preserves existing slot %d" % slot)
	Progression.award_xp(1000000000)
	check(Progression.snapshot().level == 100 and Progression.snapshot().xp == 0 and Progression.snapshot().attribute_points == 201, "Large XP award terminates at configured level cap with correct budget")
	check(not Progression.award_xp(1).ok and ProgressionSchema.valid(Progression.snapshot()), "Level cap retains valid bounded data")
	await SceneRouter.new_game()
	check(Progression.snapshot() == ProgressionSchema.defaults(), "Repeated New Game never carries previous character data")

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

