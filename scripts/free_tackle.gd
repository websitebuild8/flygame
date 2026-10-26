extends RefCounted
## Free CC BY 4.0 models; full creator credits in free-tackle-source.json.
const SPINNING=preload("res://assets/models/tackle/sobrom_reel.glb")
const OVERHEAD=preload("res://assets/models/tackle/overhead_reel.glb")
static func build(parent: Node3D,kind: String,model: String) -> Node3D:
	return overhead(parent,model) if kind=="overhead" else spinning(parent)
static func spinning(parent: Node3D) -> Node3D:
	var root=SPINNING.instantiate() as Node3D;parent.add_child(root)
	var crank=root.find_child("Crank",true,false) as Node3D
	var rotor=root.find_child("Rotor",true,false) as MeshInstance3D
	var spool=root.find_child("Spool",true,false) as MeshInstance3D
	# Empty bearing nodes keep animation independent of the stationary body.
	var bearing=Node3D.new();bearing.name="BailBearing";root.add_child(bearing)
	bearing.position=rotor.position;rotor.reparent(bearing,true)
	crank.set_meta("spin_axis",Vector3.RIGHT)
	crank.set_meta("grip_point",Vector3(.178589,0,-.152555))
	bearing.set_meta("spin_axis",Vector3.FORWARD)
	var lip=Marker3D.new();spool.add_child(lip);lip.position=Vector3(0,.058,-.045)
	var roller=Marker3D.new();bearing.add_child(roller);roller.position=Vector3(.097,.0009,-.167)
	root.set_meta("crank",crank);root.set_meta("rotor",bearing);root.set_meta("spool",spool)
	root.set_meta("spool_lip",lip);root.set_meta("line_roller",roller)
	root.set_meta("mount_foot",Vector3(0,.254164,.015319))
	root.set_meta("kind","spinning");root.set_meta("right_hand_retrieve",true);root.set_meta("imported_model",true)
	return root
static func overhead(parent: Node3D,model: String) -> Node3D:
	var root=Node3D.new();root.name="ImportedOverheadReel";parent.add_child(root)
	var space=Node3D.new();root.add_child(space)
	space.basis=Basis(Vector3.UP,PI).scaled(Vector3.ONE*.56)
	space.position=-(space.basis*Vector3(-.021087,-.206056,-.107257))
	var source=OVERHEAD.instantiate();space.add_child(source)
	for player in source.find_children("*","AnimationPlayer",true,false):player.stop();player.active=false
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material=StandardMaterial3D.new()
			material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
			material.metallic=.4;material.roughness=.48
			if "frame" in str(mesh.name):material.albedo_color=Color("344759") if model=="ocea" else Color("303238")
			elif "guard" in str(mesh.name):material.albedo_color=Color("b8a26a")
			else:material.albedo_color=Color("bec9cd")
			mesh.set_surface_override_material(surface,material)
	var rotor=Node3D.new();rotor.name="SpoolBearing";root.add_child(rotor)
	var spool=source.find_child("spool",true,false) as Node3D
	spool.reparent(rotor,true)
	# Wound line fills the downloaded spool; only the spool rotates, not the housing.
	var line=MeshInstance3D.new();rotor.add_child(line)
	var cylinder=CylinderMesh.new();cylinder.height=.255;cylinder.top_radius=.062;cylinder.bottom_radius=.062;cylinder.radial_segments=32
	line.mesh=cylinder;line.rotation.z=PI/2
	var braid=StandardMaterial3D.new();braid.albedo_color=Color("6aabb0");braid.roughness=.8;line.material_override=braid
	var guide=Node3D.new();guide.name="MovingLineGuide";root.add_child(guide)
	var authored_guide=source.find_child("line_guide",true,false) as Node3D
	guide.position=root.to_local(authored_guide.global_position)
	authored_guide.reparent(guide,true)
	source.find_child("pawl",true,false).reparent(guide,true)
	guide.set_meta("rest_position",guide.position)
	var roller=Marker3D.new();guide.add_child(roller);roller.position=Vector3(0,.04,0)
	var lip=Marker3D.new();root.add_child(lip);lip.position=Vector3(0,.055,-.035)
	# Reuse the already licensed authored crank and grip rather than a primitive handle.
	var donor=preload("res://scripts/imported_tackle.gd").reel(root)
	var crank=donor.get_meta("crank") as Node3D
	crank.reparent(root,true);crank.position=Vector3(.16,0,0)
	donor.free()
	root.set_meta("crank",crank);root.set_meta("rotor",rotor);root.set_meta("spool",spool)
	root.set_meta("level_wind",guide);root.set_meta("spool_lip",lip);root.set_meta("line_roller",roller)
	root.scale=Vector3.ONE*.55
	root.set_meta("mount_foot",Vector3(0,-.163,0));root.set_meta("kind","overhead")
	root.set_meta("right_hand_retrieve",true);root.set_meta("imported_model",true)
	return root
