extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://audio-helm-menu-check.json"
	root.add_child(game);game.set_physics_process(false)
	assert(game.equipped_boat=="skiff" and game.owned_boats==["skiff"],"Scout replaces removed starter")
	var world=preload("res://scripts/world_data.gd")
	assert(world.BOATS.size()==4)
	for vessel in world.BOATS:assert(vessel.id not in ["dinghy","runner"])
	var sound=game.feedback
	assert(sound.reel_variants.size()==3 and sound.splash_variants.size()==4)
	assert(sound.ambience.stream.loop and sound.ambience.stream.get_length()>11)
	game.interface.start_trip()
	sound.update_ambience(true);assert(sound.ambience.playing)
	sound.sound_enabled=false;sound.update_ambience(true);assert(not sound.ambience.playing)
	sound.sound_enabled=true;sound.update_ambience(false);assert(not sound.ambience.playing)
	sound.cast_feedback(Vector3.ZERO)
	assert(not sound.splash_players[0].playing,"Cast waits for the lure to hit the water before splashing")
	sound.splash(Vector3.ZERO)
	assert(sound.splash_players[0].playing,"Water impact triggers supplied splash audio")
	for id in ["skiff","launch","glacier","grady"]:
		game.equipped_boat=id;game.apply_boat()
		var controls=game.driving_controls
		controls.pov=false;controls.lever_value=.7;controls.wheel_display=.5
		controls._process(0)
		assert(controls.model_wheel.part and controls.model_throttle==null)
		assert(controls.model_wheel.visible)
		assert(controls.model_wheel.part.mesh==game.boat_visual.get_node("HelmWheel").mesh,"HUD wheel shares this hull's actual mesh")
		assert(is_equal_approx(controls.lever_value,.7),"Shared 2D throttle retains power input")
		assert(not controls.model_wheel.part.basis.is_equal_approx(Basis.IDENTITY))
		controls.pov=true;controls._process(0)
		assert(not controls.model_wheel.visible)
	assert(not sound.effects.bite.stream.loop and sound.effects.bite.stream is AudioStreamOggVorbis,"Hook cue uses a single reeling clip")
	game.interface.engine_button.set_running(true)
	assert(game.interface.engine_button.running and game.interface.engine_button.text=="")
	game.interface.engine_button.set_running(false)
	assert(not game.interface.engine_button.running)
	game.interface.toggle_menu()
	await process_frame;await process_frame
	var screen=Rect2(Vector2.ZERO,root.get_visible_rect().size)
	assert(screen.encloses(game.interface.menu.get_global_rect()),"Scrollable menu fits screen")
	for removed in ["dinghy","runner"]:
		var file=FileAccess.open(game.save_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"owned_boats":[removed,"launch"],"equipped_boat":removed}));file.close()
		game.load_trip()
		assert(game.equipped_boat=="skiff" and "launch" in game.owned_boats,"Old saves migrate without losing other boats")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free();await process_frame
	print("PASS: supplied ambience/reel/splash audio, mute, four 3D helms, menu fit and legacy boat migration")
	quit()
