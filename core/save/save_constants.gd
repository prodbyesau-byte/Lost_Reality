class_name SaveConstants
extends RefCounted

const VERSION: int = 4
const FORMAT: String = "haunted-dimension-save"
const MANUAL_SLOTS: Array[int] = [1, 2, 3]
const AUTOSAVE_SLOT: int = 0
const ALL_SLOTS: Array[int] = [1, 2, 3, 0]
const DIRECTORY: String = "user://saves"
const MAX_FILE_BYTES: int = 4 * 1024 * 1024

static func valid_slot(slot: int) -> bool:
	return slot in ALL_SLOTS

static func slot_name(slot: int) -> String:
	return "Autosave" if slot == AUTOSAVE_SLOT else "Manual %02d" % slot

static func filename(slot: int) -> String:
	return "autosave.json" if slot == AUTOSAVE_SLOT else "manual_%d.json" % slot
