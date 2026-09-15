extends Node
## Commands atomically update one authoritative GameState section. No parallel cached state.
const SECTION: String = "progression"

func _ready() -> void:
	GameState.register_section(SECTION, ProgressionSchema.valid, ProgressionSchema.defaults())
	EventBus.load_completed.connect(func(_slot: int, _recovered: bool) -> void: _notify())
	EventBus.new_game_started.connect(_notify)

func snapshot() -> Dictionary:
	return GameState.get_section(SECTION)

func award_xp(amount: int) -> Dictionary:
	if amount <= 0 or amount > 1000000000:
		return {"ok": false, "error": "XP awards must be between 1 and 1,000,000,000."}
	if SceneRouter.busy or SaveManager.busy:
		return {"ok": false, "error": "Wait for the current save or transition."}
	var state := snapshot()
	if int(state.level) == ProgressionRules.maximum_level():
		return {"ok": false, "error": "Maximum test level reached."}
	var previous := int(state.level)
	state.xp = int(state.xp) + amount
	while int(state.level) < ProgressionRules.maximum_level() and int(state.xp) >= ProgressionRules.xp_required(int(state.level)):
		state.xp = int(state.xp) - ProgressionRules.xp_required(int(state.level))
		state.level = int(state.level) + 1
		state.attribute_points = int(state.attribute_points) + ProgressionRules.points_at_level(int(state.level))
	if int(state.level) == ProgressionRules.maximum_level():
		state.xp = 0
	state.profession_unlocks = ProfessionCatalog.unlocks(int(state.level), state.stats)
	if not GameState.set_section(SECTION, state):
		return {"ok": false, "error": "Progression validation failed."}
	# Commit first. Observers always see the final consistent state, including multi-level awards.
	for level in range(previous + 1, int(state.level) + 1):
		EventBus.level_up.emit(level)
		if level == 1:
			EventBus.progression_unlocked.emit()
	_notify()
	return {"ok": true, "levels_gained": int(state.level) - previous}

func allocate_attribute(stat_id: String) -> Dictionary:
	if SceneRouter.busy or SaveManager.busy:
		return {"ok": false, "error": "Wait for the current save or transition."}
	var state := snapshot()
	if not StatCatalog.NAMES.has(stat_id) or int(state.level) < 1 or int(state.attribute_points) < 1:
		return {"ok": false, "error": "No attribute point is available for this stat."}
	state.stats[stat_id] = int(state.stats[stat_id]) + 1
	state.attribute_points = int(state.attribute_points) - 1
	state.profession_unlocks = ProfessionCatalog.unlocks(int(state.level), state.stats)
	return _commit(state)

func select_profession(id: String) -> Dictionary:
	if SceneRouter.busy or SaveManager.busy:
		return {"ok": false, "error": "Wait for the current save or transition."}
	var state := snapshot()
	if int(state.level) < 1 or not state.profession_unlocks.get(id, false):
		return {"ok": false, "error": "This profession is locked."}
	if state.selected_profession == id:
		return {"ok": false, "error": "This profession is already active."}
	var previous: String = state.selected_profession
	state.selected_profession = id
	var result := _commit(state)
	if result.ok:
		EventBus.profession_changed.emit(previous, id)
	return result

func base_stat(id: String) -> int:
	return int(snapshot().stats.get(id, 0))

func stat_bonus(id: String) -> int:
	return ProfessionCatalog.stat_bonus(snapshot().selected_profession, id)

func effective_stat(id: String) -> int:
	return base_stat(id) + stat_bonus(id)

func skill_modifiers() -> Dictionary:
	var definition: Dictionary = ProfessionCatalog.definitions().get(snapshot().selected_profession, {})
	return definition.get("skill_modifiers", {}).duplicate(true)

func debug_award_xp(amount: int = 100) -> Dictionary:
	# Explicit test entry point; no natural XP sources are implemented in Milestone 2.
	return award_xp(amount)

func _commit(state: Dictionary) -> Dictionary:
	if not GameState.set_section(SECTION, state):
		return {"ok": false, "error": "Progression validation failed."}
	_notify()
	return {"ok": true}

func _notify() -> void:
	EventBus.progression_changed.emit()
