extends SceneTree
const World=preload("res://scripts/world_data.gd")
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("checks")
func check(condition: bool,text: String) -> void:
	if not condition: failures.append(text)
func checks() -> void:
	var nav=preload("res://scripts/sea_navigation.gd").new()
	nav.configure(false)
	check(not nav.set_destination(Vector2(0,12),Vector2(125,-45),"Locked east"),"Locked eastern region cannot be routed into")
	check(not nav.set_destination(Vector2(0,12),Vector2(-25,30),"Land"),"Waypoints cannot be set on land")
	check(nav.set_destination(Vector2(-80,-60),Vector2(0,120),"Around home"),"A navigable route around an island exists")
	check(nav.route.size()>2,"Route around island must bend rather than cross land")
	for i in range(nav.route.size()-1):
		check(nav.clear_line(nav.route[i],nav.route[i+1]),"Every smoothed map route segment clears land")
	nav.configure(true)
	for spot in World.SPOTS:
		check(nav.set_destination(Vector2(0,12),spot.at,spot.name),"Every fishing spot is reachable after unlocking: "+spot.name)
	check(World.SPOTS.size()==7 and World.FISH.size()==15,"Expanded spot/fish catalogues are present")
	var fight=preload("res://scripts/fish_fight.gd").new()
	fight.start(Vector3.ZERO,Vector3.FORWARD,1.1)
	var original=fight.position
	var saw_run=false
	var saw_jump=false
	var saw_splash=false
	for i in range(210):
		fight.step(1.0/60,true,1,1,1,1)
		saw_run=saw_run or fight.running
		saw_jump=saw_jump or fight.position.y>0
		saw_splash=saw_splash or fight.splash_event
	check(fight.position.distance_to(original)>1 and saw_run and saw_jump and saw_splash,"Hooked fish swims, runs, jumps and triggers water crossings")
	var tension=fight.tension
	fight.step(0.2,false,1,1,1,1)
	check(fight.tension<tension,"Releasing the reel eases a moving fish's tension")
	fight.progress=0.98
	fight.step(0.1,true,1,1,1,1)
	check(fight.position.y>0.9 and fight.position.distance_to(fight.origin)>4,"Fish lifts clear of water outside the bow during landing")
	check(fight.landing_age<1.6,"Landing pose remains visible before the catch screen")
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://ocean-checks.json"
	root.add_child(game)
	game.set_physics_process(false)
	game.interface.start_trip()
	game.coins=10000
	game.catches=0
	game.return_home()
	game.open_shop("Boats")
	check(not game.purchase_item("skiff"),"Boat purchase requires catch milestone as well as coins")
	game.catches=3
	check(game.purchase_item("skiff") and game.equipped_boat=="skiff","Unlocked speedboat can be bought and equipped")
	check(game.driving_controls.skin=="skiff" and game.icebox_capacity()==14,"Boat changes helm design and capacity")
	game.leave_fishing()
	game.driving_controls.wheel_command=0.7
	game._physics_process(0.15)
	check(absf(game.boat_visual.get_node("OutboardPivot").rotation.y)>0.01,"Outboard swivels with steering input")
	game.return_home()
	game.toggle_driving_camera()
	game._physics_process(0.1)
	check(game.driving_controls.pov,"First-person helm uses projected wheel and throttle controls")
	game.catches=20
	game.open_shop("Boats")
	check(game.purchase_item("launch"),"Top boat can be purchased after its milestone")
	check(game.boat_visual.has_node("OutboardPivot2") and game.driving_controls.skin=="launch","Launch has twin motors and unique helm")
	game.leave_fishing()
	game.driving_controls.wheel_command=-0.6
	game._physics_process(0.15)
	check(is_equal_approx(game.boat_visual.get_node("OutboardPivot").rotation.y,game.boat_visual.get_node("OutboardPivot2").rotation.y),"Twin motors steer together")
	game.day_cycle.hours=12
	game.day_cycle.apply_lighting()
	var daylight=game.day_cycle.sun.light_energy
	game.day_cycle.hours=22
	game.day_cycle.apply_lighting()
	check(game.day_cycle.sun.light_energy<daylight and game.day_cycle.moon.visible,"Day/night changes lighting and shows the moon")
	game.day_cycle.weather=2
	game.day_cycle.advance(20)
	game.day_cycle.update_rain(Vector3.ZERO,true)
	check(game.day_cycle.rain.emitting and game.day_cycle.cover>0.8,"Rain weather produces rain and overcast lighting")
	game.day_cycle.weather=3
	game.day_cycle.advance(20)
	check(game.day_cycle.roughness>0.9,"Rough weather increases sea state")
	game.day_cycle.update_rain(Vector3.ZERO,false)
	check(not game.day_cycle.rain.emitting,"Rain is hidden indoors")
	game.day_cycle.hours=23.9
	game.day_cycle.advance(10)
	check(game.day_cycle.hours<1,"Game clock rolls over midnight")
	game.save_trip()
	game.equipped_boat="dinghy"
	game.owned_boats=["dinghy"]
	game.load_trip()
	check(game.equipped_boat=="launch" and "skiff" in game.owned_boats and game.day_cycle.hours<1,"Boats and time persist through saves")
	game.return_home()
	game.boat.position=World.SPOTS[1].at.x*Vector3.RIGHT+World.SPOTS[1].at.y*Vector3.BACK
	game.first_person_driving=false
	game.cast()
	check(game.fishing and game.active_spot.id=="reef","Fishing works at additional spots")
	game.fish_timer=3
	game.reeling=true
	game._physics_process(0.1)
	check(game.fish_actor.visible and game.line_target().is_equal_approx(game.fight.position+Vector3.UP*0.5*game.fight.landing_lift),"Line endpoint follows the actual hooked fish")
	check(game.feedback.bend_amount>0,"Rod bends under fish load")
	game.fight.progress=0.94
	game.fight.step(.1,false,1,1,1,1)
	game._physics_process(.1)
	game.interface.refresh()
	check(game.progress<1 and game.can_put_fish_on_boat() and game.interface.put_fish_button.visible,"Manual landing is offered before the bar is full")
	var before_catch=game.catches
	game.put_fish_on_boat()
	game.put_fish_on_boat()
	check(game.landing_to_boat,"Putting aboard starts a guarded landing animation")
	await create_timer(.9).timeout
	check(game.catches==before_catch+1,"Manual landing stores exactly one catch on repeated presses")
	game.close_catch()
	game.return_home()
	game.drive.gear=1
	game.drive.engine_running=false
	game.driving_controls.lever_value=1
	game.interface.refresh()
	check(not game.market_button.disabled and not game.interface.workshop_button.disabled,"Engine cutoff enables stopped harbour actions with gear engaged")
	game.open_shop("Boat")
	check(game.shop_mode,"Cutoff allows entering harbour shops with gear engaged")
	game.leave_fishing()
	game.boat.position=game.SPOT
	game.drive.gear=1
	game.driving_controls.lever_value=1
	game.cast()
	check(game.fishing and not game.drive.engine_running,"Stopped boat can fish with engine off and forward selected")
	game.leave_fishing()
	game.driving_controls.lever_value=1
	game.toggle_engine()
	check(not game.drive.engine_running,"Restart requires neutral")
	game.driving_controls.neutral()
	game.toggle_engine()
	check(game.drive.engine_running,"Engine restarts in neutral")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await create_timer(0.3).timeout
	if failures.is_empty():
		print("PASS: map routes/obstacles/locks, expanded spots, swimming/runs/jumps/splashes, boat unlock/purchase/designs, POV helm, swivelling/twin motors, day/night/midnight, persistence, line and rod feedback")
		quit(0)
	else:
		for message in failures: push_error(message)
		quit(1)
