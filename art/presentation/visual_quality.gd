extends Node
signal changed
## Runtime presentation choice only; does not alter gameplay state or save format.
var atmospheric: bool = true
var _detail_visible: bool = true
var _timer: float = 0.0

func detail_enabled() -> bool:
	return atmospheric and (not is_instance_valid(SceneRouter.camera_rig) or SceneRouter.camera_rig.camera.size < 24.0)

func _process(delta: float) -> void:
	_timer += delta
	if _timer < 0.25:
		return
	_timer = 0.0
	var detail := detail_enabled()
	if detail != _detail_visible:
		_detail_visible = detail
		for node in get_tree().get_nodes_in_group("art_details"):
			node.visible = detail
		for mesh in get_tree().get_nodes_in_group("art_lod_meshes"):
			mesh.mesh = mesh.get_meta("lod_detail") if detail else mesh.get_meta("lod_simple")

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("visual_quality") and event.is_action_pressed("visual_quality") and not event.is_echo():
		set_atmospheric(not atmospheric)
		EventBus.message_requested.emit("Visual quality: " + ("Atmospheric" if atmospheric else "Performance"))

func set_atmospheric(value: bool) -> void:
	atmospheric = value
	for node in get_tree().get_nodes_in_group("art_environments"):
		apply_environment(node.environment)
	for light in get_tree().get_nodes_in_group("art_lights"):
		light.shadow_enabled = value and light.get_meta("art_shadow",false)
	_detail_visible = not value
	_timer = 1.0
	changed.emit()

func apply_environment(environment: Environment) -> void:
	var advanced := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssao_enabled = atmospheric and advanced
	environment.ssao_radius = 0.65
	environment.ssao_intensity = 1.25
	environment.ssao_power = 1.3
	environment.glow_enabled = atmospheric and advanced
	environment.glow_intensity = 0.12
	environment.glow_hdr_threshold = 1.5
	environment.volumetric_fog_enabled = atmospheric and advanced
	environment.volumetric_fog_density = 0.0015
	environment.volumetric_fog_length = 65.0
	environment.volumetric_fog_albedo = Color("8b9697")
	environment.volumetric_fog_ambient_inject = 0.10

func create_environment(parent: Node3D) -> void:
	var node := WorldEnvironment.new()
	var environment := Environment.new()
	var lighting: Dictionary = ArtMaterials.config().lighting
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("11191b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(lighting.ambient_color)
	environment.ambient_light_energy = lighting.ambient_energy
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.88
	environment.adjustment_contrast = 1.04
	environment.fog_enabled = true
	environment.fog_density = lighting.fog_density
	environment.fog_light_color = Color("39464b")
	environment.fog_light_energy = 0.35
	apply_environment(environment)
	node.environment = environment
	parent.add_child(node)
	node.add_to_group("art_environments")
	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-57,-30,0)
	moon.light_color = Color(lighting.moon_color)
	moon.light_energy = lighting.moon_energy
	moon.light_angular_distance = 1.2
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 65
	moon.shadow_bias = 0.035
	parent.add_child(moon)
	# New levels inherit the active detail profile immediately.
	for detail in parent.get_tree().get_nodes_in_group("art_details"):
		detail.visible = atmospheric and (not is_instance_valid(SceneRouter.camera_rig) or SceneRouter.camera_rig.camera.size < 24.0)
