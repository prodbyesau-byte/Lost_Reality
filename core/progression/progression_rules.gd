class_name ProgressionRules
extends RefCounted
static var _data: Dictionary = {}

static func config() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
	return _data.duplicate(true)

static func maximum_level() -> int:
	return int(config().maximum_level)

static func xp_required(level: int) -> int:
	if level >= maximum_level():
		return 0
	var rules := config()
	return int(rules.first_level_xp) + level * int(rules.xp_increase_per_level)

static func points_at_level(level: int) -> int:
	if level < 1:
		return 0
	return int(config().first_level_attribute_points if level == 1 else config().later_level_attribute_points)

static func total_points(level: int) -> int:
	if level < 1:
		return 0
	return points_at_level(1) + (level - 1) * int(config().later_level_attribute_points)
