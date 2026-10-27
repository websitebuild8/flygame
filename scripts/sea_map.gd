extends Control
const World=preload("res://scripts/world_data.gd")
var game: Node3D
var selected_label: Label
var map_rect=Rect2()
const MINT=Color("8bdecb")
const GOLD=Color("f2c37e")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(550,360)
func chart_rect() -> Rect2:
	var side=minf(size.x-36,size.y-44)
	return Rect2(Vector2((size.x-side)/2,16),Vector2(side,side))
func chart(point: Vector2) -> Vector2:
	var rect=chart_rect()
	return rect.position+(point+Vector2.ONE*World.CHART_HALF)/(World.CHART_HALF*2)*rect.size
func sea(point: Vector2) -> Vector2:
	var rect=chart_rect()
	return (point-rect.position)/rect.size*(World.CHART_HALF*2)-Vector2.ONE*World.CHART_HALF
func text(text_value: String, at: Vector2, color: Color=Color("a9c5cc"), font_size: int=13) -> void:
	draw_string(ThemeDB.fallback_font,at,text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _gui_input(event: InputEvent) -> void:
	var at=Vector2.ZERO
	var pressed=false
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		at=event.position
		pressed=event.pressed
	elif event is InputEventScreenTouch:
		at=event.position
		pressed=event.pressed
	if not pressed or not chart_rect().has_point(at):
		return
	var target=sea(at)
	var title="Custom waypoint"
	var nearest_distance=18.0
	for spot in World.SPOTS:
		var d=target.distance_to(spot.at)
		if d<nearest_distance:
			if game.catches<int(spot.unlock):
				selected_label.text="%s unlocks after %d catches." % [spot.name,spot.unlock]
				return
			target=spot.at
			title=spot.name
			break
	for port in World.Harbours.all_ports():
		if target.distance_to(port.dock)<18:
			target=port.dock;title=port.name+" harbour / market";break
	if game.set_waypoint(target,title):
		selected_label.text="Route set to %s. Return to helm and follow the chart." % title
	else:
		selected_label.text="Choose open water or an unlocked fishing marker."
	queue_redraw()
func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
func _draw() -> void:
	if not game:
		return
	var rect=chart_rect()
	draw_rect(rect,Color("123746"))
	for i in range(11):
		var v=-World.CHART_HALF+i*(World.CHART_HALF/5)
		draw_line(chart(Vector2(v,-World.CHART_HALF)),chart(Vector2(v,World.CHART_HALF)),Color("204754"),1)
		draw_line(chart(Vector2(-World.CHART_HALF,v)),chart(Vector2(World.CHART_HALF,v)),Color("204754"),1)
	if not game.unlocked:
		var a=chart(Vector2(World.EAST_UNLOCK,-World.CHART_HALF))
		draw_rect(Rect2(a,Vector2(rect.end.x-a.x,rect.size.y)),Color(0.02,0.07,0.12,0.55))
	for island in World.ISLANDS:
		var radius=island.radius/(World.CHART_HALF*2)*rect.size.x
		var outline=PackedVector2Array()
		for p in World.outline(island):outline.append(chart(p))
		draw_colored_polygon(outline,Color("b6bd83"))
		draw_polyline(outline+PackedVector2Array([outline[0]]),Color("dcc998"),2,true)
		text(island.name,chart(island.at)+Vector2(-30,-radius-6),Color("d5e4dd"),12)
	for spot in World.SPOTS:
		var p=chart(spot.at)
		var open=game.catches>=int(spot.unlock)
		draw_arc(p,7,0,TAU,24,GOLD if open else Color("70848f"),2,true)
		draw_circle(p,2,GOLD if open else Color("70848f"))
		text(spot.name,p+Vector2(9,4),GOLD if open else Color("70848f"),11)
	for port in World.Harbours.all_ports():
		var dock=chart(port.dock)
		draw_rect(Rect2(dock-Vector2(4,4),Vector2(8,8)),Color.WHITE)
		for wall in port.walls:draw_line(chart(wall[0]),chart(wall[1]),Color("cfceb5"),1.5,true)
	if game.navigation.has_destination:
		var route=game.navigation.route
		for i in range(route.size()-1):
			draw_dashed_line(chart(route[i]),chart(route[i+1]),GOLD,2,7,true)
		var pin=chart(game.navigation.destination)
		draw_arc(pin,11,0,TAU,24,GOLD,2,true)
		draw_line(pin+Vector2(-15,0),pin+Vector2(15,0),GOLD,1)
		draw_line(pin+Vector2(0,-15),pin+Vector2(0,15),GOLD,1)
	var boat_at=chart(Vector2(game.boat.position.x,game.boat.position.z))
	var angle=-game.boat.rotation.y
	var triangle=PackedVector2Array()
	for p in [Vector2(0,-10),Vector2(6,7),Vector2(0,4),Vector2(-6,7)]:
		triangle.append(boat_at+p.rotated(angle))
	draw_colored_polygon(triangle,MINT)
	text("N ↑",rect.position+Vector2(9,21),Color.WHITE,18)
	text("200 m",rect.end-Vector2(85,10),Color.WHITE,12)
	draw_line(rect.end-Vector2(10+rect.size.x*200.0/(World.CHART_HALF*2),24),rect.end-Vector2(10,24),Color.WHITE,2)
