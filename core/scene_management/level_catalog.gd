class_name LevelCatalog
extends RefCounted
## Stable IDs are persisted; arbitrary paths from save files are never loaded.
const LEVELS: Dictionary = {
	"tenement": {"path": "res://world/test_area/tenement.tscn", "title": "The Tenement", "extent": 14.0},
	"courtyard": {"path": "res://world/test_area/courtyard.tscn", "title": "The Courtyard", "extent": 14.0},
}

static func valid_id(id: String) -> bool:
	return LEVELS.has(id)

static func title(id: String) -> String:
	return LEVELS.get(id, {}).get("title", id)
