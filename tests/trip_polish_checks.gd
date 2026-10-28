extends SceneTree
const Conditions=preload("res://scripts/fishing_conditions.gd")
const Daily=preload("res://scripts/daily_requests.gd")
const Identity=preload("res://scripts/boat_identity.gd")
const PerformanceControl=preload("res://scripts/adaptive_performance.gd")
func _initialize():call_deferred("checks")
func checks():
 var conditions=Conditions.new();conditions.lure=1;conditions.depth=2
 assert(conditions.weight("Giant trevally",20,1)>conditions.weight("Skipjack tuna",20,1),"Matching lure, depth, weather and night improve target odds")
 var rng=RandomNumberGenerator.new();rng.seed=321
 for i in range(50):assert(conditions.choose(preload("res://scripts/world_data.gd").SPOTS[0],20,1,rng).name!="Sailfish","Conditions never introduce fish outside a spot pool")
 conditions.restore({"lure":99,"depth":-1});assert(conditions.lure==2 and conditions.depth==0,"Saved setups are bounded")
 var daily=Daily.new();var now=Time.get_unix_time_from_system();daily.refresh(now);var jobs=daily.offers();var species=jobs[1].species
 for i in range(3):daily.record({"species":species,"weight":7})
 assert(daily.ready(0) and daily.ready(1) and daily.ready(2),"One landed fish can contribute to independent requests")
 assert(daily.claim(1).mvr==100 and daily.claim(1).is_empty(),"Daily reward claims are exactly once")
 var old_day=daily.day;daily.refresh(now-86400);assert(daily.day==old_day and daily.claimed[1],"Clock rewind does not reopen a claimed request")
 var saved=daily.snapshot();var restored_daily=Daily.new();restored_daily.restore(saved);assert(restored_daily.claimed[1] and restored_daily.ready(0),"Request counts and claim flags persist")
 daily.refresh(now+86400);assert(daily.counts==[0,0,0] and daily.claimed==[false,false,false],"A new UTC day resets requests")
 var identity=Identity.new();assert(identity.rename("skiff","  Blue [Wave]\n  "));assert(identity.title("skiff")=="Blue Wave")
 assert(not identity.choose("skiff","ocean",49) and identity.choose("skiff","ocean",50),"Boat badges respect milestones")
 var restored_identity=Identity.new();restored_identity.restore(identity.snapshot(),50);assert(restored_identity.title("skiff")=="Blue Wave" and restored_identity.badge("skiff",50).id=="ocean")
 var performance=PerformanceControl.new();performance.configure(0)
 for i in range(250):performance.sample(.05,true)
 assert(performance.scale<.60 and performance.scale>=.45,"Sustained low rendered FPS lowers resolution within bounds")
 var scale=performance.scale
 for i in range(500):performance.sample(.05,false)
 assert(performance.scale==scale,"Menus/background do not train automatic resolution")
 performance.enabled=false
 for i in range(500):performance.sample(.05,true)
 assert(performance.scale==scale,"Manual graphics can disable adaptation")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://trip-polish.json";root.add_child(game);game.set_physics_process(false);game.set_process(false);game.interface.start_trip();game.drive.engine_running=false
 assert(game.interface.tutorial_panel.visible or game.tutorial.next(game)=="helm","New players receive contextual guidance")
 game.interface.fishing_setup.open();assert(game.interface.menu_visible and game.interface.fishing_setup.visible,"Fishing setup pauses gameplay")
 game.interface.fishing_setup.pickers[0].item_selected.emit(1);assert(game.fishing_conditions.lure==1);game.interface.fishing_setup.close();assert(not game.interface.menu_visible)
 game.tutorial.dismiss("helm");game.name_boat("Reef Runner");game.catches=30;game.cosmetics.lifetime_catches=30;assert(game.choose_boat_badge("reef"))
 assert(game.cosmetics.can_use("captain_teal") and game.cosmetics.can_use("ocean_racer") and not game.cosmetics.choose("island_reel","ocean_racer"),"Milestone liveries are boat-only and earned without payments")
 game.daily_requests=Daily.new();game.daily_requests.refresh();game.active_spot=game.World.SPOTS[0];game.active_species=game.World.FISH[0];game.active_catch={"species":"Yellowfin tuna","weight":8.0,"value":123,"size":1.0,"grade":"TROPHY"}
 game.fish_actor=game.Art.fish(game,.1,"Yellowfin tuna");var hooked=game.fish_actor;game.fishing=true;game.land_fish()
 assert(game.catch_model==hooked and hooked.get_parent()==game.camera,"Catch showcase reuses the hooked fish instead of building another model")
 assert(game.daily_requests.counts[0]==1 and game.inventory.size()==1,"Daily catches are recorded without consuming the fish")
 game.interface.update_catch_reveal(1.2);assert("8.0 kg" in game.catch_text.text and "MVR 123" in game.catch_text.text,"Reveal finishes at the immutable catch weight and value")
 assert(game.interface.catch_caption.text=="SPECIES DISCOVERED!" and game.interface.catch_stars.stars==3,"Discovery and trophy use visible celebrations")
 game.close_catch();assert(not game.interface.catch_sparkles.enabled,"Celebration stops on dismissal")
 for i in range(2):game.daily_requests.record({"species":"Yellowfin tuna","weight":8})
 var money=game.coins;var xp=game.experience.total;var reward=game.claim_daily_request(0)
 assert(game.coins==money+75 and game.experience.total==xp+40 and game.claim_daily_request(0).is_empty(),"Integrated daily reward saves cash and XP together once")
 game.sound_preference=false;game.vibration_preference=false;game.reduce_motion=true;game.save_trip();game.load_trip()
 assert(game.boat_identity.title("skiff")=="Reef Runner" and game.boat_identity.badge("skiff",game.catches).id=="reef","Boat identity survives a real trip save")
 assert(game.daily_requests.claimed[0] and game.fishing_conditions.lure==1 and not game.sound_preference and game.reduce_motion,"Requests, setup and comfort preferences survive reload")
 for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
  root.size=dimensions
  for tab in ["Collection","Daily","My boat"]:
   game.interface.logbook.open(tab);await process_frame;await process_frame
   assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(game.interface.logbook.get_global_rect()),"Expanded club fits landscape screens")
   assert(game.interface.logbook.tabs.size.x<=game.interface.logbook.size.x,"Expanded tab bar fits the screen")
   game.interface.logbook.close_screen()
  game.interface.fishing_setup.open();await process_frame;await process_frame;assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(game.interface.fishing_setup.get_global_rect()),"Fishing setup fits small landscape screens");game.interface.fishing_setup.close()
 game.queue_free();await create_timer(.2).timeout
 print("PASS: fishing conditions, spot pools, daily rollover/clock rewind/exact-once claims, boat milestones and names, adaptive resolution, tutorials, saved preferences, pooled catch reveal and small-screen UI")
 quit()
