class_name MapAreaData
extends RefCounted
## Authored map coordinates are a save contract, independent of render meshes.
var area_id: String
var floor_id: String
var definition: Dictionary
var layout: Dictionary
var origin: Vector2
var dimensions: Vector2i
var cell_size: float
var terrain_cache: Dictionary = {}

func _init(area: String, floor_key: String, data: Dictionary, geometry: Dictionary) -> void:
	area_id = area
	floor_id = floor_key
	definition = data
	layout = geometry
	origin = Vector2(data.origin[0], data.origin[1])
	dimensions = Vector2i(data.size[0], data.size[1])
	cell_size = data.cell_size

func zone_id() -> String:
	return area_id + ":" + floor_id

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floor((point.x - origin.x) / cell_size), floor((point.y - origin.y) / cell_size))

func cell_center(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2.ONE * 0.5) * cell_size

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < dimensions.x and cell.y < dimensions.y

func bounds() -> Rect2:
	return Rect2(origin, Vector2(dimensions) * cell_size)

func terrain(cell: Vector2i) -> Color:
	if terrain_cache.has(cell):
		return terrain_cache[cell]
	var point := cell_center(cell)
	var color := Color("202d33")
	for room in layout.get("rooms", []):
		if str(room.get("floor", "0")) != floor_id:
			continue
		if Rect2(room.x - room.w / 2.0, room.z - room.d / 2.0, room.w, room.d).has_point(point):
			color = Color("32474d")
	for kind in ["obstacles", "walls"]:
		for solid in layout.get(kind, []):
			if str(solid.get("floor", "0")) != floor_id:
				continue
			var rect := Rect2(solid.position[0] - solid.size[0] / 2.0, solid.position[2] - solid.size[2] / 2.0, solid.size[0], solid.size[2])
			if rect.intersects(Rect2(point - Vector2.ONE * cell_size * 0.5, Vector2.ONE * cell_size)):
				color = Color("789095") if kind == "walls" else Color("506166")
	terrain_cache[cell] = color
	return color
