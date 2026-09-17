extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS  ",message)
	else:
		failures += 1
		push_error("FAIL  "+message)
func tick() -> void:
	for i in 5: await get_tree().process_frame
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
	SaveManager.store = SaveStore.new("user://regression_character_unused")
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	for startup in game.get_children():
		if startup is StartScreen:
			await startup._new_game()
	await tick()
	var menu: SaveLoadMenu
	for child in game.get_children():
		if child is SaveLoadMenu: menu = child
	var original := Progression.snapshot().duplicate(true)
	await key(KEY_C)
	var panel := menu.character_panel
	check(menu.overlay.visible and get_tree().paused and panel.active_tab == "PLAYER","C opens PLAYER and pauses gameplay")
	check(panel.tabs.get_child_count() == 2,"Exactly two tabs")
	check(panel.sockets.size() == 9,"Nine equipment sockets")
	var preview_rect := panel.preview.get_global_rect()
	for id in ["head","chest","legs"]:
		check(panel.sockets[id].get_global_rect().end.x <= preview_rect.position.x,"Left socket "+id)
	for id in ["necklace","ring_1","ring_2","feet"]:
		check(panel.sockets[id].get_global_rect().position.x >= preview_rect.end.x,"Right socket "+id)
	for id in ["main_hand","off_hand"]:
		check(panel.sockets[id].get_global_rect().position.y >= preview_rect.end.y,"Hands below player "+id)
	check(panel.preview.viewport.find_world_3d() != SceneRouter.player.get_world_3d(),"Preview has isolated 3D world")
	check(panel.preview.model.get_script() == null,"Preview does not clone gameplay script")
	check(panel.preview.model.find_children("*","CollisionObject3D",true,false).is_empty(),"No gameplay collision in preview")
	var meshes := panel.preview.model.find_children("*","MeshInstance3D",true,false)
	var source_meshes: Array[Node] = SceneRouter.player.visual.find_children("*","MeshInstance3D",true,false)
	check(meshes.size() == source_meshes.size() and meshes.size() > 0,"Actual full current appearance copied")
	check(meshes[0].mesh == source_meshes[0].mesh,"Preview shares actual render asset")
	var live_transform: Transform3D = SceneRouter.player.visual.transform
	var before: float = panel.preview.model.rotation.y
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	panel.preview.gui_input.emit(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(80,0)
	panel.preview.gui_input.emit(motion)
	check(not is_equal_approx(before,panel.preview.model.rotation.y),"Drag rotates preview")
	check(SceneRouter.player.visual.transform == live_transform,"Preview rotation leaves live player intact")
	panel.skills_button.pressed.emit()
	await tick()
	check(panel.skills_tab.visible and not panel.player_tab.visible,"SKILLS replaces PLAYER content")
	check(panel.preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED and not panel.preview.dragging,"Hidden preview stops rendering and drag")
	check(panel.skill_entries.size() == 9 and panel.groups.get_child_count() == 4,"Nine skills in four groups")
	for entry in panel.skill_entries.values():
		check(entry.state_label.text == "UNAVAILABLE" and not entry.progress.visible and not entry.level_label.visible,"Unimplemented skill has no invented progress")
	panel.progression_toggle.pressed.emit()
	await tick()
	check(panel.progression_scroll.visible and not panel.groups.visible,"Existing attributes and professions accessible")
	check(panel.summary.text.contains("Level 0"),"Existing progression displays actual state")
	check(Progression.snapshot() == original,"Panel interactions do not mutate progression")
	await key(KEY_ESCAPE)
	check(not menu.overlay.visible and not get_tree().paused,"Escape closes and resumes")
	await key(KEY_C)
	check(panel.active_tab == "PLAYER" and not panel.progression_scroll.visible,"Reopening resets to PLAYER")
	await key(KEY_C)
	check(not menu.overlay.visible and not get_tree().paused,"C closes and resumes")
	check(panel.preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Closed preview stops rendering")
	if DisplayServer.get_name() != "headless":
		menu.open(false)
		menu.confirmation.popup_centered()
		await tick()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/shared_dialog_native.png")
		menu.close()
	print("Character UI checks: %d; failures: %d" % [checks,failures])
	get_tree().quit(1 if failures else 0)

