extends Node
var failures := 0
var checks := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS  ",label)
	else:
		failures += 1
		push_error("FAIL  "+label)
func settle() -> void:
	for i in 6: await get_tree().process_frame
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event = InputEventKey.new()
	event.physical_keycode = code
	Input.parse_input_event(event)
	await settle()
func run() -> void:
	var store := SaveStore.new("user://regression_delete_"+str(Time.get_ticks_usec()))
	SaveManager.store = store
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	var menu: SaveLoadMenu
	var start: StartScreen
	var hud: GameHUD
	for child in game.get_children():
		if child is SaveLoadMenu: menu = child
		if child is StartScreen: start = child
		if child is GameHUD: hud = child
	await start._new_game()
	await settle()
	for label in hud.find_children("*","Label",true,false):
		check(not label.text.contains("LOST REALITY") and not label.text.contains("LEVEL 00") and not label.text.contains("TENEMENT"),"No permanent identity/progression HUD")
	await key(KEY_ESCAPE)
	check(menu.overlay.visible and get_tree().paused and not menu.rows.visible and not menu.slot_hint.visible,"ESC pauses without save UI")
	var titles: Array[String] = []
	for button in menu.actions.get_children(): titles.append(button.text)
	check(titles == ["RESUME","SETTINGS","QUIT GAME"],"Exactly three pause actions")
	menu.actions.get_child(1).pressed.emit()
	check(menu.settings_view and menu.settings.visible and get_tree().paused,"Settings opens paused")
	await key(KEY_ESCAPE)
	check(not menu.settings_view and menu.actions.visible and get_tree().paused,"ESC settings returns to pause")
	menu.actions.get_child(2).pressed.emit()
	check(menu.quit_confirmation.visible and menu.quit_confirmation.ok_button_text == "QUIT","Quit requires confirmation")
	menu.quit_confirmation.hide()
	await key(KEY_ESCAPE)
	check(not menu.overlay.visible and not get_tree().paused,"ESC pause resumes")
	for slot in SaveConstants.ALL_SLOTS:
		check(store.write_slot(slot,SaveManager.capture(slot)).ok,"Seed isolated slot "+str(slot))
		check(store.write_slot(slot,SaveManager.capture(slot)).ok,"Seed recovery copy "+str(slot))
	var other := store.deletion_revision(2)
	var point: WorldSavePoint
	var door: WorldDoor
	for object in get_tree().get_nodes_in_group("interactables"):
		if object is WorldSavePoint: point = object
		if object is WorldDoor: door = object
	check(door.prompt() == "Open Door","Door contextual prompt")
	check(point.prompt() == "Use Savepoint","Savepoint contextual prompt")
	SceneRouter.player.global_position = point.global_position + Vector3(0,0.01,1.5)
	SceneRouter.player.reset_motion()
	await settle()
	check(SaveManager.begin_manual_session(point) and menu.rows.visible,"Savepoint still opens save workflow")
	var revision := store.deletion_revision(1)
	menu.delete_dialog.request(1)
	check(menu.delete_dialog.visible,"Delete opens confirmation")
	menu.delete_dialog.canceled.emit()
	menu.delete_dialog.hide()
	check(store.deletion_revision(1) == revision,"Cancel preserves all files")
	menu.delete_dialog.request(1)
	var modified := SaveManager.capture(1)
	modified.metadata.timestamp += 1
	store.write_slot(1,modified)
	menu.delete_dialog.confirmed.emit()
	check(store.exists(1),"Stale confirmation cannot delete changed save")
	for suffix in [".tmp",".bak.tmp"]:
		DirAccess.copy_absolute(store.path_for(1),store.path_for(1)+suffix)
	menu.delete_dialog.request(1)
	menu.delete_dialog.confirmed.emit()
	check(not store.exists(1) and store.deletion_revision(1).is_empty() and not store.read_slot(1).ok,"Confirmed delete removes primary and recovery; no resurrection")
	check(store.deletion_revision(2) == other,"Other slots unchanged")
	check(menu.rows.get_child(0).get_child(0).text.contains("EMPTY") and menu.rows.get_child(0).get_child(1).disabled,"Savepoint row refreshes immediately and cannot load empty")
	check(not SaveManager.delete_slot(-1,"x").ok,"Invalid slot deletion rejected")
	menu.close()
	start._show_load()
	start.overlay.show()
	get_tree().paused = true
	var auto_revision := store.deletion_revision(0)
	start.delete_dialog.request(0)
	start.delete_dialog.confirmed.emit()
	check(not auto_revision.is_empty() and not store.exists(0),"Autosave deletion supported")
	var auto_row := start.content.get_child(9-1)
	check(auto_row is HBoxContainer,"Load menu rows preserved")
	check(not store.read_slot(0).ok,"Deleted autosave not loadable")
	if DisplayServer.get_name() != "headless":
		await settle()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/delete_load.png")
	start.overlay.hide()
	get_tree().paused = false
	check(SaveManager.autosave_after_transition().ok,"Future autosaves still work")
	var file := FileAccess.open(store.path_for(3),FileAccess.WRITE)
	file.store_string("corrupted")
	file.close()
	check(SaveManager.delete_slot(3,store.deletion_revision(3)).ok and not store.exists(3),"Corrupted primary and valid backup deleted together")
	for slot in SaveConstants.ALL_SLOTS:
		var token := store.deletion_revision(slot)
		if not token.is_empty(): store.delete_slot(slot,token)
	DirAccess.remove_absolute(store.directory)
	print("Pause/delete checks: %d; failures: %d" % [checks,failures])
	get_tree().quit(1 if failures else 0)

