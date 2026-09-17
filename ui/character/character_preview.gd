class_name CharacterPreview
extends SubViewportContainer
var viewport: SubViewport
var model: Node3D
var dragging := false
var yaw := 0.22

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(470,465)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,600)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var studio := Node3D.new()
	viewport.add_child(studio)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0,0,0,0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c7c9c4")
	environment.environment.ambient_light_energy = 0.7
	studio.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30,-140,0)
	key.light_color = Color("fff0d9")
	key.light_energy = 1.25
	studio.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-30,35,0)
	rim.light_color = Color("9daeb1")
	rim.light_energy = 0.65
	studio.add_child(rim)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	camera.position = Vector3(0,1.12,-4)
	studio.add_child(camera)
	camera.look_at(Vector3(0,0.89,0))
	camera.current = true
	gui_input.connect(_drag)
	visibility_changed.connect(func() -> void:
		dragging = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED)

func sync_player() -> void:
	if is_instance_valid(model):
		viewport.remove_child(model)
		model.queue_free()
	if not is_instance_valid(SceneRouter.player):
		return
	var source: Node3D = SceneRouter.player.visual
	# Copy the actual render hierarchy, without gameplay scripts, signals or groups.
	model = source.duplicate(0) as Node3D
	model.process_mode = Node.PROCESS_MODE_DISABLED
	model.transform = Transform3D.IDENTITY
	yaw = 0.22
	model.rotation.y = yaw
	viewport.add_child(model)
	# Current procedural visual: reset copied presentation joints to calm idle.
	# A future imported character can supply its own idle pose without cloning the actor.
	for property in ["legs","knees","arms","elbows"]:
		var joints: Variant = source.get(property)
		if joints is Array:
			for joint in joints:
				var copy := model.get_node_or_null(source.get_path_to(joint)) as Node3D
				if copy:
					copy.rotation.x = -0.1 if property == "elbows" else 0.0

func _drag(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	if event is InputEventMouseMotion and dragging and is_instance_valid(model):
		yaw += event.relative.x*0.009
		model.rotation.y = yaw
	if event is InputEventMouse:
		accept_event()
