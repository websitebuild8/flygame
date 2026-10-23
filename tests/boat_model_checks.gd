extends SceneTree
const Boats=preload("res://scripts/boat_models.gd")
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
	for vessel in World.BOATS:
		var listing=preload("res://scripts/gear_catalog.gd").item(vessel.id)
		assert(listing.name==vessel.name and listing.price==vessel.price and listing.unlock==vessel.unlock,"Boat shop labels and progression match the playable vessels")
	var holder=Node3D.new();root.add_child(holder)
	for id in ["skiff","launch","glacier","grady"]:
		var boat=Boats.build(holder,id)
		assert(boat.get_meta("imported_model",false),"Real boat upgrade uses its imported hull")
		assert(boat.has_node("DrivingView") and boat.has_node("FishingView"),"Each hull has its own cockpit and fishing cameras")
		var count=0
		for mesh in boat.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays=mesh.mesh.surface_get_arrays(surface)
				count+=arrays[Mesh.ARRAY_INDEX].size()/3
				var mat=mesh.get_active_material(surface) as StandardMaterial3D
				if mat:
					assert(mat.resource_name!="Scout_Trailer","Road trailer is excluded from the floating boat")
					if mat.albedo_texture:assert(mat.albedo_texture.get_width()<=1024,"Boat colour maps remain mobile sized")
		assert(count>50000 and count<120000,"Imported hull stays within the measured mobile mesh budget")
		var hull=boat.find_child("Hull",true,false) as Node3D
		var hull_rest=hull.transform
		var wheel=boat.get_node("HelmWheel") as MeshInstance3D
		assert(wheel.mesh.get_aabb().size.length()<.8,"Animated wheel excludes the larger dashboard panels")
		wheel.basis=wheel.get_meta("rest_basis")*Basis(Vector3.BACK,1.5)
		assert(hull.transform.is_equal_approx(hull_rest),"Wheel rotation leaves the cabin and instruments fixed")
		var motor=boat.get_node("OutboardPivot") as Node3D
		if id=="skiff":
			var lever=boat.get_node("ThrottleLever") as MeshInstance3D
			assert(lever.position.is_equal_approx(Vector3(.1206,.681,.4005)),"Scout lever pivots at the original starboard control bearing")
			assert(lever.mesh.get_aabb().size.x<.09,"Scout moving lever excludes the radio and fixed housing")
			var grip=Vector3(0,.15,0)
			var forward=Basis(Vector3.RIGHT,-.8)*grip
			assert(forward.z<grip.z,"Forward throttle pushes the Scout grip toward the bow")
		assert(motor.get_node("Propeller") is MeshInstance3D,"Original propeller is independently animated")
		if id in ["launch","glacier","grady"]:assert(boat.has_node("OutboardPivot2/Propeller"),"Both original twin props remain connected")
		boat.free()
	holder.free()
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://boat-model-checks.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip()
	game._physics_process(.016)
	assert(game.boat_visual.get_node("HelmWheel").scale.is_equal_approx(Vector3.ONE*1.65),"Starter helm retains its enlarged rim after steering updates")
	for id in ["skiff","launch","glacier","grady"]:
		game.equipped_boat=id;game.apply_boat();game.return_home();game.first_person_driving=true;game._physics_process(.016)
		var wheel=game.boat_visual.get_node("HelmWheel") as Node3D
		var screen=game.camera.unproject_position(wheel.global_position)
		assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).has_point(screen),"Physical POV wheel remains visible and reachable")
		assert(game.camera.global_position.distance_to(wheel.global_position)<1,"Cockpit controls stay within reach")
		var motor=game.boat_visual.get_node("OutboardPivot")
		var prop=motor.get_node("Propeller")
		game.drive.engine_running=true;game.drive.gear=1;game.drive.rpm=.7;game.drive.steering=.6
		var before=prop.rotation.z;game.update_outboards(.1)
		assert(absf(motor.rotation.y)>.01 and not is_equal_approx(prop.rotation.z,before),"New motors steer and props turn while in gear")
		game.drive.engine_running=false;before=prop.rotation.z;game.update_outboards(.1)
		assert(is_equal_approx(prop.rotation.z,before),"Engine cutoff stops the imported propellers")
	assert(World.vessel("skiff").name=="Scout 17 Centre Console" and World.vessel("launch").name=="Boston Whaler 285 Conquest","Existing save identifiers select the named real models")
	game.shop_mode=true;game.coins=20000;game.catches=21
	assert(not game.purchase_item("glacier"),"New catamaran requires its catch milestone")
	game.catches=30
	for id in ["glacier","grady"]:
		assert(game.purchase_item(id) and game.equipped_boat==id,"New boats can be bought with game currency and equipped")
		assert(game.icebox_capacity()==int(World.vessel(id).storage),"Each new hull has its listed fish capacity")
	game.save_trip();game.load_trip()
	assert(game.equipped_boat=="grady" and "glacier" in game.owned_boats,"New boat purchases survive reload")
	game.queue_free();await create_timer(.3).timeout
	print("PASS: imported hulls, trailer removal, mesh/texture budgets, fixed instruments, distinct POV mounts, steering, twin props, cutoff and save identifiers")
	quit()
