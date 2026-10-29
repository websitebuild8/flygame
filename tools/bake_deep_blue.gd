extends SceneTree
## Offline bridge: canonicalized, unskinned meshes keep mobile fishing inexpensive.
const SOURCE=preload("res://assets/models/reference/deep_blue.glb")
func _initialize():call_deferred("run")
func vec(v: Vector3) -> Array:return [v.x,v.y,v.z]
func matrix(t: Transform3D) -> Dictionary:return {"origin":vec(t.origin),"axes":[vec(t.basis.x),vec(t.basis.y),vec(t.basis.z)]}
func renderer(mesh: MeshInstance3D,reference: Node3D) -> Dictionary:
 var skeleton=mesh.get_node(mesh.skeleton) as Skeleton3D;skeleton.force_update_all_bone_transforms()
 var inverse=reference.global_transform.affine_inverse();var transforms: Array[Transform3D]=[];var names=[]
 for bind in range(mesh.skin.get_bind_count()):
  var bone=skeleton.find_bone(mesh.skin.get_bind_name(bind));assert(bone>=0)
  transforms.append(inverse*skeleton.global_transform*skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind));names.append(str(skeleton.get_bone_name(bone)))
 var surfaces=[]
 for surface in range(mesh.mesh.get_surface_count()):
  var arrays=mesh.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL];var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS];var points=[];var directions=[];var groups=[];var uv=[]
  var normal_frames=[]
  for t in transforms:normal_frames.append(t.basis.inverse().transposed())
  for i in range(vertices.size()):
   var point=Vector3.ZERO;var direction=Vector3.ZERO;var maximum=-1.0;var group=""
   for slot in range(4):
    var index=i*4+slot;var weight=weights[index];var bind=bones[index]
    if weight>0:point+=(transforms[bind]*vertices[i])*weight;direction+=(normal_frames[bind]*normals[i])*weight
    if weight>maximum:maximum=weight;group=names[bind]
   points.append(vec(point));directions.append(vec(direction.normalized()));groups.append(group);var st=arrays[Mesh.ARRAY_TEX_UV][i];uv.append([st.x,st.y])
  surfaces.append({"vertices":points,"normals":directions,"groups":groups,"uv":uv,"indices":Array(arrays[Mesh.ARRAY_INDEX])})
 var pivots={}
 for bone in range(skeleton.get_bone_count()):pivots[str(skeleton.get_bone_name(bone))]=matrix(inverse*skeleton.global_transform*skeleton.get_bone_global_pose(bone))
 return {"name":str(mesh.name),"surfaces":surfaces,"pivots":pivots}
func run():
 var model=SOURCE.instantiate();root.add_child(model);var player=model.find_children("*","AnimationPlayer",true,false)[0];player.play("Show01");player.seek(0,true);player.advance(0)
 var data={"meshes":[],"reel_samples":[]}
 var reel: MeshInstance3D
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  if "Reel" in str(mesh.name):reel=mesh
  else:data.meshes.append(renderer(mesh,model))
 var skeleton=reel.get_node(reel.skeleton) as Skeleton3D;var ids={}
 for name in ["Bone_Reel_Handle","Bone_Reel_Wheel","Bone_Reel_Bobbin","Bone020","X"]:ids[name]=skeleton.find_bone(name)
 # The source Show clip changes the display arrangement. Bake the live reel
 # from Waiting instead, removing the source camera/hand outfit transforms.
 player.play("Waiting01");player.seek(0,true);player.advance(0);skeleton.force_update_all_bone_transforms()
 var body_frame=Node3D.new();root.add_child(body_frame)
 var wheel=skeleton.global_transform*skeleton.get_bone_global_pose(ids.Bone_Reel_Wheel)
 body_frame.global_transform=Transform3D(wheel.basis.orthonormalized(),wheel.origin)
 data.meshes.append(renderer(reel,body_frame))
 player.play("Reeling01")
 for i in range(73):
  var time=float(i)/60;player.seek(time,true);player.advance(0);skeleton.force_update_all_bone_transforms();var sample={"time":time,"bones":{}}
  wheel=skeleton.global_transform*skeleton.get_bone_global_pose(ids.Bone_Reel_Wheel)
  var inverse=Transform3D(wheel.basis.orthonormalized(),wheel.origin).affine_inverse()
  for name in ids:sample.bones[name]=matrix(inverse*skeleton.global_transform*skeleton.get_bone_global_pose(ids[name]))
  data.reel_samples.append(sample)
 body_frame.queue_free()
 var out=FileAccess.open("/tmp/deep-blue-baked.json",FileAccess.WRITE);out.store_string(JSON.stringify(data));out.close()
 model.queue_free();await process_frame;print("Exported posed mesh data and reel pivot samples");quit()
