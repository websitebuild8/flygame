extends Control
var game: Node3D
const WHITE=Color("fff9e9")
func text(value: String,at: Vector2,px: int,color: Color=WHITE,width: float=360) -> void:
	var font=ThemeDB.fallback_font
	draw_string_outline(font,at,value,HORIZONTAL_ALIGNMENT_CENTER,width,px,4,Color(.04,.09,.12,.9))
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_CENTER,width,px,color)
func _draw() -> void:
	if not game or not game.fishing:return
	var f=game.fight;var mid=size.x*.5
	if not f.hooked:
		text("BITE!",Vector2(mid-180,18),22,Color("ffdc64"))
		var x=mid-13
		draw_style_box(box(Color("25343a"),7),Rect2(x-4,31,34,118))
		draw_style_box(box(Color("bfcac8"),4),Rect2(x-1,34,28,112))
		for i in range(3):draw_rect(Rect2(x+3,38+i*34,20,34),[Color("ee6940"),Color("f6c553"),Color("6dd348")][i])
		var y=38+game.hook_timing()*102
		draw_line(Vector2(x-8,y),Vector2(x+32,y),Color.WHITE,4,true)
		text("HOOK",Vector2(mid-180,177),15)
		return
	var c=Vector2(mid,228);var radius=190.0
	var a0=PI*1.20;var a1=PI*1.80
	draw_arc(c,radius,a0,a1,80,Color("18252e"),30,true)
	draw_arc(c,radius,a0,a1,80,Color("c6d0ce"),24,true)
	draw_arc(c,radius,a0,a1,80,Color("49585e"),19,true)
	for i in range(80):
		var t=float(i)/80
		var color=Color("ffb927") if t<.65 else (Color("77d527") if t<.90 else Color("f16c40"))
		draw_arc(c,radius,a0+(a1-a0)*t,a0+(a1-a0)*(t+1.0/80),2,color,13,true)
	if f.power_charge>.01:draw_arc(c,radius+17,a0,a0+(a1-a0)*f.power_charge,80,Color("c3f664"),4,true)
	var needle=a0+(a1-a0)*f.tension
	var p=c+Vector2(cos(needle),sin(needle))*radius
	draw_line(p-Vector2(cos(needle),sin(needle))*12,p+Vector2(cos(needle),sin(needle))*12,Color("f7fcf3"),4,true)
	var label="POWER REEL!" if f.power_time>0 else ("ESCAPING" if f.running else "")
	if game.feedback.hook_rating_time>0:label=game.feedback.hook_rating.replace(" HOOK","")
	if f.tension>.86:label="HIGH TENSION"
	if not label.is_empty():text(label,Vector2(mid-180,26),24,Color("a8ee45") if label=="PERFECT" else Color("ffb04c"))
	var badge=Vector2(mid,127)
	draw_circle(badge,21,Color(.04,.09,.12,.75))
	draw_arc(badge,19,-PI/2,PI*1.5,32,Color("ef583d") if f.running else Color("78dbc0"),4,true)
	var fish=PackedVector2Array([badge+Vector2(-11,0),badge+Vector2(-4,-5),badge+Vector2(7,-3),badge+Vector2(12,-8),badge+Vector2(12,8),badge+Vector2(6,3),badge+Vector2(-4,5)])
	draw_colored_polygon(fish,Color("f36645") if f.running else WHITE)
	text("%d m"%roundi(f.position.distance_to(f.origin)),Vector2(mid-180,172),24,Color("ffd669"))
	if game.reeling:
		text("−%d"%roundi(f.pull_strength),Vector2(mid+23,135),23,Color("ff7143"),110)
	text("SWIPE ↑ POWER REEL" if f.power_charge>=1 else "FISH STAMINA  %d%%"%roundi((1-f.progress)*100),Vector2(mid-180,195),12)
func box(color: Color,radius: int) -> StyleBoxFlat:
	var b=StyleBoxFlat.new();b.bg_color=color;b.set_corner_radius_all(radius);return b
