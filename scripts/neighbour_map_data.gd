extends RefCounted
const Base=preload("res://scripts/kelaa_map_data.gd")
const Harbours=preload("res://scripts/island_harbours.gd")
static var maps: Dictionary=Harbours.raw_maps
static var outlines: Dictionary={}
static var boxes: Dictionary={}
var data: Dictionary
var coast: PackedVector2Array
var bounds: Rect2
var breakwaters: Array[PackedVector2Array]=[]
func _init(title: String):
 data=maps[title];coast=outline(title);bounds=boxes[title]
 for wall in Harbours.get_port(title).walls:breakwaters.append(wall)
static func outline(title: String) -> PackedVector2Array:
 if not outlines.has(title):
  outlines[title]=Harbours.get_port(title).coast;boxes[title]=Base.polygon_bounds(outlines[title])
 return outlines[title]
static func blocks_water(at: Vector2,title: String,margin: float) -> bool:
 var polygon=outline(title)
 if not boxes[title].grow(margin).has_point(at):return false
 if Geometry2D.is_point_in_polygon(at,polygon):return true
 for i in range(polygon.size()):
  if Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()]).distance_squared_to(at)<margin*margin:return true
 return false
static func points(values: Array) -> PackedVector2Array:return Base.points(values)
static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:return Base.polygon_bounds(polygon)
