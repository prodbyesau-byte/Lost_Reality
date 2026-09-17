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
var new_game_confirmation: ConfirmationDialog
var actions: VBoxContainer
var settings: VBoxContainer
var settings_view := false
var delete_dialog: SaveDeleteDialog

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
	panel.add_theme_stylebox_override("panel", CharacterTheme.box(Color(0,0,0,0),Color(0,0,0,0),0))
	center.add_child(panel)
	var frame := CharacterFrame.new()
	frame.header_rule = false
	panel.add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,36)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(UIStyle.label("LOST REALITY", 14, UIStyle.ACCENT))
	heading = UIStyle.label("", 32)
	column.add_child(heading)
	slot_hint = UIStyle.label("3 manual slots  /  1 autosave", 16, UIStyle.MUTED)
	column.add_child(slot_hint)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	column.add_child(rows)
	character_panel = CharacterPanel.new()
	center.add_child(character_panel)
	character_panel.close_requested.connect(close)
	character_panel.hide()
	status = UIStyle.label("", 16, UIStyle.MUTED)
	status.custom_minimum_size = Vector2(0, 48)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	var resume := Button.new()
	resume.text = "RESUME"
	resume.pressed.connect(close)
	actions.add_child(resume)
	var settings_button := Button.new()
	settings_button.text = "SETTINGS"
	settings_button.pressed.connect(open_settings)
	actions.add_child(settings_button)
	settings = VBoxContainer.new()
	settings.add_theme_constant_override("separation",16)
	column.add_child(settings)
	SettingsContent.populate(settings)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(open.bind(false))
	settings.add_child(back)
	settings.hide()
	var quit := Button.new()
	quit.text = "QUIT GAME"
	quit.pressed.connect(func() -> void: quit_confirmation.popup_centered())
	actions.add_child(quit)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Overwrite manual save?"
	confirmation.dialog_text = "Replace this manual save with your current progress?\nThe previous valid save is retained as a recovery copy."
	confirmation.confirmed.connect(_confirm_save)
	add_child(confirmation)
	quit_confirmation = ConfirmationDialog.new()
	quit_confirmation.title = "QUIT GAME?"
	quit_confirmation.ok_button_text = "QUIT"
	quit_confirmation.cancel_button_text = "CANCEL"
	quit_confirmation.dialog_text = "Progress since your last save will be lost.\nManual saves are available only at a SavePoint."
	quit_confirmation.confirmed.connect(func() -> void: get_tree().quit())
	add_child(quit_confirmation)
	new_game_confirmation = ConfirmationDialog.new()
	new_game_confirmation.title = "Start a New Game?"
	new_game_confirmation.dialog_text = "Start again at Level 0 with zero stats and no profession?\nUnsaved progress will be lost. Existing save slots are kept."
	new_game_confirmation.confirmed.connect(_new_game)
	add_child(new_game_confirmation)
	for dialog in [confirmation,quit_confirmation,new_game_confirmation]:
		UIStyle.style_dialog(dialog)
	delete_dialog = SaveDeleteDialog.new()
	add_child(delete_dialog)
	delete_dialog.completed.connect(func(result: Dictionary) -> void:
		_refresh()
		status.text = "Save deleted." if result.ok else result.error)
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
		if settings_view:
			open(false)
		elif overlay.visible:
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
	panel.show()
	rows.visible = save_mode
	slot_hint.visible = save_mode
	status.visible = save_mode
	panel.custom_minimum_size.x = 900 if save_mode else 620
	settings_view = false
	settings.hide()
	actions.show()
	heading.text = "SAVE STATE" if save_mode else "SYSTEM PAUSED"
	status.text = "Choose a manual slot. Existing saves require confirmation." if save_mode else "Manual saving is available at a SavePoint. Loading replaces current progress."
	if save_mode: _refresh()
	overlay.show()
	if not save_mode: actions.get_child(0).grab_focus()
	get_tree().paused = true

func open_character() -> void:
	if working or SceneRouter.busy:
		return
	SaveManager.end_manual_session()
	save_mode = false
	character_view = true
	panel.hide()
	character_panel.show()
	overlay.show()
	get_tree().paused = true
	character_panel.open_default()

func close() -> void:
	if working:
		return
	confirmation.hide()
	quit_confirmation.hide()
	new_game_confirmation.hide()
	delete_dialog.hide()
	settings_view = false
	character_panel.preview.dragging = false
	character_panel.preview.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
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
		EventBus.message_requested.emit("New Game: Level 0. No profession.")
	else:
		status.visible = save_mode
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
		var text := SaveSlotPresentation.text(slot,result,SaveManager.store.exists(slot))
		var label := UIStyle.label(text, 16)
		label.add_theme_stylebox_override("normal",CharacterTheme.box(CharacterTheme.SURFACE,CharacterTheme.DIM,10))
		if not result.ok and SaveManager.store.exists(slot):
			label.add_theme_color_override("font_color",CharacterTheme.ERROR)
		elif result.get("recovered",false):
			label.add_theme_color_override("font_color",CharacterTheme.WARNING)
		label.custom_minimum_size = Vector2(520, 78)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var load_button := Button.new()
		load_button.text = "Load"
		load_button.disabled = not result.ok
		load_button.pressed.connect(_load.bind(slot))
		row.add_child(load_button)
		delete_dialog.add_action(row,slot)
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
	status.text = "Recovering saved state…"
	var result: Dictionary = await SaveManager.load_slot(slot)
	working = false
	if result.ok:
		close()
	else:
		status.text = result.error



func open_settings() -> void:
	open(false)
	SettingsContent.refresh(settings)
	settings_view = true
	heading.text = "CONFIGURATION"
	actions.hide()
	settings.show()
	get_tree().paused = true
	settings.get_child(1).grab_focus()

