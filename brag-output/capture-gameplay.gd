extends SceneTree
var game
const OUT="/home/ahusan/Desktop/flygame/brag-output/composition/assets/footage/"
const FRAME="/tmp/ishaq-brag-frames/"
func _initialize():call_deferred("run")
func tick():
 game.app_active=true
 game._physics_process(1.0/30)
func frame(clip: String,index: int):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(FRAME+clip+"-%04d.png"%index)
func encode(clip: String,count: int):
 var args=PackedStringArray(["-y","-loglevel","error","-framerate","30","-i",FRAME+clip+"-%04d.png","-frames:v",str(count),"-vf","scale=1280:720","-threads","2","-c:v","libx264","-preset","fast","-crf","18","-pix_fmt","yuv420p","-movflags","+faststart",OUT+clip+".mp4"])
 var result=OS.execute("/tmp/ishaq-node/bin/ffmpeg",args)
 assert(result==0,"Footage encode failed")
 print("CAPTURED ",clip," ",count," frames")
 for i in range(count):DirAccess.remove_absolute(FRAME+clip+"-%04d.png"%i)
func run():
 print("START CAPTURE")
 root.size=Vector2i(1280,720)
 root.position=Vector2i(1600,0)
 game=load("res://scenes/main.tscn").instantiate();game.save_path="user://promo-staged.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
 game.feedback.sound_enabled=false;game.graphics_quality=2;game.graphics_shadows=true;game.apply_graphics();game.day_cycle.weather=0;game.day_cycle.hours=9;game.day_cycle.apply_lighting()
 game.interface.visible=false
 for i in range(90):
  tick();var t=float(i)/89
  game.camera.position=Vector3(-52,58,62).lerp(Vector3(-30,50,40),t);game.camera.look_at(Vector3(28,-.4,50));game.camera.fov=65
  if i%30==0:print("ISLAND FRAME ",i)
  await frame("island",i)
 encode("island",90)
 game.equipped_boat="grady";game.apply_boat();game.boat.position=Vector3(-4,0,-42);game.boat.rotation=Vector3.ZERO;game.drive.engine_running=true;game.driving_controls.lever_value=.42
 for i in range(105):
  tick();var t=float(i)/104
  game.camera.position=game.boat.position+Vector3(2.7-t*.7,1.7,3.4);game.camera.look_at(game.boat.position+Vector3(0,-.1,-.25));game.camera.fov=65
  await frame("helm",i)
 encode("helm",105)
 game.return_home();game.boat.position=game.SPOT;game.boat.rotation=Vector3.ZERO;game.interface.visible=true
 game.equipped_boat="skiff";game.apply_boat();game.driving_controls.neutral();game.drive.reset();game.fishing_action()
 for i in range(150):
  if i==18:game.fishing_action()
  if i==94:game.fish_timer=3;game.fight.hooked=true;game.reeling=true
  if i==117:game.fight.progress=.96;game.reeling=false;game.fight.tension=.4
  tick();await frame("fishing",i)
 encode("fishing",150)
 if game.fishing:game.land_fish()
 game.close_catch();game.leave_fishing();game.return_home();game.day_cycle.hours=10;game.day_cycle.apply_lighting();game.sell()
 for i in range(114):
  if i==15:game.serve_customer()
  if i==65:game.serve_customer()
  tick();await frame("market",i)
 encode("market",114)
 game.leave_fishing();game.return_home();game.interface.visible=false;game.day_cycle.hours=17.4;game.day_cycle.apply_lighting()
 for i in range(141):
  tick();var t=float(i)/140
  game.camera.position=Vector3(-37,9,4).lerp(Vector3(-46,12,8),t);game.camera.look_at(Vector3(28,-.2,35));game.camera.fov=65
  await frame("outro",i)
 encode("outro",141)
 game.queue_free();await create_timer(.2).timeout;quit()
