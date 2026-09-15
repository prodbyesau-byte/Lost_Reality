class_name StatCatalog
extends RefCounted
## Stable IDs; future combat reads these values without owning allocation or persistence.
const NAMES: Dictionary = {
	"strength": "Strength", "fitness": "Fitness", "dexterity": "Dexterity",
	"perception": "Perception", "intelligence": "Intelligence", "willpower": "Willpower",
}

static func zero_stats() -> Dictionary:
	var result := {}
	for id in NAMES:
		result[id] = 0
	return result
