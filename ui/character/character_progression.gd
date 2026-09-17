class_name CharacterProgression
extends VBoxContainer
## Content hosted by the existing pause menu so only one UI owns pause/input.
var summary: Label
var xp_bar: ProgressBar
var points: Label
var profession_summary: Label
var feedback: Label
var stat_labels: Dictionary = {}
var allocation_buttons: Dictionary = {}
var profession_buttons: Dictionary = {}
var profession_labels: Dictionary = {}
var debug_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	summary = UIStyle.label("", 21)
	add_child(summary)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size.y = 12
	xp_bar.show_percentage = false
	add_child(xp_bar)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	add_child(columns)
	var stats := VBoxContainer.new()
	stats.custom_minimum_size.x = 365
	stats.add_theme_constant_override("separation", 8)
	columns.add_child(stats)
	stats.add_child(UIStyle.label("ATTRIBUTES", 16, UIStyle.ACCENT))
	points = UIStyle.label("", 16)
	stats.add_child(points)
	stats.add_child(UIStyle.label("Base  +  profession  =  total", 14, UIStyle.MUTED))
	for id in StatCatalog.NAMES:
		var row := HBoxContainer.new()
		stats.add_child(row)
		var label := UIStyle.label("", 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		stat_labels[id] = label
		var button := Button.new()
		button.text = "+"
		button.pressed.connect(_allocate.bind(id))
		row.add_child(button)
		allocation_buttons[id] = button
	var professions := VBoxContainer.new()
	professions.custom_minimum_size.x = 460
	professions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	professions.add_theme_constant_override("separation", 8)
	columns.add_child(professions)
	professions.add_child(UIStyle.label("PROFESSIONS", 16, UIStyle.ACCENT))
	profession_summary = UIStyle.label("", 16)
	professions.add_child(profession_summary)
	var definitions := ProfessionCatalog.definitions()
	for id in definitions:
		var definition: Dictionary = definitions[id]
		var row := HBoxContainer.new()
		professions.add_child(row)
		var label := UIStyle.label("", 17)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		profession_labels[id] = label
		var button := Button.new()
		button.text = "Select"
		button.pressed.connect(_select.bind(id))
		row.add_child(button)
		profession_buttons[id] = button
		var description := UIStyle.label(definition.description, 14, UIStyle.MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		professions.add_child(description)
		var bonus_parts: PackedStringArray = []
		for stat_id in StatCatalog.NAMES:
			var bonus := ProfessionCatalog.stat_bonus(id, stat_id)
			if bonus != 0:
				bonus_parts.append("%s %+d" % [StatCatalog.NAMES[stat_id], bonus])
		professions.add_child(UIStyle.label(" / ".join(bonus_parts), 14, UIStyle.ACCENT))
	var note := UIStyle.label("Profession bonuses apply only while active. Switching never stacks them.\nBase attributes have no gameplay effects yet.", 14, UIStyle.MUTED)
	add_child(note)
	var testing := HBoxContainer.new()
	testing.add_theme_constant_override("separation", 16)
	add_child(testing)
	debug_button = Button.new()
	debug_button.text = "DEBUG: Award 100 XP"
	debug_button.pressed.connect(_debug_xp)
	testing.add_child(debug_button)
	feedback = UIStyle.label("", 15, UIStyle.ACCENT)
	feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	testing.add_child(feedback)
	EventBus.progression_changed.connect(refresh)
	refresh()

func refresh() -> void:
	var state := Progression.snapshot()
	var required := ProgressionRules.xp_required(int(state.level))
	summary.text = "Level %d   /   XP %d / %d   /   %d XP to next level" % [state.level, state.xp, required, required - int(state.xp)] if required > 0 else "Level %d   /   Maximum test level" % state.level
	xp_bar.max_value = required if required > 0 else 1
	xp_bar.value = state.xp if required > 0 else 1
	points.text = "Available points: %d" % state.attribute_points if state.level >= 1 else "Locked until Level 1  /  Available points: 0"
	for id in stat_labels:
		stat_labels[id].text = "%s   %d + %d = %d" % [StatCatalog.NAMES[id], state.stats[id], Progression.stat_bonus(id), Progression.effective_stat(id)]
		allocation_buttons[id].disabled = state.level < 1 or state.attribute_points < 1
	var definitions := ProfessionCatalog.definitions()
	var current: String = state.selected_profession
	profession_summary.text = "Current: " + ("None" if current.is_empty() else str(definitions[current].name))
	for id in profession_labels:
		var selected: bool = id == current
		var unlocked: bool = state.profession_unlocks[id]
		profession_labels[id].text = "%s  /  %s" % [definitions[id].name, "Active" if selected else ("Unlocked" if unlocked else "Locked")]
		profession_buttons[id].text = "Active" if selected else "Select"
		profession_buttons[id].disabled = selected or not unlocked
	debug_button.disabled = state.level >= ProgressionRules.maximum_level()

func _allocate(id: String) -> void:
	var result := Progression.allocate_attribute(id)
	feedback.text = "Attribute point allocated." if result.ok else result.error

func _select(id: String) -> void:
	var result := Progression.select_profession(id)
	feedback.text = "Profession activated." if result.ok else result.error

func _debug_xp() -> void:
	var result := Progression.debug_award_xp()
	feedback.text = "Awarded 100 XP." if result.ok else result.error
