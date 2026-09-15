class_name PlayerActor
extends CharacterBody3D

@export var speed: float = 4.8
@export var acceleration: float = 25.0
@export var deceleration: float = 32.0
@export var turn_sharpness: float = 16.0
var camera_rig: IsometricCameraRig
var interactor: PlayerInteractor
var visual: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.25
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	visual = HumanVisual.new()
	add_child(visual)
	interactor = PlayerInteractor.new()
	interactor.name = "Interactor"
	add_child(interactor)

func _physics_process(delta: float) -> void:
	if SceneRouter.busy or camera_rig == null:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := camera_rig.movement_direction(input)
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	horizontal = horizontal.move_toward(direction * speed, (acceleration if not input.is_zero_approx() else deceleration) * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = -0.5 if is_on_floor() else velocity.y - 22.0 * delta
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-turn_sharpness * delta))
	move_and_slide()

func reset_motion() -> void:
	velocity = Vector3.ZERO
	if is_instance_valid(interactor):
		interactor.clear_focus()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
