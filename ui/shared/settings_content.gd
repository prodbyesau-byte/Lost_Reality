class_name SettingsContent
extends RefCounted
static func populate(content: VBoxContainer) -> void:
	content.add_child(UIStyle.label("DISPLAY",13,UIStyle.ACCENT))
	var quality := Button.new()
	quality.name = "Quality"
	quality.text = "Visual quality: " + ("Atmospheric" if VisualQuality.atmospheric else "Performance")
	quality.pressed.connect(func() -> void:
		VisualQuality.set_atmospheric(not VisualQuality.atmospheric)
		quality.text = "Visual quality: " + ("Atmospheric" if VisualQuality.atmospheric else "Performance")
	)
	content.add_child(quality)
	var fullscreen := UIStyle.label("Display: Fullscreen", 15, UIStyle.MUTED)
	fullscreen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(fullscreen)
	content.add_child(UIStyle.label("ACCESSIBILITY",13,UIStyle.ACCENT))
	var interference := CheckButton.new()
	interference.name = "Interference"
	interference.text = "Subtle interface interference"
	interference.button_pressed = MachineInterference.enabled
	interference.toggled.connect(func(value: bool) -> void: MachineInterference.enabled = value)
	content.add_child(interference)


static func refresh(content: VBoxContainer) -> void:
	content.get_node("Quality").text = "Visual quality: " + ("Atmospheric" if VisualQuality.atmospheric else "Performance")
	content.get_node("Interference").set_pressed_no_signal(MachineInterference.enabled)
