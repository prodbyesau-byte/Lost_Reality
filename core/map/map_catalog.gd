class_name MapCatalog
extends RefCounted
## Only trusted project definitions are loaded; saves contain IDs, never paths.
static var _definitions: Dictionary = {}
static var _areas: Dictionary = {}

static func definitions() -> Dictionary:
	if _definitions.is_empty():
		_definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps.json"))
	return _definitions

static func area(id: String, floor_id: String = "0") -> MapAreaData:
	var data: Dictionary = definitions().get(id, {})
	if not data.get("floors", {}).has(floor_id):
		return null
	var key := id + ":" + floor_id
	if not _areas.has(key):
		var geometry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data.layout))
		_areas[key] = MapAreaData.new(id, floor_id, data.floors[floor_id], geometry)
	return _areas[key]

static func zone(id: String) -> MapAreaData:
	var parts := id.split(":")
	return area(parts[0], parts[1]) if parts.size() == 2 else null

static func floor_at(id: String, height: float) -> String:
	for key in definitions().get(id, {}).get("floors", {}):
		var floor_data: Dictionary = definitions()[id].floors[key]
		if height >= floor_data.min_y and height < floor_data.max_y:
			return key
	return ""
