extends RefCounted
const World=preload("res://scripts/world_data.gd")
static func clear_water(from: Vector2,to: Vector2,unlocked: bool,radius: float) -> bool:
 var steps=maxi(1,ceili(from.distance_to(to)/.4))
 for i in range(1,steps+1):
  if not World.water(from.lerp(to,float(i)/steps),unlocked,radius):return false
 return true
static func sweeps_circle(from: Vector2,to: Vector2,center: Vector2,radius: float) -> bool:
 return Geometry2D.get_closest_point_to_segment(center,from,to).distance_squared_to(center)<radius*radius
# Navigation retains its conservative route clearance; contact uses a narrow hull capsule.
const HULLS={"skiff":Vector2(.43,.22),"launch":Vector2(.65,.30),"glacier":Vector2(.57,.32),"grady":Vector2(.78,.31)}
static func hull_points(at: Vector2,yaw: float,id: String) -> Array[Vector2]:
 var shape: Vector2=HULLS.get(id,HULLS.skiff);var forward=Vector2(-sin(yaw),-cos(yaw));var points: Array[Vector2]=[]
 for t in [-1.0,-.5,0.0,.5,1.0]:points.append(at+forward*shape.x*t)
 return points
static func hull_clear(at: Vector2,yaw: float,id: String,unlocked: bool) -> bool:
 var shape: Vector2=HULLS.get(id,HULLS.skiff)
 for p in hull_points(at,yaw,id):
  if not World.water(p,unlocked,shape.y+.025):return false
 return true
static func sweep_hull(from: Vector2,to: Vector2,old_yaw: float,new_yaw: float,id: String,unlocked: bool) -> bool:
 var steps=maxi(1,ceili(from.distance_to(to)/.08+absf(angle_difference(old_yaw,new_yaw))/.08))
 var already_clear=hull_clear(from,old_yaw,id,unlocked)
 var previous_clearance=hull_clearance(from,old_yaw,id,unlocked) if not already_clear else 0.0
 for i in range(1,steps+1):
  var t=float(i)/steps
  if not hull_clear(from.lerp(to,t),lerp_angle(old_yaw,new_yaw,t),id,unlocked):
   if already_clear:return false
   # An existing overlap may leave, but never travel deeper through an obstacle.
   var clearance=hull_clearance(from.lerp(to,t),lerp_angle(old_yaw,new_yaw,t),id,unlocked)
   if clearance<=previous_clearance+.0000001:return false
   previous_clearance=clearance
 return true
static func segment_distance(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> float:
 if Geometry2D.segment_intersects_segment(a,b,c,d)!=null:return 0
 return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a,c,d)),b.distance_to(Geometry2D.get_closest_point_to_segment(b,c,d))),minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c,a,b)),d.distance_to(Geometry2D.get_closest_point_to_segment(d,a,b))))
static func hulls_overlap(a: Vector2,heading: float,id: String,b: Vector2,other_heading: float,other_id: String,other_radius: float=.29) -> bool:
 var shape: Vector2=HULLS.get(id,HULLS.skiff);var other: Vector2=HULLS.get(other_id,Vector2(.55,other_radius))
 var f=Vector2(-sin(heading),-cos(heading))*shape.x;var g=Vector2(-sin(other_heading),-cos(other_heading))*other.x
 return segment_distance(a-f,a+f,b-g,b+g)<shape.y+other.y+.025
static func hull_clearance(at: Vector2,yaw: float,id: String,unlocked: bool) -> float:
 var shape: Vector2=HULLS.get(id,HULLS.skiff);var result=INF
 for sample in hull_points(at,yaw,id):
  var clearance=World.SEA_RADIUS-sample.length()
  if not unlocked:clearance=minf(clearance,World.EAST_UNLOCK-sample.x)
  for port in World.Harbours.all_ports():
   if not World.Kelaa.polygon_bounds(port.polygon).grow(4).has_point(sample):continue
   for wall in port.walls:clearance=minf(clearance,sample.distance_to(Geometry2D.get_closest_point_to_segment(sample,wall[0],wall[1]))-.6)
  for island in World.ISLANDS:
   var polygon=World.outline(island)
   if not World.Kelaa.polygon_bounds(polygon).grow(4).has_point(sample):continue
   var distance=INF
   for i in range(polygon.size()):distance=minf(distance,sample.distance_to(Geometry2D.get_closest_point_to_segment(sample,polygon[i],polygon[(i+1)%polygon.size()])))
   clearance=minf(clearance,-distance if Geometry2D.is_point_in_polygon(sample,polygon) else distance)
  result=minf(result,clearance-shape.y-.025)
 return result
