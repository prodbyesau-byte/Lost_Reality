extends Node3D
## Repeatable front/side/back inspection of the actual playable character geometry.
func _ready() -> void:
	call_deferred("run")

func run() -> void:
	VisualQuality.create_environment(self)
	var floor_mesh := ArtMeshes.box(self,Vector3(0,-0.045,0),Vector3(14,0.08,14),"concrete")
	floor_mesh.material_override = ArtMaterials.surface("concrete")
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30,-145,0)
	key.light_energy = 1.5
	key.light_color = Color("ffe8d1")
	add_child(key)
	var characters: Array[HumanVisual] = []
	for index in 3:
		var character := HumanVisual.new()
		character.position.x = (index-1)*1.2
		character.rotation.y = [0.0,PI/2,PI][index]
		add_child(character)
		characters.append(character)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.3
	add_child(camera)
	camera.position = Vector3(0,1.7,-8)
	camera.look_at(Vector3(0,0.87,0))
	camera.current = true
	for i in 45:
		await get_tree().process_frame
	for character in characters:
		assert(character.has_node("GreyTShirt") and character.has_node("OpenHoodie") and character.has_node("CanvasBackpack") and character.has_node("TousledBrownHair"),"Reference outfit is complete")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/player_reference_turnaround.png")
	print("PLAYER VISUAL: front/side/back outfit review passed")
	get_tree().quit()
