class_name LevelExit
extends Interactable
var destination: String
var entrance: String = "entry"

func _ready() -> void:
	super._ready()
	interaction_radius = 2.5
	interaction_name = "Travel to " + LevelCatalog.title(destination)
	ArtMeshes.box(self,Vector3(0,0.03,0),Vector3(2,0.05,1.1),"concrete")
	for x in [-1.0, 1.0]:
		ArtMeshes.box(self,Vector3(x,1.3,0),Vector3(0.15,2.6,0.3),"metal")
	ArtMeshes.box(self,Vector3(0,2.6,0),Vector3(2.15,0.15,0.3),"metal")
	ArtMeshes.box(self,Vector3(0,2.86,0),Vector3(1.9,0.33,0.07),"paint")
	ArtProps.work_lamp(self,Vector3(0,3.18,0),0.65,false)
	WorldGeometry.label(self, LevelCatalog.title(destination).to_upper() + "  →", Vector3(0, 2.90, 0.1), 26, Color("d7c5a4"))

func interact(_actor: PlayerActor) -> void:
	var result: Dictionary = await SceneRouter.travel(destination, entrance)
	if not result.ok:
		EventBus.message_requested.emit(result.error)
