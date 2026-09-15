class_name TestLevel
extends Node3D
@export_file("*.json") var layout_path: String
var layout: Dictionary
var _solids: Array[Dictionary] = []

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	_build()

func spawn_position(id: String) -> Variant:
	if not layout.spawns.has(id):
		return null
	return SaveSerializer.to_vector(layout.spawns[id])

func _build() -> void:
	var slab := WorldGeometry.box(self, Vector3(0, -0.25, 0), Vector3(28, 0.5, 28), Color("242f36"), true)
	slab.material_override = ArtMaterials.floor_surface(0,0.5)
	for room in layout.rooms:
		var floor_mesh := WorldGeometry.box(self, Vector3(room.x, 0.012, room.z), Vector3(room.w, 0.025, room.d), Color(room.color), false)
		var kind := 1 if room.name.contains("REFUGE") else (2 if room.name.contains("HALL") else 0)
		floor_mesh.material_override = ArtMaterials.floor_surface(kind,0.6 if layout.id == "courtyard" else 0.12)
	for wall in layout.walls:
		var pos := SaveSerializer.to_vector(wall.position)
		var size := SaveSerializer.to_vector(wall.size)
		var mesh := WorldGeometry.box(self, pos, size, Color("596568"), true, wall.get("cutaway", -1.0))
		mesh.material_override = ArtMaterials.surface("plaster")
		ArtDressing.wall(self,pos,size,wall.get("cutaway",-1.0))
		# Occluders match visible full walls, never the invisible height of a cutaway.
		if not wall.has("cutaway"):
			var occluder := OccluderInstance3D.new()
			var shape := BoxOccluder3D.new()
			shape.size = size
			occluder.occluder = shape
			occluder.position = pos
			add_child(occluder)
		_solids.append({"position": pos, "size": size})
	for item in layout.obstacles:
		var pos := SaveSerializer.to_vector(item.position)
		var size := SaveSerializer.to_vector(item.size)
		var collision_mesh := WorldGeometry.box(self, pos, size, Color(item.get("color", "70665b")), true)
		collision_mesh.hide()
		ArtProps.furnish(self,item.get("asset","crates"),size,pos)
		_solids.append({"position": pos, "size": size})
	for item in layout.objects:
		var object: Interactable
		match item.type:
			"save": object = WorldSavePoint.new()
			"lamp":
				object = TestObject.new()
				object.persistent_id = layout.id + "/" + item.id
			"door":
				object = WorldDoor.new()
				object.persistent_id = layout.id + "/" + item.id
			"exit":
				object = LevelExit.new()
				object.destination = item.destination
				object.entrance = item.get("entrance", "entry")
		object.position = SaveSerializer.to_vector(item.position)
		add_child(object)
		if item.type in ["save", "lamp"]:
			_solids.append({"position": object.position + Vector3(0, 0.7, 0), "size": Vector3(0.65, 1.4, 0.65)})
	ArtDressing.dress(self,layout_path.get_basename()+"_art.json")
	VisualQuality.create_environment(self)

func apply_persistent_state() -> void:
	for child in get_children():
		if child.has_method("apply_state"):
			child.apply_state()

func position_is_safe(position: Vector3, sections: Dictionary) -> bool:
	# Conservative capsule-vs-box check before committing loaded data.
	for solid in _solids:
		if _overlaps(position, solid.position, solid.size):
			return false
	for object in layout.objects:
		if object.type == "door" and not sections.get("world", {}).get(layout.id + "/" + object.id, false):
			if _overlaps(position, SaveSerializer.to_vector(object.position) + Vector3(0, 1.2, 0), Vector3(1.8, 2.4, 0.18)):
				return false
	return true

func _overlaps(player_position: Vector3, center: Vector3, size: Vector3) -> bool:
	var delta := player_position - center
	# Radius is slightly smaller than the physical capsule to accept resting contact.
	var closest_x := maxf(absf(delta.x) - size.x / 2.0, 0.0)
	var closest_z := maxf(absf(delta.z) - size.z / 2.0, 0.0)
	return closest_x * closest_x + closest_z * closest_z < 0.30 * 0.30 and player_position.y < center.y + size.y / 2.0 and player_position.y + 1.7 > center.y - size.y / 2.0
