extends RefCounted
const Art=preload("res://scripts/world_art.gd")
const Tackle=preload("res://scripts/tackle_art.gd")

static func build(root: Node3D,id: String) -> Node3D:
	if id in ["skiff","launch","glacier","grady"]:
		return preload("res://scripts/imported_boats.gd").build(root,id)
	var visual=Node3D.new()
	visual.name="Visual"
	root.add_child(visual)
	Art.dinghy(visual)
	var colors={"dinghy":Color("259d99"),"skiff":Color("315bca"),"runner":Color("d35540"),"launch":Color("e6bd55")}
	for child in visual.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			(child.material_override as StandardMaterial3D).albedo_color=colors[id]
	var wheel=visual.get_node("HelmWheel")
	for child in wheel.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			wheel.remove_child(child)
			child.queue_free()
		elif child is MeshInstance3D and child.mesh is TorusMesh:
			(child.material_override as StandardMaterial3D).albedo_color=Color("8e6447") if id=="launch" else (Color("e0e8e5") if id=="skiff" else colors[id])
	wheel.scale=Vector3.ONE*1.65
	wheel.set_meta("rest_basis",wheel.basis)
	var spokes=6 if id=="launch" else (5 if id=="skiff" else 3)
	for i in range(spokes):
		var a=float(i)*TAU/spokes
		Art.pole(wheel,Vector3.ZERO,Vector3(cos(a)*0.15,sin(a)*0.15,0),0.012,colors[id])
	var size=1.0 if id=="dinghy" else (1.12 if id=="skiff" else (1.3 if id=="runner" else 1.5))
	visual.scale=Vector3(size,1.0,size*1.05)
	if id!="dinghy":
		for side in [-1,1]:
			Art.block(visual,Vector3(side*1.03,0.2,0.3),Vector3(0.08,0.15,3.5),colors[id])
		var wind=Art.block(visual,Vector3(0.45,1.25,0.35),Vector3(0.75,0.5,0.05),Color("82bac5"))
		var glass=wind.material_override as StandardMaterial3D
		glass.albedo_color.a=0.55
		glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	if id in ["runner","launch"]:
		for side in [-1,1]:
			Art.pole(visual,Vector3(side*0.8,0.3,0.4),Vector3(side*0.8,2.1,0.4),0.04,Color("c2d2cf"))
		Art.block(visual,Vector3(0,2.15,0.3),Vector3(2,0.12,2.6),colors[id])
	if id=="launch":
		var motor=visual.get_node("OutboardPivot")
		motor.position.x=-0.5
		var other=motor.duplicate()
		other.name="OutboardPivot2"
		visual.add_child(other)
		other.position.x=0.5
		Art.block(visual,Vector3(-0.5,0.55,1.1),Vector3(0.65,0.6,0.4),Color("d8e6df"))
		Art.block(visual,Vector3(0.5,0.55,1.1),Vector3(0.65,0.6,0.4),Color("d8e6df"))
	var lever=Node3D.new()
	lever.name="ThrottleLever"
	visual.add_child(lever)
	lever.position=Vector3(0.92,0.93,0.7)
	Art.block(visual,Vector3(0.92,0.75,0.7),Vector3(0.16,0.3,0.3),Color("284c58"))
	Art.pole(lever,Vector3.ZERO,Vector3(0,0.24,0),0.025,Color("bccbc5"))
	Art.oval(lever,Vector3(0,0.25,0),Vector3(0.12,0.08,0.11),colors[id])
	if id=="launch":
		var other_lever=lever.duplicate()
		other_lever.name="ThrottleLever2"
		visual.add_child(other_lever)
		other_lever.position.x-=0.15
	for side in [-1,1]:
		var lamp=Art.oval(visual,Vector3(side,0.6,-0.7),Vector3.ONE*0.1,Color("db7164") if side<0 else Color("6ee5a3"))
		var mat=lamp.material_override as StandardMaterial3D
		mat.emission_enabled=true
		mat.emission=mat.albedo_color
	return visual
