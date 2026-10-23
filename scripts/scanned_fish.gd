extends Node3D
## Imported species in the same canonical frame as the existing catch models.
const MODELS={
 "Skipjack tuna":preload("res://assets/models/fish/skipjack.glb"),
 "Sailfish":preload("res://assets/models/fish/sailfish.glb"),
 "Mahi-mahi":preload("res://assets/models/fish/mahi_mahi.glb")
}
const SKIN=preload("res://shaders/trevally_swim.gdshader")
var species_name=""
var swim_intensity=1.0
var phase=0.0
var skins: Array[ShaderMaterial]=[]
func setup(name_text: String) -> void:
	species_name=name_text
	assert(MODELS.has(name_text),"Missing imported species: "+name_text)
	var source=MODELS[name_text].instantiate()
	add_child(source)
	for mesh_node in source.find_children("*","MeshInstance3D",true,false):
		mesh_node.custom_aabb=mesh_node.get_aabb().grow(.2)
		for surface in range(mesh_node.mesh.get_surface_count()):
			var original=mesh_node.mesh.surface_get_material(surface) as StandardMaterial3D
			var skin=ShaderMaterial.new()
			skin.shader=SKIN
			skin.set_shader_parameter("use_vertex_color",name_text=="Sailfish")
			if name_text=="Sailfish" and original:
				var part_names=["PolySphere","PM3D_Sphere3D1","PM3D_Sphere3D1_1","PM3D_Sphere3D1_2","PM3D_Sphere3D1_3","PM3D_Cylinder3D1","PM3D_Sphere3D1_4","Extract10"]
				skin.set_shader_parameter("sail_part",part_names.find(original.resource_name))
			if original and original.albedo_texture:
				skin.set_shader_parameter("skin_texture",original.albedo_texture)
			mesh_node.set_surface_override_material(surface,skin)
			skins.append(skin)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	phase=fmod(phase+delta*clampf(3.8+swim_intensity*2.2,3.8,10.5),TAU)
	for skin in skins:
		skin.set_shader_parameter("phase",phase)
		skin.set_shader_parameter("amplitude",clampf(.025+swim_intensity*.018,.025,.095))
