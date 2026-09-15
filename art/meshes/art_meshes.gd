class_name ArtMeshes
extends RefCounted
static var _boxes: Dictionary = {}
static var _simple_boxes: Dictionary = {}

static func box(parent: Node3D, position: Vector3, size: Vector3, material_id: String, bevel: float = 0.025) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.position = position
	var detailed := bevel_box(size, bevel)
	var key := str(size)
	if not _simple_boxes.has(key):
		_simple_boxes[key] = bevel_box(size, bevel)
	mesh.set_meta("lod_detail",detailed)
	mesh.set_meta("lod_simple",_simple_boxes[key])
	mesh.mesh = detailed if VisualQuality.detail_enabled() else _simple_boxes[key]
	mesh.material_override = ArtMaterials.surface(material_id)
	parent.add_child(mesh)
	mesh.add_to_group("art_lod_meshes")
	return mesh

static func bevel_box(size: Vector3, bevel: float) -> ArrayMesh:
	var key := str(size) + "/" + str(bevel)
	if _boxes.has(key):
		return _boxes[key]
	var b := minf(bevel, minf(size.x, minf(size.y, size.z)) * 0.22)
	var x := size.x / 2.0
	var z := size.z / 2.0
	var h := size.y / 2.0
	var points: Array[Vector2] = [Vector2(-x+b,-z),Vector2(x-b,-z),Vector2(x,-z+b),Vector2(x,z-b),Vector2(x-b,z),Vector2(-x+b,z),Vector2(-x,z-b),Vector2(-x,-z+b)]
	var rings: Array = []
	for layer in 4:
		var y: float = [-h, -h+b, h-b, h][layer]
		var inset := b if layer == 0 or layer == 3 else 0.0
		var ring: Array[Vector3] = []
		for p in points:
			ring.append(Vector3(p.x * (x-inset)/x, y, p.y * (z-inset)/z))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in 3:
		for i in 8:
			var next := (i+1)%8
			_triangle(surface,rings[layer][i],rings[layer+1][i],rings[layer+1][next])
			_triangle(surface,rings[layer][i],rings[layer+1][next],rings[layer][next])
	for i in 8:
		_triangle(surface,Vector3(0,-h,0),rings[0][i],rings[0][(i+1)%8])
		_triangle(surface,Vector3(0,h,0),rings[3][i],rings[3][(i+1)%8])
	var result := surface.commit()
	_boxes[key] = result
	return result

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, center: Vector3 = Vector3.ZERO) -> void:
	var normal := (c-a).cross(b-a).normalized()
	if normal.dot((a+b+c)/3.0-center) < 0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	for point in [a,b,c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x,point.y))
		surface.add_vertex(point)

static func profile(parent: Node3D, rings: Array[Vector3], material_id: String, segments: int = 24) -> MeshInstance3D:
	# Rings contain (radius_x, height, radius_z); supports grounded tailored silhouettes.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0,(rings[0].y+rings[-1].y)/2.0,0)
	for layer in rings.size()-1:
		for i in segments:
			var angle := TAU * i / segments
			var next := TAU * (i+1) / segments
			var lower: Vector3 = rings[layer]
			var upper: Vector3 = rings[layer+1]
			var a := Vector3(cos(angle)*lower.x,lower.y,sin(angle)*lower.z)
			var b := Vector3(cos(next)*lower.x,lower.y,sin(next)*lower.z)
			var c := Vector3(cos(next)*upper.x,upper.y,sin(next)*upper.z)
			var d := Vector3(cos(angle)*upper.x,upper.y,sin(angle)*upper.z)
			_triangle(surface,a,b,c,center)
			_triangle(surface,a,c,d,center)
	for ring in [rings[0],rings[-1]]:
		for i in segments:
			_triangle(surface,Vector3(0,ring.y,0),Vector3(cos(TAU*i/segments)*ring.x,ring.y,sin(TAU*i/segments)*ring.z),Vector3(cos(TAU*(i+1)/segments)*ring.x,ring.y,sin(TAU*(i+1)/segments)*ring.z),center)
	var result := MeshInstance3D.new()
	surface.index()
	surface.generate_normals()
	result.mesh = surface.commit()
	result.material_override = ArtMaterials.surface(material_id)
	parent.add_child(result)
	return result

