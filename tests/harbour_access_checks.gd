extends SceneTree
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
 var path="user://harbour-only-check.json"
 var old_save={"coins":321,"inventory":[{"species":"Skipjack tuna","weight":2.5,"value":120}],"hold_value":120,"pending_payment":73,"owned_boats":["skiff","launch"],"equipped_boat":"skiff","island_journey":{"active":true,"title":"HA. Baarah","cargo":"pickup","owned":["pickup","bike","car"]}}
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(old_save));file.close()
 var game=load("res://scenes/main.tscn").instantiate();game.save_path=path;root.add_child(game);game.set_physics_process(false);game.interface.start_trip()
 assert(game.coins==321 and game.inventory.size()==1 and game.inventory[0].value==120 and game.pending_payment==73,"Old land saves retain catch inventory, MVR and pending payments")
 assert(Vector2(game.boat.position.x,game.boat.position.z).is_equal_approx(Vector2(game.DOCK.x,game.DOCK.z)),"Old land saves resume safely aboard at the home berth")
 assert("launch" in game.owned_boats,"Existing boat unlocks remain owned")
 assert(not DirAccess.dir_exists_absolute("res://assets/models/island"),"Cancelled land vehicle assets are absent from the project")
 for port in World.Harbours.all_ports():
  game.boat.position=Vector3(port.dock.x,0,port.dock.y);game.drive.engine_running=false;game.drive.reset();game.speed=0;game.interface.refresh()
  assert(game.market_button.visible and not game.market_button.disabled,"Each inner berth exposes direct Market access")
  game.sell();assert(game.market_mode and game.market.island_name==port.name,"Berth opens the correct market without land travel")
  if game.pending_payment>0:
   game._physics_process(.016);game.serve_customer();assert(game.coins==394 and game.pending_payment==0,"Pending MVR remains collectable")
  game.leave_fishing();game._physics_process(.016)
  assert(not game.market_mode and (not game.market.seller_hands or not game.market.seller_hands.visible),"Returning to the boat hides market hands")
 game.save_trip();var saved=JSON.parse_string(FileAccess.get_file_as_string(path))
 assert(not saved.has("island_journey") and saved.inventory.size()==1 and saved.inventory[0].value==120,"Next save drops obsolete travel state without losing fish")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: direct access to all five harbour markets, old land-save recovery, retained fish/boats/MVR, collectible pending payment and hidden market hands")
 quit()
