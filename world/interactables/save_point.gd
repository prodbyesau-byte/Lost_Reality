class_name WorldSavePoint
extends Interactable

var beacon: MeshInstance3D

func _ready() -> void:
	super._ready()
	name = "SavePoint"
	interaction_name = "Use SavePoint"
	beacon = WorldGeometry.box(self, Vector3(0, 0.58, 0), Vector3(0.65, 1.16, 0.65), Color("59695c"), true)
	beacon.material_override = ArtMaterials.surface("paint").duplicate()
	sight_body = beacon.get_parent() as StaticBody3D
	ArtMeshes.box(self,Vector3(0,1.19,0),Vector3(0.72,0.06,0.72),"wood_edge")
	ArtMeshes.box(self,Vector3(0,0.61,0.34),Vector3(0.52,0.84,0.035),"paint")
	ArtMeshes.box(self,Vector3(0.19,0.68,0.37),Vector3(0.04,0.18,0.035),"metal")
	ArtMeshes.box(self,Vector3(0.1,1.24,0.10),Vector3(0.29,0.03,0.34),"paper")
	ArtProps.work_lamp(self,Vector3(-0.17,1.45,-0.15),0.85,false)
	WorldGeometry.label(self, "SAVE POINT", Vector3(0, 1.98, 0), 25, Color("b6c6ac"))

func interact(_actor: PlayerActor) -> void:
	SaveManager.begin_manual_session(self)

func focus(active: bool) -> void:
	(beacon.material_override as StandardMaterial3D).albedo_color = Color("83927b") if active else Color("59695c")
