class_name CharacterPanel
extends PanelContainer
signal close_requested
var active_tab := "PLAYER"
var player_tab: VBoxContainer
var skills_tab: VBoxContainer
var player_button: Button
var skills_button: Button
var preview: CharacterPreview
var sockets: Dictionary = {}
var skill_entries: Dictionary = {}
var progression: CharacterProgression
var progression_scroll: ScrollContainer
var groups: GridContainer
var progression_toggle: Button
var identity: Label
var selected_hint: Label
var tabs: HBoxContainer
var allocation_buttons: Dictionary:
	get: return progression.allocation_buttons
var profession_buttons: Dictionary:
	get: return progression.profession_buttons
var summary: Label:
	get: return progression.summary
var feedback: Label:
	get: return progression.feedback
var debug_button: Button:
	get: return progression.debug_button

func _ready() -> void:
	custom_minimum_size = Vector2(1100,790)
	theme = CharacterTheme.theme()
	add_theme_stylebox_override("panel",CharacterTheme.box(Color(0,0,0,0),Color(0,0,0,0),0))
	var frame := CharacterFrame.new()
	add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left","right"]:
		margin.add_theme_constant_override("margin_"+side,40)
	margin.add_theme_constant_override("margin_top",25)
	margin.add_theme_constant_override("margin_bottom",20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(CharacterTheme.label("LOST REALITY",11,CharacterTheme.ACCENT))
	titles.add_child(CharacterTheme.label("SUBJECT STATUS",30,CharacterTheme.TEXT,true))
	identity = CharacterTheme.label("",14,CharacterTheme.MUTED)
	identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(identity)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(38,38)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",4)
	column.add_child(tabs)
	var tab_group := ButtonGroup.new()
	for title in ["PLAYER","SKILLS"]:
		var button := Button.new()
		button.text = title
		button.custom_minimum_size = Vector2(180,40)
		button.toggle_mode = true
		button.button_group = tab_group
		button.pressed.connect(select_tab.bind(title))
		tabs.add_child(button)
		if title == "PLAYER": player_button = button
		else: skills_button = button
	player_tab = VBoxContainer.new()
	player_tab.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(player_tab)
	_build_player()
	skills_tab = VBoxContainer.new()
	skills_tab.size_flags_vertical = SIZE_EXPAND_FILL
	skills_tab.add_theme_constant_override("separation",14)
	column.add_child(skills_tab)
	_build_skills()
	var footer := HBoxContainer.new()
	column.add_child(footer)
	var left := CharacterTheme.label("",11,CharacterTheme.MUTED)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	footer.add_child(left)
	footer.add_child(CharacterTheme.label("LOST REALITY",11,CharacterTheme.DIM))
	EventBus.progression_changed.connect(refresh)
	select_tab("PLAYER")
	refresh()

func _build_player() -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",26)
	player_tab.add_child(body)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation",25)
	body.add_child(left)
	var selection := ButtonGroup.new()
	for record in [["head","Head"],["chest","Upper\nbody"],["legs","Lower\nbody"]]:
		_socket(left,record[0],record[1],selection)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = SIZE_EXPAND_FILL
	middle.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(middle)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(470,465)
	stage.size_flags_vertical = SIZE_EXPAND_FILL
	middle.add_child(stage)
	var backdrop := CharacterBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)
	preview = CharacterPreview.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(preview)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation",17)
	body.add_child(right)
	for record in [["necklace","Necklace"],["ring_1","Ring I"],["ring_2","Ring II"],["feet","Feet"]]:
		_socket(right,record[0],record[1],selection)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation",20)
	player_tab.add_child(bottom)
	_socket(bottom,"main_hand","Main\nhand",selection)
	_socket(bottom,"off_hand","Off\nhand",selection)
	selected_hint = CharacterTheme.label("Equipment unavailable · Current clothing shown",12,CharacterTheme.MUTED)
	selected_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_tab.add_child(selected_hint)

