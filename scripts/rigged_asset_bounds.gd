extends RefCounted
## CPU skin bounds for conversion QA/preview only; never evaluated every gameplay frame.
static func measure(root: Node3D) -> AABB:
 var inverse=root.global_transform.affine_inverse();var bounds=AABB();var first=true
 var meshes=root.find_children("*","MeshInstance3D",true,false)
 if root is MeshInstance3D:meshes.append(root)
 for mesh in meshes:
  var skeleton=mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
  var skin=mesh.skin as Skin
  var matrices: Array[Transform3D]=[]
  if skeleton and skin:
   skeleton.force_update_all_bone_transforms()
   for bind in range(skin.get_bind_count()):
    var bone=skin.get_bind_bone(bind)
    if bone<0:bone=skeleton.find_bone(skin.get_bind_name(bind))
    assert(bone>=0,"Converted skin contains an unresolved bone")
    matrices.append(inverse*skeleton.global_transform*skeleton.get_bone_global_pose(bone)*skin.get_bind_pose(bind))
  for surface in range(mesh.mesh.get_surface_count()):
   var arrays=mesh.mesh.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array;var bones=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
   var stride=4
   if bones!=null and bones.size()==vertices.size()*8:stride=8
   for i in range(vertices.size()):
    var point=Vector3.ZERO
    if not matrices.is_empty() and bones!=null and weights!=null:
     for slot in range(stride):
      var index=i*stride+slot
      if weights[index]>0:point+=(matrices[bones[index]]*vertices[i])*weights[index]
    else:point=inverse*mesh.global_transform*vertices[i]
    if first:bounds=AABB(point,Vector3.ZERO);first=false
    else:bounds=bounds.expand(point)
 return bounds
