extends RefCounted
const World = preload("res://scripts/world_data.gd")
var grid = AStarGrid2D.new()
var region_open = false
var destination = Vector2.ZERO
var has_destination = false
var destination_name = ""
var route = PackedVector2Array()
var last_origin = Vector2(INF,INF)
var arrived = false

func configure(unlocked: bool) -> void:
	region_open = unlocked
	grid.region = Rect2i(-130,-130,261,261)
	grid.cell_size = Vector2(5,5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(-130,131):
		for y in range(-130,131):
			grid.set_point_solid(Vector2i(x,y),not World.water(Vector2(x*5,y*5),unlocked,World.NAV_CLEARANCE))

func cell(point: Vector2) -> Vector2i:
	return Vector2i(roundi(point.x/5),roundi(point.y/5))

func clear_line(a: Vector2,b: Vector2) -> bool:
	var steps = maxi(1,ceili(a.distance_to(b)/1.5))
	for i in range(steps+1):
		if not World.water(a.lerp(b,float(i)/steps),region_open,World.NAV_CLEARANCE):
			return false
	return true

func set_destination(origin: Vector2, target: Vector2, title: String) -> bool:
	if not World.water(target,region_open,World.NAV_CLEARANCE) or not grid.is_in_boundsv(cell(target)) or grid.is_point_solid(cell(target)):
		return false
	var old_target = destination
	var old_name = destination_name
	var old_route = route.duplicate()
	destination = target
	destination_name = title
	if not rebuild(origin):
		destination=old_target
		destination_name=old_name
		route=old_route
		return false
	has_destination = true
	arrived = false
	return true

func rebuild(origin: Vector2) -> bool:
	var start = cell(origin)
	if not grid.is_in_boundsv(start) or grid.is_point_solid(start):
		return false
	var raw = grid.get_point_path(start,cell(destination))
	if raw.is_empty():
		return false
	var points = PackedVector2Array([origin])
	for point in raw:
		points.append(point)
	points.append(destination)
	var smooth = PackedVector2Array([origin])
	var index = 0
	while index<points.size()-1:
		var next = index+1
		for j in range(points.size()-1,index,-1):
			if clear_line(points[index],points[j]):
				next=j
				break
		smooth.append(points[next])
		index=next
	route=smooth
	last_origin=origin
	return true

func update(origin: Vector2) -> void:
	if not has_destination:
		return
	arrived=origin.distance_to(destination)<12
	if origin.distance_to(last_origin)>7:
		rebuild(origin)

func remaining(origin: Vector2) -> float:
	if not has_destination or route.size()<2:
		return 0
	var result = origin.distance_to(route[1])
	for i in range(1,route.size()-1):
		result += route[i].distance_to(route[i+1])
	return result

func clear() -> void:
	has_destination=false
	route.clear()
	arrived=false
