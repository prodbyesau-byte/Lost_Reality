extends Node
## Exploration owns its JSON namespace. Physics visibility and presentation stay separate.
signal exploration_changed
const SECTION := "exploration"
@export var reveal_radius: float = 5.0
@export var reveal_interval: float = 0.15
@export var minimap_range: float = 12.0
var current_floor: String = "0"
var debug_grid := false
var debug_markers := false
var _markers: Dictionary = {}
var _visible_live: Dictionary = {}
var _state: Dictionary = ExplorationSchema.defaults()
var _textures: Dictionary = {}
var _clock := 0.0
var _writing := false

func _ready() -> void:
	GameState.register_section(SECTION, ExplorationSchema.valid, ExplorationSchema.defaults())
	GameState.sections_replaced.connect(_reload)
	GameState.section_changed.connect(func(key: String) -> void:
		if key == SECTION and not _writing: _reload())
	EventBus.scene_changed.connect(_scene_changed)
	_reload()

func _reload() -> void:
	_state = GameState.get_section(SECTION)
	_textures.clear()
	_visible_live.clear()
	_clock = 0.0
	exploration_changed.emit()

func _scene_changed(_id: String) -> void:
	current_floor = MapCatalog.floor_at(SceneRouter.current_id, SceneRouter.player.global_position.y)
	_visible_live.clear()
	_clock = 0.0
	# Loading must restore exactly the saved mask. Reveal resumes on gameplay ticks.
	exploration_changed.emit()

func register_marker(marker: MapTrackable) -> void:
	_markers[marker.get_instance_id()] = weakref(marker)

func unregister_marker(marker: MapTrackable) -> void:
	_markers.erase(marker.get_instance_id())
	_visible_live.erase(marker.get_instance_id())

func attach_area(level: Node3D, area_id: String) -> void:
	for floor_id in MapCatalog.definitions().get(area_id, {}).get("floors", {}):
		var area := MapCatalog.area(area_id, floor_id)
		for id in area.definition.pois:
			var data: Dictionary = area.definition.pois[id]
			var marker := MapTrackable.new()
			marker.area_id = area_id
			marker.floor_id = floor_id
			marker.marker_id = id
			marker.title = data.title
			marker.category = MapTrackable.Category.get(data.kind, MapTrackable.Category.POI)
			marker.visibility_rule = MapTrackable.Visibility.DISCOVERED_POI
			marker.position = SaveSerializer.to_vector(data.position)
			level.add_child(marker)

func _physics_process(delta: float) -> void:
	if SceneRouter.busy or not is_instance_valid(SceneRouter.player):
		return
	current_floor = MapCatalog.floor_at(SceneRouter.current_id, SceneRouter.player.global_position.y)
	var area := MapCatalog.area(SceneRouter.current_id, current_floor)
	if area == null:
		return
	_clock -= delta
	if _clock <= 0.0:
		_clock = reveal_interval
		reveal_near_player()
	_visible_live.clear()
	for ref in _markers.values():
		var marker := ref.get_ref() as MapTrackable
		if marker == null or not marker.enabled or marker.category == MapTrackable.Category.PLAYER:
			continue
		if marker.area_id == area.area_id and marker.floor_id == current_floor and marker.visibility_rule == MapTrackable.Visibility.LIVE_SIGHT:
			if is_explored(area, area.cell_at(marker.map_position())) and can_see(marker.global_position + Vector3.UP * marker.sight_height, marker.sight_body):
				_visible_live[marker.get_instance_id()] = marker.global_position

func can_see(target: Vector3, target_body: CollisionObject3D = null) -> bool:
	if not is_instance_valid(SceneRouter.player) or SceneRouter.busy:
		return false
	var eye := SceneRouter.player.global_position + Vector3.UP * 1.5
	if Vector2(target.x - eye.x, target.z - eye.z).length() > reveal_radius:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, target, 1)
	query.exclude = [SceneRouter.player.get_rid()]
	var hit := SceneRouter.player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (target_body != null and hit.collider == target_body)

