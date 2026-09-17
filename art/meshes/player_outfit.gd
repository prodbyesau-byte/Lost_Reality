class_name PlayerOutfit
extends RefCounted
## Reference outfit geometry. Cosmetic only: the backpack is not an inventory system.

static func dress(parent: Node3D) -> void:
	var shirt := ArtMeshes.profile(parent,[Vector3(0.14,0.80,0.10),Vector3(0.16,0.86,0.112),Vector3(0.151,1.02,0.102),Vector3(0.175,1.22,0.118),Vector3(0.18,1.31,0.103),Vector3(0.073,1.39,0.067)],"player_shirt",32)
	shirt.name = "GreyTShirt"
	_open_jacket(parent)
	# Hood rests behind the neck; front edges frame the exposed shirt.
	ArtMeshes.tube(parent,[Vector3(-0.092,1.34,-0.064),Vector3(-0.142,1.38,0.017),Vector3(-0.118,1.40,0.107),Vector3(0,1.36,0.155),Vector3(0.118,1.40,0.107),Vector3(0.142,1.38,0.017),Vector3(0.092,1.34,-0.064)],[0.028,0.041,0.053,0.068,0.053,0.041,0.028],"player_hoodie",16)
	for side in [-1,1]:
		ArtMeshes.tube(parent,[Vector3(side*0.079,1.34,-0.090),Vector3(side*0.082,1.20,-0.124),Vector3(side*0.085,1.15,-0.133)],[0.004,0.0035,0.004],"player_laces",8)
		ArtMeshes.tube(parent,[Vector3(side*0.080,1.34,-0.098),Vector3(side*0.072,1.17,-0.123),Vector3(side*0.062,0.98,-0.124),Vector3(side*0.068,0.81,-0.108)],[0.004,0.004,0.004,0.004],"metal",8)
		var pocket := ArtMeshes.rounded(parent,Vector3(side*0.121,0.915,-0.093),Vector3(0.092,0.145,0.024),"player_hoodie",0.011)
		pocket.rotation.z = -side*0.10
	# Padded backpack and front pocket, sized to the back instead of the collision capsule.
	var pack := Node3D.new()
	pack.name = "CanvasBackpack"
	parent.add_child(pack)
	ArtMeshes.rounded(pack,Vector3(0,1.08,0.185),Vector3(0.30,0.44,0.17),"player_pack",0.079)
	ArtMeshes.rounded(pack,Vector3(0,0.985,0.278),Vector3(0.252,0.20,0.06),"player_pack",0.028)
	ArtMeshes.tube(pack,[Vector3(-0.125,1.18,0.24),Vector3(-0.10,1.27,0.235),Vector3(0,1.295,0.232),Vector3(0.10,1.27,0.235),Vector3(0.125,1.18,0.24)],[0.004,0.004,0.004,0.004,0.004],"player_laces",8)
	ArtMeshes.cylinder(pack,Vector3(-0.102,1.075,0.314),Vector3(0.102,1.075,0.314),0.004,"metal")
	ArtMeshes.tube(pack,[Vector3(-0.05,1.29,0.16),Vector3(-0.04,1.34,0.165),Vector3(0.04,1.34,0.165),Vector3(0.05,1.29,0.16)],[0.013,0.013,0.013,0.013],"player_pack",8)
	for side in [-1,1]:
		ArtMeshes.tube(parent,[Vector3(side*0.105,1.23,0.21),Vector3(side*0.16,1.36,0.085),Vector3(side*0.171,1.32,-0.051),Vector3(side*0.163,1.16,-0.093),Vector3(side*0.15,0.97,0.006),Vector3(side*0.13,0.9,0.15)],[0.021,0.023,0.023,0.021,0.012,0.012],"player_pack",10)
		ArtMeshes.rounded(parent,Vector3(side*0.167,1.19,-0.112),Vector3(0.041,0.048,0.016),"plastic",0.007)

