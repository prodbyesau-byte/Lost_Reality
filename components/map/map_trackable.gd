class_name MapTrackable
extends Node3D
## Attach under an entity. No global object scans; lifetime follows the component.
enum Category { PLAYER, NPC, ENEMY, QUEST, POI, SAVEPOINT, CUSTOM, LOCATION }
enum Visibility { LIVE_SIGHT, DISCOVERED_POI }
@export var category: Category = Category.CUSTOM
@export var visibility_rule: Visibility = Visibility.LIVE_SIGHT
@export var area_id: String = ""
@export var floor_id: String = "0"
@export var marker_id: String = ""
@export var title: String = ""
@export var enabled: bool = true
@export var sight_height: float = 1.5
## Optional target collider lets a ray hit the entity itself without hiding its blip.
var sight_body: CollisionObject3D

func _ready() -> void:
	MapManager.register_marker(self)

func _exit_tree() -> void:
	MapManager.unregister_marker(self)

func map_position() -> Vector2:
	return Vector2(global_position.x, global_position.z)