func reveal_near_player() -> void:
	if SceneRouter.busy or get_tree().paused or not is_instance_valid(SceneRouter.player):
		return
	var area := MapCatalog.area(SceneRouter.current_id, current_floor)
	if area == null:
		return
	var eye := SceneRouter.player.global_position + Vector3.UP * 1.5
	var point := Vector2(eye.x, eye.z)
	var first := area.cell_at(point - Vector2.ONE * reveal_radius)
	var last := area.cell_at(point + Vector2.ONE * reveal_radius)
	var next := _state.duplicate(true)
	var zone: Dictionary = next.zones.get(area.zone_id(), {"chunks": {}, "pois": {}})
	var changed := false
	for y in range(maxi(0, first.y), mini(area.dimensions.y - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(area.dimensions.x - 1, last.x) + 1):
			var cell := Vector2i(x, y)
			var center := area.cell_center(cell)
			if point.distance_to(center) > reveal_radius or ExplorationSchema.has_cell(zone.chunks, cell):
				continue
			var query := PhysicsRayQueryParameters3D.create(eye, Vector3(center.x, eye.y, center.y), 1)
			query.exclude = [SceneRouter.player.get_rid()]
			var hit := SceneRouter.player.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():
				# Reveal only the wall surface cell, never the terrain behind it.
				cell = area.cell_at(Vector2(hit.position.x, hit.position.z))
			if area.contains(cell):
				changed = _mark_cell(zone.chunks, cell) or changed
	for ref in _markers.values():
		var marker := ref.get_ref() as MapTrackable
		if marker == null or not marker.enabled or marker.area_id != area.area_id or marker.floor_id != area.floor_id:
			continue
		if marker.visibility_rule != MapTrackable.Visibility.DISCOVERED_POI or not area.definition.pois.has(marker.marker_id) or zone.pois.has(marker.marker_id):
			continue
		if can_see(marker.global_position + Vector3.UP * marker.sight_height, marker.sight_body):
			_mark_cell(zone.chunks, area.cell_at(marker.map_position()))
			zone.pois[marker.marker_id] = true
			changed = true
	if changed:
		next.zones[area.zone_id()] = zone
		_commit(next)

func _mark_cell(chunks: Dictionary, cell: Vector2i) -> bool:
	if ExplorationSchema.has_cell(chunks, cell):
		return false
	var key := ExplorationSchema.chunk_key(cell)
	var bytes := PackedByteArray()
	if chunks.has(key):
		bytes = str(chunks[key]).hex_decode()
	else:
		bytes.resize(ExplorationSchema.BYTES)
	var bit := ExplorationSchema.bit_index(cell)
	bytes[bit / 8] |= 1 << (bit % 8)
	chunks[key] = bytes.hex_encode()
	return true

func _commit(next: Dictionary) -> bool:
	_writing = true
	var ok := GameState.set_section(SECTION, next)
	_writing = false
	if ok:
		_state = next
		exploration_changed.emit()
	return ok

func zone_state(area: MapAreaData) -> Dictionary:
	return _state.zones.get(area.zone_id(), {"chunks": {}, "pois": {}})

func is_explored(area: MapAreaData, cell: Vector2i) -> bool:
	return area != null and area.contains(cell) and ExplorationSchema.has_cell(zone_state(area).chunks, cell)

func discovered_zones() -> Array:
	var result: Array = _state.zones.keys()
	result.sort()
	return result

func chunk_texture(area: MapAreaData, chunk: Vector2i) -> Texture2D:
	var key := "%d,%d" % [chunk.x, chunk.y]
	var mask: String = zone_state(area).chunks.get(key, "")
	if mask.is_empty():
		return null
	var cache_key := area.zone_id() + "/" + key
	if _textures.has(cache_key) and _textures[cache_key].mask == mask:
		return _textures[cache_key].texture
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 16:
		for x in 16:
			var cell := chunk * 16 + Vector2i(x, y)
			if is_explored(area, cell):
				image.set_pixel(x, y, area.terrain(cell))
	var texture := ImageTexture.create_from_image(image)
	_textures[cache_key] = {"mask": mask, "texture": texture}
	return texture

func visible_markers(area: MapAreaData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Persisted POIs remain available even when their scene is unloaded.
	for id in zone_state(area).pois:
		var data: Dictionary = area.definition.pois[id]
		result.append({"id": id, "position": Vector2(data.position[0], data.position[2]), "kind": data.kind, "title": data.title})
	for ref in _markers.values():
		var marker := ref.get_ref() as MapTrackable
		if marker == null or not marker.enabled:
			continue
		if marker.category == MapTrackable.Category.PLAYER:
			if SceneRouter.current_id == area.area_id and current_floor == area.floor_id:
				result.append({"id": "player", "position": marker.map_position(), "kind": "PLAYER", "title": "You", "rotation": marker.global_rotation.y})
		elif marker.area_id == area.area_id and marker.floor_id == area.floor_id and _visible_live.has(marker.get_instance_id()):
			# A component can move during _process after the physics visibility pass.
			# Never draw a stale blip across a fog boundary or newly occluding wall.
			if not is_explored(area, area.cell_at(marker.map_position())):
				continue
			if marker.global_position != _visible_live[marker.get_instance_id()] and not can_see(marker.global_position + Vector3.UP * marker.sight_height, marker.sight_body):
				continue
			result.append({"id": marker.marker_id, "position": marker.map_position(), "kind": MapTrackable.Category.keys()[marker.category], "title": marker.title})
	return result

func debug_enabled() -> bool:
	return OS.is_debug_build() and "--map-debug" in OS.get_cmdline_user_args()

func debug_reveal() -> bool:
	if not debug_enabled():
		return false
	var area := MapCatalog.area(SceneRouter.current_id, current_floor)
	if area == null:
		return false
	var next := _state.duplicate(true)
	var zone := {"chunks": {}, "pois": {}}
	for y in area.dimensions.y:
		for x in area.dimensions.x:
			_mark_cell(zone.chunks, Vector2i(x, y))
	for id in area.definition.pois:
		zone.pois[id] = true
	next.zones[area.zone_id()] = zone
	return _commit(next)

func debug_clear() -> bool:
	return _commit(ExplorationSchema.defaults()) if debug_enabled() else false

func debug_registered() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not debug_enabled():
		return result
	for ref in _markers.values():
		var marker := ref.get_ref() as MapTrackable
		if marker != null:
			result.append({"id": marker.marker_id, "area": marker.area_id, "floor": marker.floor_id, "position": marker.map_position()})
	return result
