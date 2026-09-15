class_name ArtDressing
extends RefCounted
## Art-only geometry never owns gameplay collision, object IDs or persistence.
static func wall(parent: Node3D, position: Vector3, size: Vector3, visible_height: float) -> void:
	var height := size.y if visible_height < 0 else visible_height
	var base := position.y-size.y/2
	var lower_height := minf(1.15,height)
	ArtMeshes.box(parent,Vector3(position.x,base+lower_height/2,position.z),Vector3(size.x+0.018,lower_height,size.z+0.018),"paint",0.01)
	ArtMeshes.box(parent,Vector3(position.x,base+0.07,position.z),Vector3(size.x+0.048,0.14,size.z+0.048),"wood",0.01)
	ArtMeshes.box(parent,Vector3(position.x,base+height+0.018,position.z),Vector3(size.x+0.06,0.045,size.z+0.06),"concrete",0.01)
	if height > 1.2:
		ArtMeshes.box(parent,Vector3(position.x,base+1.17,position.z),Vector3(size.x+0.028,0.055,size.z+0.028),"wood_edge",0.008)
	# Irregular mesh decals stay on the visible face; no extra collision or projector cost.
	var horizontal := size.x > size.z
	var length := size.x if horizontal else size.z
	var random := RandomNumberGenerator.new()
	random.seed = int(absf(position.x*137+position.z*991))+53
	for i in int(length/2.5):
		var offset := random.randf_range(-length*0.44,length*0.44)
		var patch_height := minf(height*0.48,0.65)
		var location := Vector3(position.x+(offset if horizontal else size.x/2+0.014),base+patch_height*0.8,position.z+(size.z/2+0.014 if horizontal else offset))
		var patch := stain(parent,location,Vector2(random.randf_range(0.18,0.36),patch_height),"stain",i+31)
		patch.rotation = Vector3(PI/2,0 if horizontal else PI/2,0)

static func dress(parent: Node3D, path: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for window in data.get("windows", []):
		ArtProps.window(parent,SaveSerializer.to_vector(window.position),float(window.get("yaw",0)))
	for fixture in data.get("lamps", []):
		var location := SaveSerializer.to_vector(fixture.position)
		ArtProps.work_lamp(parent,location,float(fixture.energy),fixture.get("shadows",false))
		ArtMeshes.cylinder(parent,Vector3(location.x,0.05,location.z),location-Vector3.UP*0.22,0.025,"metal")
		ArtMeshes.box(parent,Vector3(location.x,0.06,location.z),Vector3(0.44,0.06,0.38),"rust")
	for patch in data.get("patches", []):
		stain(parent,SaveSerializer.to_vector(patch.position),Vector2(patch.size[0],patch.size[1]),patch.get("material","stain"),int(patch.get("seed",3)))
	for plants in data.get("vegetation", []):
		vegetation(parent,SaveSerializer.to_vector(plants.position),Vector2(plants.size[0],plants.size[1]),int(plants.count),int(plants.seed))
	for pile in data.get("debris", []):
		debris(parent,SaveSerializer.to_vector(pile.position),int(pile.seed))
	for roots in data.get("corruption", []):
		corruption(parent,SaveSerializer.to_vector(roots.position),int(roots.seed))
	# A low-detail, non-traversable ground apron prevents the level reading as a floating board.
	var apron := ArtMeshes.box(parent,Vector3(0,-0.35,0),Vector3(80,0.12,80),"concrete")
	apron.material_override = ArtMaterials.floor_surface(3,0.45)
	for building in data.get("background", []):
		SuburbanAssets.building(parent,SaveSerializer.to_vector(building.position),SaveSerializer.to_vector(building.size),building.get("style","house"),float(building.get("yaw",0)))
	for vehicle in data.get("cars", []):
		SuburbanAssets.car(parent,SaveSerializer.to_vector(vehicle.position),float(vehicle.get("yaw",0)))
	for tree_data in data.get("trees", []):
		SuburbanAssets.tree(parent,SaveSerializer.to_vector(tree_data.position),float(tree_data.height),int(tree_data.seed))
	for road_data in data.get("roads", []):
		var points: Array[Vector3] = []
		for point in road_data.points:
			points.append(SaveSerializer.to_vector(point))
		SuburbanAssets.road(parent,points,float(road_data.width))

static func stain(parent: Node3D, position: Vector3, size: Vector2, material_id: String, seed_value: int) -> MeshInstance3D:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for i in 18:
		var angle := TAU*i/18.0
		var radius := random.randf_range(0.7,1.0)
		ring.append(Vector3(cos(angle)*size.x*radius,0,sin(angle)*size.y*radius))
	for i in 18:
		for point in [Vector3.ZERO,ring[i],ring[(i+1)%18]]:
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(point.x/size.x,point.z/size.y)*0.5+Vector2.ONE*0.5)
			surface.add_vertex(point)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/materials/stain.gdshader")
	material.set_shader_parameter("stain_color",Color(ArtMaterials.config().materials[material_id].color))
	mesh.material_override = material
	mesh.position = position
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	mesh.add_to_group("art_details")
	return mesh

static func vegetation(parent: Node3D, position: Vector3, size: Vector2, count: int, seed_value: int) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for direction in 3:
		var angle := direction*TAU/3.0
		var right := Vector3(cos(angle),0,sin(angle))*0.13
		var tip := Vector3(cos(angle)*0.19,0.60,sin(angle)*0.19)
		for point in [-right,right,tip]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(point)
	var material := ArtMaterials.surface("vegetation").duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = surface.commit()
	multimesh.instance_count = count
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for i in count:
		var transform := Transform3D(Basis(Vector3.UP,random.randf_range(0,TAU)).scaled(Vector3.ONE*random.randf_range(0.45,1.45)),Vector3(random.randf_range(-size.x,size.x),0,random.randf_range(-size.y,size.y)))
		multimesh.set_instance_transform(i,transform)
		multimesh.set_instance_color(i,Color(0.8+random.randf()*0.2,0.8+random.randf()*0.2,0.7,1))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multimesh
	node.material_override = material
	node.position = position
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = 75
	parent.add_child(node)
	node.add_to_group("art_details")

static func debris(parent: Node3D, position: Vector3, seed_value: int) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	root.add_to_group("art_details")
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for i in 9:
		var paper := ArtMeshes.box(root,Vector3(random.randf_range(-0.55,0.55),0.04+i*0.001,random.randf_range(-0.4,0.4)),Vector3(0.15+random.randf()*0.16,0.008,0.22+random.randf()*0.10),"paper",0.001)
		paper.rotation.y = random.randf_range(0,TAU)
		paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 5:
		var chip := ArtMeshes.box(root,Vector3(random.randf_range(-0.5,0.5),0.06,random.randf_range(-0.4,0.4)),Vector3(0.14,0.09,0.12),"plaster")
		chip.rotation = Vector3(0.1,random.randf()*TAU,0.13)

static func corruption(parent: Node3D, position: Vector3, seed_value: int) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	root.add_to_group("art_details")
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for branch in 5:
		var previous := Vector3.ZERO
		for segment in 5:
			var next := previous + Vector3(random.randf_range(-0.3,0.3),random.randf_range(0.18,0.33),random.randf_range(-0.05,0.07))
			ArtMeshes.cylinder(root,previous,next,0.025-segment*0.003,"corruption")
			previous = next
