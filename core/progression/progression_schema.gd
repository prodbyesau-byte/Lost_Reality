class_name ProgressionSchema
extends RefCounted
## Pure validation used by both the save pipeline and runtime commands.
static func defaults() -> Dictionary:
	return {
		"level": 0, "xp": 0, "stats": StatCatalog.zero_stats(), "attribute_points": 0,
		"profession_unlocks": ProfessionCatalog.unlocks(0, StatCatalog.zero_stats()),
		"selected_profession": "",
	}

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if not integer(value.get("level"), 0, ProgressionRules.maximum_level()):
		return false
	var level := int(value.level)
	var xp_limit := maxi(0, ProgressionRules.xp_required(level) - 1)
	if not integer(value.get("xp"), 0, xp_limit):
		return false
	var budget := ProgressionRules.total_points(level)
	if not integer(value.get("attribute_points"), 0, budget):
		return false
	if not value.get("stats") is Dictionary or value.stats.size() != StatCatalog.NAMES.size():
		return false
	var spent: int = 0
	for id in StatCatalog.NAMES:
		if not integer(value.stats.get(id), 0, budget):
			return false
		spent += int(value.stats[id])
	if spent + int(value.attribute_points) != budget:
		return false
	if not value.get("profession_unlocks") is Dictionary:
		return false
	var expected := ProfessionCatalog.unlocks(level, value.stats)
	if value.profession_unlocks.size() != expected.size():
		return false
	for id in expected:
		if not value.profession_unlocks.get(id) is bool or value.profession_unlocks[id] != expected[id]:
			return false
	if not value.get("selected_profession") is String:
		return false
	var selected: String = value.selected_profession
	return selected.is_empty() or (expected.has(selected) and expected[selected])
