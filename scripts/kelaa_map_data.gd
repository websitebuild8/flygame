extends RefCounted
## Shared geometry for the island, navigation and every chart. North is -Z.
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/kelaa/kelaa.json"))
const Harbour=preload("res://scripts/harbour_layout.gd")
static var mapped_coast=points(data.coast)
static var coast=carve_harbour()
static func carve_harbour() -> PackedVector2Array:
	var pieces=Geometry2D.clip_polygons(mapped_coast,Harbour.polygon())
	var largest=PackedVector2Array()
	for piece in pieces:
		if piece.size()>largest.size():largest=piece
	return largest
static var bounds=polygon_bounds(coast)
static var breakwaters=wall_paths()
static func wall_paths() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for wall in Harbour.WALLS:result.append(PackedVector2Array(wall))
	return result
static func points(values: Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for p in values:result.append(Vector2(p[0],p[1]))
	return result
static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var rect=Rect2(polygon[0],Vector2.ZERO)
	for p in polygon:rect=rect.expand(p)
	return rect
static func blocks_water(at: Vector2,margin: float) -> bool:
	if not bounds.grow(margin+25).has_point(at):return false
	for path in breakwaters:
		for i in range(path.size()-1):
			if Geometry2D.get_closest_point_to_segment(at,path[i],path[i+1]).distance_squared_to(at)<pow(margin+.6,2):return true
	if Geometry2D.is_point_in_polygon(at,coast):return true
	for i in range(coast.size()):
		if Geometry2D.get_closest_point_to_segment(at,coast[i],coast[(i+1)%coast.size()]).distance_squared_to(at)<margin*margin:return true
	return false
