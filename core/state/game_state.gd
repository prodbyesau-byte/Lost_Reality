extends Node
## JSON-only namespaced persistence. Future systems own a section, not a save file.
## Registered validators must be pure: they run before any loaded state is applied.
var sections: Dictionary = {}
var total_playtime: float = 0.0
var _validators: Dictionary = {}
var _defaults: Dictionary = {}

func _process(delta: float) -> void:
	if is_instance_valid(SceneRouter.player) and not SceneRouter.busy:
		total_playtime += delta

func register_section(key: String, validator: Callable, defaults: Dictionary = {}) -> bool:
	if key.is_empty() or _validators.has(key) or not validator.is_valid():
		return false
	_validators[key] = validator
	if not defaults.is_empty():
		_defaults[key] = defaults.duplicate(true)
		if not sections.has(key):
			sections[key] = defaults.duplicate(true)
	return true

func validate_sections(value: Dictionary) -> String:
	for key in _validators:
		if _defaults.has(key) and not value.has(key):
			return "Missing required section: " + key
		if value.has(key) and not _validators[key].call(value[key]):
			return "Invalid data in section: " + key
	return ""

func get_section(key: String) -> Dictionary:
	return sections.get(key, {}).duplicate(true)

func set_section(key: String, value: Dictionary) -> bool:
	if not SaveValidator.json_safe(value):
		return false
	if _validators.has(key) and not _validators[key].call(value):
		return false
	sections[key] = value.duplicate(true)
	return true

func snapshot() -> Dictionary:
	return sections.duplicate(true)

func restore(value: Dictionary, playtime: float) -> void:
	sections = value.duplicate(true)
	total_playtime = playtime

func reset() -> void:
	sections = _defaults.duplicate(true)
	total_playtime = 0.0
