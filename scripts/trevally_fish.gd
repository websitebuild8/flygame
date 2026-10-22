extends Node3D
## CC0 scanned Caranx ignobilis, with per-instance body/tail movement.
const MODEL=preload("res://assets/models/fish/trevally.glb")
const SKIN=preload("res://shaders/trevally_swim.gdshader")
var species_name="Giant trevally"
var swim_intensity=1.0
var phase=0.0
var skins: Array[ShaderMaterial]=[]
func setup(name_text: String) -> void:
	species_name=name_text
	var source=MODEL.instantiate()
	add_child(source)
	for mesh_node in source.find_children("*","MeshInstance3D",true,false):
		mesh_node.custom_aabb=AABB(Vector3(-.6,-.8,-1.4),Vector3(1.2,1.6,2.8))
		for surface in range(mesh_node.mesh.get_surface_count()):
			var original=mesh_node.mesh.surface_get_material(surface)
			var skin=ShaderMaterial.new()
			skin.shader=SKIN
			if original is StandardMaterial3D:
				skin.set_shader_parameter("skin_texture",original.albedo_texture)
			mesh_node.set_surface_override_material(surface,skin)
			skins.append(skin)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	phase=fmod(phase+delta*clampf(3.8+swim_intensity*2.2,3.8,10.5),TAU)
	for skin in skins:
		skin.set_shader_parameter("phase",phase)
		skin.set_shader_parameter("amplitude",clampf(.025+swim_intensity*.018,.025,.095))
