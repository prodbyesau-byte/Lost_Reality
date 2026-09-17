class_name HumanVisual
extends Node3D
## Ordinary adult silhouette. Presentation-only joints; physics remains on PlayerActor.
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
var phase: float = 0.0

func _ready() -> void:
	PlayerOutfit.dress(self)
	ArtMeshes.cylinder(self,Vector3(0,1.38,0),Vector3(0,1.49,0),0.063,"player_skin")
	PlayerOutfit.head(self)
	PlayerOutfit.hair(self)
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.09,0.83,0)
		add_child(leg)
		ArtMeshes.profile(leg,[Vector3(0.065,-0.36,0.067),Vector3(0.07,-0.29,0.075),Vector3(0.095,-0.13,0.099),Vector3(0.097,-0.02,0.10),Vector3(0.08,0.025,0.09)],"player_denim")
		var knee := Node3D.new()
		knee.position.y = -0.35
		leg.add_child(knee)
		ArtMeshes.profile(knee,[Vector3(0.061,-0.34,0.063),Vector3(0.063,-0.29,0.065),Vector3(0.077,-0.17,0.076),Vector3(0.071,-0.04,0.071),Vector3(0.064,0.02,0.067)],"player_denim")
		ArtMeshes.rounded(knee,Vector3(0,-0.395,-0.045),Vector3(0.15,0.15,0.28),"rubber",0.060)
		ArtMeshes.rounded(knee,Vector3(0,-0.451,-0.045),Vector3(0.153,0.036,0.283),"player_laces",0.015)
		for lace in 4:
			ArtMeshes.cylinder(knee,Vector3(-0.040,-0.334-lace*0.006,-0.037-lace*0.022),Vector3(0.040,-0.334-lace*0.006,-0.055-lace*0.022),0.003,"player_laces")
		ArtMeshes.rounded(leg,Vector3(0,-0.07,0.096),Vector3(0.11,0.14,0.01),"player_denim",0.004)
		knees.append(knee)
		legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side*0.23,1.31,0)
		arm.rotation.z = side*0.09
		add_child(arm)
		ArtMeshes.profile(arm,[Vector3(0.053,-0.24,0.052),Vector3(0.064,-0.15,0.067),Vector3(0.079,-0.04,0.077),Vector3(0.071,0.025,0.065),Vector3(0.039,0.05,0.044)],"player_hoodie")
		var elbow := Node3D.new()
		elbow.position.y = -0.23
		elbow.rotation.x = -0.10
		arm.add_child(elbow)
		ArtMeshes.profile(elbow,[Vector3(0.043,-0.24,0.045),Vector3(0.046,-0.19,0.048),Vector3(0.061,-0.09,0.06),Vector3(0.055,0.018,0.055)],"player_hoodie")
		ArtMeshes.ellipsoid(elbow,Vector3(0,-0.285,0),Vector3(0.076,0.105,0.051),"player_skin")
		ArtMeshes.ellipsoid(elbow,Vector3(-side*0.038,-0.275,-0.006),Vector3(0.028,0.065,0.028),"player_skin")
		for finger in 4:
			ArtMeshes.ellipsoid(elbow,Vector3(-0.024+finger*0.016,-0.342+absf(finger-1.5)*0.008,-0.006),Vector3(0.017,0.065,0.022),"player_skin")
		elbows.append(elbow)
		arms.append(arm)

func _process(delta: float) -> void:
	var actor := get_parent() as CharacterBody3D
	if actor == null:
		return
	var speed := Vector2(actor.velocity.x,actor.velocity.z).length()
	phase += speed*delta*3.0
	var amplitude := clampf(speed/4.8,0,1)*0.48
	for i in legs.size():
		var swing := sin(phase+i*PI)*amplitude
		legs[i].rotation.x = lerpf(legs[i].rotation.x,swing,1.0-exp(-14*delta))
		arms[i].rotation.x = -legs[i].rotation.x*0.65
		knees[i].rotation.x = lerpf(knees[i].rotation.x,maxf(0,-sin(phase+i*PI))*amplitude*1.3,1.0-exp(-14*delta))
		elbows[i].rotation.x = -0.1-absf(swing)*0.35
