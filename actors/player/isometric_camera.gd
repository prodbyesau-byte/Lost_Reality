class_name IsometricCameraRig
extends Node3D

@export var follow_sharpness: float = 12.0
@export var zoom_sharpness: float = 14.0
@export var minimum_size: float = 10.0
@export var maximum_size: float = 28.0
var target: Node3D
var desired_size: float = 19.0
var camera: Camera3D

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = desired_size
	camera.near = 0.1
	camera.far = 180.0
	add_child(camera)
	camera.position = Vector3(22, 27, 22)
	camera.look_at(Vector3.ZERO)
	camera.current = true

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	global_position = global_position.lerp(target.global_position + Vector3.UP * 0.8, 1.0 - exp(-follow_sharpness * delta))
	var viewport_size := get_viewport().get_visible_rect().size
	# Retain the baseline horizontal view on narrow screens; wide screens reveal more.
	var framing := maxf(1.0, (1440.0 / 900.0) / maxf(viewport_size.aspect(), 0.01))
	camera.size = lerpf(camera.size, desired_size * framing, 1.0 - exp(-zoom_sharpness * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_zoom(-1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_zoom(1.5)

func adjust_zoom(amount: float) -> void:
	desired_size = clampf(desired_size + amount, minimum_size, maximum_size)

func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector3.UP * 0.8

func movement_direction(input: Vector2) -> Vector3:
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0
	forward.y = 0
	return (right.normalized() * input.x - forward.normalized() * input.y).limit_length(1.0)
