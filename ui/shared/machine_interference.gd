class_name MachineInterference
extends Control
## Rare decorative interference. No text, focus, hitboxes or saved data are altered.
static var enabled := true
var remaining := 0.0
var cooldown := 18.0
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	cooldown = rng.randf_range(18,34)
func _process(delta: float) -> void:
	if not is_visible_in_tree() or not enabled:
		if remaining > 0:
			remaining = 0
			queue_redraw()
		return
	cooldown -= delta
	if cooldown <= 0:
		remaining = 0.12
		cooldown = rng.randf_range(24,45)
	if remaining > 0:
		remaining = maxf(0,remaining-delta)
		queue_redraw()
func _draw() -> void:
	if remaining <= 0 or not enabled: return
	# Interference is confined to the top enclosure rail, away from controls.
	draw_line(Vector2(size.x*0.64,7),Vector2(size.x*0.84,7),Color(0.53,0.68,0.71,0.25),1)
	draw_line(Vector2(size.x*0.70,10),Vector2(size.x*0.78,10),Color(0.72,0.78,0.8,0.16),1)
