extends RefCounted
## Harbour locations/orientations follow the available OSM harbour/wall data.
## Narrow real basins are widened at game scale so all playable boats can enter.
const Base=preload("res://scripts/kelaa_map_data.gd")
const Home=preload("res://scripts/harbour_layout.gd")
static var raw_maps: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/neighbours/islands.json"))
static var ports: Dictionary={}
static func local_point(port: Dictionary,u: float,v: float) -> Vector2:return port.origin+port.inward*u+port.along*v
static func points_polygon(port: Dictionary) -> PackedVector2Array:
 return PackedVector2Array([local_point(port,-port.depth,-port.half),local_point(port,port.land,-port.half),local_point(port,port.land,port.half),local_point(port,-port.depth,port.half)])
static func get_port(title: String) -> Dictionary:
 if ports.has(title):return ports[title]
 var port: Dictionary
 if title=="HA. Kelaa":
  port={"name":title,"origin":Vector2(23,16),"inward":Vector2.RIGHT,"along":Vector2.DOWN,"depth":33.0,"land":0.0,"half":14.0,"gate":6.0,"dock":Home.HOME,"entrance":Home.ENTRANCE,"coast":Base.coast,"source":"Mapped Kelaa harbour, widened game basin","theme":0}
 else:
  var data: Dictionary=raw_maps[title];var coast=Base.points(data.coast);var box=Base.polygon_bounds(coast)
  var reference=PackedVector2Array();var source="Coast-based approximation; harbour footprint unavailable"
  for feature in data.harbour:
   if feature.tags.get("landuse","")=="harbour":reference=Base.points(feature.points);source="OSM harbour "+str(feature.osm_id);break
  if reference.is_empty():
   for feature in data.harbour:
    if feature.tags.get("leisure","")=="marina":reference=Base.points(feature.points);source="OSM marina "+str(feature.osm_id);break
  if reference.is_empty():
   for feature in data.harbour:reference.append_array(Base.points(feature.points))
   if not reference.is_empty():source="OSM pier/wall locations; approximated harbour footprint"
  var target=Base.polygon_bounds(reference).get_center() if not reference.is_empty() else box.get_center()+Vector2(-box.size.x,0)
  var nearest=Vector2.ZERO;var tangent=Vector2.DOWN;var distance=INF
  for i in range(coast.size()):
   var a=coast[i];var b=coast[(i+1)%coast.size()];var p=Geometry2D.get_closest_point_to_segment(target,a,b)
   if p.distance_squared_to(target)<distance:nearest=p;tangent=(b-a).normalized();distance=p.distance_squared_to(target)
  var outward=Vector2(tangent.y,-tangent.x)
  if Geometry2D.is_point_in_polygon(nearest+outward*1.5,coast):outward=-outward
  var inward=-outward;var along=Vector2(-inward.y,inward.x)
  var half=12.0
  if not reference.is_empty():
   var low=INF;var high=-INF
   for p in reference:low=minf(low,(p-nearest).dot(along));high=maxf(high,(p-nearest).dot(along))
   half=clampf((high-low)*.7,11,17)
  port={"name":title,"origin":nearest,"inward":inward,"along":along,"depth":18.0,"land":6.0,"half":half,"gate":5.5,"source":source,"theme":["HA. Filladhoo","HA. Vashafaru","HA. Dhidhdhoo","HA. Baarah"].find(title)+1}
  port.dock=local_point(port,0,0);port.entrance=local_point(port,-port.depth,0)
  var pieces=Geometry2D.clip_polygons(coast,points_polygon(port))
  while pieces.size()>1 and port.land>1:
   port.land*=.5;pieces=Geometry2D.clip_polygons(coast,points_polygon(port))
  var largest=PackedVector2Array()
  for piece in pieces:
   if piece.size()>largest.size():largest=piece
  port.coast=largest if not largest.is_empty() else coast
 port.polygon=points_polygon(port)
 port.walls=[PackedVector2Array([local_point(port,-port.depth,-port.half),local_point(port,port.land,-port.half)]),PackedVector2Array([local_point(port,-port.depth,port.half),local_point(port,port.land,port.half)]),PackedVector2Array([local_point(port,-port.depth,-port.half),local_point(port,-port.depth,-port.gate)]),PackedVector2Array([local_point(port,-port.depth,port.gate),local_point(port,-port.depth,port.half)]),PackedVector2Array([local_point(port,port.land,-port.half),local_point(port,port.land,port.half)])]
 ports[title]=port;return port
static func all_ports() -> Array:
 var result=[]
 for title in ["HA. Kelaa","HA. Filladhoo","HA. Vashafaru","HA. Dhidhdhoo","HA. Baarah"]:result.append(get_port(title))
 return result
static func containing(at: Vector2) -> String:
 for port in all_ports():
  if Geometry2D.is_point_in_polygon(at,port.polygon):return port.name
 return ""
static func berth_at(at: Vector2) -> String:
 for port in all_ports():
  if at.distance_squared_to(port.dock)<64 and Geometry2D.is_point_in_polygon(at,port.polygon):return port.name
 return ""
static func blocks_walls(at: Vector2,margin: float) -> bool:
 for port in all_ports():
  if not Base.polygon_bounds(port.polygon).grow(margin+2).has_point(at):continue
  for wall in port.walls:
   if Geometry2D.get_closest_point_to_segment(at,wall[0],wall[1]).distance_squared_to(at)<pow(margin+.6,2):return true
 return false
