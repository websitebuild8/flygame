extends Node3D
const Art = preload("res://scripts/world_art.gd")
var customers: Array[Node3D] = []
var displayed_fish: Node3D
var payment: MeshInstance3D
var serve_motion = 0.0
var queue_moving = false
var customer_number = 0
var handing_over = false
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
	Art.block(self,Vector3(0,-0.12,0),Vector3(12,0.2,14),Color("d7c8a4"))
	Art.block(self,Vector3(0,2,-5),Vector3(12,4,0.2),Color("8ebbb2"))
	for x in [-5.5,5.5]:
		Art.block(self,Vector3(x,2,0),Vector3(0.2,4,12),Color("dfdfc9"))
		for z in [-3,1,4]:
			Art.pole(self,Vector3(x,0,z),Vector3(x,4.2,z),0.12,Color("936d48"))
	Art.block(self,Vector3(0,4.3,0),Vector3(12,0.25,13),Color("4a807a"))
	for x in [-4,-2,0,2,4]:
		Art.block(self,Vector3(x,4,0),Vector3(0.12,0.22,12),Color("ac8353"))
	Art.block(self,Vector3(0,0.55,0),Vector3(6,1.1,1.3),Color("996846"))
	Art.block(self,Vector3(0,1.15,0),Vector3(6.2,0.15,1.5),Color("eee6d2"))
	Art.block(self,Vector3(0,0.63,0.67),Vector3(4.8,0.7,0.04),Color("267a7b"))
	Art.label(self,"ISHAQ'S FRESH CATCH",Vector3(0,2.95,-4.8),30)

	for x in [-2.2,2.2]:
		Art.block(self,Vector3(x,0.35,-2),Vector3(1.2,0.7,0.8),Color("ad8453"))
		Art.fish(self,0.4).position = Vector3(x,0.76,-2)
	for i in range(5):
		var person = Art.customer(self,i)
		person.position = queue_spot(i)
		customers.append(person)
	payment = Art.block(self,Vector3(0.8,1.28,0.05),Vector3(0.35,0.025,0.18),Color("82bc7c"))
	payment.visible = false
	displayed_fish = Art.fish(self,0.65)
	displayed_fish.position = Vector3(-0.5,1.43,0.1)
	displayed_fish.rotation.y = PI/2
	# Seller's forearms are visible at the counter from the first-person camera.
	for side in [-1,1]:
		Art.pole(self,Vector3(side*0.65,1,1.5),Vector3(side*0.55,1.3,0.65),0.085,Color("d6dfca"))
		Art.oval(self,Vector3(side*0.55,1.3,0.58),Vector3(0.16,0.12,0.25),Color("ac7c58"))

func queue_spot(index: int) -> Vector3:
	return Vector3(minf(index*0.8,2.8),0,-1.8-index*0.7)

func pose_camera(camera: Camera3D) -> void:
	camera.position = global_position + Vector3(0,2.1,2.7)
	camera.look_at(global_position+Vector3(0,1.4,-1.5))

func set_species(species: String) -> void:
	if species==shown_species or handing_over:
		return
	shown_species = species
	displayed_fish.queue_free()
	displayed_fish = Art.fish(self,0.65,species)
	displayed_fish.position = Vector3(-0.5,1.43,0.1)
	displayed_fish.rotation.y = PI/2

func set_sale(has_fish: bool, waiting_payment: bool) -> void:
	displayed_fish.visible = handing_over or (has_fish and not waiting_payment)
	payment.visible = waiting_payment

func hand_over() -> void:
	handing_over = true
	var tween = create_tween()
	tween.tween_property(displayed_fish,"position:z",-1.1,0.35)
	tween.tween_callback(func():
		displayed_fish.position.z = 0.1
		displayed_fish.visible = false
		handing_over = false
	)

func collect_cash() -> void:
	var cash = payment.duplicate() as MeshInstance3D
	add_child(cash)
	cash.visible = true
	var tween = create_tween()
	tween.tween_property(cash,"position",Vector3(0.4,1.4,2.0),0.4)
	tween.tween_callback(cash.queue_free)

func advance_queue() -> void:
	if queue_moving:
		return
	queue_moving = true
	var first = customers.pop_front()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(first,"position",Vector3(4,0,-1.5),0.7)
	for i in range(customers.size()):
		tween.tween_property(customers[i],"position",queue_spot(i),0.6)
	tween.chain().tween_callback(func():
		first.position = queue_spot(4)
		customers.append(first)
		queue_moving = false
		customer_number += 1
	)

func animate(time: float) -> void:
	for i in range(customers.size()):
		customers[i].rotation.z = sin(time*1.5+i)*0.012
