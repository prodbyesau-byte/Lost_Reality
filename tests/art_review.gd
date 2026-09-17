extends Node
## Presentation regression + actual viewport captures. Never writes real player saves.
var failures: int = 0
var checks: int = 0
var measurements: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS  ",message)
	else:
		failures += 1
		push_error("FAIL  "+message)

func settle(frames: int = 30) -> void:
	for i in frames:
		await get_tree().process_frame

func run() -> void:
	SaveManager.store = SaveStore.new("user://regression_art_unused")
	var game := preload("res://core/game.tscn").instantiate()
	add_child(game)
	for startup in game.get_children():
		if startup is StartScreen:
			await startup._new_game()
	await settle(80)
	check(SceneRouter.current_id == "tenement", "Art pass boots into the same level")
	check(SceneRouter.player.visual is HumanVisual, "Human visual is separate from player physics")
	check(SceneRouter.current_level.find_children("*","CollisionObject3D",true,false).size() == 18, "Tenement retains all 18 original world collision bodies")
	check(SaveConstants.VERSION == 4 and Progression.snapshot() == ProgressionSchema.defaults(), "Visual pass preserves current save format and initial progression")
	check(ArtMaterials.surface("wood") == ArtMaterials.surface("wood"), "Shared materials are cached")
	check(ArtMaterials.surface("plaster").normal_enabled and ArtMaterials.surface("plaster").normal_texture != null, "PBR surfaces include normal maps")
	check(ArtMaterials.surface("metal").metallic > ArtMaterials.surface("wood").metallic, "Metal and wood have distinct PBR response")
	check(ArtMaterials.surface("plaster").uv1_world_triplanar and ArtMaterials.surface("plaster").uv1_scale == Vector3.ONE*0.5, "World material mapping keeps consistent density")
	var before := GameState.snapshot()
	var light: TestObject
	for object in get_tree().get_nodes_in_group("interactables"):
		if object is TestObject:
			light = object
	check(not light.practical.visible, "Persistent lamp starts off visually")
	light.interact(SceneRouter.player)
	check(light.practical.visible, "Interaction switches actual 3D light on")
	light.interact(SceneRouter.player)
	check(not light.practical.visible, "Interaction switches actual 3D light off")
	GameState.restore(before,GameState.total_playtime)
	var environment := get_tree().get_first_node_in_group("art_environments").environment as Environment
	VisualQuality.set_atmospheric(false)
	await settle(40)
	check(not environment.ssao_enabled and not environment.volumetric_fog_enabled, "Performance profile disables expensive effects")
	check(GameState.snapshot() == before, "Quality changes do not touch saved gameplay data")
	var all_hidden := true
	for detail in get_tree().get_nodes_in_group("art_details"):
		all_hidden = all_hidden and not detail.visible
	check(all_hidden, "Performance profile hides secondary clutter")
	var reduced := true
	for mesh in get_tree().get_nodes_in_group("art_lod_meshes"):
		reduced = reduced and mesh.mesh is ArrayMesh
	check(reduced, "Performance profile preserves bevelled silhouettes instead of cube replacements")
	VisualQuality.set_atmospheric(true)
	await settle(40)
	var advanced := RenderingServer.get_current_rendering_method() == "forward_plus"
	check(environment.ssao_enabled == advanced, "AO enabled only on a supporting renderer")
	check(environment.volumetric_fog_enabled == advanced, "Volumetric haze enabled only on a supporting renderer")
	check(get_tree().get_first_node_in_group("art_lod_meshes").mesh is ArrayMesh, "Atmospheric profile restores detailed mesh LODs")
	await capture("tenement",true)
	SceneRouter.camera_rig.desired_size = 10
	await settle(45)
	await capture("close",false)
	SceneRouter.camera_rig.desired_size = 28
	# Advance the smoothing and timed LOD refresh independent of render frame rate.
	SceneRouter.camera_rig._process(1.0)
	VisualQuality._process(0.3)
	await settle(45)
	all_hidden = true
	for detail in get_tree().get_nodes_in_group("art_details"):
		all_hidden = all_hidden and not detail.visible
	check(all_hidden, "Zoom-out LOD removes secondary clutter")
	await capture("wide",false)
	SceneRouter.camera_rig.desired_size = 19
	await settle(45)
	await SceneRouter.travel("courtyard","entry",false)
	await settle(45)
	check(SceneRouter.current_level.find_children("*","CollisionObject3D",true,false).size() == 11, "Courtyard retains all 11 original collision bodies")
	check(SceneRouter.current_level.find_children("*","MultiMeshInstance3D",true,false).size() >= 3, "Vegetation uses instanced geometry")
	var after := GameState.snapshot()
	# Traveling now legitimately discovers terrain; art must preserve all other state.
	after.erase("exploration")
	var before_without_map := before.duplicate(true)
	before_without_map.erase("exploration")
	check(after == before_without_map, "Art-dressed scene transition preserves non-exploration gameplay state")
	await capture("courtyard",true)
	VisualQuality.set_atmospheric(false)
	await settle(45)
	await capture("performance",true)
	if not measurements.is_empty():
		var file := FileAccess.open("res://tests/output/art_metrics.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(measurements,"  "))
		file.close()
	print("ART RESULT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func capture(id: String, measure: bool) -> void:
	if DisplayServer.get_name() == "headless" or "--no-captures" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/output/art_"+id+".png")
	if measure:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await settle(30)
		var elapsed: Array[float] = []
		for i in 90:
			var start := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			elapsed.append((Time.get_ticks_usec()-start)/1000.0)
		elapsed.sort()
		var metrics := {"view": id, "renderer": RenderingServer.get_current_rendering_method(), "median_frame_ms": elapsed[45], "p95_frame_ms": elapsed[85], "draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}
		measurements.append(metrics)
		print("ART METRICS ",JSON.stringify(metrics))


