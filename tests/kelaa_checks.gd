extends SceneTree
const Map=preload("res://scripts/kelaa_map_data.gd")
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
 assert(Map.mapped_coast.size()==114 and Map.data.roads.size()>100,"Authentic OSM coastline and road network are bundled")
 assert(Map.data.buildings.size()==20 and Map.data.source.license=="ODbL 1.0")
 assert(Map.bounds.size.y>Map.bounds.size.x*2,"Kelaa retains its long curved outline")
 assert(World.water(Vector2(2.3,12),false,7),"Home mooring has room for the navigation clearance")
 for spot in World.SPOTS:assert(World.water(spot.at,true,7),"Fishing spot stays clear of the recreated island: "+str(spot.name))
 var inside=0
 for x in range(10,60,3):
  for z in range(0,125,3):
   var p=Vector2(x,z)
   if Geometry2D.is_point_in_polygon(p,Map.coast):
    inside+=1;assert(not World.water(p,true,0),"Boat collision matches the rendered coast")
 assert(inside>100)
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://kelaa-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
 var island=game.get_node("KelaaIsland")
 assert(island.house_count>=100 and island.house_count<=195,"Dense but bounded village geometry")
 assert(island.palm_count>=100 and island.palm_count<400,"Palms have a bounded instancing budget")
 assert(island.chunk_count<30 and island.batches.is_empty(),"Buildings/roads are batched by area, not separate nodes for every wall")
 assert("Hukuru Miskiyy" in island.mapped_landmarks and "Masjid Al-Zahra" in island.mapped_landmarks,"Recognisable mapped landmarks inform the recreation")
 var triangles=0;var draws=0
 for child in island.get_children():
  if child is MeshInstance3D:
   draws+=child.mesh.get_surface_count()
   for surface in range(child.mesh.get_surface_count()):triangles+=child.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()/3
 assert(draws<35 and triangles<25000,"Village and terrain stay within a small static geometry budget")
 assert(game.navigation.set_destination(Vector2(2.3,12),Vector2(game.SPOT.x,game.SPOT.z),"Lagoon"),"A safe route leaves the rebuilt harbour")
 for i in range(game.navigation.route.size()-1):assert(game.navigation.clear_line(game.navigation.route[i],game.navigation.route[i+1]))
 game.sell();assert(game.market_mode,"Home mooring still opens the market")
 game.leave_fishing();game.open_shop();assert(game.shop_mode,"Home mooring still opens the equipment shop")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: real coastline/roads, village and palm budgets, landmarks, shoreline collision, all fishing spots, harbour routes and shop access")
 quit()
