extends SceneTree
const Profile=preload("res://scripts/catch_profile.gd")
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
	var rng=RandomNumberGenerator.new();rng.seed=731
	for definition in World.FISH:
		var weights={};var prices={};var light={};var heavy={}
		for i in range(200):
			var fish=Profile.roll(definition,rng)
			assert(fish.weight>=definition.min and fish.weight<=definition.max,"Individual stays within its species weight range")
			assert(fish.value>0,"Market offers stay positive")
			weights[fish.weight]=true;prices[fish.value]=true
			if light.is_empty() or fish.weight<light.weight:light=fish
			if heavy.is_empty() or fish.weight>heavy.weight:heavy=fish
		assert(weights.size()>20 and prices.size()>15,"Repeated species have varied weights and prices")
		assert(heavy.value>light.value and heavy.size>light.size and heavy.strength>light.strength,"Heavier individuals affect value, visible size and fight strength")
	var fight=preload("res://scripts/fish_fight.gd").new()
	fight.start(Vector3.ZERO,Vector3.FORWARD,1);fight.hooked=false
	fight.step(.5,true,1,1,1,1)
	assert(fight.progress==0,"The timing phase precedes fighting")
	fight.strike(.95);var strike_progress=fight.progress;fight.strike(1)
	assert(fight.hooked and fight.progress==strike_progress,"A good strike rewards timing exactly once")
	assert(not fight.request_power(),"Power reel needs charge")
	fight.power_charge=1;assert(fight.request_power(),"Charged reel starts a burst")
	assert(not fight.request_power(),"Repeated burst input cannot spend the same charge twice")
	var before=fight.progress;fight.step(.1,true,1,1,1,1)
	assert(fight.progress-before>.02,"Power reel actually increases retrieval")
	for i in range(440):fight.step(1.0/60,false,1,1,1,1)
	assert(fight.escaped,"Excessive slack lets the fish escape")
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://fishing-gameplay-check.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip()
	game.boat.position=game.SPOT;game.cast()
	var individual=game.active_catch.duplicate()
	game.fish_timer=3;game.reeling=true;game._physics_process(.016)
	assert(game.fight.hooked and game.feedback.strike_kick>0,"Hook input drives the rod strike and timing feedback")
	assert(game.feedback.hands.visible,"Fishing has a grip hand and a crank-following hand")
	assert(game.feedback.hands.get_meta("imported_model",false),"Fishing hands use the authored textured glove/sleeve model")
	assert(game.feedback.equipment.has_meta("authored_blank"),"Gameplay uses the imported full rod mesh")
	var authored=game.feedback.equipment.get_meta("authored_blank") as MeshInstance3D
	assert(authored.get_meta("imported_model",false) and authored.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].size()>0,"Authored rod retains its UV/textured geometry")
	assert((authored.get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("bend")>0,"Live imported rod geometry receives the fish-load bend")
	var reel=game.feedback.equipment.get_meta("reel") as Node3D
	var seat=game.feedback.equipment.to_global(game.feedback.equipment.get_meta("reel_seat"))
	assert(reel.to_global(reel.get_meta("mount_foot")).distance_to(seat)<.001,"Reel mounting foot stays seated on the rod")
	assert(reel.get_meta("right_hand_retrieve",false),"Starter reel is configured for right-hand winding")
	var bearing=game.feedback.rig.to_local(game.feedback.crank.global_position)
	assert(bearing.x>0,"Physical crank bearing sits on the right of the rod")
	for i in range(4):await process_frame
	var hands=game.feedback.hands
	# Elbow direction belongs to the player's camera/body frame, not the yawing rod.
	var view=game.feedback.rig.get_parent()
	var left_elbow=view.to_local(hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(hands.chains[0].lower).origin))
	var left_wrist=view.to_local(hands.wrists[0].global_position)
	assert(left_elbow.x<left_wrist.x-.04,"Left elbow bends outward from the player's body")
	var right_elbow=view.to_local(hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(hands.chains[1].lower).origin))
	var right_wrist=view.to_local(hands.wrists[1].global_position)
	assert(right_elbow.x>right_wrist.x+.10,"Right elbow bends outward to the right")
	var hand_space=game.feedback.rig.global_basis.inverse()*hands.skeleton.global_basis
	var palm_frame=(hand_space*hands.skeleton.get_bone_global_pose(hands.chains[0].hand).basis).orthonormalized()
	assert(palm_frame.x.dot(Vector3.UP)>.8,"Palm faces upward to support the rod")
	var finger_start=hands.skeleton.find_bone("index_L.L_12")
	var finger_end=hands.skeleton.find_bone("index_L.002.L_10")
	var start_direction=(hand_space*hands.skeleton.get_bone_global_pose(finger_start).basis.y).normalized()
	var end_direction=(hand_space*hands.skeleton.get_bone_global_pose(finger_end).basis.y).normalized()
	assert(start_direction.x>.8 and end_direction.x<-.8,"Fingers pass under the rod on the right and return left around it")
	var thumb=hands.skeleton.find_bone("thumb_L.002.L_7")
	var thumb_direction=(hand_space*hands.skeleton.get_bone_global_pose(thumb).basis.y).normalized()
	assert(thumb_direction.x>.8,"Thumb closes in the opposing left-to-right direction")
	for i in range(2):
		var bone=hands.skeleton.find_bone("hand_L.L_25" if i==0 else "hand_L.R_51")
		var actual=hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(bone).origin)
		assert(actual.distance_to(hands.wrists[i].global_position)<.08,"Authored wrist reaches the rod/handle target rather than following an invisible marker alone")
	var at=game.feedback.rig.to_local(game.feedback.crank.to_global(game.feedback.crank.get_meta("grip_point")))
	assert(game.feedback.hands.winding.position.distance_to(at)<.05,"Winding hand tracks the actual animated handle")
	var original_rig=game.feedback.rig.transform
	var shoulder_before=hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(hands.chains[0].upper).origin)
	game.feedback.rig.rotate_x(.12)
	hands.pose(at,true,false)
	var shoulder_after=hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(hands.chains[0].upper).origin)
	assert(shoulder_before.distance_to(shoulder_after)<.001,"Rod pumping moves the hands without dragging the player's shoulders")
	game.feedback.rig.transform=original_rig;hands.pose(at,true,false)
	game.fight.power_charge=1
	var drag=InputEventScreenDrag.new();drag.index=4;drag.relative=Vector2(0,-90)
	game.interface.swipe_pointer=3;game.interface.reel_gesture(drag)
	assert(game.fight.power_time==0,"A second finger cannot trigger the reel gesture")
	drag.index=3;game.interface.reel_gesture(drag)
	assert(game.fight.power_time>0,"Upward swipe on the owned reel pointer triggers power")
	game.land_fish()
	assert(game.inventory[-1].weight==individual.weight and game.inventory[-1].value==individual.value,"Landing preserves the hooked individual's weight and price")
	game.save_trip();game.load_trip()
	assert(is_equal_approx(game.inventory[-1].weight,individual.weight) and game.inventory[-1].value==individual.value,"Individual catch details survive save and reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path));game.queue_free();await create_timer(.3).timeout
	print("PASS: individual weights/values/sizes, timed strike, power charge and swipe ownership, slack escape, crank-linked hands and saved catch details")
	quit()
