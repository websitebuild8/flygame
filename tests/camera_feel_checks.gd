extends SceneTree
func _initialize():call_deferred("checks")
func checks():
 var controller=preload("res://scripts/adaptive_performance.gd").new()
 for mobile in [false,true]:
  for quality in range(3):
   controller.configure(quality,mobile)
   for i in range(1800):controller.sample(.1,true)
   var floor_scale=.45 if mobile else [.45,.65,.85][quality]
   assert(is_equal_approx(controller.scale,floor_scale),"Sustained load respects the selected desktop/mobile clarity floor")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://camera-feel.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip();game.drive.engine_running=false;game.boat.position=game.SPOT
 game.cast(true);game.cast();game.fish_timer=3;game.bite_announced=true;game.fight.hooked=true;game.fight.progress=.35;game.fight.tension=.45;game.reeling=true
 var views=[]
 for i in range(25):
  game._physics_process(1.0/60);views.append(game.camera.global_basis)
 assert(not views[0].is_equal_approx(views[-1]),"Fish tracking and tension-driven camera motion remain active")
 assert(game.feedback.bend_amount>.2 and game.feedback.winding_speed>1,"Tension still bends the rod and winding still drives the reel")
 var before=game.camera.fov;game.fight.power_time=1.35
 for i in range(15):game._physics_process(1.0/60)
 assert(game.camera.fov>before+.5,"Power-reel camera burst retains its zoom action")
 game.feedback.strike_kick=.8;game._physics_process(1.0/60)
 assert(game.fishing_camera_offset.length()>.001,"Strike camera kick still affects the first-person pose")
 game.fight.power_time=0;game.fight.progress=.99;game.fight.landing_lift=1;game.fight.tension=.3;game.reeling=false
 for i in range(25):game._physics_process(1.0/60)
 assert(is_zero_approx(game.camera.v_offset) and game.camera.fov<78,"Landing never replaces the close lens with the rejected wide-angle shifted view")
 assert(not game.reduce_motion,"Fresh saves keep full motion enabled")
 game.queue_free();await process_frame
 print("PASS: desktop clarity floors, unchanged mobile range, fish tracking, tension bend, reel motion, power zoom, strike kick and original landing perspective")
 quit()
