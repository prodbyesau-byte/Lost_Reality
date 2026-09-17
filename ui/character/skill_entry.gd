class_name CharacterSkillEntry
extends PanelContainer
var state_label: Label
var level_label: Label
var progress: ProgressBar
var modifiers: Label

func configure(skill_name: String, description: String) -> void:
	add_theme_stylebox_override("panel",CharacterTheme.box(CharacterTheme.SURFACE,CharacterTheme.DIM,12))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",5)
	add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var title := CharacterTheme.label(skill_name,18,CharacterTheme.TEXT,true)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title)
	state_label = CharacterTheme.label("UNAVAILABLE",10,CharacterTheme.MUTED)
	row.add_child(state_label)
	var detail := CharacterTheme.label(description,13,CharacterTheme.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	level_label = CharacterTheme.label("",12,CharacterTheme.ACCENT)
	column.add_child(level_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 7
	progress.show_percentage = false
	column.add_child(progress)
	modifiers = CharacterTheme.label("",12,CharacterTheme.ACCENT)
	column.add_child(modifiers)
	set_record({})

func set_record(record: Dictionary) -> void:
	# Empty records deliberately have no fabricated level, XP or progression bar.
	var available: bool = record.get("available",false)
	state_label.text = "ACTIVE" if available else "UNAVAILABLE"
	level_label.visible = available and record.has("level")
	if level_label.visible:
		level_label.text = "Level %d" % int(record.level)
	progress.visible = available and record.has("xp") and record.get("xp_required",0) > 0
	if progress.visible:
		progress.max_value = record.xp_required
		progress.value = record.xp
		level_label.text += "  ·  %d / %d XP" % [record.xp,record.xp_required]
	modifiers.text = str(record.get("modifiers","")) if available else ""
	modifiers.visible = not modifiers.text.is_empty()
