extends Node
## Gameplay authorization and orchestration. SaveStore is intentionally unaware of UI.
var store := SaveStore.new()
var _save_point: WeakRef
var busy: bool = false

func begin_manual_session(point: Node3D) -> bool:
	if busy or SceneRouter.busy or not point is WorldSavePoint:
		return false
	if not is_instance_valid(SceneRouter.player) or not SceneRouter.player.interactor.can_interact(point):
		return false
	_save_point = weakref(point)
	EventBus.save_menu_requested.emit()
	return true

func end_manual_session() -> void:
	_save_point = null

func authorized() -> bool:
	if _save_point == null or not is_instance_valid(SceneRouter.player):
		return false
	var point: Variant = _save_point.get_ref()
	return is_instance_valid(point) and SceneRouter.player.interactor.can_interact(point)

func capture(slot: int) -> Dictionary:
	return {
		"version": SaveConstants.VERSION,
		"metadata": {"slot": slot, "timestamp": Time.get_unix_time_from_system(), "playtime": GameState.total_playtime},
		"scene": SceneRouter.current_id,
		"player": {"position": SaveSerializer.vector(SceneRouter.player.global_position), "rotation": SaveSerializer.vector(SceneRouter.player.rotation)},
		"sections": GameState.snapshot(),
	}

func save_manual(slot: int, confirmed_revision: String = "") -> Dictionary:
	if busy or SceneRouter.busy or slot not in SaveConstants.MANUAL_SLOTS or not authorized():
		return {"ok": false, "error": "Manual saving requires an active SavePoint interaction."}
	if store.revision(slot) != confirmed_revision:
		return {"ok": false, "error": "Confirm overwrite of the current save before saving."}
	var result := _save(slot)
	if result.ok:
		end_manual_session()
	return result

func autosave_after_transition() -> Dictionary:
	if busy or SceneRouter.busy or not is_instance_valid(SceneRouter.player):
		return {"ok": false, "error": "Cannot autosave during an unfinished transition."}
	return _save(SaveConstants.AUTOSAVE_SLOT)

func _save(slot: int) -> Dictionary:
	busy = true
	var payload := capture(slot)
	var validation := GameState.validate_sections(payload.sections)
	var result: Dictionary
	if not validation.is_empty():
		result = {"ok": false, "error": validation}
	else:
		result = store.write_slot(slot, payload)
	busy = false
	if result.ok:
		EventBus.save_completed.emit(slot)
	return result

func load_slot(slot: int) -> Dictionary:
	if busy or SceneRouter.busy:
		return {"ok": false, "error": "A save or transition is already in progress."}
	var result := store.read_slot(slot)
	if not result.ok:
		return result
	var error := GameState.validate_sections(result.data.sections)
	if not error.is_empty():
		return {"ok": false, "error": error}
	busy = true
	var restored: Dictionary = await SceneRouter.restore_save(result.data)
	busy = false
	if not restored.ok:
		return restored
	end_manual_session()
	EventBus.load_completed.emit(slot, result.get("recovered", false))
	return result

func delete_slot(slot: int, confirmed_revision: String) -> Dictionary:
	if busy or SceneRouter.busy:
		return {"ok":false,"error":"A save or transition is already in progress."}
	busy = true
	var result := store.delete_slot(slot,confirmed_revision)
	busy = false
	return result
