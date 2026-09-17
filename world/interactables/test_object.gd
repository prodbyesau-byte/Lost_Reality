class_name TestObject
extends Interactable
var persistent_id: String
var lamp: MeshInstance3D
var practical: OmniLight3D

func _ready() -> void:
	super._ready()
	interaction_name = "Activate"
	lamp = WorldGeometry.box(self, Vector3(0, 0.7, 0), Vector3(0.65, 1.4, 0.65), Color("bd9468"), true)
	sight_body = lamp.get_parent() as StaticBody3D
	lamp.hide()
	ArtMeshes.box(self,Vector3(0,0.05,0),Vector3(0.60,0.10,0.60),"rust")
	ArtMeshes.cylinder(self,Vector3(0,0.08,0),Vector3(0,1.3,0),0.04,"metal")
	practical = ArtProps.work_lamp(self,Vector3(0,1.3,0),2.4,true)
	apply_state()

func interact(_actor: PlayerActor) -> void:
	var state := GameState.get_section("world")
	state[persistent_id] = not state.get(persistent_id, false)
	GameState.set_section("world", state)
	apply_state()
	EventBus.message_requested.emit("Test lamp switched %s. Its state is persistent." % ("on" if state[persistent_id] else "off"))

func apply_state() -> void:
	var active: bool = GameState.get_section("world").get(persistent_id, false)
	var material := lamp.material_override as StandardMaterial3D
	material.emission_enabled = active
	material.emission = Color("edba73")
	material.albedo_color = Color("edba73") if active else Color("645c54")
	if is_instance_valid(practical):
		practical.visible = active
		# The light source itself follows the existing persistent toggle.
		var bulb := practical.get_parent().get_child(1) as MeshInstance3D
		(bulb.material_override as StandardMaterial3D).emission_enabled = active

