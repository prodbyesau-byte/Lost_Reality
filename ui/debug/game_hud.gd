class_name GameHUD
extends CanvasLayer
var location: Label
var interaction: Label
var toast: Label
var debug_label: Label
var toast_time: float = 0.0

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.theme()
	add_child(root)
	var title := UIStyle.label("H A U N T E D   D I M E N S I O N", 25)
	title.position = Vector2(38, 28)
	root.add_child(title)
	var subtitle := UIStyle.label("HAUNTED DIMENSION     /     SUBURBAN SURVIVAL", 13, UIStyle.ACCENT)
	subtitle.position = Vector2(40, 66)
	root.add_child(subtitle)
	var quality := UIStyle.label("F4  /  Atmospheric", 14, UIStyle.MUTED)
	quality.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	quality.position = Vector2(-225,34)
	root.add_child(quality)
	VisualQuality.changed.connect(func() -> void: quality.text = "F4  /  " + ("Atmospheric" if VisualQuality.atmospheric else "Performance"))
	location = UIStyle.label("", 18, UIStyle.MUTED)
	location.position = Vector2(40, 96)
	root.add_child(location)
	var help := UIStyle.label("WASD / ARROWS   Move     •     E   Interact     •     WHEEL   Zoom     •     C   Character     •     ESC   Menu", 16, UIStyle.MUTED)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(40, -44)
	root.add_child(help)
	interaction = UIStyle.label("", 23, UIStyle.ACCENT)
	interaction.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	interaction.position = Vector2(40, -130)
	root.add_child(interaction)
	toast = UIStyle.label("", 17)
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	toast.position = Vector2(40, -85)
	root.add_child(toast)
	debug_label = UIStyle.label("", 15, UIStyle.ACCENT)
	debug_label.position = Vector2(40, 142)
	debug_label.visible = false
	root.add_child(debug_label)
	EventBus.scene_changed.connect(func(id: String) -> void: location.text = "●   " + LevelCatalog.title(id).to_upper())
	EventBus.interaction_focus_changed.connect(func(text: String) -> void: interaction.text = text)
	EventBus.message_requested.connect(_message)
	EventBus.save_completed.connect(func(slot: int) -> void: _message(SaveConstants.slot_name(slot) + " saved."))
	EventBus.load_completed.connect(func(slot: int, recovered: bool) -> void: _message(SaveConstants.slot_name(slot) + (" restored from recovery copy." if recovered else " loaded.")))
	EventBus.level_up.connect(func(level: int) -> void: _message("Level %d reached. Press C to spend attribute points." % level))

func _process(delta: float) -> void:
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
