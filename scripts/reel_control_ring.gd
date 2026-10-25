extends Control
var game: Node3D
var title_font: FontVariation
func _ready():
	title_font=FontVariation.new();title_font.base_font=ThemeDB.fallback_font;title_font.variation_embolden=1.0
	title_font.variation_transform=Transform2D(Vector2(1,0),Vector2(-.18,1),Vector2.ZERO)
func _draw() -> void:
	if not game or not game.fishing_view:return
	var c=size*.5;var radius=minf(size.x,size.y)*.5-8
	var pulling=game.reeling or (game.fishing and game.fight.power_time>0)
	var charge=game.fight.power_charge if game.fishing else 0.0
	var power=game.fishing and game.fight.power_time>0
	if charge>=1 or power:
		for i in range(9):draw_circle(c,radius+18-i,Color(1,.67,.12,.015+float(i)*.004))
	draw_circle(c+Vector2(0,4),radius+8,Color(0,0,0,.5))
	draw_circle(c,radius+6,Color("25343a"))
	draw_circle(c,radius+3,Color("d9e2df"))
	draw_circle(c,radius,Color("58696c"))
	draw_circle(c,radius-4,Color("162d34"))
	for i in range(45):
		var t=float(i)/44
		var orange=Color("f58b13").lerp(Color("ffbc3c"),t) if pulling or not game.fishing else Color("99501b").lerp(Color("cb7b24"),t)
		draw_circle(c+Vector2(0,-t*3),radius-7-float(i)*.55,orange)
	draw_arc(c,radius-10,PI*1.12,PI*1.85,48,Color(1,.91,.62,.65),3,true)
	draw_arc(c,radius+1,0,TAU,64,Color("92e5d3"),2,true)
	# Rotating external handle, rather than a generic loading spinner.
	var angle=game.feedback.cast_age*(3.8 if pulling else .15)
	var arm=c+Vector2(cos(angle),sin(angle))*(radius+10)
	draw_line(c+Vector2(cos(angle),sin(angle))*(radius-2),arm,Color("b6c4c5"),7,true)
	var knob=StyleBoxFlat.new();knob.bg_color=Color("28343c");knob.set_corner_radius_all(4);knob.set_border_width_all(2);knob.border_color=Color("a4b7b9")
	draw_style_box(knob,Rect2(arm-Vector2(7,11),Vector2(14,22)))
	var title=game.fish_button.text.split("\n")[0].replace("REEL IN","REEL-IN")
	var width=title_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
	var at=c+Vector2(-width*.5,8)
	draw_string_outline(title_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,21,3,Color(.22,.12,.02,.8))
	draw_string(title_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
	if charge>=1:
		var arrow=PackedVector2Array([c+Vector2(-8,-radius-9),c+Vector2(8,-radius-9),c+Vector2(8,-radius-28),c+Vector2(20,-radius-28),c+Vector2(0,-radius-51),c+Vector2(-20,-radius-28),c+Vector2(-8,-radius-28)])
		draw_colored_polygon(arrow,Color("ffe570"))
