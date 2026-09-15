extends Node
## Stages a level before committing; the player, camera and UI survive transitions.
var host: Node3D
var player: CharacterBody3D
var camera_rig: Node3D
var current_id: String = ""
var current_level: Node3D
var busy: bool = false

func configure(level_host: Node3D, actor: CharacterBody3D, rig: Node3D) -> void:
	host = level_host
	player = actor
	camera_rig = rig

func travel(id: String, spawn_id: String = "entry", autosave: bool = true) -> Dictionary:
	return await _transition(id, spawn_id, {}, autosave)

func restore_save(data: Dictionary) -> Dictionary:
	return await _transition(data.scene, "entry", data, false)

func new_game() -> Dictionary:
	if SaveManager.busy:
		return {"ok": false, "error": "Wait for the current save or load."}
	var result: Dictionary = await _transition("tenement", "entry", {}, false, true)
	if result.ok:
		EventBus.new_game_started.emit()
	return result

func _transition(id: String, spawn_id: String, saved: Dictionary, autosave: bool, reset_state: bool = false) -> Dictionary:
	if busy or not LevelCatalog.valid_id(id) or not is_instance_valid(host):
		return {"ok": false, "error": "Level transition is unavailable."}
	busy = true
	var packed := load(LevelCatalog.LEVELS[id].path) as PackedScene
	if packed == null:
		busy = false
		return {"ok": false, "error": "Could not load destination."}
	var staged := packed.instantiate() as Node3D
	if staged == null or not staged.has_method("spawn_position"):
		if staged != null:
			staged.free()
		busy = false
		return {"ok": false, "error": "Invalid destination scene."}
	# Build hidden while the current level remains intact.
	staged.visible = false
	host.add_child(staged)
	var destination: Variant = staged.spawn_position(spawn_id)
	if destination == null:
		staged.free()
		busy = false
		return {"ok": false, "error": "Unknown destination entrance."}
	if not saved.is_empty():
		destination = SaveSerializer.to_vector(saved.player.position)
		if not staged.position_is_safe(destination, saved.sections):
			staged.free()
			busy = false
			return {"ok": false, "error": "Saved position intersects level geometry."}
	SaveManager.end_manual_session()
	if reset_state:
		GameState.reset()
	elif not saved.is_empty():
		GameState.restore(saved.sections, saved.metadata.playtime)
	staged.apply_persistent_state()
	if is_instance_valid(current_level):
		host.remove_child(current_level)
		current_level.queue_free()
	current_level = staged
	current_id = id
	staged.visible = true
	player.global_position = destination
	player.rotation = SaveSerializer.to_vector(saved.player.rotation) if not saved.is_empty() else Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.reset_motion()
	camera_rig.snap_to_target()
	# Give collision registration one physics tick before input or autosave resumes.
	await get_tree().physics_frame
	busy = false
	EventBus.scene_changed.emit(id)
	if autosave:
		var result: Dictionary = SaveManager.autosave_after_transition()
		if not result.ok:
			EventBus.message_requested.emit("Transition complete. Autosave failed: " + result.error)
	return {"ok": true}
