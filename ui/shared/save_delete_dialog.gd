class_name SaveDeleteDialog
extends ConfirmationDialog
signal completed(result: Dictionary)
var pending_slot := -1
var pending_revision := ""
func _ready() -> void:
	title = "DELETE SAVE?"
	ok_button_text = "DELETE"
	cancel_button_text = "CANCEL"
	UIStyle.style_dialog(self)
	confirmed.connect(_confirm)
	canceled.connect(func() -> void: pending_slot = -1; pending_revision = "")
func request(slot: int) -> void:
	if SaveManager.busy or SceneRouter.busy: return
	pending_slot = slot
	pending_revision = SaveManager.store.deletion_revision(slot)
	if pending_revision.is_empty(): return
	dialog_text = "%s\nThis save and its recovery copies will be permanently deleted." % SaveConstants.slot_name(slot)
	popup_centered()
	get_cancel_button().grab_focus()
func _confirm() -> void:
	var slot := pending_slot
	var revision := pending_revision
	pending_slot = -1
	pending_revision = ""
	var result := SaveManager.delete_slot(slot,revision)
	hide()
	completed.emit(result)
func add_action(row: Control, slot: int) -> Button:
	var button := Button.new()
	button.text = "DELETE"
	button.disabled = SaveManager.store.deletion_revision(slot).is_empty()
	button.pressed.connect(request.bind(slot))
	row.add_child(button)
	return button
