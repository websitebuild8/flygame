extends RefCounted
## Owner-authorized Deep Blue geometry, adapted to the existing fishing controls.
## Live meshes are baked once offline: no second skeleton/AnimationPlayer per rod.
const Data=preload("res://scripts/deep_blue_data.gd")
const SOURCE=preload("res://assets/models/reference/deep_blue.glb")
static var source_materials: Dictionary={}
static func materials():
 if not source_materials.is_empty():return
 var source=SOURCE.instantiate()
 for mesh in source.find_children("*","MeshInstance3D",true,false):
  source_materials["Reel" if "Reel" in str(mesh.name) else "Rod"]=mesh.get_active_material(0)
 source.free()
 assert(source_materials.size()==2,"Converted Deep Blue texture materials must be present")
static func piece(parent: Node3D,name: String,geometry: ArrayMesh,material: Material) -> MeshInstance3D:
 var mesh=MeshInstance3D.new();mesh.name=name;mesh.mesh=geometry;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(mesh);mesh.set_meta("imported_model",true)
 if material:
  for surface in range(geometry.get_surface_count()):mesh.set_surface_override_material(surface,material)
 return mesh
static func rod(parent: Node3D) -> MeshInstance3D:
 materials()
 var mesh=piece(parent,"AuthoredRodBlank",Data.ROD,null)
 var source=source_materials.Rod as StandardMaterial3D
 var shader=ShaderMaterial.new();shader.shader=preload("res://shaders/authored_rod.gdshader");shader.set_shader_parameter("albedo_map",source.albedo_texture);shader.set_shader_parameter("tint",Color.WHITE);shader.set_shader_parameter("preserve_source_color",true)
 shader.set_shader_parameter("has_normal",source.normal_enabled and source.normal_texture!=null)
 if source.normal_texture:shader.set_shader_parameter("normal_map",source.normal_texture)
 mesh.set_surface_override_material(0,shader)
 parent.set_meta("authored_tip",Data.TIP);parent.set_meta("guide_points",PackedVector3Array(Data.GUIDES));parent.set_meta("deep_blue",true)
 return mesh
static func reel(parent: Node3D) -> Node3D:
 materials()
 var root=Node3D.new();root.name="DeepBlueSpinningReel";parent.add_child(root)
 var material=(source_materials.Reel as StandardMaterial3D).duplicate()
 var body=piece(root,"Body",Data.BODY,material)
 var spool=piece(root,"Spool",Data.SPOOL,material)
 var rotor=Node3D.new();rotor.name="BailBearing";root.add_child(rotor);rotor.position=Data.ROTOR_PIVOT;rotor.set_meta("spin_axis",Vector3.FORWARD)
 piece(rotor,"Rotor",Data.ROTOR,material)
 var crank=Node3D.new();crank.name="Crank";root.add_child(crank);crank.position=Data.CRANK_PIVOT;crank.set_meta("spin_axis",Vector3.RIGHT);crank.set_meta("grip_point",Data.GRIP_POINT)
 piece(crank,"CrankArm",Data.CRANK,material)
 var knob=Node3D.new();knob.name="FreeHandleKnob";crank.add_child(knob);knob.position=Data.KNOB_ORIGIN;piece(knob,"HandleGrip",Data.KNOB,material)
 var roller=Marker3D.new();roller.name="LineRoller";rotor.add_child(roller);roller.position=Data.LINE_ROLLER
 var lip=Marker3D.new();lip.name="SpoolLip";spool.add_child(lip);lip.position=Data.SPOOL_LIP
 root.set_meta("crank",crank);root.set_meta("rotor",rotor);root.set_meta("spool",spool);root.set_meta("body",body);root.set_meta("free_knob",knob)
 root.set_meta("spool_lip",lip);root.set_meta("line_roller",roller);root.set_meta("mount_foot",Data.MOUNT_FOOT)
 root.set_meta("rotor_ratio",Data.ROTOR_RATIO);root.set_meta("spool_travel",Data.SPOOL_TRAVEL);root.set_meta("deep_blue",true)
 root.set_meta("grip_offset",Vector3(0,0,.014));root.set_meta("kind","spinning");root.set_meta("right_hand_retrieve",true);root.set_meta("imported_model",true)
 return root
