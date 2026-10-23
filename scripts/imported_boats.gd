extends RefCounted
## BoatUS Foundation CC BY 4.0 hulls with independent cockpit and engine parts.
const MODELS={"skiff":preload("res://assets/models/boats/scout.glb"),"launch":preload("res://assets/models/boats/whaler.glb"),"grady":preload("res://assets/models/boats/grady.glb"),"glacier":preload("res://assets/models/boats/glacier.glb")}
const Art=preload("res://scripts/world_art.gd")
static func build(parent: Node3D,id: String) -> Node3D:
	var root=Node3D.new()
	root.name="Visual"
	parent.add_child(root)
	var model=MODELS[id].instantiate()
	root.add_child(model)
	for part_name in ["HelmWheel","ThrottleLever","OutboardPivot","OutboardPivot2"]:
		var part=model.find_child(part_name,true,false) as Node3D
		if part:
			part.reparent(root,true)
			part.set_meta("rest_basis",part.basis)
			if part_name=="ThrottleLever" and id in ["skiff","glacier","grady"]:
				part.set_meta("travel_direction",-1.0)
			if part_name.begins_with("Outboard"):
				part.set_meta("imported_model",true)
				var prop=part.find_child("Propeller*",false,false) as Node3D
				assert(prop,"Imported outboards need their own propeller")
				prop.name="Propeller"
	assert(root.has_node("HelmWheel") and root.has_node("ThrottleLever"))
	var wheel=root.get_node("HelmWheel") as Node3D
	# A modestly larger physical rim makes touch winding legible on a phone.
	wheel.scale*=1.2
	wheel.set_meta("rest_basis",wheel.basis)
	var pov=Marker3D.new()
	pov.name="DrivingView"
	root.add_child(pov)
	pov.position=wheel.position+Vector3(0,.32,.65)
	var fishing=Marker3D.new()
	fishing.name="FishingView"
	root.add_child(fishing)
	fishing.position={"launch":Vector3(0,1.5,-3.25),"skiff":Vector3(0,1.25,-2.45),"glacier":Vector3(0,1.5,-2.9),"grady":Vector3(0,1.5,-3.2)}[id]
	var box=Node3D.new()
	box.name="Icebox"
	root.add_child(box)
	box.position={"launch":Vector3(-.65,.25,1.25),"skiff":Vector3(-.5,.23,1.5),"glacier":Vector3(-.7,.5,1.2),"grady":Vector3(-.8,.55,1.6)}[id]
	Art.block(box,Vector3.ZERO,Vector3(.5,.4,.6),Color("d9e6e1"))
	Art.block(box,Vector3(0,.22,0),Vector3(.53,.06,.63),Color("315b75") if id=="skiff" else Color("b79a5c"))
	root.set_meta("imported_model",true)
	root.set_meta("model_id",{"skiff":"scout","launch":"whaler","glacier":"glacier","grady":"grady"}[id])
	return root
