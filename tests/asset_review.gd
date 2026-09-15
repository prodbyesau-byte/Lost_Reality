extends Node3D
## Off-map presentation review using the same production assets, scale and camera angle.
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS  ",label)
	else:
		failures += 1
		push_error("FAIL  "+label)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var ground := ArtMeshes.box(self,Vector3(0,-0.18,0),Vector3(40,0.3,40),"concrete")
	ground.material_override = ArtMaterials.floor_surface(3,0.1)
	VisualQuality.create_environment(self)
	SuburbanAssets.building(self,Vector3(-3,0,-4),Vector3(6.5,5.5,7),"house")
	SuburbanAssets.building(self,Vector3(7,0,-6),Vector3(7,3.2,6),"pharmacy")
	SuburbanAssets.car(self,Vector3(1,0,3),0.25)
	SuburbanAssets.tree(self,Vector3(-7,0,2),5.2,887)
	ArtProps.furnish(self,"sofa",Vector3(3,1.3,1.2),Vector3(6,0.65,3))
	var character := HumanVisual.new()
	character.position = Vector3(3,0,4)
	add_child(character)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 19
	add_child(camera)
	camera.position = Vector3(22,27,22)+Vector3(0,1,0)
	camera.look_at(Vector3(0,1,0))
	camera.current = true
	check(get_tree().get_nodes_in_group("art_architecture").size() == 2,"Detailed architecture instantiated")
	check(get_tree().get_nodes_in_group("art_vehicles").size() == 1,"Shaped sedan instantiated")
	check(character.knees.size() == 2 and character.elbows.size() == 2,"Human visual has articulated knees and elbows")
	check(find_children("*","CollisionObject3D",true,false).is_empty(),"Scenery kit has no gameplay collision or state")
	for id in ["brick","wood","fabric","roof","bark","asphalt","skin"]:
		var material := ArtMaterials.surface(id)
		check(material.albedo_texture != null and material.normal_texture != null and material.ao_texture != null,"Complete PBR maps: "+id)
	for i in 60:
		await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/asset_neighbourhood.png")
		camera.size = 7
		camera.position = Vector3(22,27,22)+Vector3(3,0.8,3)
		camera.look_at(Vector3(3,0.8,3))
		for i in 15:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/output/asset_close.png")
	print("ASSET RESULT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
