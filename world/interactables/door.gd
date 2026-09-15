class_name WorldDoor
extends Interactable

var persistent_id: String
var opened: bool = false
var panel: MeshInstance3D
var collider: CollisionShape3D

func _ready() -> void:
	super._ready()
	panel = WorldGeometry.box(self, Vector3(0, 1.2, 0), Vector3(1.8, 2.4, 0.18), Color("8b7862"), true)
	panel.material_override = ArtMaterials.surface("wood")
	sight_body = panel.get_parent() as StaticBody3D
	collider = sight_body.get_child(0) as CollisionShape3D
	for y in [-0.64,0.39]:
		ArtMeshes.box(panel,Vector3(0,y,0.11),Vector3(1.38,0.72,0.045),"wood_edge")
		ArtMeshes.box(panel,Vector3(0,y,0.139),Vector3(1.22,0.56,0.025),"wood")
	ArtMeshes.box(panel,Vector3(0.64,-0.13,0.15),Vector3(0.06,0.24,0.04),"metal")
	ArtMeshes.box(panel,Vector3(0.55,-0.06,0.19),Vector3(0.22,0.045,0.04),"metal")
	for x in [-0.96,0.96]:
		ArtMeshes.box(self,Vector3(x,1.2,0),Vector3(0.11,2.48,0.31),"wood_edge")
	ArtMeshes.box(self,Vector3(0,2.44,0),Vector3(2.03,0.12,0.31),"wood_edge")
	apply_state()

func prompt() -> String:
	return "Close door" if opened else "Open door"

func interact(_actor: PlayerActor) -> void:
	if opened:
		# Prevent closing the collision panel through the player.
		var local := to_local(_actor.global_position)
		if absf(local.x) < 1.25 and absf(local.z) < 0.55:
			EventBus.message_requested.emit("Step clear of the doorway before closing it.")
			return
	opened = not opened
	var state := GameState.get_section("world")
	state[persistent_id] = opened
	GameState.set_section("world", state)
	_update_panel()

func apply_state() -> void:
	opened = GameState.get_section("world").get(persistent_id, false)
	_update_panel()

func _update_panel() -> void:
	if collider == null:
		return
	collider.set_deferred("disabled", opened)
	panel.visible = true
	panel.rotation.y = -PI/2 if opened else 0.0
	panel.position = Vector3(-0.9,0,0.9) if opened else Vector3.ZERO
