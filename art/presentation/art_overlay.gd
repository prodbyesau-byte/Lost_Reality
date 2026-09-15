class_name ArtOverlay
extends CanvasLayer
func _ready() -> void:
	layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://art/presentation/vignette.gdshader")
	rect.material = shader
	add_child(rect)
