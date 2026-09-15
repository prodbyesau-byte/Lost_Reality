class_name ArtProps
extends RefCounted
## Visual-only reusable furniture. Existing level collision envelopes remain authoritative.
static func furnish(parent: Node3D, kind: String, size: Vector3, position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Art_" + kind
	root.position = position - Vector3.UP * size.y / 2.0
	parent.add_child(root)
	var w := size.x
	var h := size.y
	var d := size.z
	if kind == "bench" and w > d:
		root.rotation.y = PI/2
		w = size.z
		d = size.x
	match kind:
		"sofa":
			ArtMeshes.rounded(root,Vector3(0,h*0.28,0),Vector3(w*0.94,h*0.24,d*0.91),"wood",0.10)
			ArtMeshes.rounded(root,Vector3(0,h*0.71,-d*0.35),Vector3(w*0.96,h*0.53,d*0.27),"fabric",0.16)
			for side in [-1,1]:
				ArtMeshes.rounded(root,Vector3(side*w*0.43,h*0.58,0),Vector3(w*0.14,h*0.52,d*0.94),"fabric",0.16)
				for z in [-d*0.34,d*0.34]:
					ArtMeshes.cylinder(root,Vector3(side*w*0.38,0.02,z),Vector3(side*w*0.38,h*0.26,z),0.065,"wood")
			for i in 3:
				var x := (i-1)*w*0.245
				ArtMeshes.rounded(root,Vector3(x,h*0.47,d*0.08),Vector3(w*0.235,h*0.23,d*0.71),"fabric",0.12)
				var cushion := ArtMeshes.rounded(root,Vector3(x,h*0.75,-d*0.20),Vector3(w*0.236,h*0.39,d*0.21),"jacket",0.11)
				cushion.rotation.x = -0.12
		"cot":
			ArtMeshes.box(root,Vector3(0,h*0.45,0),Vector3(w,h*0.18,d),"metal")
			ArtMeshes.rounded(root,Vector3(0,h*0.7,0),Vector3(w*0.92,h*0.42,d*0.95),"fabric",0.16)
			ArtMeshes.rounded(root,Vector3(0,h*0.94,-d*0.32),Vector3(w*0.64,h*0.16,d*0.19),"fabric",0.09)
			for fold in 9:
				ArtMeshes.rounded(root,Vector3(0,h*0.94+sin(fold*1.4)*0.012,d*(-0.09+fold*0.06)),Vector3(w*0.90,0.045,d*0.065),"jacket",0.015)
			for x in [-w*0.44,w*0.44]:
				for z in [-d*0.43,d*0.43]:
					ArtMeshes.cylinder(root,Vector3(x,0.05,z),Vector3(x,h*0.48,z),0.04,"metal")
		"sideboard", "cabinet":
			ArtMeshes.box(root,Vector3(0,h/2,0),size,"wood",0.04)
			ArtMeshes.box(root,Vector3(0,h+0.015,0),Vector3(w+0.04,0.055,d+0.04),"wood_edge")
			for x in [-w*0.25,w*0.25]:
				for y in [h*0.28,h*0.69]:
					ArtMeshes.box(root,Vector3(x,y,d/2+0.014),Vector3(w*0.46,h*0.36,0.045),"wood_edge")
					ArtMeshes.box(root,Vector3(x,y,d/2+0.05),Vector3(0.24,0.035,0.05),"metal")
			_books(root,Vector3(-w*0.24,h+0.04,0),3)
		"desk", "table":
			ArtMeshes.rounded(root,Vector3(0,h-0.07,0),Vector3(w,0.14,d),"wood_edge",0.065)
			for x in [-w*0.42,w*0.42]:
				for z in [-d*0.40,d*0.40]:
					ArtMeshes.cylinder(root,Vector3(x*0.92,0.04,z*0.92),Vector3(x,h*0.9,z),0.055,"wood",0.075)
			ArtMeshes.box(root,Vector3(w*0.23,h*0.61,0),Vector3(w*0.32,h*0.40,d*0.85),"wood")
			ArtMeshes.box(root,Vector3(w*0.23,h*0.65,d*0.44),Vector3(0.24,0.04,0.04),"metal")
			_books(root,Vector3(-w*0.23,h+0.01,0),2)
			ArtMeshes.box(root,Vector3(0,h+0.018,d*0.17),Vector3(0.32,0.006,0.42),"paper")
		"crates":
			for x in [-w*0.25,w*0.25]:
				ArtMeshes.box(root,Vector3(x,h/2,0),Vector3(w*0.48,h,d),"wood")
				for z in [-d*0.43,d*0.43]:
					ArtMeshes.box(root,Vector3(x,h+0.025,z),Vector3(w*0.49,0.07,0.11),"wood_edge")
					ArtMeshes.box(root,Vector3(x,h*0.18,z*1.17),Vector3(w*0.49,0.14,0.04),"wood_edge")
		"shelf":
			for y in [0.10,h*0.42,h*0.76,h*0.98]:
				ArtMeshes.box(root,Vector3(0,y,0),Vector3(w,0.055,d),"wood")
			for x in [-w*0.46,w*0.46]:
				for z in [-d*0.45,d*0.45]:
					ArtMeshes.box(root,Vector3(x,h/2,z),Vector3(0.07,h,0.07),"rust")
			for x in [-w*0.25,0,w*0.25]:
				ArtMeshes.box(root,Vector3(x,h*0.57,0),Vector3(w*0.22,h*0.23,d*0.7),"paper")
			_books(root,Vector3(-w*0.2,h*0.79,0),5)
		"planter":
			ArtMeshes.box(root,Vector3(0,h*0.83,0),Vector3(w*0.86,0.12,d*0.86),"soil")
			for x in [-w/2+0.15,w/2-0.15]:
				ArtMeshes.rounded(root,Vector3(x,h/2,0),Vector3(0.30,h,d),"concrete",0.14)
			for z in [-d/2+0.15,d/2-0.15]:
				ArtMeshes.rounded(root,Vector3(0,h/2,z),Vector3(w, h,0.30),"concrete",0.14)
			ArtDressing.vegetation(root,Vector3(0,h*0.90,0),Vector2(w*0.38,d*0.38),90,49)
			SuburbanAssets.tree(root,Vector3(0,h*0.9,0),3.5,27)
		"bench":
			for z in [-d*0.43,d*0.43]:
				ArtMeshes.tube(root,[Vector3(-w*0.35,h*0.58,z),Vector3(-w*0.36,h*0.78,z),Vector3(0,h*0.82,z),Vector3(w*0.34,h*0.75,z),Vector3(w*0.34,h*0.25,z)],[0.035,0.035,0.035,0.035,0.035],"metal")
			for x in [-w*0.3,0,w*0.3]:
				ArtMeshes.box(root,Vector3(x,h*0.55,0),Vector3(w*0.24,0.08,d),"wood_edge")
			for z in [-d*0.38,d*0.38]:
				ArtMeshes.box(root,Vector3(0,h*0.28,z),Vector3(w*0.8,h*0.50,0.10),"rust")
			for y in [h*0.77,h*0.96]:
				ArtMeshes.box(root,Vector3(w*0.45,y,0),Vector3(0.08,h*0.14,d),"wood")
		"utility":
			ArtMeshes.box(root,Vector3(0,h/2,0),size,"metal",0.06)
			for x in [-w*0.24,w*0.24]:
				ArtMeshes.box(root,Vector3(x,h*0.52,d/2+0.02),Vector3(w*0.45,h*0.87,0.035),"paint")
				for i in 5:
					ArtMeshes.box(root,Vector3(x,h*0.7+i*0.065,d/2+0.055),Vector3(w*0.25,0.025,0.026),"rubber")
				ArtMeshes.box(root,Vector3(x+w*0.14,h*0.45,d/2+0.06),Vector3(0.04,0.22,0.045),"rust")
		_:
			ArtMeshes.box(root,Vector3(0,h/2,0),size,"wood")
	return root

static func _books(parent: Node3D, position: Vector3, count: int) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	root.add_to_group("art_details")
	for i in count:
		var book := ArtMeshes.box(root,Vector3(0,0.028+i*0.055,0),Vector3(0.27,0.048,0.35),"paper" if i%2 == 0 else "paint",0.005)
		book.rotation.y = i*0.13

static func window(parent: Node3D, position: Vector3, yaw: float = 0.0, boarded: bool = true) -> void:
	var root := Node3D.new()
	root.position = position
	root.rotation.y = yaw
	parent.add_child(root)
	ArtMeshes.box(root,Vector3.ZERO,Vector3(1.7,1.35,0.06),"rubber")
	ArtMeshes.box(root,Vector3(0,0,0.038),Vector3(1.51,1.17,0.018),"glass")
	for x in [-0.85,0.0,0.85]:
		ArtMeshes.box(root,Vector3(x,0,0.08),Vector3(0.08,1.5,0.08),"wood_edge")
	for y in [-0.7,0,0.7]:
		ArtMeshes.box(root,Vector3(0,y,0.08),Vector3(1.8,0.075,0.08),"wood_edge")
	ArtMeshes.box(root,Vector3(0,-0.74,0.14),Vector3(1.98,0.10,0.30),"concrete")
	for i in (2 if boarded else 0):
		var board := ArtMeshes.box(root,Vector3(0,-0.25+i*0.49,0.17),Vector3(1.99,0.18,0.055),"wood")
		board.rotation.z = -0.10+i*0.22

static func work_lamp(parent: Node3D, position: Vector3, energy: float = 2.5, shadows: bool = false) -> OmniLight3D:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	ArtMeshes.box(root,Vector3.ZERO,Vector3(0.23,0.36,0.24),"metal")
	var bulb := ArtMeshes.box(root,Vector3(0,0,0.135),Vector3(0.15,0.26,0.055),"glass")
	bulb.material_override = ArtMaterials.light_surface(Color("e1b77b"),0.8)
	for x in [-0.08,0.08]:
		ArtMeshes.cylinder(root,Vector3(x,-0.18,0.18),Vector3(x,0.18,0.18),0.012,"metal")
	ArtMeshes.cylinder(root,Vector3(-0.12,0.20,0),Vector3(0.12,0.20,0),0.025,"rust")
	var light := OmniLight3D.new()
	light.position = Vector3(0,0,0.24)
	light.light_color = Color(ArtMaterials.config().lighting.warm_color)
	light.light_energy = energy
	light.omni_range = 7.0
	light.omni_attenuation = 1.5
	light.light_size = 0.14
	light.shadow_enabled = shadows and VisualQuality.atmospheric
	light.set_meta("art_shadow", shadows)
	root.add_child(light)
	light.add_to_group("art_lights")
	return light
