extends SceneTree
const Art=preload("res://scripts/world_art.gd")
const Bounds=preload("res://scripts/rigged_asset_bounds.gd")
const World=preload("res://scripts/world_data.gd")
const Challenges=preload("res://scripts/spot_challenges.gd")
func _initialize():call_deferred("checks")
func checks():
 var stage=Node3D.new();root.add_child(stage)
 var fish=Art.fish(stage,1,"Giant grouper")
 assert(fish.player.get_animation_list().size()==5,"Recovered grouper retains five source clips")
 var envelope=AABB();var first=true
 for clip in ["Swim01","Pulling01","Show01"]:
  fish.player.play(clip)
  for sample in range(61):
   fish.player.seek(fish.player.get_animation(clip).length*sample/61.0,true);fish.player.advance(0)
   var measured=Bounds.measure(fish)
   envelope=measured if first else envelope.merge(measured);first=false
   assert(fish.canonical_bounds().encloses(measured),"Grouper envelope contains skin: "+clip+str(measured))
 print("Grouper animated envelope: ",envelope)
 var copy=Art.fish(stage,1,"Giant grouper")
 assert(copy.player.get_animation("Swim01")!=fish.player.get_animation("Swim01"),"Independent fish clips do not overwrite each other")
 var locations=[]
 for spot in World.SPOTS:
  if 6 in spot.fish:locations.append(spot.id)
 assert(locations==["east","night","sunset"],"Heavy grouper is found at unlocked reef/drift spots")
 var rng=RandomNumberGenerator.new();rng.seed=88265;var weights={};var prices={}
 for i in range(60):
  var item=preload("res://scripts/catch_profile.gd").roll(World.FISH[6],rng)
  assert(item.weight>=3 and item.weight<=24 and item.value>0)
  weights[item.weight]=true;prices[item.value]=true
 assert(weights.size()>25 and prices.size()>25,"Grouper weight and MVR offers vary per individual")
 var system=Challenges.new()
 assert(not system.start("east_grouper","east",3,9,10) and not system.start("east_grouper","east",4,9,0),"Challenge respects level and point unlock")
 assert(system.start("east_grouper","east",4,9,10))
 system.record({"species":"Rusty jobfish","weight":20},"east",9);system.record({"species":"Giant grouper","weight":7.9},"east",9)
 assert(system.active.count==0,"Wrong species and small specimens cannot clear the challenge")
 var saved=Challenges.new();saved.restore(system.snapshot());assert(saved.active.id=="east_grouper","Active bonus challenge survives a save")
 saved.record({"species":"Giant grouper","weight":21},"east",9)
 assert(saved.result.success and saved.result.stars==3,"Trophy grouper earns three stars")
 var prize=saved.claim();assert(prize.mvr==180 and prize.xp==180 and saved.claim().is_empty(),"First clear pays MVR and XP exactly once")
 assert(saved.start("east_grouper","east",4,9,10));saved.record({"species":"Giant grouper","weight":21},"east",9)
 assert(saved.claim().mvr==0,"Replays cannot farm the first-clear payout")
 assert(system.start("reef_jobfish","reef",2,9,0)==false,"Cannot stack active challenges")
 system=Challenges.new();assert(system.start("reef_jobfish","reef",2,9,0));system.record({"species":"Rusty jobfish","weight":5.2},"reef",9)
 assert(system.result.stars==3 and system.claim().mvr==120,"Existing jobfish gains its own trophy challenge")
 stage.queue_free();await process_frame
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://grouper-ui.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip()
 var panel=game.interface.logbook;panel.open("Spots");await process_frame
 var found=[]
 for button in panel.content.find_children("*","Button",true,false):
  if button.text in ["Rankarumas specialist","Drop-off heavyweight"]:found.append(button)
 assert(found.size()==2,"Bonus challenges have visible entry buttons in the Spots tab")
 for button in found:
  if button.text=="Drop-off heavyweight":button.pressed.emit();break
 await process_frame
 var correct=false
 for label in panel.content.find_children("*","Label",true,false):
  if label.text=="Drop-off heavyweight":correct=true
 assert(correct,"Grouper challenge button opens its own details")
 game.queue_free();await process_frame
 print("PASS: grouper animated envelope, independent clips, distribution, variable weight/prices and two gated, saved, exact-once trophy challenges")
 quit()
