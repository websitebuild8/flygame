extends RefCounted
const Art = preload("res://scripts/world_art.gd")

static func cylinder(parent: Node3D, at: Vector3, radius: float, depth: float, axis: Vector3, color: Color, metal: bool = true) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 32
	var node = Art.mesh_node(parent,mesh,at,color)
	node.quaternion = Quaternion(Vector3.UP,axis.normalized())
	var mat = node.material_override as StandardMaterial3D
	mat.metallic = 0.75 if metal else 0.0
	mat.roughness = 0.23 if metal else 0.65
	return node

static func ring(parent: Node3D, at: Vector3, radius: float, tube: float, color: Color, axis: Vector3 = Vector3.UP) -> MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius-tube
	mesh.outer_radius = radius+tube
	mesh.rings = 32
	mesh.ring_segments = 8
	var node = Art.mesh_node(parent,mesh,at,color)
	node.quaternion = Quaternion(Vector3.UP,axis.normalized())
	(node.material_override as StandardMaterial3D).metallic = 0.8
	return node

static func reel(parent: Node3D, kind: String, model: String = "island_reel") -> Node3D:
	if kind=="spinning" and model=="island_reel":
		return preload("res://scripts/imported_tackle.gd").reel(parent)
	var root = Node3D.new()
	parent.add_child(root)
	var silver = Color("b3c5c7")
	var dark = {"island_reel":Color("1e7090"),"saragosa":Color("6d8294"),"pursuit":Color("342d43"),"ocea":Color("8babbc"),"fathom":Color("25282d")}.get(model,Color("24445c"))
	var gold = Color("d0ac49") if model!="ocea" else Color("568cb9")
	var line_color = Color("7ab7a2")
	var rotor = Node3D.new()
	root.add_child(rotor)
	var spool: Node3D
	if kind=="overhead":
		for side in [-1,1]:
			cylinder(root,Vector3(side*0.13,0,0),0.12,0.035,Vector3.RIGHT,dark)
			ring(root,Vector3(side*0.15,0,0),0.105,0.008,silver,Vector3.RIGHT)
			for i in range(5):
				var a = float(i)*TAU/5
				cylinder(root,Vector3(side*0.152,sin(a)*0.085,cos(a)*0.085),0.006,0.006,Vector3.RIGHT,silver)
		spool = cylinder(rotor,Vector3.ZERO,0.082,0.22,Vector3.RIGHT,line_color,false)
		for side in [-1,1]:
			cylinder(rotor,Vector3(side*0.1,0,0),0.094,0.012,Vector3.RIGHT,gold)
		for i in range(4):
			var a = float(i)*TAU/4+0.3
			Art.pole(root,Vector3(-0.12,sin(a)*0.1,cos(a)*0.1),Vector3(0.12,sin(a)*0.1,cos(a)*0.1),0.009,silver)
		# Conventional reel sits on top of the blank with a clamp below.
		Art.block(root,Vector3(0,-0.14,0),Vector3(0.17,0.04,0.17),dark)
		if model=="ocea":
			for i in range(5):
				var a = float(i)*TAU/5
				Art.pole(root,Vector3(0.17,0,0),Vector3(0.17,sin(a)*0.07,cos(a)*0.07),0.009,silver)
		else:
			var drag_lever = Art.pole(root,Vector3(0.17,0,0),Vector3(0.17,0.1,-0.07),0.012,gold)
			drag_lever.name = "DragLever"
	else:
		Art.oval(root,Vector3(0,-0.02,0.07),Vector3(0.16,0.16,0.25),dark)
		Art.pole(root,Vector3(0,0.04,0.05),Vector3(0,0.19,0.05),0.028,silver)
		Art.block(root,Vector3(0,0.19,0.05),Vector3(0.1,0.03,0.22),dark)
		spool = cylinder(root,Vector3(0,0,-0.10),0.085,0.10,Vector3.FORWARD,line_color,false)
		for z in [-0.16,-0.04]:
			cylinder(root,Vector3(0,0,z),0.102,0.018,Vector3.FORWARD,silver)
			ring(root,Vector3(0,0,z),0.099,0.007,gold,Vector3.FORWARD)
		cylinder(root,Vector3(0,0,-0.18),0.048,0.025,Vector3.FORWARD,dark)
		# Wire bail is an arc, with separate arms connected to the rotor.
		var previous = Vector3(0.13,0,-0.02)
		for i in range(1,25):
			var a = float(i)*PI/24
			var point = Vector3(cos(a)*0.13,sin(a)*0.13,-0.11-sin(a)*0.07)
			Art.pole(rotor,previous,point,0.004,silver)
			previous = point
		for side in [-1,1]:
			Art.pole(rotor,Vector3(side*0.12,0,-0.02),Vector3(side*0.08,0,0.07),0.012,dark)
	var crank = Node3D.new()
	root.add_child(crank)
	crank.position = Vector3(0.18,0,0.04) if kind=="overhead" else Vector3(-0.12,-0.02,0.05)
	var side = 1 if kind=="overhead" else -1
	Art.pole(crank,Vector3.ZERO,Vector3(side*0.03,-0.13,0),0.012,silver)
	Art.pole(crank,Vector3(side*0.03,-0.13,0),Vector3(side*0.10,-0.13,0),0.014,gold)
	Art.oval(crank,Vector3(side*0.11,-0.13,0),Vector3(0.07,0.075,0.12),dark)
	for i in range(8):
		if kind=="overhead":
			ring(rotor,Vector3(-0.085+i*0.024,0,0),0.083,0.0015,line_color.lightened(0.15),Vector3.RIGHT)
		else:
			ring(root,Vector3(0,0,-0.145+i*0.012),0.086,0.0015,line_color.lightened(0.15),Vector3.FORWARD)
	root.set_meta("crank",crank)
	root.set_meta("rotor",rotor)
	root.set_meta("spool",spool)
	root.set_meta("kind",kind)
	return root

static func rod(parent: Node3D, kind: String, reel_id: String, rod_id: String, braided: bool) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var segments: Array[MeshInstance3D] = []
	var rod_color={"island_rod":Color("237b99"),"grappler":Color("613c8f"),"offshore_rod":Color("b9523c")}.get(rod_id,Color("2b7665"))
	Art.pole(root,Vector3(0,-0.04,0.38),Vector3(0,0.10,-0.05),0.035,Color("233640"))
	for i in range(4):
		ring(root,Vector3(0,0.03-i*0.025,0.12+i*0.06),0.034,0.003,Color("b39c60"),Vector3(0,0.14,-0.43).normalized())
	for i in range(9):
		var start = Vector3(0,0.1+i*0.13,-i*0.22)
		var end = start+Vector3(0,0.13,-0.22)
		var segment = Art.pole(root,start,end,0.014-i*0.0011,rod_color)
		segments.append(segment)
		var wrap=ring(segment,Vector3(0,0.06,0),0.015-i*0.0011,0.002,Color("d9ad54"))
		wrap.name="ThreadWrap"
		var guide = ring(segment,Vector3(0,0.1,0.018),0.022-i*0.0015,0.0025,Color("aebdbe"))
		guide.name = "Guide"
	var equipment = reel(root,kind,reel_id)
	equipment.position = Vector3(0,0.19,-0.04) if kind=="overhead" else Vector3(0,-0.14,-0.03)
	root.set_meta("segments",segments)
	root.set_meta("reel",equipment)
	root.set_meta("braided",braided)
	return root
