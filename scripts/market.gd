extends Node3D
const Art = preload("res://scripts/world_art.gd")
var customers: Array[Node3D] = []
var displayed_fish: Node3D
var payment: Node3D
var serve_motion = 0.0
var cash_motion=0.0
var seller_hands: Node3D
var register: Node3D
var register_total: Label3D
var queue_moving = false
var customer_number = 0
var handing_over = false
var island_name=""
var theme_index=0
var floor_node: MeshInstance3D
var back_wall: MeshInstance3D
var roof_node: MeshInstance3D
var counter_front: MeshInstance3D
var market_sign: Label3D
var theme_decor: Node3D
var shown_species = "Yellowfin tuna"

func _ready() -> void:
	position = Vector3(0,0,500)
	for x in [-2,2]:
		var light=OmniLight3D.new()
		add_child(light)
		light.position=Vector3(x,3,1)
		light.light_energy=1.1
		light.light_color=Color("f5dfb8")
		light.omni_range=8
	floor_node=Art.block(self,Vector3(0,-0.12,0),Vector3(12,0.2,14),Color("d7c8a4"))
	back_wall=Art.block(self,Vector3(0,2,-5),Vector3(12,4,0.2),Color("8ebbb2"))
	for x in [-5.5,5.5]:
		Art.block(self,Vector3(x,2,0),Vector3(0.2,4,12),Color("dfdfc9"))
		for z in [-3,1,4]:
			Art.pole(self,Vector3(x,0,z),Vector3(x,4.2,z),0.12,Color("936d48"))
	roof_node=Art.block(self,Vector3(0,4.3,0),Vector3(12,0.25,13),Color("4a807a"))
	for x in [-4,-2,0,2,4]:
		Art.block(self,Vector3(x,4,0),Vector3(0.12,0.22,12),Color("ac8353"))
	Art.block(self,Vector3(0,0.55,0),Vector3(6,1.1,1.3),Color("996846"))
	Art.block(self,Vector3(0,1.15,0),Vector3(6.2,0.15,1.5),Color("eee6d2"))
	counter_front=Art.block(self,Vector3(0,0.63,0.67),Vector3(4.8,0.7,0.04),Color("267a7b"))
	market_sign=Art.label(self,"ISHAQ'S FRESH CATCH",Vector3(0,2.95,-4.3),30)

	for x in [-2.2,2.2]:
		Art.block(self,Vector3(x,0.35,-2),Vector3(1.2,0.7,0.8),Color("ad8453"))
		Art.fish(self,0.4).position = Vector3(x,0.76,-2)
	for i in range(5):
		var person=preload("res://scripts/market_customer.gd").new();person.variation=i;add_child(person)
		person.position = queue_spot(i)
		customers.append(person)
	payment=preload("res://scripts/market_cash.gd").new()
	add_child(payment);payment.position=Vector3(.12,1.226,.12);payment.rotation.y=-.15
	payment.visible = false
	displayed_fish = Art.fish(self,0.50)
	displayed_fish.position = Vector3(0.0,1.36,0.1)
	displayed_fish.rotation.y = PI/2
	register=preload("res://assets/models/market/cash_register.glb").instantiate();add_child(register)
	register.name="CashRegister";register.set_meta("imported_model",true)
	var bounds=AABB();var first=true
	for mesh in register.find_children("*","MeshInstance3D",true,false):
		var box=(register.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	var factor=.65/maxf(bounds.size.x,.01)
	register.scale*=factor
	register.rotation.y=PI
	register.position=Vector3(-.92,1.225,0)-register.basis*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	register_total=Art.label(self,"MVR 0",Vector3(-.835,1.685,.23),22)
	register_total.pixel_size=.00105
	set_island("HA. Kelaa")

func queue_spot(index: int) -> Vector3:
	return Vector3(minf(index*0.8,2.8),0,-1.8-index*0.7)

func pose_camera(camera: Camera3D) -> void:
	camera.position = global_position + Vector3(0,1.85,1.35)
	camera.look_at(global_position+Vector3(0,1.4,-1.5))

func update_hands(camera: Camera3D,active: bool):
	if active and not seller_hands:
		seller_hands=preload("res://scripts/market_hands.gd").new();camera.add_child(seller_hands)
	if seller_hands:
		seller_hands.visible=active
		if active:seller_hands.update_pose(self)

func set_species(species: String) -> void:
	if species==shown_species or handing_over:
		return
	shown_species = species
	displayed_fish.queue_free()
	displayed_fish = Art.fish(self,0.50,species)
	displayed_fish.position = Vector3(0.0,1.36,0.1)
	displayed_fish.rotation.y = PI/2

func set_sale(has_fish: bool, payment_amount: int) -> void:
	var waiting_payment=payment_amount>0
	payment.set_amount(payment_amount)
	displayed_fish.visible = preload("res://scripts/world_data.gd").has_fish_model(shown_species) and (handing_over or (has_fish and not waiting_payment))
	payment.visible = waiting_payment

func hand_over() -> void:
	# Finish pending sales/queue transitions even when the off-screen room is suspended.
	handing_over = true
	var reach=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);reach.tween_property(self,"serve_motion",1.0,.18);reach.tween_property(self,"serve_motion",0.0,.25)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(displayed_fish,"position:z",-1.1,0.35)
	tween.tween_callback(func():
		displayed_fish.position.z = 0.1
		displayed_fish.visible = false
		handing_over = false
	)

