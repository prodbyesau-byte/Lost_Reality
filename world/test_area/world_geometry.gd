class_name WorldGeometry
extends RefCounted
## Small greybox construction helpers; layouts live separately in data resources.
static func box(parent: Node3D, position: Vector3, size: Vector3, color: Color, solid: bool, visual_height: float = -1.0) -> MeshInstance3D:
	var holder: Node3D = parent
	if solid:
		var body := StaticBody3D.new()
		body.position = position
		parent.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		holder = body
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	if visual_height > 0:
		box_mesh.size.y = visual_height
	# Structural solids keep simple collision, but expose finished bevelled render edges.
	mesh.mesh = ArtMeshes.bevel_box(box_mesh.size, 0.025)
	mesh.position = Vector3.ZERO if solid else position
	if visual_height > 0:
		mesh.position.y -= (size.y - visual_height) / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh.material_override = material
	holder.add_child(mesh)
	return mesh

static func label(parent: Node3D, text: String, position: Vector3, size: int, color: Color) -> Label3D:
	var result := Label3D.new()
	result.text = text
	result.position = position
	result.font_size = size
	result.pixel_size = 0.009
	result.modulate = color
	result.outline_size = 4
	result.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(result)
	return result
