class_name ProfessionCatalog
extends RefCounted
## Definitions are content. Unlock state and the single selected ID belong to progression.
static var _definitions: Dictionary = {}

static func definitions() -> Dictionary:
	if _definitions.is_empty():
		var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/professions.json"))
		for definition in entries:
			assert(not _definitions.has(definition.id), "Duplicate profession ID")
			_definitions[definition.id] = definition
	return _definitions.duplicate(true)

static func eligible(definition: Dictionary, level: int, stats: Dictionary) -> bool:
	# Level 1 is the system gate; individual professions may have stricter requirements.
	var requirements: Dictionary = definition.unlock_requirements
	if level < maxi(1, int(requirements.minimum_level)):
		return false
	for id in requirements.base_stats:
		if stats.get(id, 0) < requirements.base_stats[id]:
			return false
	return true

static func unlocks(level: int, stats: Dictionary) -> Dictionary:
	var result := {}
	var entries := definitions()
	for id in entries:
		result[id] = eligible(entries[id], level, stats)
	return result

static func stat_bonus(profession_id: String, stat_id: String) -> int:
	var definition: Dictionary = definitions().get(profession_id, {})
	if definition.is_empty():
		return 0
	# Bonuses are derived from the active profession, never repeatedly granted on selection.
	return int(definition.starting_bonuses.stats.get(stat_id, 0)) + int(definition.stat_modifiers.get(stat_id, 0))
