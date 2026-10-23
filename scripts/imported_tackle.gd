extends RefCounted
## CC BY 4.0 Ergin ERYILDIR rod/reel; source and modifications in asset credits.
const SOURCE=preload("res://assets/models/tackle/fishing_rod.glb")
static func reel(parent: Node3D) -> Node3D:
	var root=Node3D.new()
	root.name="ImportedSpinningReel"
	parent.add_child(root)
	var source=SOURCE.instantiate()
	root.add_child(source)
	var space=Node3D.new()
	root.add_child(space)
	var bounds=AABB()
	var first=true
	var parts={}
	for part_name in ["Object001_rod06_0","Rod02_rod06_0","Object002_RodThread_0","rod03_rod06_0"]:
		var original=source.find_child(part_name,true,false) as MeshInstance3D
		assert(original,"Missing imported reel part: "+part_name)
		var part=MeshInstance3D.new()
		part.name=part_name
		part.mesh=original.mesh
		space.add_child(part)
		part.transform=source.global_transform.affine_inverse()*original.global_transform
		parts[part_name]=part
		var box=part.transform*part.get_aabb()
		bounds=box if first else bounds.merge(box)
		first=false
	var factor=.44/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	space.scale=Vector3.ONE*factor
	space.position=-bounds.get_center()*factor
	var crank=pivot_for(space,parts.rod03_rod06_0,source,"rod03","Crank")
	var rotor=pivot_for(space,parts.Rod02_rod06_0,source,"Rod02","Rotor")
	crank.set_meta("spin_axis",Vector3.BACK)
	rotor.set_meta("spin_axis",Vector3.RIGHT)
	root.rotation.y=-PI/2
	root.set_meta("crank",crank)
	root.set_meta("rotor",rotor)
	root.set_meta("spool",parts.Object002_RodThread_0)
	root.set_meta("kind","spinning")
	root.set_meta("imported_model",true)
	source.free()
	return root
static func pivot_for(parent: Node3D,part: MeshInstance3D,source: Node3D,source_pivot_name: String,label_text: String) -> Node3D:
	var pivot=Node3D.new()
	pivot.name=label_text
	parent.add_child(pivot)
	# Preserve the authored bearing frame; mesh bounds are offset from the shaft.
	var bearing=source.find_child(source_pivot_name,true,false) as Node3D
	assert(bearing,"Missing reel bearing: "+source_pivot_name)
	pivot.transform=source.global_transform.affine_inverse()*bearing.global_transform
	part.reparent(pivot,true)
	return pivot
static func rod_preview(parent: Node3D) -> Node3D:
	var root=Node3D.new()
	parent.add_child(root)
	var source=SOURCE.instantiate()
	root.add_child(source)
	for player in source.find_children("*","AnimationPlayer",true,false): player.stop()
	var bounds=AABB()
	var first=true
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		var box=(source.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box)
		first=false
	var factor=2.1/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	source.scale*=factor
	source.position=-bounds.get_center()*factor
	root.set_meta("imported_model",true)
	return root
