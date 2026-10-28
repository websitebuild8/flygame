extends SceneTree
func _initialize():call_deferred("checks")
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://gamified-ui.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip();game.drive.engine_running=false
 var ui=game.interface
 game.trip_progress.record_catch({"species":"Yellowfin tuna","weight":9.6,"value":180},"Kelaa Lagoon")
 for i in range(6):game.trip_progress.record_catch({"species":"Skipjack tuna","weight":4.2,"value":80},"Kelaa Lagoon")
 ui.refresh();assert(ui.collection_button.visible and ui.quests_button.visible,"Collection and challenges have independent HUD entry points")
 for button in [ui.collection_button,ui.quests_button,ui.map_button,ui.camera_button]:assert(button.icon!=null and button.custom_minimum_size.x>=56,"HUD icons remain large touch targets")
 for button in ui.menu.find_children("*","Button",true,false):assert(button.text!="Logbook & contracts","Challenges are no longer buried in Settings")
 ui.collection_button.pressed.emit();await process_frame;await process_frame
 assert(ui.logbook.visible and ui.menu_visible and not ui.menu.visible,"Collection opens its own paused screen")
 var portraits=0;var medals=0;var bars=0
 for picture in ui.logbook.find_children("*","TextureRect",true,false):
  if picture.texture and "/fish/" in picture.texture.resource_path:portraits+=1
  if picture.texture and "/medals/" in picture.texture.resource_path:medals+=1
 for bar in ui.logbook.find_children("*","ProgressBar",true,false):bars+=1
 assert(portraits==5 and medals>=3 and bars>=6,"Collection has five portraits, earned medals and visible progress")
 for label in ui.logbook.find_children("*","Label",true,false):
  if label.text=="9.6 kg":assert(label.get_line_count()==1,"Weight numbers stay together inside cards")
 ui.logbook.details("Yellowfin tuna");await process_frame;assert(ui.logbook.visible,"Fish details remain available without a text-heavy collection")
 ui.logbook.close_screen();assert(not ui.menu_visible and not ui.menu.visible,"Back returns directly to gameplay, not Settings")
 ui.quests_button.pressed.emit();await process_frame;await process_frame
 assert(ui.logbook.tab=="Spots" and ui.logbook.visible,"Trophy opens spot challenges directly")
 ui.logbook.show_tab("Contracts");await process_frame
 var accept: Button
 for button in ui.logbook.find_children("*","Button",true,false):
  if button.text=="Accept":accept=button;break
 assert(accept and not accept.disabled,"Visual contract cards can be accepted at harbour")
 accept.pressed.emit();await process_frame;assert(not game.trip_progress.active.is_empty(),"Accepting a visual card starts a real contract")
 ui.logbook.show_tab("Weekly");await process_frame
 assert(ui.logbook.find_children("*","ProgressBar",true,false).size()>=2,"Weekly challenge shows its two progress goals")
 ui.logbook.close_screen();game.message="Old routine message";ui.refresh();ui.message_until=0;ui.refresh();assert(not game.status.visible,"Routine HUD messages fade instead of staying on screen")
 for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
  root.size=dimensions;ui.apply_safe_area();ui.collection_button.pressed.emit();await process_frame;await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(ui.logbook.get_global_rect()),"Angler's Club fits both landscape sizes")
  ui.logbook.close_screen()
 assert(ui.game.info.text.begins_with("MVR") and not ui.route_label.visible,"HUD wallet remains explicit and empty navigation text is hidden")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: independent Fish/Goals screens, icon touch targets, portraits/medals/progress, readable card numbers, real contract acceptance, two screen sizes and compact fading HUD")
 quit()
