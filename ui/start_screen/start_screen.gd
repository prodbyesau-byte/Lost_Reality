class_name StartScreen
extends CanvasLayer

var overlay: Control
var main_panel: PanelContainer
var content: VBoxContainer
var status: Label
var working: bool = false
var current_view := "main"
var delete_dialog: SaveDeleteDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build_ui()
	delete_dialog = SaveDeleteDialog.new()
	add_child(delete_dialog)
	delete_dialog.completed.connect(func(result: Dictionary) -> void:
		_show_load()
		if not result.ok: status.text = result.error)
	_show_main()

func _build_ui() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	overlay.theme = UIStyle.theme()
	add_child(overlay)

	var background := preload("res://ui/start_screen/start_screen_background.tscn").instantiate() as Control
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.z_index = -1
	overlay.add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.03, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(620, 0)
	main_panel.add_theme_stylebox_override("panel", CharacterTheme.box(Color(0,0,0,0),Color(0,0,0,0),0))
	var frame := CharacterFrame.new()
	frame.header_rule = false
	main_panel.add_child(frame)
	center.add_child(main_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 52)
	main_panel.add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	var eyebrow := UIStyle.label("SYS // LOCAL TERMINAL", 14, UIStyle.ACCENT)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := UIStyle.label("LOST REALITY", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var subtitle := UIStyle.label("REALITY STATUS: UNKNOWN", 15, UIStyle.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	status = UIStyle.label("", 15, UIStyle.MUTED)
	status.custom_minimum_size = Vector2(0, 42)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status)

func _show_main() -> void:
	current_view = "main"
	main_panel.custom_minimum_size.x = 620
	_clear_content_after_status()
	_add_action("NEW GAME", _new_game).grab_focus()
	_add_action("LOAD GAME", _show_load)
	_add_action("SETTINGS", _show_settings)
	var quit := _add_action("QUIT", func() -> void: get_tree().quit())
	quit.add_theme_color_override("font_color", UIStyle.MUTED)
	status.text = "NETWORK: OFFLINE"
	overlay.show()
	get_tree().paused = true

func _show_load() -> void:
	current_view = "load"
	main_panel.custom_minimum_size.x = 900
	_clear_content_after_status()
	var heading := UIStyle.label("LOAD GAME", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	for slot in SaveConstants.ALL_SLOTS:
		var result := SaveManager.store.read_slot(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)
		var label := UIStyle.label(_slot_text(slot, result), 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(0, 48)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var load_button := Button.new()
		load_button.text = "Load"
		load_button.disabled = not result.ok
		load_button.pressed.connect(_load.bind(slot))
		row.add_child(load_button)
		delete_dialog.add_action(row,slot)
	_add_back_button()
	status.text = "Choose a save slot. Invalid or empty slots cannot be loaded."

func _show_settings() -> void:
	current_view = "settings"
	main_panel.custom_minimum_size.x = 620
	_clear_content_after_status()
	var heading := UIStyle.label("CONFIGURATION", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	SettingsContent.populate(content)
	_add_back_button()
	status.text = "Presentation settings are not part of save files."

func _new_game() -> void:
	if working:
		return
	working = true
	status.text = "Reconstructing local area…"
	get_tree().paused = false
	var result: Dictionary = await SceneRouter.new_game()
	working = false
	if result.ok:
		_finish()
	else:
		get_tree().paused = true
		status.text = result.error

func _load(slot: int) -> void:
	if working:
		return
	working = true
	status.text = "Recovering saved state…"
	get_tree().paused = false
	var result: Dictionary = await SaveManager.load_slot(slot)
	working = false
	if result.ok:
		_finish()
	else:
		get_tree().paused = true
		status.text = result.error

func _finish() -> void:
	overlay.hide()
	get_tree().paused = false

func _clear_content_after_status() -> void:
	while content.get_child_count() > 4:
		var child := content.get_child(4)
		content.remove_child(child)
		child.queue_free()

func _add_action(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.pressed.connect(callback)
	content.add_child(button)
	return button

func _add_back_button() -> void:
	var back := _add_action("BACK", _show_main)
	back.add_theme_color_override("font_color", UIStyle.MUTED)
	back.grab_focus()

func _slot_text(slot: int, result: Dictionary) -> String:
	return SaveSlotPresentation.text(slot,result,SaveManager.store.exists(slot))

func _input(event: InputEvent) -> void:
	if not overlay.visible: return
	if event.is_action_pressed("menu"):
		if not working and current_view != "main": _show_main()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("character") or event.is_action_pressed("interact") or event.is_action_pressed("world_map"):
		get_viewport().set_input_as_handled()


