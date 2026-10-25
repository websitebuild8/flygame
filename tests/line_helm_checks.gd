extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://line-helm-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
	game.boat.position=game.SPOT;game.first_person_driving=true
	for id in ["dinghy","runner","skiff","launch","grady","glacier"]:
		game.equipped_boat=id;game.apply_boat();game.drive.reset()
		game.driving_controls.wheel_command=.4;game.driving_controls.lever_value=.6
		for i in range(30):game._physics_process(1.0/60)
		var helm=game.helm_hands
		assert(helm.visible and helm.rim_radius>.03,"POV shows authored hands on every boat's controls")
		assert(helm.hands.grip.global_position.distance_to(helm.wheel_contact)<.001,"Wheel hand remains on the moving rim")
		assert(helm.hands.winding.global_position.distance_to(helm.lever.to_global(helm.lever_grip))<.001,"Throttle hand follows the boat's physical lever")
		for side in range(2):
			var wrist=helm.hands.skeleton.to_global(helm.hands.skeleton.get_bone_global_pose(helm.hands.chains[side].hand).origin)
			assert(wrist.distance_to(helm.hands.wrists[side].global_position)<.02,"Authored wrists reach the control grips")
		var before=helm.lever_contact
		game.driving_controls.lever_value=-.6
		for i in range(15):game._physics_process(1.0/60)
		assert(before.distance_to(helm.lever_contact)>.025,"Hand travels with forward/neutral/reverse lever motion")
	game.first_person_driving=false;game._physics_process(.016)
	assert(not game.helm_hands.visible,"Driving hands hide outside POV")
	game.boat.position=game.SPOT;game.driving_controls.neutral();game.drive.reset();game.cast();game.fish_timer=3;game.reeling=true;game._physics_process(.016)
	assert(not game.helm_hands.visible,"Driving hands hide during fishing")
	var feedback=game.feedback;var curve=preload("res://scripts/rod_curve.gd")
	for bend in [0.0,.45,.95]:
		feedback.bend_amount=bend;feedback.cast_age=2
		feedback.update_feedback(0,true,true,.5,game.line_target())
		var points=feedback.routed_line_points
		assert(points.size()==18,"Continuous line includes spool, roller, four guides and outgoing line")
		for i in range(4):
			var expected=feedback.equipment.to_global(curve.point(curve.guides()[i],bend))
			assert(points[i+2].distance_to(expected)<.0001,"Line follows each authored hole under rod bending")
		assert(points[-1].distance_to(game.line_target())<.001,"Line reaches the lure/fish after the final tip guide")
	var roller=feedback.equipment.get_meta("reel").get_meta("line_roller")
	var before=roller.global_position
	feedback.rotor.rotate_object_local(feedback.rotor.get_meta("spin_axis",Vector3.BACK),.6)
	assert(roller.global_position.distance_to(before)>.005,"Line pickup travels with the rotating bail")
	feedback.equip("ocea","grappler","powerpro");feedback.bend_amount=.6
	feedback.update_feedback(0,true,true,.5,game.line_target())
	assert(feedback.routed_line_points.size()==17,"Overhead reel feeds directly to the guides without a spinning bail")
	for i in range(4):
		var expected=feedback.equipment.to_global(curve.point(curve.guides(true)[i],.6))
		assert(feedback.routed_line_points[i+1].distance_to(expected)<.0001,"Overhead line follows the upper-side guide holes")
	print("PASS: all six POV helm grips, lever motion, camera visibility, spool/roller routing, all four bent guides and final fish endpoint")
	game.free();quit()
