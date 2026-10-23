extends RefCounted
## Original procedural models; no third-party art dependencies.

static func mat(color: Color, roughness: float = 0.65) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat(color)
	parent.add_child(node)
	node.position = pos
	return node

static func block(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return mesh_node(parent, mesh, pos, color)

static func oval(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 12
	var node = mesh_node(parent, mesh, pos, color)
	node.scale = size
	return node

static func pole(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius * 0.8
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 10
	var node = mesh_node(parent, mesh, (start + end) * 0.5, color)
	var direction = (end - start).normalized()
	node.quaternion = Quaternion(Vector3.UP, direction)
	return node

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 60) -> Label3D:
	var node = Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.008
	node.outline_size = 6
	parent.add_child(node)
	node.position = pos
	return node

static func fish(parent: Node3D, size: float = 1.0, species: String = "Yellowfin tuna") -> Node3D:
	var script_path="res://scripts/trevally_fish.gd" if species=="Giant trevally" else "res://scripts/textured_fish.gd"
	if species in ["Skipjack tuna","Sailfish","Mahi-mahi"]:
		script_path="res://scripts/scanned_fish.gd"
	var root = load(script_path).new() as Node3D
	parent.add_child(root)
	root.setup(species)
	root.scale = Vector3.ONE*size
	return root

static func palm(parent: Node3D, base: Vector3, height: float, angle: float) -> void:
	var top = base + Vector3(0.5, height, 0.2)
	pole(parent, base, top, 0.18, Color("94714a"))
	for j in range(8):
		var a=angle+float(j)*TAU/8
		var direction=Vector3(cos(a),0,sin(a))
		var across=Vector3(-sin(a),0,cos(a))
		var vertices=PackedVector3Array()
		var indices=PackedInt32Array()
		for k in range(11):
			var t=float(k)/10
			var center=top+direction*t*3.2+Vector3(0,sin(t*PI)*0.45-t*t*0.9,0)
			var width=sin(t*PI)*0.42
			vertices.append(center-across*width)
			vertices.append(center+across*width)
		for k in range(10):
			var n=k*2
			indices.append_array(PackedInt32Array([n,n+1,n+2,n+1,n+3,n+2]))
		var arrays=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_INDEX]=indices
		var raw=ArrayMesh.new()
		raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var tool=SurfaceTool.new()
		tool.create_from(raw,0)
		tool.generate_normals()
		var leaf=mesh_node(parent,tool.commit(),Vector3.ZERO,Color("4a8f55") if j%2==0 else Color("3c7e4d"))
		(leaf.material_override as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
		pole(parent,top,top+direction*3.1+Vector3(0,-0.8,0),0.018,Color("699459"))
	for j in range(3):
		oval(parent, top + Vector3(float(j)*0.2, -0.3, 0), Vector3.ONE*0.3, Color("73613c"))

static func island(parent: Node3D, center: Vector3, radius: float) -> void:
	# Layered tapered shore avoids the original vertical-sided cylinder.
	for j in range(3):
		var mesh = CylinderMesh.new()
		mesh.top_radius = radius - j * 2.4
		mesh.bottom_radius = radius + 3.0 - j * 2.4
		mesh.height = 0.65
		mesh.radial_segments = 48
		mesh_node(parent, mesh, center + Vector3(0, j*0.42-0.5, 0), Color("f2dfac") if j < 2 else Color("87a96d"))
	for i in range(12):
		var angle = float(i)*2.399
		var distance = radius * (0.3 + float(i % 4)*0.14)
		var point = center + Vector3(cos(angle)*distance, 0.7, sin(angle)*distance)
		palm(parent, point, 4.5 + float(i % 3), angle)
	for i in range(3):
		var p = center + Vector3(-5 + i * 5, 1.5, -1)
		block(parent, p, Vector3(3.5, 2.5, 3), Color("f2e8d2"))
		var roof = block(parent, p + Vector3(0, 1.6, 0), Vector3(4.2, 0.4, 3.9), Color("3a807e"))
		roof.rotation.z = 0.12
		block(parent, p + Vector3(0, 0, 1.52), Vector3(0.8, 1.8, 0.05), Color("377f83"))
		for side in [-1, 1]:
			block(parent, p + Vector3(side*1.1, 0.3, 1.54), Vector3(0.55, 0.7, 0.06), Color("7cbac3"))
	for i in range(9):
		var a = float(i)*TAU/9
		oval(parent, center+Vector3(cos(a)*(radius-0.4), 0, sin(a)*(radius-0.4)), Vector3(1.8, 0.9, 1.2), Color("b3b5a1"))

static func dinghy(root: Node3D) -> void:
	# Shaped pointed bow with a broad transom and open cockpit.
	var vertices = PackedVector3Array([
		Vector3(-1.05,0.1,2.5), Vector3(1.05,0.1,2.5), Vector3(1.1,0.1,-1.1), Vector3(0,0.1,-3), Vector3(-1.1,0.1,-1.1),
		Vector3(-0.78,-0.48,2.35), Vector3(0.78,-0.48,2.35), Vector3(0.72,-0.48,-1), Vector3(0,-0.3,-2.5), Vector3(-0.72,-0.48,-1)])
	var indices = PackedInt32Array()
	for i in range(5):
		var n = (i+1)%5
		indices.append_array(PackedInt32Array([i,n,5+i,n,5+n,5+i]))
	indices.append_array(PackedInt32Array([5,6,7,5,7,8,5,8,9]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface=SurfaceTool.new()
	surface.create_from(mesh,0)
	surface.generate_normals()
	var hull = mesh_node(root, surface.commit(), Vector3.ZERO, Color("e5efdf"))
	(hull.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	block(root, Vector3(0,0.08,0.4), Vector3(1.85,0.18,3.8), Color("c7b48c"))
	for i in range(5):
		var n = (i+1)%5
		pole(root, vertices[i]+Vector3(0,0.25,0), vertices[n]+Vector3(0,0.25,0),0.12,Color("4b9e9f"))
	for z in [-0.9,1.2]:
		block(root, Vector3(0,0.42,z),Vector3(1.9,0.16,0.5),Color("a77b4b"))
		block(root, Vector3(0,0.53,z),Vector3(1.5,0.12,0.4),Color("f2e9d2"))
	var motor=preload("res://scripts/imported_marine.gd").motor(root)
	motor.position=Vector3(0,0,2.6)
	var icebox = Node3D.new()
	icebox.name = "Icebox"
	root.add_child(icebox)
	icebox.position = Vector3(-0.5,0.4,0.2)
	block(icebox,Vector3.ZERO,Vector3(0.65,0.6,0.8),Color("d4e8e5"))
	block(icebox,Vector3(0,0.33,0),Vector3(0.7,0.08,0.85),Color("3c979b"))
	for x in [-0.96,0.96]:
		oval(root,Vector3(x,0.15,1.1),Vector3(0.28,0.5,0.28),Color("f4f1e5"))
	# Small side console ties the touch helm to the physical boat.
	block(root,Vector3(0.45,0.55,0.45),Vector3(0.72,0.8,0.65),Color("d9e5d9"))
	block(root,Vector3(0.45,0.97,0.4),Vector3(0.66,0.08,0.6),Color("345b65"))
	var wheel = Node3D.new()
	wheel.name = "HelmWheel"
	root.add_child(wheel)
	wheel.position = Vector3(0.45,1.04,0.68)
	var ring = TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.18
	ring.rings = 24
	ring.ring_segments = 8
	mesh_node(wheel,ring,Vector3.ZERO,Color("657e83")).rotation.x = PI/2
	for i in range(3):
		var a = float(i)*TAU/3
		pole(wheel,Vector3.ZERO,Vector3(cos(a)*0.15,sin(a)*0.15,0),0.012,Color("bac9c4"))
	oval(wheel,Vector3.ZERO,Vector3(0.07,0.07,0.04),Color("24414d"))
	label(root,"ISHAQ",Vector3(0,0.6,2.6),28)

static func customer(parent: Node3D, index: int) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var shirts = [Color("36a6a4"), Color("dd9b57"), Color("657caf"), Color("e4d4b6"), Color("ae6f73")]
	var skin = Color("a8734e") if index % 2 == 0 else Color("bf8b64")
	oval(root,Vector3(0,1.14,0),Vector3(0.6,0.85,0.36),shirts[index%5])
	oval(root,Vector3(0,1.78,0),Vector3(0.38,0.44,0.36),skin)
	oval(root,Vector3(0,1.94,0.02),Vector3(0.4,0.18,0.37),Color("28373c"))
	for x in [-0.17,0.17]:
		pole(root,Vector3(x,0.8,0),Vector3(x,0.18,0),0.105,Color("324b5a"))
		oval(root,Vector3(x,0.1,0.09),Vector3(0.2,0.16,0.4),Color("293b41"))
		pole(root,Vector3(x*2,1.4,0),Vector3(x*2.3,0.95,0.12),0.09,skin)
		oval(root,Vector3(x*0.6,1.81,0.17),Vector3(0.045,0.05,0.025),Color("253741"))
	return root
