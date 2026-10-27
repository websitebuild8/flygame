extends Control
const Power=preload("res://scripts/marine_power.gd")
const World=preload("res://scripts/world_data.gd")
var game: Node3D
var chart=false
var portrait=false
func text(value: String,at: Vector2,font_size: int,color: Color=Color("e1f8f0")):
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw():
	if not game:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("071b24"))
	if chart:
		var center=size*.5
		var scale_factor=minf(size.x,size.y)/300.0
		var boat_at=Vector2(game.boat.position.x,game.boat.position.z)
		for island in World.ISLANDS:
			var outline=PackedVector2Array()
			for p in World.outline(island):outline.append(center+(p-boat_at)*scale_factor)
			draw_colored_polygon(outline,Color("b6bd85"))
		if game.navigation.has_destination:
			var route=game.navigation.route
			for i in range(route.size()-1):draw_line(center+(route[i]-boat_at)*scale_factor,center+(route[i+1]-boat_at)*scale_factor,Color("f2c37e"),3,true)
			var pin=center+(game.navigation.destination-boat_at)*scale_factor
			draw_arc(pin,7,0,TAU,24,Color("f2c37e"),3,true)
		for spot in World.SPOTS:
			draw_arc(center+(spot.at-boat_at)*scale_factor,4,0,TAU,12,Color("f2c37e"),2,true)
		var arrow=PackedVector2Array()
		for point in [Vector2(0,-13),Vector2(9,10),Vector2(0,5),Vector2(-9,10)]:arrow.append(center+point.rotated(-game.boat.rotation.y))
		draw_colored_polygon(arrow,Color("65e6a1"))
		text("N  •  KELAA",Vector2(12,23),20)
		text("© OpenStreetMap contributors",Vector2(12,size.y-10),12,Color("9abcb9"))
		return
	var power=game.drive.throttle if game.drive.engine_running and game.drive.gear!=0 else 0.0
	var color=Power.color_for(power)
	var gear="N" if game.drive.gear==0 else ("F" if game.drive.gear>0 else "R")
	if portrait:
		text("%.1f" % (absf(game.speed)*1.94384),Vector2(18,85),72)
		text("kn  •  "+gear,Vector2(18,138),38,color)
		text("%d%%" % roundi(power*100),Vector2(18,205),56,color)
		return
	text("ENGINE" if game.drive.engine_running else "ENGINE OFF",Vector2(16,29),22,color)
	text("%.1f kn" % (absf(game.speed)*1.94384),Vector2(16,113),76)
	text("%s   POWER %d%%" % [gear,roundi(power*100)],Vector2(16,165),35,color)
	for level in range(16):
		draw_rect(Rect2(16+level*23,187,18,24),color if power>=float(level+1)/16 else Color("24414a"))
