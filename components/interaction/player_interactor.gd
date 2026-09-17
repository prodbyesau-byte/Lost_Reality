class_name PlayerInteractor
extends Node

var focused: Interactable

func _physics_process(_delta: float) -> void:
	if SceneRouter.busy:
		clear_focus()
		return
	var nearest: Interactable
	var distance := INF
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if can_interact(candidate):
			var next_distance: float = get_parent().global_position.distance_squared_to(candidate.global_position)
			if next_distance < distance:
				distance = next_distance
				nearest = candidate
	if nearest != focused:
		clear_focus()
		focused = nearest
		if is_instance_valid(focused):
			focused.focus(true)
	EventBus.interaction_focus_changed.emit(focused.prompt() if is_instance_valid(focused) else "")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not SceneRouter.busy:
		if is_instance_valid(focused) and can_interact(focused):
			focused.interact(get_parent())
			get_viewport().set_input_as_handled()

func can_interact(candidate: Node3D) -> bool:
	if not is_instance_valid(candidate) or not candidate is Interactable or not candidate.is_inside_tree():
		return false
	var actor := get_parent() as PlayerActor
	if actor.global_position.distance_to(candidate.global_position) > candidate.interaction_radius:
		return false
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, candidate.global_position + Vector3.UP, 1)
	query.exclude = [actor.get_rid()]
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == candidate.sight_body

func clear_focus() -> void:
	if is_instance_valid(focused):
		focused.focus(false)
	focused = null
	EventBus.interaction_focus_changed.emit("")

