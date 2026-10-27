extends SceneTree
## Editor-only asset preparation. Source directory is supplied after --.
var source="/tmp/ishaq-harbour-source"
func _initialize():call_deferred("run")
func compact(arrays: Array,indices: PackedInt32Array) -> Array:
 var result=[];result.resize(Mesh.ARRAY_MAX)
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array();var tangents=PackedFloat32Array();var faces=PackedInt32Array();var remap={}
 for old in indices:
  if not remap.has(old):
   remap[old]=vertices.size();vertices.append(arrays[Mesh.ARRAY_VERTEX][old]);normals.append(arrays[Mesh.ARRAY_NORMAL][old]);uv.append(arrays[Mesh.ARRAY_TEX_UV][old])
   if arrays[Mesh.ARRAY_TANGENT]!=null:
    for j in range(4):tangents.append(arrays[Mesh.ARRAY_TANGENT][old*4+j])
  faces.append(remap[old])
 result[Mesh.ARRAY_VERTEX]=vertices;result[Mesh.ARRAY_NORMAL]=normals;result[Mesh.ARRAY_TEX_UV]=uv;result[Mesh.ARRAY_INDEX]=faces
 if not tangents.is_empty():result[Mesh.ARRAY_TANGENT]=tangents
 return result
func write_mesh(root: Node3D,path: String):
 var doc=GLTFDocument.new();var state=GLTFState.new();assert(doc.append_from_scene(root,state)==OK);assert(doc.write_to_filesystem(state,path)==OK);root.free()
func run():
 var args=OS.get_cmdline_user_args();if not args.is_empty():source=args[0]
 var doc=GLTFDocument.new();var state=GLTFState.new();assert(doc.append_from_file(source+"/rock/boulder_01_1k.gltf",state)==OK)
 var original=state.get_meshes()[0].mesh;var material=original.get_surface_material(0)
 original.generate_lods(60,30,[])
 var arrays=original.get_surface_arrays(0);var lowest=original.get_surface_lod_indices(0,original.get_surface_lod_count(0)-1)
 arrays=compact(arrays,lowest)
 for pass_index in range(2):
  var importer=ImporterMesh.new();importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays);importer.generate_lods(150,60,[])
  var selected=arrays[Mesh.ARRAY_INDEX];var distance=absf(selected.size()/3.0-220)
  for i in range(importer.get_surface_lod_count(0)):
   var candidate=importer.get_surface_lod_indices(0,i);var d=absf(candidate.size()/3.0-220)
   if d<distance:selected=candidate;distance=d
  arrays=compact(importer.get_surface_arrays(0),selected)
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(0,material)
 var root=Node3D.new();var rock=MeshInstance3D.new();root.add_child(rock);rock.owner=root;rock.name="ArmourRock";rock.mesh=mesh
 print("ROCK TRIANGLES ",arrays[Mesh.ARRAY_INDEX].size()/3," VERTICES ",arrays[Mesh.ARRAY_VERTEX].size())
 write_mesh(root,"res://assets/models/harbour/armour_rock.glb")
 # Adapt the CC0 lighthouse: remove landscape base and steps; keep the white tower and gallery.
 var beacon_state=GLTFState.new();assert(doc.append_from_file(source+"/beacon/lighthouse.glb",beacon_state)==OK)
 var beacon=doc.generate_scene(beacon_state);root=Node3D.new()
 var bodies={};var colors={};var low=INF;var high=-INF
 for part in beacon.find_children("*","Node3D",true,false):
  if not (part is MeshInstance3D or part is ImporterMeshInstance3D):continue
  var imported_mesh=part.mesh.get_mesh() if part is ImporterMeshInstance3D else part.mesh
  if str(part.name).begins_with("rock") or str(part.name).begins_with("steps"):continue
  var transform=part.transform;var parent=part.get_parent()
  while parent!=beacon:transform=parent.transform*transform;parent=parent.get_parent()
  for surface in range(imported_mesh.get_surface_count()):
   var mat=imported_mesh.surface_get_material(surface) as StandardMaterial3D
   var category="Lens" if mat.resource_name=="glass" else ("Metal" if mat.resource_name in ["metal","dark"] else "WhiteTower")
   if not bodies.has(category):var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);bodies[category]=tool
   var a=imported_mesh.surface_get_arrays(surface);var idx=a[Mesh.ARRAY_INDEX];var count=idx.size() if idx!=null and not idx.is_empty() else a[Mesh.ARRAY_VERTEX].size()
   for i in range(count):
    var index=idx[i] if idx!=null and not idx.is_empty() else i
    var vertex=transform*a[Mesh.ARRAY_VERTEX][index];low=minf(low,vertex.y);high=maxf(high,vertex.y)
    bodies[category].set_normal((transform.basis*a[Mesh.ARRAY_NORMAL][index]).normalized());bodies[category].add_vertex(vertex)
 var scale_factor=1.25/(high-low)
 for category in bodies:
  var body_mesh=bodies[category].commit();var mat=StandardMaterial3D.new();mat.resource_name=category
  mat.albedo_color=Color("e5e6dc") if category=="WhiteTower" else (Color("343d40") if category=="Metal" else Color("dd5150"))
  mat.roughness=.8 if category=="WhiteTower" else .4
  if category=="Lens":mat.emission_enabled=true;mat.emission=Color("dd5150");mat.emission_energy_multiplier=.5
  body_mesh.surface_set_material(0,mat)
  var part=MeshInstance3D.new();part.name=category;part.mesh=body_mesh;root.add_child(part);part.owner=root;part.scale=Vector3.ONE*scale_factor;part.position.y=-low*scale_factor
 write_mesh(root,"res://assets/models/harbour/white_beacon.glb")
 beacon.free();print("Prepared mobile rock and three-surface white beacon");quit()
