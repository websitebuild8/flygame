extends SceneTree
const World=preload("res://scripts/world_data.gd")
const Collision=preload("res://scripts/marine_collision.gd")
func _initialize():call_deferred("checks")
func checks():
 var nav=preload("res://scripts/sea_navigation.gd").new();nav.configure(true)
 for port in World.Harbours.all_ports():
  assert(World.water(port.dock,true,World.NAV_CLEARANCE),"Every island has a water berth: "+port.name)
  assert(World.water(port.entrance,true,World.NAV_CLEARANCE),"Every harbour has a navigable mouth")
  assert(nav.set_destination(World.Harbour.HOME,port.dock,port.name),"Each island market is reachable")
  for wall in port.walls:assert(not World.water(wall[0].lerp(wall[1],.5),true,.1),"Each visible quay blocks boats")
 assert(Collision.sweeps_circle(Vector2(-4,-80),Vector2(4,-80),Vector2(0,-80),1),"Swept collision catches fast crossing motion")
 assert(not Collision.clear_water(Vector2(0,0),Vector2(0,5),true,World.BOAT_CLEARANCE),"Fast motion cannot pass through a harbour wall")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://sailing-expansion-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
 game.first_person_driving=true
 for id in ["skiff","launch","glacier","grady"]:
  game.equipped_boat=id;game.apply_boat();game.boat.rotation=Vector3.ZERO;game.drive.engine_running=false;game.driving_controls.neutral()
  for i in range(30):game._physics_process(1.0/30)
  var lever=game.boat_visual.get_node("ThrottleLever");var grip=game.helm_hands.lever_grip
  assert(grip.y>.02 and lever.get_aabb().grow(.02).has_point(grip),"Hand grip remains on the actual knob after scaling")
  var y=[]
  for value in [-1.0,0.0,1.0]:
   game.driving_controls.lever_value=value;game.update_outboards(.016);game.helm_hands.update_pose(.1,true,0)
   y.append(game.camera.unproject_position(lever.to_global(grip)).y)
   assert(game.helm_hands.hands.winding.global_position.distance_to(lever.to_global(grip))<.001,"Hand follows the real lever")
   var hands=game.helm_hands.hands
   var wrist=hands.skeleton.to_global(hands.skeleton.get_bone_global_pose(hands.chains[1].hand).origin)
   assert(wrist.distance_to(hands.wrists[1].global_position)<.008,"Skinned wrist reaches the throttle grip")
  assert(y[2]<y[1] and y[1]<y[0],"Forward/up, neutral, reverse/back must project in order on every boat")
 game.driving_controls.neutral();game.first_person_driving=false;game.camera_mode=0
 for expected in [1,2,3,0]:game.toggle_driving_camera();assert(game.camera_mode==expected and game.first_person_driving==(expected==1))
 assert(game.traffic.actors.size()==6,"Only six lightweight traffic boats are active")
 var incoming=false;var outgoing=false;var initial=game.traffic.actors[0].position
 game.boat.position=Vector3(0,0,-100)
 for step in range(2400):
  game.traffic.update(1.0/30,true)
  if World.Harbours.containing(game.traffic.actors[0].position)=="HA. Kelaa":incoming=true
  if World.Harbours.containing(game.traffic.actors[1].position)!="HA. Kelaa":outgoing=true
 assert(game.traffic.actors[0].position.distance_to(initial)>15 and incoming and outgoing,"Traffic travels into and out of the harbour")
 var target=game.traffic.actors[0];target.position=Vector2(0,-80);target.wait=100
 assert(game.traffic.motion_blocked(Vector2(0,-75),Vector2(0,-85),World.BOAT_CLEARANCE),"Player sweep detects another boat")
 game.boat.position=Vector3(0,0,-75);game.boat.rotation=Vector3.ZERO;game.drive.engine_running=true;game.drive.speed=12;game.speed=12;game.driving_controls.lever_value=1
 game._physics_process(.5)
 assert(is_equal_approx(game.boat.position.z,-75) and game.speed==0,"A collision stops the player before crossing the other boat")
 game.drive.reset();game.driving_controls.neutral();game.speed=0
 var expected_money=game.coins
 for port in World.Harbours.all_ports():
  game.boat.position=Vector3(port.dock.x,0,port.dock.y);game.inventory=[{"species":"Yellowfin tuna","weight":2.0,"value":120}];game.hold_value=120
  game.sell();assert(game.market_mode and game.market.island_name==port.name and game.market.theme_index==port.theme,"Each harbour opens its own market theme")
  game.serve_customer();await create_timer(.45).timeout;game.serve_customer();await create_timer(.85).timeout
  expected_money+=120;assert(game.coins==expected_money and game.pending_payment==0,"All island markets conserve exact MVR payments")
  game.leave_fishing()
 game.queue_free();await create_timer(.2).timeout
 print("PASS: all island harbours/markets, throttle direction and grip on four boats, four cameras, sparse inbound/outbound traffic, swept collisions and exact MVR sales")
 quit()
