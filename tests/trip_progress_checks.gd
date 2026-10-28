extends SceneTree
const Progress=preload("res://scripts/trip_progress.gd")
func _initialize():call_deferred("checks")
func catch_item(species: String,weight: float,value: int=120) -> Dictionary:return {"species":species,"weight":weight,"value":value}
func checks():
 var progress=Progress.new()
 var fresh=progress.record_catch(catch_item("Skipjack tuna",3),"Kelaa Lagoon")
 assert(fresh.new_species and not fresh.record and progress.records.size()==1,"First catch discovers a species")
 var best=progress.record_catch(catch_item("Skipjack tuna",5,200),"Outer reef")
 assert(best.record and progress.records["Skipjack tuna"].best==5 and progress.records["Skipjack tuna"].value==200,"Larger catch sets personal records")
 progress.record_catch(catch_item("Skipjack tuna",2),"Lagoon")
 assert(progress.records["Skipjack tuna"].best==5 and progress.records["Skipjack tuna"].count==3,"Smaller catches increase total without lowering a record")
 var offer=progress.offers()[0];assert(progress.accept(offer.id,"HA. Kelaa"))
 assert(not progress.accept(progress.offers()[1].id,"HA. Kelaa"),"Only one contract is active")
 progress.deliver(catch_item("Skipjack tuna",3),"HA. Baarah");progress.deliver(catch_item("Yellowfin tuna",3),"HA. Kelaa")
 assert(progress.active.count==0,"Wrong island/species cannot advance a contract")
 progress.deliver(catch_item("Skipjack tuna",1),"HA. Kelaa");progress.deliver(catch_item("Skipjack tuna",1),"HA. Kelaa")
 assert(not progress.ready(),"Contract needs both count and total weight")
 progress.deliver(catch_item("Skipjack tuna",3),"HA. Kelaa");assert(progress.ready())
 assert(progress.claim("HA. Baarah")==0 and progress.claim("HA. Kelaa")==offer.reward and progress.claim("HA. Kelaa")==0,"Reward is paid once at the chosen harbour")
 assert(progress.completed==1 and progress.offers()[0].id!=offer.id,"Completing a contract rotates offers")
 for i in range(10):progress.record_catch(catch_item(["Skipjack tuna","Yellowfin tuna","Giant trevally"][i%3],3))
 assert(progress.weekly_ready() and progress.claim_weekly()==300 and progress.claim_weekly()==0,"Weekly reward requires varied catches and cannot be collected twice")
 var mastery=Progress.new()
 for i in range(15):mastery.record_catch(catch_item("Skipjack tuna",3))
 assert(mastery.mastery("Skipjack tuna")=="Master angler" and mastery.mastery("Sailfish")=="Undiscovered","Mastery badges reflect real landed catches")
 var loaded=Progress.new();loaded.restore(progress.snapshot());assert(loaded.records==progress.records and loaded.weekly.claimed and loaded.completed==1,"Journal/records/claimed rewards persist")
 var before=loaded.weekly.id;loaded.refresh_week((float(before)+1)*604800-259200+1)
 assert(loaded.weekly.count==0 and not loaded.weekly.claimed and loaded.records.size()==3,"Weekly rollover leaves permanent records intact")
 var traces: Array[String]=[]
 for species in preload("res://scripts/fish_fight.gd").BEHAVIOURS:
  var fight=preload("res://scripts/fish_fight.gd").new();fight.set_species(species);fight.start(Vector3.ZERO,Vector3.FORWARD,1,.22)
  var runs=0;var jumps=0
  for frame in range(120):
   fight.step(1.0/30,true,1,1,1,1)
   if fight.running:runs+=1
   if fight.jumping:jumps+=1
  traces.append("%d_%d_%s"%[runs,jumps,fight.position])
 assert(traces.size()==5 and traces[0]!=traces[1] and traces[2]!=traces[3] and traces[3]!=traces[4],"Species have distinct runs, sweeps and jump patterns")
 var file_path="user://progress-check.json";var file=FileAccess.open(file_path,FileAccess.WRITE)
 file.store_string(JSON.stringify({"coins":300,"inventory":[catch_item("Skipjack tuna",4)],"hold_value":120}));file.close()
 var game=load("res://scenes/main.tscn").instantiate();game.save_path=file_path;root.add_child(game);game.set_physics_process(false);game.interface.start_trip();game.drive.engine_running=false
 assert(game.trip_progress.records["Skipjack tuna"].best==4 and game.trip_progress.weekly.get("count",0)==0,"Old inventory seeds records without fabricating weekly progress")
 assert(game.accept_contract(game.trip_progress.offers()[0].id),"Can accept a contract while safely berthed")
 game.sell();game.interface.refresh();game.serve_customer();assert(game.trip_progress.active.count==1 and game.pending_payment==120,"Market delivery and pending payment save together")
 await create_timer(.45).timeout;game.serve_customer();await create_timer(.85).timeout;assert(game.coins==420,"Normal fish payment is unchanged")
 game.inventory=[catch_item("Skipjack tuna",3)];game.hold_value=120;game.serve_customer();await create_timer(.45).timeout;game.serve_customer();await create_timer(.85).timeout
 assert(game.trip_progress.ready());var reward=game.trip_progress.active.reward;var coins=game.coins
 assert(game.claim_contract()==reward and game.claim_contract()==0 and game.coins==coins+reward,"Real market deliveries unlock exactly one bonus")
 game.leave_fishing();game.active_species=game.World.FISH[2];game.active_catch={"species":"Skipjack tuna","weight":6.0,"value":200,"size":1.0,"grade":"LARGE"};game.fishing=true;game.land_fish()
 assert("NEW PERSONAL BEST" in game.interface.catch_caption.text and game.trip_progress.records["Skipjack tuna"].best==6,"Landing shows the new personal-best celebration")
 var count=game.trip_progress.records["Skipjack tuna"].count;game.land_fish();assert(game.trip_progress.records["Skipjack tuna"].count==count,"A repeated landing call cannot double-count the catch")
 game.close_catch();game.leave_fishing();game.interface.toggle_menu();game.interface.logbook.open()
 for tab in ["Collection","Contracts","Weekly"]:game.interface.logbook.show_tab(tab);await process_frame
 assert(game.interface.logbook.visible and game.interface.menu_visible,"Logbook pauses gameplay across all tabs")
 game.interface.toggle_menu();assert(not game.interface.logbook.visible and not game.interface.menu_visible,"Dismissing the overlay restores gameplay")
 game.save_trip();game.load_trip();assert(game.trip_progress.records["Skipjack tuna"].best==6 and game.trip_progress.completed==1,"Real save/reload retains records and contract completions")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: collection/records/mastery, correct delivery filters, one-time contract/weekly rewards, rotation, rollover, legacy migration, exact market payments, catch celebrations and logbook navigation")
 quit()
