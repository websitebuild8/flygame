extends Node3D
## Original lightweight traffic hulls: open dinghy, cabin launch and local fishing boat.
static var meshes: Dictionary={}
var design=0
var hull: Node3D
var imported_id=""
var wake: MeshInstance3D
func _ready():
 if design in [1,4]:
  imported_id="skiff" if design==1 else "glacier"
  hull=preload("res://scripts/imported_boats.gd").MODELS[imported_id].instantiate();add_child(hull)
  hull.scale=Vector3.ONE*.22;hull.position.y=-.6*(1-.22)
  for part in hull.find_children("*","MeshInstance3D",true,false):
   part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   part.visibility_range_end=140;part.lod_bias=.25
  set_meta("imported_boat",imported_id)
 else:
  hull=MeshInstance3D.new();hull.mesh=mesh_for(design);hull.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(hull)
  hull.position.y=-.555;hull.visibility_range_end=220
 wake=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(.45,1.8);wake.mesh=quad;wake.rotation.x=-PI/2;wake.position=Vector3(0,-.585,1.3);add_child(wake)
 var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color(.7,.9,.88,.25);material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;wake.material_override=material;wake.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;wake.visibility_range_end=180
func set_speed(speed: float):
 wake.visible=speed>.5;wake.scale.y=1+speed*.08
static func mesh_for(style: int) -> ArrayMesh:
 if meshes.has(style):return meshes[style]
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var color=[Color("cee0d6"),Color("326f97"),Color("6f9e8e"),Color("a5684d"),Color("d1c394"),Color("5c7892")][style%6]
 var length_scale=1.0 if style%3==0 else (1.15 if style%3==1 else 1.45)
 var outline=[Vector2(-.24,.65),Vector2(.24,.65),Vector2(.29,-.25),Vector2(0,-.85),Vector2(-.29,-.25)]
 for i in range(5):
  var a: Vector2=outline[i];var b: Vector2=outline[(i+1)%5];a.y*=length_scale;b.y*=length_scale
  var normal=Vector3(b.y-a.y,0,a.x-b.x).normalized()
  for p in [Vector3(a.x,.20,a.y),Vector3(b.x,.20,b.y),Vector3(b.x*.65,-.03,b.y*.8),Vector3(a.x,.20,a.y),Vector3(b.x*.65,-.03,b.y*.8),Vector3(a.x*.65,-.03,a.y*.8)]:tool.set_color(color.srgb_to_linear());tool.set_normal(normal);tool.add_vertex(p)
 add_box(tool,Vector3(0,.06,0),Vector3(.43,.06,1.2*length_scale),Color("bcaf89"))
 for z in [-.25,.3]:add_box(tool,Vector3(0,.23,z*length_scale),Vector3(.47,.045,.14),Color("c2c9b7"))
 if style%3==1:
  add_box(tool,Vector3(0,.34,.05),Vector3(.42,.31,.5),Color("dce4d7"));add_box(tool,Vector3(0,.41,-.207),Vector3(.34,.15,.015),Color("4c8c9a"));add_box(tool,Vector3(0,.52,.05),Vector3(.51,.06,.62),color)
 elif style%3==2:
  for x in [-.19,.19]:add_box(tool,Vector3(x,.37,.15),Vector3(.025,.4,.025),Color("777b67"))
  add_box(tool,Vector3(0,.58,.15),Vector3(.52,.05,.9),Color("b69d68"))
 add_box(tool,Vector3(0,.15,.73*length_scale),Vector3(.14,.27,.18),Color("354349"))
 tool.generate_normals();var mesh=tool.commit();var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.8;material.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.surface_set_material(0,material);meshes[style]=mesh;return mesh
static func add_box(tool: SurfaceTool,at: Vector3,size: Vector3,color: Color):
 var arrays=BoxMesh.new().get_mesh_arrays()
 for index in arrays[Mesh.ARRAY_INDEX]:tool.set_color(color.srgb_to_linear());tool.set_normal(arrays[Mesh.ARRAY_NORMAL][index]);tool.add_vertex(at+arrays[Mesh.ARRAY_VERTEX][index]*size)
