extends Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_configure_input()
	var host := Node3D.new()
	host.name = "LevelHost"
	add_child(host)
	var player := preload("res://actors/player/player.tscn").instantiate() as PlayerActor
	add_child(player)
	var camera := IsometricCameraRig.new()
	camera.name = "CameraRig"
	add_child(camera)
	camera.target = player
	player.camera_rig = camera
	SceneRouter.configure(host, player, camera)
	add_child(ArtOverlay.new())
	var hud := GameHUD.new()
	add_child(hud)
	var menu := SaveLoadMenu.new()
	add_child(menu)
	await SceneRouter.new_game()
	EventBus.message_requested.emit("Find your footing. The green pedestal is a SavePoint.")

func _configure_input() -> void:
	var mappings := {
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E], "menu": [KEY_ESCAPE], "debug_overlay": [KEY_F3],
		"character": [KEY_C], "visual_quality": [KEY_F4]
	}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in mappings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
