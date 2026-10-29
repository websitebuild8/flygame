extends SceneTree
const Art=preload("res://scripts/world_art.gd")
const Bounds=preload("res://scripts/rigged_asset_bounds.gd")
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
 var stage=Node3D.new();root.add_child(stage)
 var fish=Art.fish(stage,1,"Rusty jobfish")
 assert(fish.player.get_animation_list().size()==5,"All five recovered clips survive")
 var envelope=AABB();var first=true
 for clip in ["Swim01","Pulling01","Show01"]:
  fish.player.play(clip)
  for sample in range(61):
   fish.player.seek(fish.player.get_animation(clip).length*sample/61.0,true);fish.player.advance(0)
   var measured=Bounds.measure(fish)
   envelope=measured if first else envelope.merge(measured);first=false
   assert(fish.canonical_bounds().encloses(measured),"Jobfish envelope contains every sampled pose: "+clip+str(measured))
 print("Jobfish animated envelope: ",envelope)
 var another=Art.fish(stage,1,"Rusty jobfish")
 assert(another.player.get_animation("Swim01")!=fish.player.get_animation("Swim01"),"Each fish owns its playback state")
 fish.set_motion("pull");assert(fish.motion=="Pulling01")
 fish.set_motion("show");assert(fish.motion=="Show01" and another.motion=="Swim01")
 var locations=[]
 for spot in World.SPOTS:
  if 5 in spot.fish:locations.append(spot.id)
 assert(locations==["reef","east","sunset"],"Jobfish is catchable at reef slopes/drop-offs, away from the shallow lagoon")
 var rng=RandomNumberGenerator.new();rng.seed=72891
 var weights={};var values={};var entry=World.FISH[5]
 for i in range(80):
  var item=preload("res://scripts/catch_profile.gd").roll(entry,rng)
  assert(item.weight>=entry.min and item.weight<=entry.max and item.value>0,"Every catch respects the species range")
  weights[item.weight]=true;values[item.value]=true
 assert(weights.size()>20 and values.size()>20,"Individuals vary in weight and MVR value")
 var conditions=preload("res://scripts/fishing_conditions.gd").new();conditions.lure=1;conditions.depth=2
 var preferred=conditions.weight(entry.name,6,1,true);conditions.lure=2;conditions.depth=0
 assert(preferred>conditions.weight(entry.name,6,1,true),"Deep reef setup improves relative jobfish chances")
 var fight=preload("res://scripts/fish_fight.gd").new();fight.set_species(entry.name);fight.start(Vector3.ZERO,Vector3.FORWARD,1,.22)
 for i in range(500):
  fight.step(1.0/30,i%50<35,1,1,1,1)
  assert(not fight.jumping,"Jobfish makes deep pulls rather than offshore billfish leaps")
 var progress=preload("res://scripts/trip_progress.gd").new();progress.record_catch({"species":entry.name,"weight":3.2,"value":58},"Kelaa Outer Reef")
 var saved=preload("res://scripts/trip_progress.gd").new();saved.restore(progress.snapshot())
 assert(saved.records[entry.name].best==3.2,"New species records survive existing journal saves")
 stage.queue_free();await process_frame
 print("PASS: animated jobfish bounds, independent playback, reef distribution, variable weights/prices, deep setup, distinct fight and journal persistence")
 quit()
