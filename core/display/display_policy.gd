extends Node
## The desktop owns the physical resolution; the game always fills that desktop.
## Minimize/Alt-Tab remain OS actions, and restoring resumes fullscreen.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.size_changed.connect(_enforce_fullscreen, CONNECT_DEFERRED)
	get_tree().root.focus_entered.connect(_enforce_fullscreen, CONNECT_DEFERRED)
	_enforce_fullscreen()

func _process(_delta: float) -> void:
	# Window has no mode_changed signal. Also protects paused menus and external changes.
	_enforce_fullscreen()

func _enforce_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_tree().root
	if window.mode != Window.MODE_FULLSCREEN and window.mode != Window.MODE_MINIMIZED:
		window.mode = Window.MODE_FULLSCREEN

func _input(event: InputEvent) -> void:
	if is_fullscreen_shortcut(event):
		get_viewport().set_input_as_handled()

func is_fullscreen_shortcut(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	return key.keycode == KEY_F11 or key.physical_keycode == KEY_F11 or (key.alt_pressed and (key.keycode in [KEY_ENTER, KEY_KP_ENTER] or key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]))
