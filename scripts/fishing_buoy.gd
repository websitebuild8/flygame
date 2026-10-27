extends Node3D
## Free 1DesignTool marine marker, batched once and shared by every fishing spot.
const MODEL=preload("res://assets/models/buoys/ocean_marker.glb")
const MODEL_SCALE=.22
static var shared_mesh: ArrayMesh
var phase=0.0
var clock=0.0
var body: MeshInstance3D
func _ready():
 name="FishingBuoy"
 phase=fposmod(position.x*.37+position.z*.23,TAU)
 body=MeshInstance3D.new();body.name="MarineMarker";body.mesh=model_mesh();add_child(body)
 body.scale=Vector3.ONE*MODEL_SCALE
 body.position.y=-.6-1.02*MODEL_SCALE
 body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 body.visibility_range_end=240
 set_meta("model_source","1DesignTool Fishing Harbour / Buoys")
func advance(delta: float,roughness: float):
 clock+=delta
 var sea=get_parent().surface.height(Vector2(position.x,position.z))
 body.position.y=sea-1.02*MODEL_SCALE+sin(clock*1.35+phase)*.004
 body.rotation=Vector3(sin(clock*.9+phase),0,cos(clock*1.1+phase))*(.025+roughness*.035)
static func model_mesh() -> ArrayMesh:
 if shared_mesh:return shared_mesh
 var source=MODEL.instantiate()
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 append_meshes(source,Transform3D.IDENTITY,tool)
 shared_mesh=tool.commit()
 var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.68
 shared_mesh.surface_set_material(0,material)
 source.free()
 return shared_mesh
static func append_meshes(node: Node,frame: Transform3D,tool: SurfaceTool):
 if node is Node3D:frame=frame*node.transform
 if node is MeshInstance3D and node.mesh:
  for surface in range(node.mesh.get_surface_count()):
   var arrays=node.mesh.surface_get_arrays(surface)
   var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL]
   var indices=arrays[Mesh.ARRAY_INDEX]
   var material=node.get_active_material(surface)
   var color=material.albedo_color if material is StandardMaterial3D else Color.WHITE
   var normal_frame=frame.basis.inverse().transposed()
   var count=indices.size() if indices!=null and indices.size()>0 else vertices.size()
   for i in range(count):
    var index=indices[i] if indices!=null and indices.size()>0 else i
    tool.set_color(color.srgb_to_linear())
    tool.set_normal((normal_frame*normals[index]).normalized())
    tool.add_vertex(frame*vertices[index])
 for child in node.get_children():append_meshes(child,frame,tool)
