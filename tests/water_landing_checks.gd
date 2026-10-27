extends SceneTree
const Surface=preload("res://scripts/water_surface.gd")
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
 var sea=Surface.new()
 for quality in [32,64,100]:
  sea.subdivisions=quality
  var plane=PlaneMesh.new();plane.size=Vector2.ONE*1800;plane.subdivide_width=quality;plane.subdivide_depth=quality
  var arrays=plane.get_mesh_arrays();var vertices=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
  for roughness in [0.0,1.0]:
   sea.roughness=roughness;sea.phase=43.7
   for triangle in [0,12,quality*6,(indices.size()/6)*3-3]:
    triangle=int(triangle/3)*3
    var a=vertices[indices[triangle]];var b=vertices[indices[triangle+1]];var c=vertices[indices[triangle+2]]
    var p=a*.23+b*.41+c*.36
    var expected=sea.vertex_height(Vector2(a.x,a.z))*.23+sea.vertex_height(Vector2(b.x,b.z))*.41+sea.vertex_height(Vector2(c.x,c.z))*.36
    assert(absf(sea.height(Vector2(p.x,p.z))-expected)<.0001,"CPU float height matches the rendered PlaneMesh triangle at every quality")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://water-landing-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
 var image=game.shallow_life.depth_image
 assert(image.get_width()==512 and image.get_height()==512,"Coastal appearance uses a small precomputed map")
 var shallow=game.shallow_life.sample(Vector2(0,16));var deep=game.shallow_life.sample(Vector2(-180,-100))
 assert(shallow.r<.5 and deep.r>.95,"Harbour shallows and offshore depths have separate colour ramps")
 game.shallow_life.update(1,Vector3(15,2,16),0,game.day_cycle.water,0)
 var low_count=0
 for value in game.shallow_life.values:
  if value.w>.5:low_count+=1
 game.shallow_life.update(1,Vector3(15,2,16),0,game.day_cycle.water,2)
 var high_count=0
 for value in game.shallow_life.values:
  if value.w>.5:high_count+=1
 assert(low_count>0 and low_count<=3 and high_count>low_count and high_count<=8,"Shallow fish activity respects quality budgets")
 game.day_cycle.weather=3;game.day_cycle.roughness=1;game.day_cycle.cover=.85
 game.boat.position=game.SPOT;game.surface.port={};game.water_port=""
 var imported=0
 for actor in game.traffic.actors:
  if actor.node.has_meta("imported_boat"):imported+=1
 assert(imported==2,"Two traffic boats reuse the authored fishing-vessel models, without multiplying the fleet")
 for boat_id in ["skiff","launch","glacier","grady"]:
  game.equipped_boat=boat_id;game.apply_boat();game.boat.position=game.SPOT;game.cast()
  game.fish_timer=3;game.fight.hooked=true
  for species in World.FISH:
   game.clear_hooked_fish();game.active_species=species
   game.active_catch={"species":species.name,"size":1.25,"weight":float(species.max),"value":120,"grade":"TROPHY","strength":1.0}
   game.fish_actor=game.Art.fish(game,.45*World.BOAT_SCALE*1.25,species.name)
   game.fight.progress=.98;game.fight.tension=.4;game.fight.landing_lift=1
   for tick in range(12):game._physics_process(1.0/30)
   var mouth=game.line_target();var tip=game.feedback.routed_line_points[-13]
   assert(absf(mouth.x-tip.x)<.0001 and absf(mouth.z-tip.z)<.0001 and mouth.y<tip.y,"Every fish hangs vertically beneath the last guide")
   assert(game.feedback.routed_line_points[-1].distance_to(mouth)<.0001,"Visible line ends at the imported fish mouth")
   assert(game.hooked_fish_bottom()>game.surface.ceiling()+.025,"The full tail clears even the maximum wave crest")
   assert(game.can_put_fish_on_boat(),"Landing button appears only after the complete fish is clear")
   assert(game.camera.position.y>game.surface.height(Vector2(game.camera.position.x,game.camera.position.z))+.23,"Fishing eye never dips into the sea")
   var screen=game.camera.unproject_position(game.fish_actor.position)
   assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).has_point(screen),"Hanging fish stays in frame on every boat")
  game.land_fish();game._physics_process(.016)
  var bounds: AABB=game.catch_model.get_meta("fish_bounds")
  assert((game.catch_model.global_transform*bounds).position.y>game.surface.ceiling(),"Catch showcase remains wholly above the ocean")
  game.close_catch();game.leave_fishing()
  for tick in range(20):
   game._physics_process(1.0/30)
   var height=game.surface.height(Vector2(game.boat.position.x,game.boat.position.z))
   assert(absf(game.boat.position.y-(height-Surface.BASE))<.001,"Player hull follows the current sea height")
  var Mount=preload("res://scripts/outboard_waterline.gd")
  for item in Mount.motors(game.boat_visual):
   var hub=item.prop.global_position
   assert(hub.y+item.radius<game.surface.height(Vector2(hub.x,hub.z))-.04,"Entire propeller disk stays submerged on every boat")
  var sources=Mount.positions(game.boat_visual)
  for direction in [-1,1]:
   game.wake.timer=0
   game.wake.update_wake(.016,game.boat.position,game.boat.basis.z,direction*2,sources,.8,direction)
   assert(game.wake.emitted_origins.size()==sources.size(),"Twin engines each emit prop wash")
   for i in range(sources.size()):
    var offset=game.wake.emitted_origins[i]-sources[i]
    assert(absf(offset.dot(game.boat.basis.z)-.025)<.001,"Forward and reverse wash both originate at the stern propeller")
   var last=(game.wake.cursor-1+game.wake.pieces.size())%game.wake.pieces.size()
   assert(game.wake.velocities[last].dot(game.boat.basis.z)*direction>0,"Reversing changes jet direction without moving the emission source")
  for actor in game.traffic.actors:
   assert(absf(actor.node.position.y-(game.surface.height(actor.position)-Surface.BASE))<.002,"NPC hulls share the player waterline sampler")
   if not actor.node.imported_id.is_empty():
    for item in Mount.motors(actor.node.hull):
     var hub=item.prop.global_position
     assert(hub.y+item.radius<game.surface.height(Vector2(hub.x,hub.z))-.04,"Imported NPC propellers also remain submerged")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: shader-matched water height at all qualities, five species hanging by the mouth on four boats, fully dry tails/showcases, safe fishing eye and two imported NPC vessels")
 quit()
