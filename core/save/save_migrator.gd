class_name SaveMigrator
extends RefCounted
## Explicit sequential migrations. Never mutate the source or downgrade newer saves.
static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version: Variant = data.get("version")
	if not (version is int or version is float) or not is_finite(float(version)) or float(version) != floor(float(version)):
		return {"ok": false, "error": "Missing or invalid save version."}
	if version > SaveConstants.VERSION:
		return {"ok": false, "future": true, "error": "This save requires a newer game version."}
	if version < 1:
		return {"ok": false, "error": "Unsupported save version."}
	if version == 1:
		if not data.get("game_state") is Dictionary:
			return {"ok": false, "error": "Invalid version 1 state."}
		data["sections"] = data.game_state
		data.erase("game_state")
		data["version"] = 2
	if data.version == 2:
		if not data.get("sections") is Dictionary:
			return {"ok": false, "error": "Invalid version 2 state."}
		# M1 has no progression. Preserve every existing namespace and the world transform.
		if not data.sections.has("progression"):
			data.sections["progression"] = ProgressionSchema.defaults()
		data["version"] = 3
	if data.version == 3:
		if not data.get("sections") is Dictionary:
			return {"ok": false, "error": "Invalid version 3 state."}
		if not data.sections.has("exploration"):
			data.sections["exploration"] = ExplorationSchema.defaults()
		data["version"] = 4
	return {"ok": true, "data": data}