static func _open_jacket(parent: Node3D) -> void:
	var rings: Array[Vector3] = [Vector3(0.166,0.80,0.118),Vector3(0.17,0.84,0.122),Vector3(0.176,0.92,0.126),Vector3(0.166,1.03,0.118),Vector3(0.188,1.20,0.133),Vector3(0.219,1.31,0.126),Vector3(0.195,1.36,0.10),Vector3(0.092,1.395,0.075)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in rings.size()-1:
		for segment in 40:
			var points: Array[Vector3] = []
			for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var ring := rings[row+offset.y]
				var angle: float = -PI/2+0.48+(TAU-0.96)*(segment+offset.x)/40.0
				var fold := 1.0+0.013*sin(angle*13+row*1.7)
				points.append(Vector3(cos(angle)*ring.x*fold,ring.y,sin(angle)*ring.z*fold))
			ArtMeshes._triangle(st,points[0],points[1],points[2],Vector3(0,1.1,0))
			ArtMeshes._triangle(st,points[0],points[2],points[3],Vector3(0,1.1,0))
	st.index()
	st.generate_normals()
	var jacket := MeshInstance3D.new()
	jacket.name = "OpenHoodie"
	jacket.mesh = st.commit()
	var cloth := ArtMaterials.surface("player_hoodie").duplicate() as StandardMaterial3D
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	jacket.material_override = cloth
	parent.add_child(jacket)

static func hair(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "TousledBrownHair"
	parent.add_child(root)
	ArtMeshes.ellipsoid(root,Vector3(0,1.688,0.016),Vector3(0.228,0.128,0.230),"player_hair")
	ArtMeshes.ellipsoid(root,Vector3(0,1.638,0.054),Vector3(0.215,0.184,0.145),"player_hair")
	for side in [-1,1]:
		ArtMeshes.tube(root,[Vector3(side*0.094,1.681,0.01),Vector3(side*0.103,1.633,-0.018),Vector3(side*0.102,1.593,-0.019)],[0.022,0.014,0.002],"player_hair",12)
	var random := RandomNumberGenerator.new()
	random.seed = 919
	for i in 30:
		var angle := TAU*i/30.0
		var x := cos(angle)*random.randf_range(0.035,0.093)
		var z := sin(angle)*random.randf_range(0.02,0.09)
		var start := Vector3(x,1.702+random.randf_range(0,0.023),z+0.013)
		var tip := start+Vector3(-0.031,random.randf_range(-0.018,0.028),-0.041)
		ArtMeshes.tube(root,[start,start.lerp(tip,0.5)+Vector3(0,0.018,0),tip],[0.014,0.013,0.001],"player_hair",8)
	for i in 8:
		var x := -0.085+i*0.023
		ArtMeshes.tube(root,[Vector3(x,1.71,-0.050),Vector3(x-0.020,1.68,-0.101),Vector3(x-0.028,1.641+0.012*sin(i),-0.104)],[0.019,0.015,0.001],"player_hair",10)

static func head(parent: Node3D) -> void:
	# Chin, jaw, cheekbones, temples and skull share one continuous surface.
	var head_mesh := ArtMeshes.profile(parent,[Vector3(0.040,1.467,0.054),Vector3(0.061,1.479,0.074),Vector3(0.085,1.514,0.089),Vector3(0.096,1.555,0.102),Vector3(0.105,1.591,0.106),Vector3(0.103,1.625,0.102),Vector3(0.105,1.664,0.105),Vector3(0.091,1.704,0.087),Vector3(0.052,1.728,0.052),Vector3(0.008,1.737,0.008)],"player_skin",48)
	head_mesh.position.z = -0.005
	ArtMeshes.tube(parent,[Vector3(0,1.618,-0.105),Vector3(0,1.582,-0.123),Vector3(0,1.568,-0.126)],[0.009,0.012,0.016],"player_skin",16)
	ArtMeshes.ellipsoid(parent,Vector3(0,1.541,-0.103),Vector3(0.049,0.011,0.010),"player_lips")
	for side in [-1,1]:
		ArtMeshes.ellipsoid(parent,Vector3(side*0.103,1.583,0),Vector3(0.028,0.058,0.031),"player_skin")
		ArtMeshes.ellipsoid(parent,Vector3(side*0.043,1.607,-0.103),Vector3(0.037,0.013,0.011),"player_eye")
		ArtMeshes.ellipsoid(parent,Vector3(side*0.043,1.607,-0.110),Vector3(0.014,0.012,0.004),"player_iris")
		ArtMeshes.tube(parent,[Vector3(side*0.022,1.622,-0.107),Vector3(side*0.044,1.628,-0.105),Vector3(side*0.065,1.620,-0.094)],[0.003,0.004,0.0015],"player_hair",8)