func _socket(parent: Node, id: String, title: String, group: ButtonGroup) -> void:
	var socket := EquipmentSocket.new()
	socket.slot_id = id
	socket.title = title
	socket.button_group = group
	socket.pressed.connect(func() -> void: selected_hint.text = title.replace("\n"," ")+" · Equipment unavailable")
	parent.add_child(socket)
	sockets[id] = socket

func _build_skills() -> void:
	skills_tab.add_child(CharacterTheme.label("SKILL RECORDS",25,CharacterTheme.TEXT,true))
	skills_tab.add_child(CharacterTheme.label("These disciplines are not available yet. No skill levels or XP have been assigned.",13,CharacterTheme.MUTED))
	groups = GridContainer.new()
	groups.columns = 2
	groups.size_flags_vertical = SIZE_EXPAND_FILL
	groups.add_theme_constant_override("h_separation",24)
	groups.add_theme_constant_override("v_separation",17)
	skills_tab.add_child(groups)
	var definitions := [
		["COMBAT",[["Firearms","Handling and knowledge of firearms."],["Melee","Close-range weapon technique."]]],
		["TECHNICAL",[["Engineering","Understanding structures and applied systems."],["Mechanics","Repair and maintenance of machinery."],["Electronics","Working with circuits and electrical devices."]]],
		["SURVIVAL / SUPPORT",[["Medicine","First aid and medical knowledge."],["Survival","Practical knowledge for hostile conditions."]]],
		["KNOWLEDGE",[["Investigation","Reading evidence and examining surroundings."],["Occult Knowledge","Understanding unfamiliar rituals and phenomena."]]]]
	for definition in definitions:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",8)
		groups.add_child(column)
		column.add_child(CharacterTheme.label(definition[0],12,CharacterTheme.ACCENT))
		for skill in definition[1]:
			var entry := CharacterSkillEntry.new()
			column.add_child(entry)
			entry.configure(skill[0],skill[1])
			skill_entries[skill[0]] = entry
	progression_toggle = Button.new()
	progression_toggle.text = "Attributes & profession   +"
	progression_toggle.pressed.connect(_toggle_progression)
	skills_tab.add_child(progression_toggle)
	progression_scroll = ScrollContainer.new()
	progression_scroll.custom_minimum_size.y = 415
	progression_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	progression_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skills_tab.add_child(progression_scroll)
	progression = CharacterProgression.new()
	progression.size_flags_horizontal = SIZE_EXPAND_FILL
	progression_scroll.add_child(progression)
	for node in progression.find_children("*","Label",true,false):
		node.add_theme_color_override("font_color",CharacterTheme.TEXT)
	progression_scroll.hide()

func _toggle_progression() -> void:
	var expanded := not progression_scroll.visible
	progression_scroll.visible = expanded
	groups.visible = not expanded
	progression_toggle.text = "Attributes & profession   −" if expanded else "Attributes & profession   +"

func open_default() -> void:
	progression_scroll.hide()
	groups.show()
	progression_toggle.text = "Attributes & profession   +"
	feedback.text = ""
	preview.sync_player()
	select_tab("PLAYER")
	refresh()
	player_button.grab_focus()

func select_tab(id: String) -> void:
	active_tab = id
	player_tab.visible = id == "PLAYER"
	skills_tab.visible = id == "SKILLS"
	player_button.button_pressed = id == "PLAYER"
	skills_button.button_pressed = id == "SKILLS"
	preview.dragging = false
	preview.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if id == "PLAYER" and is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func refresh() -> void:
	if not is_instance_valid(progression): return
	progression.refresh()
	var state := Progression.snapshot()
	var profession_name := "No profession" if state.selected_profession.is_empty() else str(ProfessionCatalog.definitions()[state.selected_profession].name)
	identity.text = "Level %d   ·   %s" % [state.level,profession_name]


