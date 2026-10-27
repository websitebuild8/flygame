extends Node3D
const Art = preload("res://scripts/world_art.gd")
const Tackle = preload("res://scripts/tackle_art.gd")
var preview_model: Node3D
var angle = 0.0
var manual_spin=0.0
var zoom=1.0

func _ready() -> void:
	position = Vector3(30,0,500)
	for x in [-2,2]:
		var light=OmniLight3D.new()
		add_child(light)
		light.position=Vector3(x,3,1)
		light.light_energy=1.1
		light.light_color=Color("f5dfb8")
		light.omni_range=8
	Art.block(self,Vector3(0,-0.1,0),Vector3(10,0.2,10),Color("d8ccb2"))
	Art.block(self,Vector3(0,2,-3.6),Vector3(10,4,0.2),Color("507c7b"))
	for x in [-4.5,4.5]:
		Art.block(self,Vector3(x,2,0),Vector3(0.2,4,8),Color("c9d5c6"))
		for y in [0.8,1.8,2.8]:
			Art.block(self,Vector3(x*0.8,y,-2.5),Vector3(1.5,0.1,1),Color("aa8862"))
	Art.block(self,Vector3(0,0.65,-0.5),Vector3(2.4,1.3,1.7),Color("254d58"))
	Art.block(self,Vector3(0,1.35,-0.5),Vector3(2.5,0.12,1.8),Color("c7c6af"))
	Art.label(self,"ISLAND TACKLE & MARINE",Vector3(0,3,-3.42),32)
	for i in range(4):
		var reel = Tackle.reel(self,"overhead" if i%2 else "spinning")
		reel.position = Vector3(-3.6,1.95,-2.5+i*0.22)
	for i in range(5):
		Art.pole(self,Vector3(3+i*0.18,0.3,-2.8),Vector3(2.7+i*0.18,2.9,-2.8),0.015,Color("314b59"))

func pose_camera(camera: Camera3D) -> void:
	camera.position = global_position+Vector3(0,2.05,2.7/zoom)
	camera.look_at(global_position+Vector3(0,1.7,-0.5))

func show_item(item: Dictionary) -> void:
	if preview_model:
		preview_model.queue_free()
	preview_model = Node3D.new()
	add_child(preview_model)
	preview_model.position = Vector3(0,1.95,-0.5)
	angle = -0.4
	if item.category=="Boats":
		var hull=preload("res://scripts/boat_models.gd").build(preview_model,item.id)
		hull.scale*=0.32/preload("res://scripts/world_data.gd").BOAT_SCALE
		hull.position.y=0
	elif item.category=="Reels":
		Tackle.reel(preview_model,item.kind,item.id).scale = Vector3.ONE*3.2
	elif item.category=="Rods" and item.id=="island_rod":
		preload("res://scripts/imported_tackle.gd").rod_preview(preview_model)
	elif item.category=="Rods":
		var rod = Tackle.rod(preview_model,item.kind,"ocea" if item.kind=="overhead" else "island_reel",item.id,false)
		rod.rotation.z = 0.5
		rod.rotation.x = -PI/2
		rod.scale = Vector3.ONE*0.6
	elif item.category=="Line":
		Tackle.cylinder(preview_model,Vector3.ZERO,0.22,0.16,Vector3.FORWARD,Color("75b6a1"),false)
		for z in [-0.1,0.1]:
			Tackle.cylinder(preview_model,Vector3(0,0,z),0.27,0.025,Vector3.FORWARD,Color("364a53"))
	elif item.id=="engine":
		preload("res://scripts/imported_marine.gd").motor(preview_model)
	elif item.id=="propeller":
		Tackle.cylinder(preview_model,Vector3.ZERO,0.13,0.25,Vector3.FORWARD,Color("a4b9bd"))
		for i in range(3):
			var a = float(i)*TAU/3
			var blade = Art.oval(preview_model,Vector3(cos(a)*0.25,sin(a)*0.25,0),Vector3(0.46,0.20,0.06),Color("b1bec2"))
			blade.rotation.z = a+0.4
	elif item.id=="icebox":
		Art.block(preview_model,Vector3.ZERO,Vector3(0.9,0.55,0.55),Color("dce9df"))
		Art.block(preview_model,Vector3(0,0.3,0),Vector3(0.95,0.07,0.6),Color("438f95"))
	else:
		Art.block(preview_model,Vector3(0,0.12,0),Vector3(0.45,0.55,0.5),Color("344d5c"))
		Art.pole(preview_model,Vector3(0,-0.15,0),Vector3(0,-0.6,0),0.09,Color("728b92"))

func _process(delta: float) -> void:
	manual_spin=maxf(0,manual_spin-delta)
	if manual_spin<=0: angle += delta*0.3
	if preview_model:
		preview_model.rotation.y = angle

func _input(event: InputEvent) -> void:
	if not get_parent().shop_mode or get_parent().interface.menu_visible:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and event.position.x<700 and event.position.y>140:
		angle+=event.relative.x*0.009
		manual_spin=2.5
	elif event is InputEventScreenDrag and event.position.x<700 and event.position.y>140:
		angle+=event.relative.x*0.009
		manual_spin=2.5
