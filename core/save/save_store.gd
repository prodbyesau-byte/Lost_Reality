class_name SaveStore
extends RefCounted
## File persistence only. Injectable directory keeps regression tests away from real saves.
var directory: String

func _init(path: String = SaveConstants.DIRECTORY) -> void:
	directory = path

func path_for(slot: int) -> String:
	return directory.path_join(SaveConstants.filename(slot))

func exists(slot: int) -> bool:
	if not SaveConstants.valid_slot(slot):
		return false
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path_for(slot) + suffix):
			return true
	return false

func read_file(path: String, slot: int) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Save file is unavailable."}
	if file.get_length() > SaveConstants.MAX_FILE_BYTES:
		return {"ok": false, "error": "Save exceeds size limit."}
	var result := SaveSerializer.decode(file.get_as_text())
	file.close()
	if not result.ok:
		return result
	var migrated := SaveMigrator.migrate(result.data)
	if not migrated.ok:
		return migrated
	var error := SaveValidator.validate(migrated.data, slot)
	if not error.is_empty():
		return {"ok": false, "error": error}
	result.data = migrated.data
	return result

func read_slot(slot: int) -> Dictionary:
	if not SaveConstants.valid_slot(slot):
		return {"ok": false, "error": "Invalid save slot."}
	var primary := read_file(path_for(slot), slot)
	if primary.ok or primary.get("future", false):
		primary["recovered"] = false
		return primary
	for suffix in [".bak", ".tmp"]:
		var recovery := read_file(path_for(slot) + suffix, slot)
		if recovery.ok:
			recovery["recovered"] = true
			recovery["source"] = suffix
			return recovery
	return {"ok": false, "error": "No valid save or recovery copy. " + primary.error}

func revision(slot: int) -> String:
	# A revision covers all artifacts, including corrupt data, for overwrite confirmation.
	var parts := ""
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = path_for(slot) + suffix
		if FileAccess.file_exists(path):
			parts += suffix + FileAccess.get_sha256(path)
	return parts.sha256_text() if not parts.is_empty() else ""

func write_slot(slot: int, data: Dictionary) -> Dictionary:
	var error := SaveValidator.validate(data, slot)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return {"ok": false, "error": "Cannot create save directory."}
	var path := path_for(slot)
	var encoded := SaveSerializer.encode(data)
	if encoded.to_utf8_buffer().size() > SaveConstants.MAX_FILE_BYTES:
		return {"ok": false, "error": "Save exceeds size limit."}
	# Preserve a valid recovery source BEFORE reusing the temporary filename.
	var previous := read_slot(slot)
	if previous.get("future", false):
		return previous
	if previous.ok:
		var backup := _write_verified(path + ".bak.tmp", previous.data, slot)
		if not backup.ok:
			return backup
		if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK:
			return {"ok": false, "error": "Cannot commit save backup."}
	var written := _write_verified(path + ".tmp", data, slot)
	if not written.ok:
		return written
	# Same-directory rename replaces the primary; never delete it before committing.
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return {"ok": false, "error": "Cannot commit save; recovery copy retained."}
	return {"ok": true}

func _write_verified(path: String, data: Dictionary, slot: int) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Cannot open save for writing."}
	file.store_string(SaveSerializer.encode(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return {"ok": false, "error": "Save write failed."}
	return read_file(path, slot)

func deletion_revision(slot: int) -> String:
	if not SaveConstants.valid_slot(slot): return ""
	var parts := ""
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		var path: String = path_for(slot) + suffix
		if FileAccess.file_exists(path): parts += suffix + FileAccess.get_sha256(path)
	return parts.sha256_text() if not parts.is_empty() else ""

func delete_slot(slot: int, confirmed_revision: String) -> Dictionary:
	if not SaveConstants.valid_slot(slot):
		return {"ok":false,"error":"Invalid save slot."}
	if confirmed_revision.is_empty() or deletion_revision(slot) != confirmed_revision:
		return {"ok":false,"error":"Save changed or is empty. Review the slot and confirm again."}
	# Exact known artifacts only. Remove recovery copies first to prevent resurrection.
	# Keep primary until last, and report IO failures instead of pretending success.
	for suffix in [".bak.tmp", ".tmp", ".bak", ""]:
		var path: String = path_for(slot) + suffix
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			return {"ok":false,"error":"Could not delete all save files. Review the slot and retry."}
	return {"ok":true}

