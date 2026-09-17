extends Node
## SubViewport renders exact target pixels with engine-managed 2D stretching. Native fullscreen is checked separately.
var failures := 0
var checks := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL  " + label)
	else:
		print("PASS  " + label)

func settle() -> void:
	for i in 15:
		await get_tree().process_frame

func run() -> void:
	var root := get_tree().root
	var visual := DisplayServer.get_name() != "headless"
	check(ProjectSettings.get_setting("display/window/size/mode") == Window.MODE_FULLSCREEN, "Fullscreen configured before window creation")
	if visual:
		check(root.mode == Window.MODE_FULLSCREEN, "Native window starts fullscreen")
		print("Native desktop: ", DisplayServer.screen_get_size())
		for mode in [Window.MODE_WINDOWED, Window.MODE_MAXIMIZED]:
			root.mode = mode
			await settle()
			check(root.mode == Window.MODE_FULLSCREEN, "External mode change restored to fullscreen")
	for code in [KEY_ENTER, KEY_KP_ENTER, KEY_F11]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.alt_pressed = code != KEY_F11
		event.pressed = true
		check(DisplayPolicy.is_fullscreen_shortcut(event), "Fullscreen shortcut consumed: " + str(code))
		root.push_input(event)
	SaveManager.store = SaveStore.new("user://regression_fullscreen_unused")
	var surface := SubViewport.new()
	surface.own_world_3d = true
	surface.size_2d_override_stretch = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(surface)
	var game := preload("res://core/game.tscn").instantiate()
	surface.add_child(game)
	for startup in game.get_children():
		if startup is StartScreen:
			for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]:
				surface.size = resolution
				surface.size_2d_override = Vector2i(roundi(maxf(1600,900*Vector2(resolution).aspect())),roundi(maxf(900,1600/Vector2(resolution).aspect())))
				for screen in ["main","settings","load"]:
					match screen:
						"main": startup._show_main()
						"settings": startup._show_settings()
						"load": startup._show_load()
					await settle()
					check(surface.get_visible_rect().encloses(startup.main_panel.get_global_rect()),"Start " + screen + " fits " + str(resolution))
					if visual:
						await RenderingServer.frame_post_draw
						surface.get_texture().get_image().save_png("res://tests/output/lost_%s_%dx%d.png" % [screen,resolution.x,resolution.y])
			await startup._new_game()
	await settle()
	var menu: SaveLoadMenu
	for child in game.get_children():
		if child is SaveLoadMenu:
			menu = child
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(3840,2160), Vector2i(1280,1024), Vector2i(3440,1440)]:
		surface.size = resolution
		surface.size_2d_override = Vector2i(roundi(maxf(1600,900*Vector2(resolution).aspect())),roundi(maxf(900,1600/Vector2(resolution).aspect())))
		await settle()
		check(surface.size == resolution, "Exact render dimensions " + str(resolution))
		var rect := surface.get_visible_rect()
		surface.global_canvas_transform = Transform2D.IDENTITY
		check(rect.size.x >= 1439 and rect.size.y >= 899, "UI retains minimum design space " + str(resolution))
		var rig := SceneRouter.camera_rig as IsometricCameraRig
		var expected_size := rig.desired_size * maxf(1.0, 1.6 / rect.size.aspect())
		# Evaluate settled framing without depending on machine frame rate.
		rig._process(1.0)
		check(is_equal_approx(rig.camera.size, expected_size), "Camera retains baseline visibility " + str(resolution))
		if visual:
			await RenderingServer.frame_post_draw
			surface.get_texture().get_image().save_png("res://tests/output/hud_%dx%d.png" % [resolution.x,resolution.y])
		menu.open(false)
		await settle()
		check(rect.encloses(menu.panel.get_global_rect()), "Save menu fits " + str(resolution))
		if visual:
			await RenderingServer.frame_post_draw
			surface.get_texture().get_image().save_png("res://tests/output/save_ui_%dx%d.png" % [resolution.x,resolution.y])
		for dialog in [menu.confirmation,menu.new_game_confirmation,menu.quit_confirmation]:
			dialog.popup_centered()
			await settle()
			check(dialog.theme.get_color("font_color","Button") == CharacterTheme.TEXT,"Dialog uses shared theme")
			check((root.get_visible_rect() if visual else rect).encloses(Rect2(Vector2(dialog.position),Vector2(dialog.size))),"Confirmation fits " + str(resolution))
			if visual and dialog == menu.confirmation:
				await RenderingServer.frame_post_draw
				surface.get_texture().get_image().save_png("res://tests/output/confirmation_%dx%d.png" % [resolution.x,resolution.y])
			dialog.hide()
		menu.open_character()
		await settle()
		if visual:
			root.mode = Window.MODE_WINDOWED
			await settle()
			surface.global_canvas_transform = Transform2D.IDENTITY
		check(rect.encloses(menu.character_panel.get_global_rect()), "Character menu fits " + str(resolution))
		if visual:
			await RenderingServer.frame_post_draw
			var capture := surface.get_texture().get_image()
			print("Capture size: ", capture.get_size(), " target: ", resolution)
			check(capture.get_size() == resolution, "Rendered image dimensions " + str(resolution))
			capture.save_png("res://tests/output/fullscreen_%dx%d.png" % [resolution.x,resolution.y])
			check(root.mode == Window.MODE_FULLSCREEN, "Fullscreen survives resolution change and paused UI " + str(resolution))
		menu.character_panel.select_tab("SKILLS")
		await settle()
		check(rect.encloses(menu.character_panel.get_global_rect()), "Skills menu fits " + str(resolution))
		for entry in menu.character_panel.skill_entries.values():
			check(menu.character_panel.get_global_rect().encloses(entry.get_global_rect()), "Skill row fits " + str(resolution))
		if visual:
			await RenderingServer.frame_post_draw
			surface.get_texture().get_image().save_png("res://tests/output/skills_%dx%d.png" % [resolution.x,resolution.y])
		menu.character_panel._toggle_progression()
		await settle()
		check(rect.encloses(menu.character_panel.get_global_rect()), "Attributes foldout fits " + str(resolution))
		menu.close()
	check(SceneRouter.current_id == "tenement", "Scene remains intact")
	check(Progression.snapshot() == ProgressionSchema.defaults(), "Display changes preserve progression")
	print("Fullscreen checks: %d; failures: %d" % [checks, failures])
	get_tree().quit(1 if failures else 0)





