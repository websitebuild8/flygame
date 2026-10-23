extends RefCounted
const OUTBOARD=preload("res://assets/models/boats/outboard.glb")
static func motor(parent: Node3D) -> Node3D:
	var root=Node3D.new()
	root.name="OutboardPivot"
	parent.add_child(root)
	var source=OUTBOARD.instantiate()
	root.add_child(source)
	var bounds=AABB()
	var first=true
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		var box=(source.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box)
		first=false
	var factor=1.5/bounds.size.y
	source.scale*=factor
	source.rotation.y=PI
	source.position=-(Basis(Vector3.UP,PI)*bounds.get_center())*factor+Vector3(0,.05,.15)
	var prop=source.find_child("Propeller",true,false) as Node3D
	assert(prop,"Imported outboard has a separately rotating propeller")
	prop.reparent(root,true)
	root.set_meta("imported_model",true)
	return root
