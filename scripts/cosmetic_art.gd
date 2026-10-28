extends RefCounted
## Instance-local material overrides preserve mesh geometry, rigging and shared source assets.
const Paint=preload("res://shaders/cosmetic_paint.gdshader")
static func apply(root: Node3D,category: String,style: Dictionary):
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  if mesh.get_meta("cosmetic_skip",false):continue
  if category=="Rods":
   for surface in range(mesh.mesh.get_surface_count()):
    var mat=mesh.get_active_material(surface)
    if mat is ShaderMaterial and mat.shader==preload("res://shaders/authored_rod.gdshader"):
     mat.set_shader_parameter("custom_color",style.color);mat.set_shader_parameter("custom_accent",style.accent);mat.set_shader_parameter("custom_paint",style.id!="original");mat.set_shader_parameter("custom_special",style.premium or style.get("pattern",false))
   continue
  if category=="Boats" and mesh.name!="Hull":continue
  if category=="Reels" and not (str(mesh.name) in ["Body","Object001_rod06_0"] or "frame" in str(mesh.name) or "guard" in str(mesh.name)):continue
  if not mesh.has_meta("cosmetic_materials"):
   var originals: Array=[]
   for i in range(mesh.mesh.get_surface_count()):originals.append(mesh.get_surface_override_material(i))
   mesh.set_meta("cosmetic_materials",originals)
  var originals=mesh.get_meta("cosmetic_materials")
  for i in range(mesh.mesh.get_surface_count()):
   mesh.set_surface_override_material(i,originals[i])
   var source=mesh.get_active_material(i) as StandardMaterial3D
   if not source or style.id=="original":continue
   if source.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA,BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS] or "glass" in source.resource_name.to_lower() or "registration" in source.resource_name.to_lower() or "fire" in source.resource_name.to_lower():continue
   var material=ShaderMaterial.new();material.shader=Paint
   material.set_shader_parameter("has_map",source.albedo_texture!=null)
   if source.albedo_texture:material.set_shader_parameter("base_map",source.albedo_texture)
   material.set_shader_parameter("base_color",source.albedo_color)
   material.set_shader_parameter("cutout",source.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
   material.set_shader_parameter("cutoff",source.alpha_scissor_threshold)
   material.set_shader_parameter("paint_color",style.color);material.set_shader_parameter("accent_color",style.accent)
   material.set_shader_parameter("has_normal",source.normal_enabled and source.normal_texture!=null)
   if source.normal_enabled and source.normal_texture:material.set_shader_parameter("normal_map",source.normal_texture)
   material.set_shader_parameter("source_roughness",source.roughness);material.set_shader_parameter("source_metallic",source.metallic)
   material.set_shader_parameter("boat",category=="Boats");material.set_shader_parameter("special",style.premium or style.get("pattern",false))
   var box=mesh.get_aabb();material.set_shader_parameter("band_low",box.position.y+box.size.y*.04);material.set_shader_parameter("band_high",box.position.y+box.size.y*.35)
   mesh.set_surface_override_material(i,material)
