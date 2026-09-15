class_name SuburbanAssets
extends RefCounted
## Original metre-scale scenery kit. Meshes only: no gameplay IDs, colliders or scripts.

static func building(parent: Node3D, position: Vector3, size: Vector3, style: String = "house", yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Architecture_" + style
	root.position = position
	root.rotation.y = yaw
	parent.add_child(root)
	root.add_to_group("art_architecture")
	var w := size.x
	var h := size.y
	var d := size.z
	ArtMeshes.box(root,Vector3(0,0.18,0),Vector3(w+0.25,0.36,d+0.25),"concrete",0.06)
	ArtMeshes.box(root,Vector3(0,h/2,0),size,"brick" if style != "house" else "plaster",0.04)
	for y in [0.45,h-0.14]:
		ArtMeshes.box(root,Vector3(0,y,0),Vector3(w+0.14,0.15,d+0.14),"concrete")
	var rise := minf(w*0.28,2.4)
	_roof(root,Vector3(0,h,0),w+0.75,d+0.8,rise)
	# Solid gable ends under the pitched roof, with roof depth rather than a paper plane.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-d/2,d/2]:
		ArtMeshes._triangle(st,Vector3(-w/2,h,z),Vector3(w/2,h,z),Vector3(0,h+rise,z),Vector3(0,h,0))
	var gable := MeshInstance3D.new()
	gable.mesh = st.commit()
	gable.material_override = ArtMaterials.surface("plaster")
	root.add_child(gable)
	for side in [-1,1]:
		ArtMeshes.cylinder(root,Vector3(side*(w/2+0.3),h-0.06,-d/2-0.3),Vector3(side*(w/2+0.3),h-0.06,d/2+0.3),0.075,"metal")
		ArtMeshes.tube(root,[Vector3(side*(w/2+0.3),h-0.1,d/2),Vector3(side*(w/2+0.15),h-0.4,d/2+0.10),Vector3(side*(w/2+0.15),0.20,d/2+0.10),Vector3(side*(w/2+0.30),0.08,d/2+0.3)],[0.055,0.055,0.055,0.055],"metal")
		for z in [-d*0.28,d*0.28]:
			for floor_index in maxi(1,int(h/2.7)):
				ArtProps.window(root,Vector3(side*(w/2+0.025),1.7+floor_index*2.7,z),side*PI/2,false)
	for x in [-w*0.29,w*0.29]:
		for floor_index in maxi(1,int(h/2.7)):
			ArtProps.window(root,Vector3(x,1.7+floor_index*2.7,d/2+0.025),0,false)
	# Recessed entry, jamb, brass handle and three broad steps.
	ArtMeshes.box(root,Vector3(0,1.12,d/2+0.03),Vector3(1.28,2.24,0.11),"wood_edge")
	ArtMeshes.box(root,Vector3(0,1.11,d/2+0.10),Vector3(1.04,2.08,0.07),"paint")
	ArtMeshes.rounded(root,Vector3(0,1.49,d/2+0.15),Vector3(0.70,0.75,0.04),"glass",0.05)
	ArtMeshes.cylinder(root,Vector3(0.38,0.94,d/2+0.19),Vector3(0.38,1.09,d/2+0.19),0.025,"metal")
	for step in 3:
		ArtMeshes.box(root,Vector3(0,0.055*(step+1),d/2+0.85-step*0.25),Vector3(1.9,0.11*(step+1),0.55),"concrete",0.035)
	if style == "house":
		_roof(root,Vector3(0,2.48,d/2+0.58),2.35,1.9,0.55)
		for x in [-0.94,0.94]:
			ArtMeshes.profile(root,[Vector3(0.09,0.1,0.09),Vector3(0.07,2.3,0.07),Vector3(0.1,2.48,0.1)],"wood_edge").position = Vector3(x,0,d/2+1.30)
		ArtMeshes.box(root,Vector3(-w*0.23,h+rise*0.72,-d*0.23),Vector3(0.7,1.6,0.85),"brick")
	else:
		ArtMeshes.box(root,Vector3(0,2.65,d/2+0.16),Vector3(w*0.78,0.5,0.17),"paint")
		var sign_label := Label3D.new()
		sign_label.text = {"pharmacy":"PHARMACY", "shop":"CORNER MARKET", "police":"POLICE", "school":"SCHOOL", "industrial":"SERVICE WORKS"}.get(style,"RESIDENCES")
		sign_label.font_size = 56
		sign_label.pixel_size = 0.005
		sign_label.position = Vector3(0,2.65,d/2+0.26)
		sign_label.modulate = Color("d7c7a8")
		sign_label.outline_size = 0
		root.add_child(sign_label)
	return root

static func _roof(parent: Node3D, position: Vector3, width: float, depth: float, rise: float) -> void:
	var slope := atan2(rise,width/2)
	var run := Vector2(width/2,rise).length()
	for side in [-1,1]:
		var panel := ArtMeshes.box(parent,position+Vector3(side*width/4,rise/2,0),Vector3(run+0.06,0.16,depth),"roof",0.025)
		panel.rotation.z = -side*slope
		for z in [-depth/2,depth/2]:
			var fascia := ArtMeshes.box(parent,position+Vector3(side*width/4,rise/2-0.05,z),Vector3(run+0.1,0.20,0.09),"wood_edge")
			fascia.rotation.z = -side*slope
	ArtMeshes.cylinder(parent,position+Vector3(0,rise,-depth/2),position+Vector3(0,rise,depth/2),0.115,"roof")

static func car(parent: Node3D, position: Vector3, yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Car_Sedan"
	root.position = position
	root.rotation.y = yaw
	parent.add_child(root)
	root.add_to_group("art_vehicles")
	# z / half-width / bottom / top: narrowed nose, bonnet, belt line and boot.
	_loft(root,[Vector4(-2.15,0.68,0.48,0.70),Vector4(-1.94,0.86,0.36,0.83),Vector4(-1.32,0.90,0.36,0.91),Vector4(-0.75,0.91,0.36,0.98),Vector4(0.65,0.91,0.36,1.0),Vector4(1.58,0.85,0.38,0.94),Vector4(2.0,0.73,0.48,0.78)],"car_paint")
	_loft(root,[Vector4(-0.87,0.79,0.92,0.99),Vector4(-0.32,0.67,0.96,1.48),Vector4(0.70,0.67,0.96,1.50),Vector4(1.32,0.76,0.95,1.03)],"glass")
	ArtMeshes.rounded(root,Vector3(0,1.51,0.22),Vector3(1.36,0.11,1.1),"car_paint",0.05)
	for side in [-1,1]:
		# A/B/C pillars, window sill and a restrained body crease.
		for ends in [[Vector3(side*0.79,0.97,-0.86),Vector3(side*0.67,1.5,-0.32)],[Vector3(side*0.80,0.98,0.27),Vector3(side*0.68,1.51,0.27)],[Vector3(side*0.77,0.97,1.32),Vector3(side*0.67,1.51,0.7)]]:
			ArtMeshes.cylinder(root,ends[0],ends[1],0.035,"car_paint")
		ArtMeshes.cylinder(root,Vector3(side*0.88,0.94,-0.9),Vector3(side*0.88,0.97,1.25),0.018,"metal")
		ArtMeshes.rounded(root,Vector3(side*0.96,1.02,-0.60),Vector3(0.22,0.13,0.27),"car_paint",0.05)
		for z in [-1.27,1.24]:
			ArtMeshes.cylinder(root,Vector3(side*0.73,0.39,z),Vector3(side*0.99,0.39,z),0.37,"rubber")
			ArtMeshes.cylinder(root,Vector3(side*0.99,0.39,z),Vector3(side*1.005,0.39,z),0.235,"metal")
			ArtMeshes.cylinder(root,Vector3(side*1.008,0.39,z),Vector3(side*1.018,0.39,z),0.085,"rubber")
			for spoke in 5:
				var angle := TAU*spoke/5
				ArtMeshes.cylinder(root,Vector3(side*1.02,0.39,z),Vector3(side*1.02,0.39+cos(angle)*0.20,z+sin(angle)*0.20),0.023,"wood_edge")
		for z in [-0.12,0.80]:
			ArtMeshes.rounded(root,Vector3(side*0.91,0.83,z),Vector3(0.035,0.045,0.19),"metal",0.015)
		ArtMeshes.rounded(root,Vector3(side*0.55,0.72,-2.03),Vector3(0.44,0.17,0.10),"glass",0.045)
		ArtMeshes.rounded(root,Vector3(side*0.55,0.73,1.96),Vector3(0.35,0.16,0.07),"rust",0.035)
	for z in [-2.10,2.0]:
		ArtMeshes.rounded(root,Vector3(0,0.50,z),Vector3(1.47,0.14,0.12),"rubber",0.045)
		ArtMeshes.box(root,Vector3(0,0.65,z*1.005),Vector3(0.43,0.12,0.02),"paper",0.008)
	return root

static func _loft(parent: Node3D, sections: Array[Vector4], material_id: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for s in sections:
		var height := s.w-s.z
		rings.append([Vector3(-s.y*0.82,s.z,s.x),Vector3(-s.y,s.z+height*.20,s.x),Vector3(-s.y,s.w-height*.16,s.x),Vector3(-s.y*.82,s.w,s.x),Vector3(s.y*.82,s.w,s.x),Vector3(s.y,s.w-height*.16,s.x),Vector3(s.y,s.z+height*.20,s.x),Vector3(s.y*.82,s.z,s.x)])
	for i in sections.size()-1:
		for j in 8:
			var k := (j+1)%8
			ArtMeshes._triangle(st,rings[i][j],rings[i+1][j],rings[i+1][k],Vector3(0,0.8,0))
			ArtMeshes._triangle(st,rings[i][j],rings[i+1][k],rings[i][k],Vector3(0,0.8,0))
	for index in [0,sections.size()-1]:
		var s := sections[index]
		for j in 8:
			ArtMeshes._triangle(st,Vector3(0,(s.z+s.w)/2,s.x),rings[index][j],rings[index][(j+1)%8],Vector3(0,0.8,0))
	st.index()
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = ArtMaterials.surface(material_id)
	parent.add_child(mesh)

static func tree(parent: Node3D, position: Vector3, height: float, seed_value: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Tree_" + str(seed_value)
	root.position = position
	parent.add_child(root)
	root.add_to_group("art_trees")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var crown_centres: Array[Vector3] = []
	ArtMeshes.tube(root,[Vector3.ZERO,Vector3(0.12,height*.24,0.04),Vector3(-0.08,height*.52,0.12),Vector3(0.24,height*.85,-0.10)],[height*.052,height*.037,height*.021,0.03],"bark")
	for i in 7:
		var angle := i*TAU/7+rng.randf_range(-0.3,0.3)
		var spread := height*rng.randf_range(0.19,0.35)
		var end := Vector3(cos(angle)*spread,height*rng.randf_range(0.58,0.90),sin(angle)*spread)
		crown_centres.append(end)
		ArtMeshes.tube(root,[Vector3(0,height*.38,0),Vector3(end.x*.48,height*.58,end.z*.48),end],[height*.025,height*.015,0.025],"bark")
		ArtMeshes.organic(root,end,Vector3(height*.40,height*.30,height*.37),"vegetation",seed_value+i*17)
	_leaf_sprays(root,crown_centres,height,rng)
	for i in 5:
		var angle := TAU*i/5
		ArtMeshes.tube(root,[Vector3(0,0.30,0),Vector3(cos(angle)*0.45,0.08,sin(angle)*0.45),Vector3(cos(angle)*0.9,0.025,sin(angle)*0.9)],[height*.035,0.065,0.012],"bark")
	return root

static func _leaf_sprays(parent: Node3D, centres: Array[Vector3], height: float, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Curved lance-shaped leaves with a raised midrib and asymmetrical edge.
	for triangle in [[Vector3(0,0,0),Vector3(-0.10,0.01,0.14),Vector3(0,0.045,0.29)],[Vector3(0,0,0),Vector3(0,0.045,0.29),Vector3(0.085,0.015,0.13)]]:
		for point in triangle:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(point.x*4+0.5,point.z*3))
			st.add_vertex(point)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = st.commit()
	multi.instance_count = centres.size()*140
	for i in multi.instance_count:
		var direction := Vector3(rng.randf_range(-1,1),rng.randf_range(-0.8,0.8),rng.randf_range(-1,1)).normalized()
		var point := centres[i%centres.size()]+direction*height*rng.randf_range(0.14,0.25)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-1,1),rng.randf_range(0,TAU),rng.randf_range(-1,1)))
		multi.set_instance_transform(i,Transform3D(basis.scaled(Vector3.ONE*rng.randf_range(0.8,1.8)),point))
		multi.set_instance_color(i,Color(0.72+rng.randf()*0.3,0.78+rng.randf()*0.25,0.65+rng.randf()*0.3))
	var mesh := MultiMeshInstance3D.new()
	mesh.multimesh = multi
	var material := ArtMaterials.surface("vegetation").duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	parent.add_child(mesh)

static func road(parent: Node3D, points: Array[Vector3], width: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size()-1:
		var tangent := (points[i+1]-points[i]).normalized()
		var side := tangent.cross(Vector3.UP)*width/2
		for p in [points[i]-side,points[i+1]+side,points[i+1]-side,points[i]-side,points[i]+side,points[i+1]+side]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.x,p.z)*0.5)
			st.add_vertex(p)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = ArtMaterials.surface("asphalt")
	parent.add_child(mesh)
	for i in points.size()-1:
		var direction := (points[i+1]-points[i]).normalized()
		for side in [-1,1]:
			var offset: Vector3 = direction.cross(Vector3.UP)*(width/2+0.1)*side
			ArtMeshes.tube(parent,[points[i]+offset+Vector3.UP*.04,points[i+1]+offset+Vector3.UP*.04],[0.11,0.11],"concrete",8)
