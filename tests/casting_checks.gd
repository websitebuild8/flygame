extends SceneTree
const Motion=preload("res://scripts/lure_cast.gd")
func _initialize():call_deferred("checks")
func checks():
 var tip=Vector3(0,2,-2)
 var end=Vector3(0,-.52,-18)
 for fps in [30,60,120]:
  var motion=Motion.new();motion.step(0,tip,0)
  assert(motion.state=="ready" and motion.position.y>0,"Ready lure hangs clear of water")
  assert(is_equal_approx(motion.position.distance_to(tip),Motion.LEADER_LENGTH),"Leader hangs from the tip, not out into the sea")
  motion.begin(end)
  var impacts=0;var highest=-100.0
  for i in range(fps*3):
   motion.step(1.0/fps,tip,float(i)/fps)
   if motion.splash_event:
    impacts+=1
    assert(motion.position.distance_to(end)<.0001,"The ballistic flight ends exactly at the water target")
   if motion.state=="flight":highest=maxf(highest,motion.position.y)
   if i<fps*.5:assert(not motion.splash_event,"No splash before release/flight")
  assert(impacts==1 and motion.state=="soak","Each cast produces exactly one impact")
  assert(highest>tip.y,"The lure arcs upwards before descending")
 for fps in [30,60,120]:
  var drop=Motion.new();drop.step(0,tip,0);var start=drop.position;drop.begin(end,true)
  var impacts=0
  for i in range(fps*2):
   drop.step(1.0/fps,tip,float(i)/fps)
   assert(drop.state!="windup" and drop.state!="flight" and drop.rod_pitch()==0,"Overhead gear drops without a casting swing")
   assert(Vector2(drop.position.x,drop.position.z).distance_to(Vector2(start.x,start.z))<.0001,"Drop stays directly below the suspended jig")
   assert(drop.position.y<=start.y+.0001,"Drop never launches upward")
   if drop.splash_event:impacts+=1
  assert(impacts==1 and drop.state=="soak","A vertical drop splashes exactly once at all frame rates")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://casting-check.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip();game.boat.position=game.SPOT
 game.fishing_action()
 assert(game.fishing_view and not game.fishing,"Start fishing enters a ready view without casting")
 for i in range(30):game._physics_process(1.0/60)
 var feedback=game.feedback
 assert(feedback.lure.visible and feedback.lure.get_meta("imported_model"),"Real free lure is visible before casting")
 assert(feedback.lure.global_position.y>-.5,"The ready lure stays above the water")
 assert(feedback.routed_line_points[-1].distance_to(feedback.lure.global_position)<.001,"The line ends on the lure eye")
 var rest_pitch=game.camera.rotation.x
 game.fishing_action()
 assert(game.fishing and feedback.cast_motion.state=="windup")
 assert(feedback.splash_age>1,"Casting starts dry, with no premature impact")
 for i in range(20):game._physics_process(1.0/60)
 assert(game.camera.rotation.x>rest_pitch+.08,"Camera lifts with the backswing")
 for i in range(100):
  game._physics_process(1.0/60)
  assert(game.feedback.lure.scale.is_equal_approx(Vector3.ONE*game.World.BOAT_SCALE),"Flight rotation must never reset the jig scale")
 assert(feedback.cast_motion.state=="soak" and feedback.splash_age<.5,"Splash follows water impact")
 assert(game.fish_timer<2.5 and not game.bite_announced,"Flight finishes before the bite")
 for quality in range(3):
  game.graphics_quality=quality;game.apply_graphics()
  assert(Engine.physics_ticks_per_second==(30 if quality==0 else 60))
  assert(feedback.spray[0].amount==[10,16,24][quality])
 assert(not game.market.visible and game.market.process_mode==Node.PROCESS_MODE_DISABLED,"Off-screen customers/market are suspended")
 for id in ["skiff","launch","glacier","grady"]:
  game.equipped_boat=id;game.apply_boat();game._physics_process(.016)
  assert(game.camera.cull_mask==1,"Fishing excludes own-vessel geometry on all four boats")
  for part in game.boat_visual.find_children("*","GeometryInstance3D",true,false):
   assert(part.layers==2,"Bow railings and hull use the excluded vessel layer")
 game.leave_fishing();game._physics_process(.016)
 assert(game.camera.cull_mask==3,"Driving restores the complete boat view")
 game.boat.position=game.DOCK;game.sell()
 assert(game.market.visible and game.market.process_mode==Node.PROCESS_MODE_INHERIT,"Market resumes on entry")
 game.leave_fishing();game.open_shop()
 assert(game.shop.visible and not game.market.visible,"Only the active shop is processed")
 game.queue_free();await create_timer(.15).timeout
 print("PASS: hanging lure, exact ballistic flight at 30/60/120 Hz, delayed single impact, ready controls, cast camera and mobile scene budgets")
 quit()