func collect_cash() -> void:
	var reach=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);reach.tween_property(self,"cash_motion",1.0,.16);reach.tween_property(self,"cash_motion",0.0,.30)
	var cash = payment.duplicate() as Node3D
	add_child(cash)
	cash.visible = true
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(cash,"position",Vector3(0.4,1.4,2.0),0.4)
	tween.tween_callback(cash.queue_free)

func advance_queue() -> void:
	if queue_moving:
		return
	queue_moving = true
	for person in customers:person.set_walking(true)
	var first = customers.pop_front()
	first.rotation.y=PI/2
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(first,"position",Vector3(4,0,-1.5),0.7)
	for i in range(customers.size()):
		tween.tween_property(customers[i],"position",queue_spot(i),0.6)
	tween.chain().tween_callback(func():
		first.position = queue_spot(4)
		customers.append(first)
		for person in customers:person.rotation.y=0;person.set_walking(false)
		queue_moving = false
		customer_number += 1
	)

func animate(time: float) -> void:
	for i in range(customers.size()):
		customers[i].rotation.z = sin(time*1.5+i)*0.004

func set_island(title: String) -> void:
	if island_name==title:return
	island_name=title
	theme_index=["HA. Kelaa","HA. Filladhoo","HA. Vashafaru","HA. Dhidhdhoo","HA. Baarah"].find(title)
	theme_index=maxi(0,theme_index)
	var themes=[
		[Color("d7c8a4"),Color("8ebbb2"),Color("4a807a"),Color("267a7b")],
		[Color("dcc9a4"),Color("b9a882"),Color("ad9366"),Color("986c45")],
		[Color("cbdde2"),Color("e3ede9"),Color("46839f"),Color("417b9a")],
		[Color("bebdaf"),Color("c2cac4"),Color("6c7374"),Color("934e3f")],
		[Color("c5bd91"),Color("8caa7a"),Color("486e48"),Color("775a3e")]
	]
	var colors=themes[theme_index]
	for i in range(4):
		var node=[floor_node,back_wall,roof_node,counter_front][i]
		(node.material_override as StandardMaterial3D).albedo_color=colors[i]
	market_sign.text=title.replace("HA. ","").to_upper()+" FISH MARKET"
	if theme_decor:remove_child(theme_decor);theme_decor.queue_free()
	theme_decor=Node3D.new();theme_decor.name="IslandMarketStyle";add_child(theme_decor)
	if theme_index==1:
		# Woven shade and fishing-net backdrop in the quieter Filladhoo market.
		for x in range(-5,6):Art.block(theme_decor,Vector3(x,3.6,-3),Vector3(.40,.12,3.2),Color("b29a68"))
		var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for i in range(15):
			var x=-4.5+i*.5;mesh.surface_add_vertex(Vector3(x,.7,-4.7));mesh.surface_add_vertex(Vector3(x,2.6,-4.7))
		for i in range(5):mesh.surface_add_vertex(Vector3(-4.5,.7+i*.45,-4.7));mesh.surface_add_vertex(Vector3(2.5,.7+i*.45,-4.7))
		mesh.surface_end();var net=MeshInstance3D.new();net.mesh=mesh;net.material_override=Art.mat(Color("536f6c"));theme_decor.add_child(net)
	elif theme_index==2:
		for x in [-3.7,0,3.7]:
			Art.block(theme_decor,Vector3(x,2.15,-4.85),Vector3(2.7,1.1,.06),Color("4c9eae"))
			Art.block(theme_decor,Vector3(x,2.15,-4.78),Vector3(.08,1.15,.05),Color("e6e6d4"))
			Art.block(theme_decor,Vector3(x,2.15,-4.76),Vector3(2.75,.08,.05),Color("e6e6d4"))
	elif theme_index==3:
		for i in range(3):
			var x=-3.8+i*3.8
			Art.block(theme_decor,Vector3(x,2.20,-4.8),Vector3(2.5,.7,.1),Color("29474d"))
			Art.label(theme_decor,"AUCTION · LOT %02d"%(i+1),Vector3(x,2.20,-4.73),24).pixel_size=.009
		for x in [-5.4,5.4]:Art.pole(theme_decor,Vector3(x,.1,-4.4),Vector3(x,3.8,-4.4),.05,Color("697b7b"))
		for x in [-3,3]:Art.block(theme_decor,Vector3(x,3.8,-1),Vector3(2.2,.09,.3),Color("eef0db"))
	elif theme_index==4:
		for i in range(16):Art.block(theme_decor,Vector3(-5.2+i*.7,1.9,-4.8),Vector3(.14,3.7,.12),Color("657c48") if i%2 else Color("897b55"))
		for side in [-1,1]:Art.pole(theme_decor,Vector3(side*5,.2,-4.5),Vector3(0,4,-4.5),.07,Color("7b654b"))
	for i in range(2+theme_index):
		var x=-4.7+(i%2)*.8;var z=-2.5-floori(i/2)*.7
		Art.block(theme_decor,Vector3(x,.3,z),Vector3(.65,.5,.6),colors[3].darkened(.12))
	for i in range(customers.size()):
		for mesh in customers[i].model.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var shader=mesh.get_surface_override_material(surface) as ShaderMaterial
				if shader:shader.set_shader_parameter("shirt_color",[Color("237d85"),Color("bb7051"),Color("547a65"),Color("8b6899"),Color("c79548")][(i+theme_index)%5])
