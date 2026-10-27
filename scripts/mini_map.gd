extends Button
const World=preload("res://scripts/world_data.gd")
var game: Node3D
var redraw_tick=0.0
const RANGE=140.0
const RADIUS=78.0
const CENTER=Vector2(90,90)
const GOLD=Color("f2c37e")
func _ready() -> void:
	flat=true
	tooltip_text="Open sea chart and set a waypoint"
func chart(at: Vector2) -> Vector2:
	return CENTER+(at-Vector2(game.boat.position.x,game.boat.position.z))*RADIUS/RANGE
func circle(at: Vector2,radius: float) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(64): points.append(at+Vector2.from_angle(i*TAU/64)*radius)
	return points
func route_segment(a: Vector2,b: Vector2) -> void:
	var d=b-a
	var offset=a-CENTER
	var length_sq=d.length_squared()
	if length_sq<0.001: return
	var projection=offset.dot(d)
	var discriminant=projection*projection-length_sq*(offset.length_squared()-RADIUS*RADIUS)
	if discriminant<0: return
	var first=maxf(0,(-projection-sqrt(discriminant))/length_sq)
	var last=minf(1,(-projection+sqrt(discriminant))/length_sq)
	if first<=last: draw_line(a+d*first,a+d*last,GOLD,2,true)
func _process(delta: float) -> void:
	redraw_tick+=delta
	if is_visible_in_tree() and redraw_tick>=.10:
		redraw_tick=0;queue_redraw()
func _draw() -> void:
	if not game: return
	draw_circle(CENTER,88,Color(0.025,0.075,0.10,0.95))
	draw_circle(CENTER,RADIUS,Color("174554"))
	var boundary=circle(CENTER,RADIUS)
	for island in World.ISLANDS:
		var outline=PackedVector2Array()
		for p in World.outline(island):outline.append(chart(p))
		for polygon in Geometry2D.intersect_polygons(boundary,outline):draw_colored_polygon(polygon,Color("b8bf89"))
	for port in World.Harbours.all_ports():
		for wall in port.walls:
			var a=chart(wall[0]);var b=chart(wall[1])
			if a.distance_to(CENTER)<RADIUS and b.distance_to(CENTER)<RADIUS:draw_line(a,b,Color("d4d3bd"),2,true)
	if game.navigation.has_destination:
		var route=game.navigation.route
		for i in range(route.size()-1): route_segment(chart(route[i]),chart(route[i+1]))
		var pin=chart(game.navigation.destination)
		pin=CENTER+(pin-CENTER).limit_length(RADIUS-7)
		draw_arc(pin,5,0,TAU,20,GOLD,2,true)
	for spot in World.SPOTS:
		var p=chart(spot.at)
		if p.distance_to(CENTER)<RADIUS-6:
			draw_arc(p,4,0,TAU,16,GOLD if game.catches>=int(spot.unlock) else Color("78909b"),2,true)
	for port in World.Harbours.all_ports():
		var dock=chart(port.dock)
		if dock.distance_to(CENTER)<RADIUS-5:draw_rect(Rect2(dock-Vector2(3,3),Vector2(6,6)),Color.WHITE)
	var boat=PackedVector2Array()
	for p in [Vector2(0,-9),Vector2(6,7),Vector2(0,4),Vector2(-6,7)]: boat.append(CENTER+p.rotated(-game.boat.rotation.y))
	draw_colored_polygon(boat,Color("8bdecb"))
	draw_arc(CENTER,RADIUS,0,TAU,96,Color("7fa9b5"),1.5,true)
	draw_string(ThemeDB.fallback_font,Vector2(85,11),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(67,179),"140 m",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("b7cdd2"))
	draw_string(ThemeDB.fallback_font,Vector2(27,162),"© OpenStreetMap",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b7cdd2"))
