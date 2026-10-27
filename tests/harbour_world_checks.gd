extends SceneTree
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func crosses_gate(route: PackedVector2Array) -> bool:
 for i in range(route.size()-1):
  var a=route[i];var b=route[i+1]
  if (a.x+10)*(b.x+10)<=0 and absf(b.x-a.x)>.001:
   var z=lerpf(a.y,b.y,(-10-a.x)/(b.x-a.x))
   if z>11 and z<23:return true
 return false
func checks():
 var nav=preload("res://scripts/sea_navigation.gd").new();nav.configure(true)
 assert(World.water(World.Harbour.HOME,true,World.NAV_CLEARANCE))
 for point in [Vector2(0,2),Vector2(0,30),Vector2(-10,6),Vector2(-10,27),Vector2(23,16)]:assert(not World.water(point,true,World.BOAT_CLEARANCE),"Quays and breakwaters stop boats")
 assert(World.water(World.Harbour.ENTRANCE,true,World.NAV_CLEARANCE),"The marked western entrance is wide enough")
 assert(nav.set_destination(World.Harbour.HOME,Vector2(0,-45),"Exit"));assert(crosses_gate(nav.route),"Outbound route must use the harbour mouth")
 for i in range(nav.route.size()-1):assert(nav.clear_line(nav.route[i],nav.route[i+1]))
 assert(nav.set_destination(Vector2(0,-45),World.Harbour.HOME,"Home"));assert(crosses_gate(nav.route),"Inbound route must use the same entrance")
 for spot in World.SPOTS:assert(nav.set_destination(World.Harbour.HOME,spot.at,spot.name),"Every fishing spot remains reachable: "+str(spot.name))
 for island in World.ISLANDS:
  var source=World.Harbours.Base.mapped_coast if island.name=="HA. Kelaa" else World.Harbours.Base.points(World.Harbours.raw_maps[island.name].coast)
  assert(source.size()>60,"All islands retain detailed mapped source outlines")
  assert(World.outline(island).size()>40,"Harbour cuts preserve the natural island coastline")
  if island.name!="HA. Kelaa":assert(island.at.distance_to(World.ISLANDS[0].at)>280,"Neighbouring islands have open sea between them")
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://harbour-world-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
 for id in ["skiff","launch","glacier","grady"]:
  game.equipped_boat=id;game.apply_boat()
  var bounds=AABB();var first=true
  for mesh in game.boat_visual.find_children("*","MeshInstance3D",true,false):
   var box=mesh.global_transform*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
  assert(bounds.size.y<1.05,"Boats are below the palms and comparable to the smallest houses")
  assert(game.boat_visual.scale.is_equal_approx(Vector3.ONE*World.BOAT_SCALE))
  game.first_person_driving=true;game._physics_process(.016)
  var screen=game.camera.unproject_position(game.boat_visual.get_node("HelmWheel").global_position)
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).has_point(screen),"Scaled cockpit wheel stays usable")
 game.boat.position=Vector3(-15,0,17);game.sell();assert(not game.market_mode,"An outside boat cannot access the harbour market")
 game.boat.position=Vector3(-40,0,-45)
 var before=game.boat.position;game.plot_home_course()
 assert(game.boat.position.is_equal_approx(before) and crosses_gate(game.navigation.route),"Home action plots an entry route instead of teleporting")
 game.return_home();game.sell();assert(game.market_mode,"The inner berth opens market services")
 game.leave_fishing();game.open_shop();assert(game.shop_mode,"The inner berth opens the equipment shop")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: enclosed harbour, mandatory entry/exit, all fishing routes, five mapped island shapes, wider spacing, boat scale, POV controls and berth-only shops")
 quit()
