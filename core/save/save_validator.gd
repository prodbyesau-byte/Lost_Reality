class_name SaveValidator
extends RefCounted

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func json_safe(value: Variant, depth: int = 0) -> bool:
	if depth > 32:
		return false
	if value == null or value is bool or value is String:
		return true
	if value is int or value is float:
		return number(value)
	if value is Array:
		for entry in value:
			if not json_safe(entry, depth + 1):
				return false
		return true
	if value is Dictionary:
		for key in value:
			if not key is String or not json_safe(value[key], depth + 1):
				return false
		return true
	return false

static func vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and number(value[0]) and number(value[1]) and number(value[2])

static func validate(data: Dictionary, slot: int) -> String:
	if data.get("version") != SaveConstants.VERSION:
		return "Unexpected save version."
	if not data.get("metadata") is Dictionary:
		return "Missing save metadata."
	var meta: Dictionary = data.metadata
	if meta.get("slot") != slot or not SaveConstants.valid_slot(slot):
		return "Save belongs to a different slot."
	if not number(meta.get("timestamp")) or meta.timestamp <= 0:
		return "Invalid timestamp."
	if not number(meta.get("playtime")) or meta.playtime < 0:
		return "Invalid playtime."
	if not data.get("scene") is String or not LevelCatalog.valid_id(data.scene):
		return "Unknown scene."
	if not data.get("player") is Dictionary:
		return "Missing player transform."
	if not vector(data.player.get("position")) or not vector(data.player.get("rotation")):
		return "Invalid player transform."
	var pos := SaveSerializer.to_vector(data.player.position)
	var extent: float = LevelCatalog.LEVELS[data.scene].extent
	if absf(pos.x) > extent or absf(pos.z) > extent or pos.y < -0.1 or pos.y > 4.0:
		return "Player position outside level bounds."
	if not data.get("sections") is Dictionary or not json_safe(data.sections):
		return "Invalid persistent state."
	for key in data.sections:
		if not data.sections[key] is Dictionary:
			return "Save sections must be dictionaries."
	if not ProgressionSchema.valid(data.sections.get("progression")):
		return "Invalid or missing progression data."
	# Existing world objects have a small, explicit schema. Unknown namespaces survive.
	var world: Variant = data.sections.get("world", {})
	for key in world:
		if not world[key] is bool:
			return "Invalid world object state."
	return ""
