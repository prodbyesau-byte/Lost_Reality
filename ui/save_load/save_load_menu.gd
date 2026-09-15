class_name SaveLoadMenu
extends CanvasLayer
var overlay: Control
var rows: VBoxContainer
var status: Label
var heading: Label
var confirmation: ConfirmationDialog
var quit_confirmation: ConfirmationDialog
var save_mode: bool = false
var pending_slot: int = -1
var pending_revision: String = ""
var working: bool = false
var character_panel: CharacterPanel
var character_view: bool = false
var slot_hint: Label
var panel: PanelContainer
var character_button: Button
var new_game_confirmation: ConfirmationDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = UIStyle.theme()
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.05, 0.065, 0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 0)
	panel.add_theme_stylebox_override("panel", UIStyle.panel())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	column.add_child(UIStyle.label("H A U N T E D   D I M E N S I O N", 14, UIStyle.ACCENT))
	heading = UIStyle.label("", 32)
	column.add_child(heading)
	slot_hint = UIStyle.label("3 manual slots  /  1 autosave", 16, UIStyle.MUTED)
	column.add_child(slot_hint)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	column.add_child(rows)
	character_panel = CharacterPanel.new()
	column.add_child(character_panel)
	character_panel.hide()
	status = UIStyle.label("", 16, UIStyle.MUTED)
	status.custom_minimum_size = Vector2(750, 48)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	var resume := Button.new()
	resume.text = "Return to game"
	resume.pressed.connect(close)
	actions.add_child(resume)
	character_button = Button.new()
	character_button.text = "Character [C]"
	character_button.pressed.connect(func() -> void: open(false) if character_view else open_character())
	actions.add_child(character_button)
	var new_game_button := Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(func() -> void: new_game_confirmation.popup_centered())
	actions.add_child(new_game_button)
	var quit := Button.new()
	quit.text = "Quit game"
	quit.pressed.connect(func() -> void: quit_confirmation.popup_centered())
	actions.add_child(quit)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Overwrite manual save?"
	confirmation.dialog_text = "Replace this manual save with your current progress?\nThe previous valid save is retained as a recovery copy."
	confirmation.confirmed.connect(_confirm_save)
	add_child(confirmation)
	quit_confirmation = ConfirmationDialog.new()
	quit_confirmation.title = "Quit Haunted Dimension?"
	quit_confirmation.dialog_text = "Progress since your last save will be lost.\nManual saves are available only at a SavePoint."
	quit_confirmation.confirmed.connect(func() -> void: get_tree().quit())
	add_child(quit_confirmation)
	new_game_confirmation = ConfirmationDialog.new()
	new_game_confirmation.title = "Start a New Game?"
	new_game_confirmation.dialog_text = "Start again at Level 0 with zero stats and no profession?\nUnsaved progress will be lost. Existing save slots are kept."
	new_game_confirmation.confirmed.connect(_new_game)
	add_child(new_game_confirmation)
	get_tree().auto_accept_quit = false
	EventBus.save_menu_requested.connect(func() -> void: open(true))
	overlay.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(quit_confirmation):
		if not overlay.visible:
			open(false)
		quit_confirmation.popup_centered()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character") and not event.is_echo() and not working and not SceneRouter.busy:
		if overlay.visible and character_view:
			close()
		else:
			open_character()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu") and not event.is_echo() and not working and not SceneRouter.busy:
		if overlay.visible:
			close()
		else:
			open(false)
		get_viewport().set_input_as_handled()

func open(at_save_point: bool) -> void:
	if working or SceneRouter.busy:
		return
	save_mode = at_save_point and SaveManager.authorized()
	if not save_mode:
		SaveManager.end_manual_session()
	character_view = false
	character_panel.hide()
	rows.show()
	slot_hint.show()
	status.show()
	panel.custom_minimum_size.x = 800
	character_button.text = "Character [C]"
	heading.text = "Save your place" if save_mode else "Pause / Load game"
	status.text = "Choose a manual slot. Existing saves require confirmation." if save_mode else "Manual saving is available at a SavePoint. Loading replaces current progress."
	_refresh()
	overlay.show()
	get_tree().paused = true

func open_character() -> void:
	if working or SceneRouter.busy:
		return
	SaveManager.end_manual_session()
	save_mode = false
	character_view = true
	heading.text = "Character / Progression"
	rows.hide()
	slot_hint.hide()
	status.hide()
	panel.custom_minimum_size.x = 940
	character_button.text = "Save slots"
	character_panel.feedback.text = ""
	character_panel.show()
	character_panel.refresh()
	overlay.show()
	get_tree().paused = true
	character_panel.debug_button.grab_focus()

func close() -> void:
	if working:
		return
	confirmation.hide()
	quit_confirmation.hide()
	new_game_confirmation.hide()
	overlay.hide()
	SaveManager.end_manual_session()
	get_tree().paused = false

func _new_game() -> void:
	if working:
		return
	working = true
	var result: Dictionary = await SceneRouter.new_game()
	working = false
	if result.ok:
		close()
		EventBus.message_requested.emit("New Game: Level 0. No profession. Press C to view your character.")
	else:
		status.show()
		status.text = result.error

func _refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for slot in SaveConstants.ALL_SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		rows.add_child(row)
		var result := SaveManager.store.read_slot(slot)
		var text := SaveConstants.slot_name(slot) + "   /   Empty"
		if result.ok:
			var meta: Dictionary = result.data.metadata
			var date := Time.get_datetime_string_from_unix_time(int(meta.timestamp)).replace("T", " ")
			text = "%s  /  %s\n%s UTC  •  %dm %02ds%s" % [SaveConstants.slot_name(slot), LevelCatalog.title(result.data.scene), date, int(meta.playtime) / 60, int(meta.playtime) % 60, "  •  Recovery available" if result.get("recovered", false) else ""]
		elif SaveManager.store.exists(slot):
			text = SaveConstants.slot_name(slot) + "  /  Unavailable\n" + result.error
		var label := UIStyle.label(text, 16)
		label.custom_minimum_size = Vector2(520, 68)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var load_button := Button.new()
		load_button.text = "Load"
		load_button.disabled = not result.ok
		load_button.pressed.connect(_load.bind(slot))
		row.add_child(load_button)
		if save_mode and slot != SaveConstants.AUTOSAVE_SLOT:
			var save_button := Button.new()
			save_button.text = "Save"
			save_button.pressed.connect(_request_save.bind(slot))
			row.add_child(save_button)
	var first := rows.get_child(0)
	for child in first.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func _request_save(slot: int) -> void:
	if working:
		return
	pending_slot = slot
	pending_revision = SaveManager.store.revision(slot)
	if not pending_revision.is_empty():
		confirmation.popup_centered()
	else:
		_confirm_save()

func _confirm_save() -> void:
	if working:
		return
	var result := SaveManager.save_manual(pending_slot, pending_revision)
	if result.ok:
		close()
	else:
		status.text = result.error
		_refresh()

func _load(slot: int) -> void:
	if working:
		return
	working = true
	status.text = "Restoring saved scene…"
	var result: Dictionary = await SaveManager.load_slot(slot)
	working = false
	if result.ok:
		close()
	else:
		status.text = result.error
