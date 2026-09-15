class_name Interactable
extends Node3D
## Extend this component and override prompt()/interact(). Selection uses range + LOS.
@export var interaction_name: String = "Inspect"
@export var interaction_radius: float = 2.3
var sight_body: CollisionObject3D

func _ready() -> void:
	add_to_group("interactables")

func prompt() -> String:
	return interaction_name

func interact(_actor: PlayerActor) -> void:
	EventBus.message_requested.emit(interaction_name)

func focus(_active: bool) -> void:
	pass
