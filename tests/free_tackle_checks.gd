extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://free-tackle-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
	for id in ["saragosa","ocea","fathom"]:
		game.feedback.equip(id,"offshore_rod" if id=="saragosa" else "grappler","powerpro")
		var assembly=game.feedback.equipment
		var reel=assembly.get_meta("reel") as Node3D
		assert(reel.get_meta("imported_model",false) and reel.get_meta("right_hand_retrieve",false))
		assert(reel.to_global(reel.get_meta("mount_foot")).distance_to(assembly.to_global(assembly.get_meta("reel_seat")))<.001,"New reel stays attached to authored rod")
		var crank=reel.get_meta("crank") as Node3D
		var rotor=reel.get_meta("rotor") as Node3D
		var crank_rest=crank.basis
		var rotor_rest=rotor.basis
		game.feedback.cast_age=2
		game.feedback.update_feedback(.1,true,true,.5,game.line_target())
		assert(not crank.basis.is_equal_approx(crank_rest) and not rotor.basis.is_equal_approx(rotor_rest),"Crank and spool/bail animate independently")
		assert(game.feedback.routed_line_points.size()==18,"Both reel types route line through the actual pickup or level wind")
		if id!="saragosa":
			var guide=reel.get_meta("level_wind") as Node3D
			assert(guide.position.distance_to(guide.get_meta("rest_position"))>.001,"Level wind traverses while winding")
			assert(reel.get_meta("spool").get_parent()==rotor,"Overhead spool is on the animated bearing")
		else:
			var body=reel.find_child("Body",true,false) as MeshInstance3D
			var before=body.global_transform
			crank.rotate_object_local(Vector3.RIGHT,.5);rotor.rotate_object_local(Vector3.FORWARD,.5)
			assert(body.global_transform.is_equal_approx(before),"Winding does not spin the stationary body")
			assert(body.get_active_material(0).albedo_texture.get_width()<=768,"New reel textures respect mobile limit")
	game.free()
	print("PASS: imported free reel variants, rod mounting, independent crank/spool/bail, level wind, line routing and mobile textures")
	quit()
