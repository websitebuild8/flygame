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
		return preload("res://scripts/deep_blue_tackle.gd").reel(parent)
	return preload("res://scripts/free_tackle.gd").build(parent,kind,model)

static func rod(parent: Node3D, kind: String, reel_id: String, rod_id: String, braided: bool) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var segments: Array[MeshInstance3D] = []
	var rod_color={"island_rod":Color("237b99"),"grappler":Color("613c8f"),"offshore_rod":Color("b9523c")}.get(rod_id,Color("2b7665"))
	var blank=preload("res://scripts/deep_blue_tackle.gd").rod(root) if rod_id=="island_rod" and kind=="spinning" else preload("res://scripts/imported_tackle.gd").live_blank(root,rod_id)
	for surface in range(blank.mesh.get_surface_count()):
		(blank.get_surface_override_material(surface) as ShaderMaterial).set_shader_parameter("overhead",kind=="overhead")
	root.set_meta("authored_blank",blank)
	var equipment = reel(root,kind,reel_id)
	var rod_axis=Vector3(0,.47,-.882666).normalized()
	var seat=Vector3(0,-.04,.38)+rod_axis*.35
	var foot=equipment.get_meta("mount_foot",Vector3(0,-.16,0) if kind=="overhead" else Vector3(0,.19,.05)) as Vector3
	equipment.basis=Basis(Vector3.RIGHT,atan2(rod_axis.y,-rod_axis.z))*equipment.basis
	equipment.position=seat-equipment.basis*foot
	equipment.set_meta("mount_foot",foot)
	root.set_meta("reel_seat",seat)
	if not root.get_meta("deep_blue",false):
		for offset in [-.045,.045]:ring(root,seat+rod_axis*offset,.023,.003,Color("aebfc4"),rod_axis)
	root.set_meta("segments",segments)
	root.set_meta("reel",equipment)
	root.set_meta("braided",braided)
	return root
