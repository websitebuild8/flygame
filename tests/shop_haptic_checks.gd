extends SceneTree
var pulses: Array=[]
func _initialize():call_deferred("checks")
func touch(control: Control,id: int,at: Vector2,down: bool):
 var event=InputEventScreenTouch.new();event.index=id;event.position=at;event.pressed=down;control._gui_input(event)
func drag(control: Control,id: int,at: Vector2,relative: Vector2):
 var event=InputEventScreenDrag.new();event.index=id;event.position=at;event.relative=relative;control._gui_input(event)
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://shop-haptics.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip();game.drive.engine_running=false;game.open_shop("Reels");await process_frame
 var control=game.interface.preview_controls;var shop=game.shop
 assert(control.visible and not(control is PanelContainer),"Preview has no large panel or zoom buttons")
 shop.zoom=1;var angle=shop.angle
 touch(control,0,Vector2(80,80),true);touch(control,1,Vector2(180,80),true);drag(control,1,Vector2(230,80),Vector2(50,0))
 assert(is_equal_approx(shop.zoom,1.5) and is_equal_approx(angle,shop.angle),"Spreading fingers zooms without rotating")
 drag(control,1,Vector2(130,80),Vector2(-100,0));assert(is_equal_approx(shop.zoom,.7),"Pinching contracts zoom within its lower bound")
 touch(control,1,Vector2(130,80),false);drag(control,0,Vector2(100,80),Vector2(20,0));assert(shop.angle>angle,"One-finger dragging rotates")
 control._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);assert(control.touches.is_empty(),"Focus loss releases touch ownership")
 var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;control._gui_input(wheel);assert(shop.zoom>.7,"Desktop scroll-wheel zoom remains available")
 var feedback=game.feedback;feedback.haptic_requested.connect(func(duration,amplitude):pulses.append([duration,amplitude]))
 for i in range(90):feedback.update_fight_haptics(1.0/30,true,.4,false,false)
 assert(pulses.size()>6 and pulses[0][0]==65 and pulses[1][0]==30,"Hooked fish produces repeated double pulses without holding reel")
 var normal=pulses[0][1];feedback.stop_fight_haptics();pulses.clear();feedback.update_fight_haptics(.02,true,.4,true,false)
 assert(pulses[0][1]>normal,"Fish runs strengthen feedback")
 feedback.stop_fight_haptics();pulses.clear()
 for i in range(40):feedback.update_fight_haptics(1.0/30,true,.4,false,true)
 assert(pulses.size()>=3 and pulses[0][1]<normal,"Landing continues with gentler pulses")
 feedback.vibration_enabled=false;pulses.clear();feedback.update_fight_haptics(1,true,1,true,false)
 assert(pulses.is_empty() and not feedback.fight_pulse_active,"Vibration setting immediately cancels fight pulses")
 feedback.vibration_enabled=true;feedback.update_fight_haptics(.02,true,.3,false,false);feedback.update_fight_haptics(.02,false,0,false,false)
 assert(not feedback.fight_pulse_active and feedback.fight_pulse_timer==0,"Ending a fight stops the pulse scheduler")
 game.leave_fishing();game.active_species=game.World.FISH[0];game.fishing=true;game.land_fish();game._physics_process(.02)
 assert(game.catch_overlay.visible and game.catch_model.visible and not feedback.line.visible and not feedback.rig.visible,"Catch screen shows the fish without fight line or rod")
 for mesh in game.camera.find_children("*","MeshInstance3D",true,false):assert(not(mesh.mesh is ImmediateMesh and mesh.visible),"Showcase creates no separate line geometry")
 assert(not feedback.fight_pulse_active,"Catch information screen has no continuing fight vibration")
 game.queue_free();await process_frame
 print("PASS: unobstructed pinch/drag/wheel preview, touch cancellation, continuous double-pulse fight/landing haptics, vibration setting and line-free catch display")
 quit()