static func cylinder(parent: Node3D, from: Vector3, to: Vector3, radius: float, material_id: String, top_radius: float = -1) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.top_radius = radius if top_radius < 0 else top_radius
	cylinder_mesh.height = from.distance_to(to)
	cylinder_mesh.radial_segments = 20
	cylinder_mesh.rings = 1
	result.mesh = cylinder_mesh
	result.position = (from+to)/2.0
	var direction := (to-from).normalized()
	result.quaternion = Quaternion(Vector3.UP, direction)
	result.material_override = ArtMaterials.surface(material_id)
	parent.add_child(result)
	return result

static func ellipsoid(parent: Node3D, position: Vector3, size: Vector3, material_id: String) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 24
	sphere.rings = 16
	result.mesh = sphere
	result.position = position
	result.scale = size
	result.material_override = ArtMaterials.surface(material_id)
	parent.add_child(result)
	return result

static func rounded(parent: Node3D, position: Vector3, size: Vector3, material_id: String, radius: float = 0.10) -> MeshInstance3D:
	# Rounded cuboid with planar centres and true circular edge/corner normals.
	var key := "rounded/" + str(size) + "/" + str(radius)
	if not _boxes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var half := size * 0.5
		var r := minf(radius, minf(half.x, minf(half.y, half.z)) * 0.95)
		var inner := half - Vector3.ONE * r
		for axis in 3:
			var u := (axis + 1) % 3
			var v := (axis + 2) % 3
			for sign_value in [-1.0, 1.0]:
				for i in 6:
					for j in 6:
						var vertices: Array[Vector3] = []
						for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
							var p := Vector3.ZERO
							p[axis] = half[axis] * sign_value
							# Denser samples at the rounded edges; broad flat middle.
							var steps := [-1.0,-0.94,-0.80,0.0,0.80,0.94,1.0]
							p[u] = half[u] * steps[i+offset.x]
							p[v] = half[v] * steps[j+offset.y]
							vertices.append(p)
						for index in ([0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]):
							var p: Vector3 = vertices[index]
							var nearest := p.clamp(-inner,inner)
							var normal := (p-nearest).normalized()
							st.set_normal(normal)
							st.set_uv(Vector2(p[u],p[v]))
							st.add_vertex(nearest + normal*r)
		st.index()
		_boxes[key] = st.commit()
	var instance := MeshInstance3D.new()
	instance.mesh = _boxes[key]
	instance.position = position
	instance.material_override = ArtMaterials.surface(material_id)
	parent.add_child(instance)
	return instance

static func tube(parent: Node3D, points: Array[Vector3], radii: Array[float], material_id: String, segments: int = 12) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in points.size():
		var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		var right := tangent.cross(Vector3.FORWARD).normalized()
		if right.length_squared() < 0.01:
			right = tangent.cross(Vector3.RIGHT).normalized()
		var up := tangent.cross(right).normalized()
		var ring: Array[Vector3] = []
		for j in segments:
			ring.append(points[i] + radii[i]*(right*cos(TAU*j/segments)+up*sin(TAU*j/segments)))
		rings.append(ring)
	for i in points.size()-1:
		for j in segments:
			var k := (j+1)%segments
			_triangle(st,rings[i][j],rings[i+1][j],rings[i+1][k],(points[i]+points[i+1])*0.5)
			_triangle(st,rings[i][j],rings[i+1][k],rings[i][k],(points[i]+points[i+1])*0.5)
	st.index()
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = ArtMaterials.surface(material_id)
	parent.add_child(mesh)
	return mesh

static func organic(parent: Node3D, position: Vector3, size: Vector3, material_id: String, seed_value: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.7
	for row in 12:
		for col in 20:
			for offset in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var phi: float = PI * (row+offset.y)/12.0
				var theta: float = TAU*(col+offset.x)/20.0
				var unit := Vector3(sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta))
				var n := noise.get_noise_3dv(unit*2.0)
				st.set_normal(unit)
				st.set_uv(Vector2(theta/TAU,phi/PI))
				st.add_vertex(unit*size*0.5*(1.0+n*0.24))
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.position = position
	mesh.material_override = ArtMaterials.surface(material_id)
	parent.add_child(mesh)
	return mesh
