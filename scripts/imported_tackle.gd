extends RefCounted
## CC BY 4.0 Ergin ERYILDIR rod/reel; source and modifications in asset credits.
const SOURCE=preload("res://assets/models/tackle/fishing_rod.glb")
static var blank_mesh: ArrayMesh
static func live_blank(parent: Node3D,rod_id: String) -> MeshInstance3D:
	if not blank_mesh:
		var source=SOURCE.instantiate()
		var original=source.find_child("Object_9",true,false) as MeshInstance3D
		assert(original)
		blank_mesh=ArrayMesh.new()
		var along=Vector3(0,.47,-.882666).normalized()
		var radial=Vector3(0,.882666,.47).normalized()
		var basis=Basis(-along,radial,Vector3.LEFT)
		var factor=2.7/767.7156
		for surface in range(original.mesh.get_surface_count()):
			var a=original.mesh.surface_get_arrays(surface)
			var vertices=a[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var normals=a[Mesh.ARRAY_NORMAL] as PackedVector3Array
			for i in range(vertices.size()):
				vertices[i]=Vector3(0,-.04,.38)+basis*(vertices[i]-Vector3(131.5645,20.9,0))*factor
				normals[i]=(basis*normals[i]).normalized()
			a[Mesh.ARRAY_VERTEX]=vertices;a[Mesh.ARRAY_NORMAL]=normals
			a[Mesh.ARRAY_BONES]=null;a[Mesh.ARRAY_WEIGHTS]=null;a[Mesh.ARRAY_TANGENT]=null
			blank_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
			blank_mesh.surface_set_material(surface,original.get_active_material(surface))
		source.free()
	var mesh=MeshInstance3D.new();mesh.name="AuthoredRodBlank";mesh.mesh=blank_mesh;parent.add_child(mesh)
	mesh.set_meta("imported_model",true)
	for surface in range(blank_mesh.get_surface_count()):
		var source_mat=blank_mesh.surface_get_material(surface) as StandardMaterial3D
		var mat=ShaderMaterial.new();mat.shader=preload("res://shaders/authored_rod.gdshader")
		mat.set_shader_parameter("albedo_map",source_mat.albedo_texture)
		mat.set_shader_parameter("tint",Color.WHITE if rod_id=="island_rod" else (Color("cfaaed") if rod_id=="grappler" else Color("b9d5ef")))
		mesh.set_surface_override_material(surface,mat)
	parent.set_meta("authored_tip",Vector3(0,1.229,-2.003))
	return mesh
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
	var crank_mesh=parts.rod03_rod06_0 as MeshInstance3D
	var grip_points: Array[Vector3]=[]
	var farthest=0.0
	for surface in range(crank_mesh.mesh.get_surface_count()):
		for vertex in crank_mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var point=crank_mesh.transform*vertex
			grip_points.append(point)
			farthest=maxf(farthest,Vector2(point.x,point.y).length())
	var grip=Vector3.ZERO
	var count=0
	for point in grip_points:
		if Vector2(point.x,point.y).length()>farthest*.85:
			grip+=point;count+=1
	crank.set_meta("grip_point",grip/maxi(1,count))
	rotor.set_meta("spin_axis",Vector3.RIGHT)
	root.rotation.y=-PI/2
	# Convert the reversible spinning reel to a right-hand retrieve, preserving its spool axis.
	# The source is rotated 90 degrees: its local Z is the rod's lateral X axis.
	root.scale.z=-1
	root.set_meta("right_hand_retrieve",true)
	root.set_meta("crank",crank)
	root.set_meta("rotor",rotor)
	root.set_meta("spool",parts.Object002_RodThread_0)
	root.set_meta("kind","spinning")
	root.set_meta("imported_model",true)
	# Locate the actual top mounting face of the stationary authored reel body.
	var body=parts.Object001_rod06_0 as MeshInstance3D
	var highest=-INF
	for surface in range(body.mesh.get_surface_count()):
		for vertex in body.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			highest=maxf(highest,root.get_parent().to_local(body.to_global(vertex)).y)
	var mount=Vector3.ZERO;var count_mount=0
	for surface in range(body.mesh.get_surface_count()):
		for vertex in body.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var point=root.get_parent().to_local(body.to_global(vertex))
			if point.y>highest-.003:mount+=root.to_local(body.to_global(vertex));count_mount+=1
	root.set_meta("mount_foot",mount/maxi(1,count_mount))
	# Anchor the pickup to an actual bail/rotor vertex near its forward rim.
	var rotor_mesh=parts.Rod02_rod06_0 as MeshInstance3D
	var points=PackedVector3Array();var bounds_rotor=AABB();var first_rotor=true
	for surface in range(rotor_mesh.mesh.get_surface_count()):
		for vertex in rotor_mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var point=rotor.to_local(rotor_mesh.to_global(vertex));points.append(point)
			bounds_rotor=AABB(point,Vector3.ZERO) if first_rotor else bounds_rotor.expand(point);first_rotor=false
	var desired=bounds_rotor.get_center()+Vector3(bounds_rotor.size.x*.35,bounds_rotor.size.y*.4,bounds_rotor.size.z*.25)
	var pickup=points[0]
	for point in points:
		if point.distance_squared_to(desired)<pickup.distance_squared_to(desired):pickup=point
	var roller=Marker3D.new();roller.name="LineRoller";rotor.add_child(roller);roller.position=pickup
	root.set_meta("line_roller",roller)
	var lip=Marker3D.new();lip.name="SpoolLip";parts.Object002_RodThread_0.add_child(lip)
	var spool_box=(parts.Object002_RodThread_0 as MeshInstance3D).get_aabb()
	lip.position=spool_box.get_center()+Vector3(0,spool_box.size.y*.45,0)
	root.set_meta("spool_lip",lip)
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
