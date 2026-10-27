extends RefCounted
const World=preload("res://scripts/world_data.gd")
static func clear_water(from: Vector2,to: Vector2,unlocked: bool,radius: float) -> bool:
 var steps=maxi(1,ceili(from.distance_to(to)/.4))
 for i in range(1,steps+1):
  if not World.water(from.lerp(to,float(i)/steps),unlocked,radius):return false
 return true
static func sweeps_circle(from: Vector2,to: Vector2,center: Vector2,radius: float) -> bool:
 return Geometry2D.get_closest_point_to_segment(center,from,to).distance_squared_to(center)<radius*radius
