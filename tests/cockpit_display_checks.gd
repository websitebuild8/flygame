extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://cockpit-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false);game.first_person_driving=true
	var power=preload("res://scripts/marine_power.gd")
	assert(power.color_for(0).g>power.color_for(0).r)
	for level in [.2,.5,1.0]:assert(power.color_for(level).is_equal_approx(power.color_for(-level)),"Power colours are symmetric in reverse")
	assert(power.color_for(1).r>power.color_for(1).g)
	for id in ["skiff","launch","glacier","grady"]:
		game.equipped_boat=id;game.apply_boat();game.drive.reset();game._physics_process(.016)
		assert(game.cockpit_displays.displays.size()==(1 if id=="skiff" else 2))
		assert(game.cockpit_displays.contents[0].game==game and not game.cockpit_displays.contents[0].chart)
		if id!="skiff":
			assert(game.cockpit_displays.contents[1].chart and not game.interface.mini_map.visible,"Second physical screen carries navigation and hides duplicate minimap")
		var controls=game.driving_controls
		assert(controls.pov and controls.cockpit_screen)
		controls.pointer(7,controls.pov_lever,true)
		assert(controls.lever_pointer==7,"Physical POV throttle owns its touch pointer")
		controls.drag(7,controls.pov_lever-Vector2(0,100))
		assert(controls.lever_value>.5,"Dragging physical throttle forward increases power")
		controls.pointer(7,controls.pov_lever,false)
		controls.neutral()
	game.feedback.cast_age=2;game.feedback.winding_speed=10
	var crank=game.feedback.crank
	var before=crank.basis
	var axis=crank.get_meta("spin_axis")
	game.feedback.update_feedback(.01,true,true,.4,game.line_target())
	assert(crank.basis.is_equal_approx(before*Basis(axis,-.1)),"Spinning retrieve reverses the crank and linked hand direction")
	game.first_person_driving=false;game._physics_process(.016)
	assert(not game.driving_controls.pov and game.interface.mini_map.visible,"External view retains its normal controls and map")
	game.queue_free();await process_frame
	print("PASS: fitted engine/navigation displays, neutral/forward/reverse colours, physical POV throttle, overlay switching and corrected retrieve direction")
	quit()
