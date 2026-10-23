extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("checks")
func check(condition: bool, text: String) -> void:
	if not condition:
		failures.append(text)
func run_for(drive: RefCounted, seconds: float, wheel: float = 0) -> void:
	for i in range(int(seconds*120)):
		drive.step(1.0/120,wheel,0)
func checks() -> void:
	var drive = preload("res://scripts/boat_drive.gd").new()
	drive.set_lever(0.1)
	run_for(drive,1)
	check(drive.gear==0 and drive.speed==0,"Neutral detent must not generate thrust")
	drive.set_lever(0.18)
	run_for(drive,8)
	var idle_speed = drive.speed
	check(idle_speed>0.7 and idle_speed<1.3,"Just in gear gives idle forward speed")
	drive.set_lever(1)
	drive.step(1.0/60,0,0)
	check(drive.speed<idle_speed+0.1,"Acceleration must not jump immediately to full speed")
	run_for(drive,10)
	var full = drive.speed
	check(full>11.5 and full<13,"Full forward reaches intended speed")
	drive.set_lever(0)
	drive.step(1.0/60,0,0)
	check(drive.gear==0 and drive.speed>full*0.95,"Neutral must disengage but preserve momentum")
	run_for(drive,2)
	check(drive.speed>0 and drive.speed<full*0.3,"Neutral should coast down smoothly")
	drive.set_lever(-1)
	drive.step(1.0/60,0,0)
	check(drive.gear==0 and drive.shift_waiting,"Reverse waits for forward momentum to slow")
	run_for(drive,10,1)
	check(drive.speed< -3 and drive.speed> -4,"Reverse is limited below full forward speed")
	check(drive.yaw_rate()>0,"Steering direction must change in reverse")
	drive.reset()
	drive.set_lever(1)
	run_for(drive,10,1)
	check(drive.yaw_rate()<0,"Clockwise wheel turns right in forward")
	drive.set_lever(-1)
	drive.step(1.0/60,0,0)
	check(drive.gear==0 and drive.speed>0,"Full forward to reverse cannot flip velocity")
	# Physics should remain approximately independent of render/physics rates.
	var slow = preload("res://scripts/boat_drive.gd").new()
	var fast = preload("res://scripts/boat_drive.gd").new()
	slow.set_lever(0.6)
	fast.set_lever(0.6)
	for i in range(30*5):
		slow.step(1.0/30,0.4,0)
	for i in range(120*5):
		fast.step(1.0/120,0.4,0)
	check(absf(slow.speed-fast.speed)<0.08,"Throttle physics must behave consistently at different frame rates")
	var helm = preload("res://scripts/helm_controls.gd").new()
	root.add_child(helm)
	helm.size = Vector2(496,224)
	await process_frame
	# Two touch pointers: releasing the wheel must not reset the throttle.
	var wheel = helm.wheel_center()
	helm.pointer(3,wheel+Vector2(65,0),true)
	helm.pointer(7,helm.rail_center()+Vector2(0,-74),true)
	helm.drag(3,wheel+Vector2(0,65))
	check(helm.wheel_command>0.5 and helm.lever_value==1,"Wheel and throttle can be held by different fingers")
	helm.pointer(3,wheel,false)
	check(helm.wheel_command==0 and helm.lever_value==1 and helm.lever_pointer==7,"Wheel release recentres without losing throttle")
	helm.pointer(7,helm.rail_center(),false)
	check(helm.lever_value==1,"Throttle persists after finger release")
	helm.update_lever(helm.rail_center()+Vector2(0,4))
	check(helm.lever_value==0,"Lever snaps at neutral")
	helm.pov=true
	for viewport_size in [Vector2(496,224),Vector2(1100,224),Vector2(760,300)]:
		helm.size=viewport_size
		helm.pov_lever=Vector2(-500,2000)
		var rail=helm.rail_center()
		check(Rect2(Vector2.ZERO,helm.size).encloses(Rect2(rail-Vector2(60,108),Vector2(120,216))),"POV throttle and complete drag range remain inside the control area")
		helm.pointer(8,rail-Vector2(0,74),true)
		check(helm.lever_value==1,"Fixed POV throttle reaches full forward")
		helm.drag(8,rail+Vector2(0,74))
		check(helm.lever_value==-1,"Fixed POV throttle reaches full reverse")
		helm.drag(8,rail)
		check(helm.lever_value==0,"Fixed POV throttle reaches neutral")
		helm.pointer(8,rail,false)
	var off_drive=preload("res://scripts/boat_drive.gd").new()
	off_drive.set_lever(1)
	off_drive.step(2,0,0)
	var moving_speed=off_drive.speed
	off_drive.engine_running=false
	off_drive.step(1,0,0)
	check(off_drive.gear==1 and off_drive.lever==1 and off_drive.rpm==0 and off_drive.speed<moving_speed,"Cutoff preserves gear and throttle but removes thrust and coasts down")
	helm.queue_free()
	var audio = preload("res://scripts/engine_audio.gd").new()
	root.add_child(audio)
	audio.update_audio(2,0.1,0,true,true)
	check(audio.players[0].playing and audio.players[0].volume_db>audio.players[2].volume_db,"Neutral engine idles without full-throttle layer")
	audio.update_audio(2,1.0,12,true,true)
	check(audio.players[2].volume_db>audio.players[0].volume_db,"Full throttle blends to the high-RPM layer")
	audio.update_audio(0.1,1,12,true,false)
	check(not audio.players[0].playing and not audio.players[2].playing,"Sound toggle stops engine playback")
	audio.update_audio(0.1,0,0,true,true,false)
	check(not audio.players[0].playing and not audio.players[2].playing,"Engine cutoff silences motor layers")
	audio.queue_free()
	await create_timer(0.3).timeout
	if failures.is_empty():
		print("PASS: neutral detent, idle gear, proportional throttle, inertia, reverse interlock, reverse steering, frame-rate consistency, dual-pointer ownership, engine audio blending/mute")
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)
