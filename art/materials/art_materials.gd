class_name ArtMaterials
extends RefCounted
## Shared PBR surfaces. Procedural source textures are deterministic, seamless, and cached.
static var _config: Dictionary = {}
static var _surfaces: Dictionary = {}
static var _normal: NoiseTexture2D
static var _tone: NoiseTexture2D

static func config() -> Dictionary:
	if _config.is_empty():
		_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_direction.json"))
	return _config.duplicate(true)

static func _textures() -> void:
	if _normal != null:
		return
	var noise := FastNoiseLite.new()
	noise.seed = 73021
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	_normal = NoiseTexture2D.new()
	_normal.width = 512
	_normal.height = 512
	_normal.seamless = true
	_normal.noise = noise
	_normal.as_normal_map = true
	_normal.bump_strength = 0.6
	_tone = NoiseTexture2D.new()
	_tone.width = 512
	_tone.height = 512
	_tone.seamless = true
	_tone.noise = noise
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.88, 0.88, 0.88))
	gradient.set_color(1, Color(1.0, 1.0, 1.0))
	_tone.color_ramp = gradient

static func surface(id: String) -> StandardMaterial3D:
	if _surfaces.has(id):
		return _surfaces[id]
	_textures()
	var definition: Dictionary = config().materials[id]
	var material := StandardMaterial3D.new()
	material.resource_name = "HD / " + id
	material.albedo_color = Color(definition.color)
	material.albedo_texture = _tone
	material.roughness = definition.roughness
	material.roughness_texture = _tone
	material.metallic = definition.metallic
	material.metallic_specular = 0.35
	material.normal_enabled = true
	material.normal_texture = _normal
	material.normal_scale = definition.normal
	var family: String = definition.get("texture", "mineral")
	var texture_root := "res://art/materials/textures/" + family
	material.albedo_texture = load(texture_root + "_albedo.png")
	material.normal_texture = load(texture_root + "_normal.png")
	material.roughness_texture = load(texture_root + "_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.ao_enabled = true
	material.ao_texture = material.roughness_texture
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	# Shared 512px surface repeat over 2m: 256 texels/metre independent of mesh size.
	material.uv1_scale = Vector3.ONE * 0.5
	if family in ["fabric", "skin", "wood", "bark", "metal"]:
		material.uv1_world_triplanar = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_surfaces[id] = material
	return material

static func floor_surface(kind: int, wetness: float = 0.0) -> ShaderMaterial:
	_textures()
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/materials/floor.gdshader")
	material.set_shader_parameter("surface_kind", kind)
	material.set_shader_parameter("wetness", wetness)
	material.set_shader_parameter("micro_normal", _normal)
	return material

static func light_surface(color: Color, energy: float = 0.65) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
