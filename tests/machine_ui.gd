extends Node
var failures := 0
var checks := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS  ",message)
	else:
		failures += 1
		push_error("FAIL  "+message)
func settle() -> void:
	for i in 8: await get_tree().process_frame
func capture(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/lost_"+name+".png")
func run() -> void:
	SaveManager.store = SaveStore.new("user://regression_machine_unused")
	check(ProjectSettings.get_setting("application/config/name") == "Lost Reality","Visible application rebranded")
	check(OS.get_user_data_dir().replace("\\","/").ends_with("Godot/app_userdata/Haunted Dimension"),"Rebrand retains exact legacy save directory")
	check(SaveConstants.FORMAT == "haunted-dimension-save" and SaveConstants.VERSION == 3,"Save format remains compatible")
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	await settle()
	var start: StartScreen
	for child in game.get_children():
		if child is StartScreen: start = child
	check(start.overlay.visible and get_tree().paused,"Main menu starts active")
	await capture("main")
	start._show_settings()
	await capture("settings")
	var toggle: CheckButton
	for child in start.content.get_children():
		if child is CheckButton: toggle = child
	check(is_instance_valid(toggle),"Interference accessibility setting present")
	toggle.button_pressed = false
	check(not MachineInterference.enabled,"Interference can be disabled")
	var effect := MachineInterference.new()
	add_child(effect)
	effect.remaining = 0.1
	effect._process(0.02)
	check(effect.remaining == 0 and effect.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Disabled effect clears and never blocks input")
	toggle.button_pressed = true
	effect.cooldown = 0
	effect._process(0.01)
	check(effect.remaining > 0 and effect.remaining <= 0.12 and effect.cooldown >= 24,"Glitch is brief and rare")
	start._show_load()
	check(start.content.get_child_count() == 10,"Four save slots and back action preserved")
	await capture("load")
	start._show_main()
	await start._new_game()
	await settle()
	check(not start.overlay.visible and not get_tree().paused,"New game navigation preserved")
	check(Progression.snapshot() == ProgressionSchema.defaults(),"No invented RPG data")
	await capture("hud")
	var invalid := SaveSlotPresentation.text(1,{"ok":false,"error":"Checksum mismatch"},true)
	check(invalid.contains("UNAVAILABLE") and invalid.contains("Checksum mismatch"),"Invalid snapshot distinct from empty")
	check(SaveSlotPresentation.text(1,{"ok":false},false).contains("EMPTY"),"Empty snapshot distinct from invalid")
	print("Machine UI checks: %d; failures: %d" % [checks,failures])
	get_tree().quit(1 if failures else 0)
