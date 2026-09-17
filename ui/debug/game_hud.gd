class_name GameHUD
extends CanvasLayer
var interaction: Label
var toast: Label
var debug_label: Label
var toast_time: float = 0.0
var loading: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)
	loading = UIStyle.label("SYNCING WORLD STATE…",16,UIStyle.ACCENT)
	loading.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	loading.position = Vector2(-320,30)
	loading.hide()
	root.add_child(loading)
	interaction = UIStyle.label("", 18, UIStyle.ACCENT)
	interaction.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	interaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(interaction)
	toast = UIStyle.label("", 17)
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	toast.position = Vector2(40, -85)
	root.add_child(toast)
	debug_label = UIStyle.label("", 15, UIStyle.ACCENT)
	debug_label.position = Vector2(40, 142)
	debug_label.visible = false
	root.add_child(debug_label)
	for label in [interaction,toast,debug_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_stylebox_override("normal",CharacterTheme.box(Color("10181de8"),CharacterTheme.DIM,10))
	interaction.visible = false
	EventBus.interaction_focus_changed.connect(func(text: String) -> void: interaction.text = "E - " + text if not text.is_empty() else ""; _update_interaction())
	EventBus.message_requested.connect(_message)
	EventBus.save_completed.connect(func(slot: int) -> void: _message(SaveConstants.slot_name(slot) + " saved."))
	EventBus.load_completed.connect(func(slot: int, recovered: bool) -> void: _message(SaveConstants.slot_name(slot) + (" restored from recovery copy." if recovered else " loaded.")))
	EventBus.level_up.connect(func(level: int) -> void: _message("Level %d reached." % level))

func _process(delta: float) -> void:
	_update_interaction()
	loading.visible = SceneRouter.busy
	if get_tree().paused: return
	toast_time = maxf(0, toast_time - delta)
	toast.visible = toast_time > 0
	if debug_label.visible and is_instance_valid(SceneRouter.player):
		debug_label.text = "FPS %d  |  %s\nPosition %s\nVelocity %.2f  |  Zoom %.1f\nPlaytime %.1fs" % [Engine.get_frames_per_second(), SceneRouter.current_id, SceneRouter.player.position, SceneRouter.player.velocity.length(), SceneRouter.camera_rig.camera.size, GameState.total_playtime]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		debug_label.visible = not debug_label.visible

func _message(text: String) -> void:
	toast.text = text
	toast_time = 6.0

func _update_interaction() -> void:
	interaction.hide()
	if interaction.text.is_empty() or SceneRouter.busy or get_tree().paused or not is_instance_valid(SceneRouter.player):
		return
	interaction.reset_size()
	interaction.position = get_viewport().get_visible_rect().size - interaction.size - Vector2(32,32)
	interaction.show()

